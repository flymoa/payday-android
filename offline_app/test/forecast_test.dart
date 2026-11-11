import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';

void main() {
  test('forecast scales spending to the full month, current month only', () {
    final now = DateTime(2026, 11, 10);
    expect(projectedMonthSpend(spentSoFar: 100000, month: DateTime(2026, 11), now: now), 300000);
    expect(projectedMonthSpend(spentSoFar: 100000, month: DateTime(2026, 10), now: now), isNull);
    expect(projectedMonthSpend(spentSoFar: 0, month: DateTime(2026, 11), now: now), isNull);
    expect(projectedMonthSpend(spentSoFar: 2800, month: DateTime(2026, 2), now: DateTime(2026, 2, 28)), 2800);
  });

  test('category month total counts only that category, month and Expense type', () {
    final tx = [
      {'type': 'Expense', 'category': 'Groceries', 'date': '2026-11-02', 'amount': 1000},
      {'type': 'Expense', 'category': 'Groceries', 'date': '2026-11-20', 'amount': 250},
      {'type': 'Expense', 'category': 'Groceries', 'date': '2026-10-31', 'amount': 999},
      {'type': 'Income', 'category': 'Groceries', 'date': '2026-11-05', 'amount': 5000},
      {'type': 'Expense', 'category': 'Leisure', 'date': '2026-11-05', 'amount': 700},
    ];
    expect(categoryMonthTotal(tx, 'Groceries', '2026-11'), 1250);
    expect(categoryMonthTotal(tx, 'Groceries', '2026-09'), 0);
  });
}
