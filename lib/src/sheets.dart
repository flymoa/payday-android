import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'model.dart';

class SyncFailure implements Exception {
  const SyncFailure(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

/// This adapter has a fixed DEMO destination. Never writes Transactions.
/// It is single-writer only: concurrent devices need server-side locking.
class DemoSheets {
  DemoSheets(this.accessToken, {http.Client? client}) : client = client ?? http.Client();
  final Future<String> Function() accessToken;
  final http.Client client;
  static const recordId = 1618029098;

  Uri get valuesBase => Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$demoSpreadsheetId/values');
  Uri valuesUri(String range) => Uri.parse('${valuesBase.toString()}/${Uri.encodeComponent(range)}')
      .replace(queryParameters: {'valueRenderOption': 'UNFORMATTED_VALUE'});
  Uri get batchUri => Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$demoSpreadsheetId:batchUpdate');

  Future<Map<String, dynamic>> request(String method, Uri uri, {Object? body}) async {
    try {
      final token = await accessToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      final response = method == 'POST'
          ? await client.post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 18))
          : await client.get(uri, headers: headers).timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) {
        if (response.statusCode == 401) throw const SyncFailure('Google session expired. Reconnect.');
        if (response.statusCode == 403) throw const SyncFailure('Google access denied to the DEMO.');
        throw SyncFailure('Google Sheets HTTP ${response.statusCode}; pending entry kept.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const SyncFailure('Invalid Google response.');
      return decoded;
    } on TimeoutException {
      throw const SyncFailure('Save was not confirmed. Retry with the same ID.');
    } on SocketException {
      throw const SyncFailure('Offline: expense kept in encrypted queue.');
    } on FormatException {
      throw const SyncFailure('Invalid Google response; pending entry kept.');
    }
  }

  Future<List<List<dynamic>>> read(String range) async {
    final r = await request('GET', valuesUri(range));
    return ((r['values'] as List<dynamic>?) ?? [])
        .map((x) => List<dynamic>.from(x as List<dynamic>)).toList();
  }

  Future<void> verifyHeaders() async {
    final r = await read("'Record'!A5:G5");
    if (r.length != 1 || r[0].length != demoHeaders.length) {
      throw const SyncFailure('DEMO Record layout changed; write disabled.');
    }
    for (var i = 0; i < demoHeaders.length; i++) {
      if (r[0][i] != demoHeaders[i]) {
        throw const SyncFailure('DEMO Record layout changed; write disabled.');
      }
    }
  }

  Future<List<String>> categories() async {
    final rows = await read("'Settings'!A19:A50");
    final items = rows.where((r) => r.isNotEmpty && r[0].toString().trim().isNotEmpty)
        .map((r) => r[0].toString().trim()).toSet().toList();
    if (items.isEmpty) throw const SyncFailure('No DEMO categories found.');
    return items;
  }

  Future<List<Transaction>> transactions(DateTime month) async {
    final rows = await read("'Record'!A6:E5005");
    final out = <Transaction>[];
    for (final r in rows) {
      if (r.length < 5 || r[0] == '' || r[0] == null) continue;
      try {
        final entry = Transaction.fromRow(r);
        if (monthKey(entry.date) == monthKey(month)) out.add(entry);
      } catch (_) {
        // Ignore incomplete manual entries, never edit them.
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  bool rowMatches(List<dynamic> row, Expense e) {
    Object? cell(int i) => i < row.length ? row[i] : null;
    return cell(0) is num && (cell(0) as num).toInt() == sheetDate(e.date)
        && cell(1) == 'Expense' && cell(2) == e.category
        && (cell(3) ?? '') == e.description
        && cell(4) is num && ((cell(4) as num).toDouble() - e.amount).abs() < .000001
        && cell(5) == e.noteWithMarker && (cell(6) ?? '') == e.billId;
  }

  /// Null = not present. true = exact same ID and values already saved.
  /// Never retry automatically when the ID is duplicated/altered.
  Future<bool> alreadySaved(Expense e) async {
    final rows = await read("'Record'!A6:G5005");
    final matches = rows.where((r) => r.length > 5 && r[5].toString().contains(e.marker)).toList();
    if (matches.length > 1) throw const SyncFailure('Repeated ID detected: manual review required.');
    if (matches.isEmpty) return false;
    if (!rowMatches(matches.single, e)) {
      throw const SyncFailure('Same ID has different data: manual review required.');
    }
    return true;
  }

  /// Leaves partial manual rows untouched. B is reserved for prefilled formulas.
  int nextAvailable(List<List<dynamic>> rows) {
    int last = -1;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if ([0, 2, 3, 4, 5, 6].any((col) =>
          col < row.length && row[col] != null && row[col].toString() != '')) {
        last = i;
      }
    }
    final result = 6 + last + 1;
    if (result > 5005) throw const SyncFailure('DEMO Record has no free rows.');
    return result;
  }

  Future<void> verifyRowFormula(int rowNumber) async {
    final target = await read("'Record'!A$rowNumber:G$rowNumber");
    if (target.isNotEmpty && [0, 2, 3, 4, 5, 6].any((i) =>
        i < target.first.length && target.first[i] != null
            && target.first[i].toString() != '')) {
      throw const SyncFailure('Target row is occupied. Nothing saved.');
    }
    final uri = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$demoSpreadsheetId')
        .replace(queryParameters: {
          'ranges': "'Record'!B$rowNumber",
          'fields': 'sheets(properties(sheetId),data(rowData(values(userEnteredValue))))'
        });
    final result = await request('GET', uri);
    final sheets = result['sheets'] as List<dynamic>? ?? [];
    if (sheets.length != 1) throw const SyncFailure('Could not inspect formula.');
    final sheet = sheets.first as Map<String, dynamic>;
    final p = sheet['properties'] as Map<String, dynamic>? ?? {};
    if (p['sheetId'] != recordId) throw const SyncFailure('Record tab ID changed.');
    final data = sheet['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) throw const SyncFailure('Formula response empty.');
    final rowData = (data[0] as Map<String, dynamic>)['rowData'] as List<dynamic>? ?? [];
    if (rowData.isEmpty) throw const SyncFailure('Formula response empty.');
    final values = (rowData[0] as Map<String, dynamic>)['values'] as List<dynamic>? ?? [];
    if (values.isEmpty) throw const SyncFailure('Formula response empty.');
    final value = (values[0] as Map<String, dynamic>)['userEnteredValue'] as Map<String, dynamic>? ?? {};
    final f = value['formulaValue']?.toString() ?? '';
    if (!f.startsWith('=IF(') || !f.contains('A$rowNumber') || !f.contains('Expense')) {
      throw const SyncFailure('Automatic Expense formula missing; write blocked.');
    }
  }

  Future<bool> save(Expense e) async {
    if (e.id.isEmpty || e.id.contains(']') || e.amount <= 0 || !e.amount.isFinite ||
        e.amount > 1000000000 || e.description.length > 150 ||
        e.note.length > 150 || e.billId.length > 40) {
      throw const SyncFailure('Invalid expense; nothing saved.');
    }
    await verifyHeaders();
    if (!(await categories()).contains(e.category)) {
      throw const SyncFailure('Expense category is not in DEMO Settings.');
    }
    if (await alreadySaved(e)) return false;
    final rows = await read("'Record'!A6:G5005");
    final rowNumber = nextAvailable(rows);
    await verifyRowFormula(rowNumber);
    Map<String, dynamic> cell(Object v) => {
      'userEnteredValue': v is num ? {'numberValue': v} : {'stringValue': v.toString()}
    };
    Map<String, dynamic> write(int col, List<Object> values) => {
      'updateCells': {
        'range': {'sheetId': recordId, 'startRowIndex': rowNumber - 1,
          'endRowIndex': rowNumber, 'startColumnIndex': col, 'endColumnIndex': col + values.length},
        'rows': [{'values': values.map(cell).toList()}],
        'fields': 'userEnteredValue'
      }
    };
    final result = await request('POST', batchUri, body: {'requests': [
      write(0, [sheetDate(e.date)]),
      write(2, [e.category, e.description, e.amount, e.noteWithMarker, e.billId])
    ]});
    if (result['spreadsheetId'] != demoSpreadsheetId || !await alreadySaved(e)) {
      throw const SyncFailure('Save not verified; expense remains pending.');
    }
    return true;
  }

  void close() => client.close();
}
