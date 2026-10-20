import 'dart:convert';

const demoSpreadsheetId = '1lu6JabfKowbZhHXrGD9rJeQdbpXNc9_YnTPucSr9_Yg';
const demoHeaders = ['Date', 'Type', 'Category', 'Description', 'Amount', 'Note', 'Bill ID (optional)'];

int sheetDate(DateTime d) => DateTime.utc(d.year, d.month, d.day)
    .difference(DateTime.utc(1899, 12, 30)).inDays;

DateTime parseSheetDate(Object? value) {
  if (value is num) return DateTime.utc(1899, 12, 30).add(Duration(days: value.toInt()));
  final parts = value.toString().split('/');
  if (parts.length == 3) return DateTime.utc(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  throw const FormatException('Invalid sheet date');
}

String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

class Expense {
  const Expense({
    required this.id, required this.account, required this.date,
    required this.category, required this.amount,
    this.description = '', this.note = '', this.billId = '',
  });
  final String id, account, category, description, note, billId;
  final DateTime date;
  final double amount;
  String get marker => '[payday-mobile-id:$id]';
  String get noteWithMarker => note.isEmpty ? marker : '$note $marker';
  Map<String, dynamic> toJson() => {
    'id': id, 'account': account, 'date': date.toIso8601String(),
    'category': category, 'description': description, 'note': note,
    'billId': billId, 'amount': amount,
  };
  factory Expense.fromJson(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    account: m['account'] as String,
    date: DateTime.parse(m['date'] as String),
    category: m['category'] as String,
    description: (m['description'] ?? '') as String,
    note: (m['note'] ?? '') as String,
    billId: (m['billId'] ?? '') as String,
    amount: (m['amount'] as num).toDouble(),
  );
  String encode() => jsonEncode(toJson());
  static Expense decode(String s) => Expense.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class Transaction {
  const Transaction(this.date, this.type, this.category, this.description, this.amount);
  final DateTime date;
  final String type, category, description;
  final double amount;
  factory Transaction.fromRow(List<dynamic> r) => Transaction(
    parseSheetDate(r[0]), '${r[1]}', '${r[2]}',
    r.length > 3 ? '${r[3]}' : '',
    r[4] is num ? (r[4] as num).toDouble() : 0,
  );
}
