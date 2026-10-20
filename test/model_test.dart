import 'package:flutter_test/flutter_test.dart';
import 'package:payday_mobile/src/model.dart';

void main() {
  test('Date to Google Sheets serial matches real DEMO', () {
    expect(sheetDate(DateTime(2026, 1, 1)), 46023);
    expect(parseSheetDate(46023), DateTime.utc(2026, 1, 1));
  });
  test('Backdated expenses belong to their own month', () {
    expect(monthKey(DateTime(2026, 9, 30)), '2026-09');
    expect(monthKey(DateTime(2026, 10, 1)), '2026-10');
  });
  test('Expense queue serialization preserves ID and amount', () {
    const email = 'sample@example.invalid';
    final e = Expense(
      id: 'test-001', account: email, date: DateTime(2026, 10, 20),
      category: 'Groceries', amount: 1.25, description: 'test');
    final restored = Expense.decode(e.encode());
    expect(restored.id, e.id);
    expect(restored.amount, 1.25);
    expect(restored.account, email);
    expect(restored.marker, '[payday-mobile-id:test-001]');
  });
}
