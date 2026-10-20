import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:payday_mobile/src/model.dart';
import 'package:payday_mobile/src/sheets.dart';

class FakeDemo {
  FakeDemo({this.validFormula = true, this.changedHeaders = false, this.failPostAfterSave = false});
  final bool validFormula, changedHeaders, failPostAfterSave;
  final Expense example = Expense(
    id: 'sync-test-uuid-001',
    account: 'test@example.invalid',
    date: DateTime(2026, 10, 20),
    category: 'Groceries',
    amount: 1.25,
    description: 'Android test purchase',
    note: 'Test',
  );

  bool saved = false;
  int writeCount = 0;
  List<dynamic>? lastRequests;

  http.Response response(Object data) =>
    http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});

  http.Client client() => MockClient((request) async {
    final url = request.url;
    if (request.method == 'GET' && url.path.contains('/values/')) {
      final range = url.pathSegments.last;
      if (range.contains('Record') && range.contains('A5:G5')) {
        return response({'values': [changedHeaders
          ? ['Wrong', ...demoHeaders.skip(1)]
          : demoHeaders]});
      }
      if (range.contains('Settings')) {
        return response({'values': [['Groceries'], ['Housing'], ['Transport']]});
      }
      if (range.contains('Record') && range.contains('A6:G5005')) {
        return response({'values': saved
            ? [[sheetDate(example.date), 'Expense', example.category,
                example.description, example.amount,
                example.noteWithMarker, example.billId]]
            : []});
      }
      if (range.contains('Record') && range.contains('A6:G6')) {
        return response({'values': saved
            ? [[sheetDate(example.date), 'Expense', example.category,
                example.description, example.amount,
                example.noteWithMarker, example.billId]]
            : []});
      }
      return response({'values': []});
    }
    if (request.method == 'GET' && url.path.endsWith('/$demoSpreadsheetId')) {
      final value = validFormula ? {'formulaValue': '=IF(A6="";"";"Expense")'} : {};
      return response({'sheets': [
        {'properties': {'sheetId': DemoSheets.recordId},
         'data': [{'rowData': [{'values': [{'userEnteredValue': value}]}]}]}
      ]});
    }
    if (request.method == 'POST' && url.path.endsWith(':batchUpdate')) {
      writeCount++;
      lastRequests = (jsonDecode(request.body) as Map<String, dynamic>)['requests'] as List<dynamic>;
      saved = true;
      if (failPostAfterSave && writeCount == 1) throw const SocketException('network dropped after commit');
      return response({'spreadsheetId': demoSpreadsheetId, 'replies': [{}, {}]});
    }
    return http.Response('unexpected request ${request.method} $url', 404);
  });
}

void main() {
  test('first expense writes A and C:G, never overwrites formula in B', () async {
    final fake = FakeDemo();
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    expect(await sheets.save(fake.example), isTrue);
    expect(fake.writeCount, 1);
    final writes = fake.lastRequests!;
    expect(writes, hasLength(2));
    final first = (writes[0] as Map<String, dynamic>)['updateCells'] as Map<String, dynamic>;
    final second = (writes[1] as Map<String, dynamic>)['updateCells'] as Map<String, dynamic>;
    expect((first['range'] as Map)['startColumnIndex'], 0);
    expect((first['range'] as Map)['endColumnIndex'], 1);
    expect((second['range'] as Map)['startColumnIndex'], 2);
    expect((second['range'] as Map)['endColumnIndex'], 7);
    sheets.close();
  });

  test('same identifier is verified rather than saved twice', () async {
    final fake = FakeDemo();
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    expect(await sheets.save(fake.example), isTrue);
    expect(await sheets.save(fake.example), isFalse);
    expect(fake.writeCount, 1);
    sheets.close();
  });

  test('network fails after commit: a retry verifies the existing entry', () async {
    final fake = FakeDemo(failPostAfterSave: true);
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    await expectLater(sheets.save(fake.example), throwsA(isA<SyncFailure>()));
    expect(fake.saved, isTrue);
    expect(await sheets.save(fake.example), isFalse);
    expect(fake.writeCount, 1);
    sheets.close();
  });

  test('missing Expense formula blocks all writes', () async {
    final fake = FakeDemo(validFormula: false);
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    await expectLater(sheets.save(fake.example), throwsA(isA<SyncFailure>()));
    expect(fake.writeCount, 0);
    sheets.close();
  });

  test('changed DEMO Record header blocks all writes', () async {
    final fake = FakeDemo(changedHeaders: true);
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    await expectLater(sheets.save(fake.example), throwsA(isA<SyncFailure>()));
    expect(fake.writeCount, 0);
    sheets.close();
  });

  test('invalid categories cannot be inserted', () async {
    final fake = FakeDemo();
    final sheets = DemoSheets(() async => 'test-token', client: fake.client());
    final wrong = Expense(
      id: 'bad-category',
      account: fake.example.account, date: fake.example.date,
      category: 'Unknown category', amount: 50,
    );
    await expectLater(sheets.save(wrong), throwsA(isA<SyncFailure>()));
    expect(fake.writeCount, 0);
    sheets.close();
  });
}
