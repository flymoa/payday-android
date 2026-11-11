import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/ledger.dart';

void main() {
  final l = Ledger({
    'transactions': [
      {'id': 1, 'date': '2026-11-02', 'type': 'Expense', 'category': 'Utilities', 'amount': 30000, 'bill_id': 'ELEC'},
      {'id': 2, 'date': '2026-11-03', 'type': 'Expense', 'category': 'Groceries', 'amount': 5000, 'bill_id': ''},
      {'id': 3, 'date': '2026-10-05', 'type': 'Savings out', 'category': 'Savings', 'amount': 100000, 'bill_id': ''},
      {'id': 4, 'date': '2026-11-06', 'type': 'Savings in', 'category': 'Savings', 'amount': 20000, 'bill_id': ''},
    ],
    'bills': [
      {'code': 'ELEC', 'due': '2026-11-15', 'amount': 50000},
      {'code': 'NET', 'due': '2026-11-20', 'amount': 25000},
      {'code': 'OLD', 'due': '2026-10-20', 'amount': 99900},
    ],
    'budgets': [
      {'month': '2026-11', 'category': 'Groceries', 'amount': 80000},
      {'month': '2026-10', 'category': 'Groceries', 'amount': 1},
    ],
    'month_closes': [
      {'month': '2026-10', 'entries_ok': 1, 'balance_ok': 1, 'extra': 7000},
      {'month': '2026-09', 'entries_ok': 1, 'balance_ok': 0, 'extra': 9999},
    ],
    'allocations': [{'amount': 3000}, {'amount': 2000}],
    'settings': [{'key': 'opening_savings', 'value': '50000'}],
    'reserves': [
      {'id': 1, 'target': 120000, 'funded': 0, 'due': '2027-04-30', 'start_month': '2026-11'},
    ],
    'reserve_movements': [
      {'id': 1, 'reserve_id': 1, 'date': '2026-11-01', 'kind': 'add', 'amount': 10000},
      {'id': 2, 'reserve_id': 1, 'date': '2026-11-09', 'kind': 'release', 'amount': 2000},
    ],
  });

  test('bills: partial payments count, only the chosen month is unpaid', () {
    expect(l.billPaid({'code': 'ELEC'}), 30000);
    expect(l.unpaidBills('2026-11'), 20000 + 25000);
  });
  test('budgets and month filters', () {
    expect(l.budgetFor('2026-11', 'Groceries'), 80000);
    expect(l.budgetFor('2026-11', 'Leisure'), 0);
    expect(l.monthTransactions('2026-11'), hasLength(3));
  });
  test('savings pool counts only fully confirmed month closes', () {
    expect(l.totalPool(), 50000 + 100000 - 20000 + 7000);
    expect(l.allocated(), 5000);
    expect(l.buffer(), 20000);
  });
  test('reserves: net month movement, history order and remaining hold', () {
    expect(l.reserveNetForMonth('2026-11'), 8000);
    expect(l.reserveHistory(1).map((r) => r['id']), [2, 1]);
    expect(l.reserveFundedAt(l.rows('reserves').single, '2026-10'), 0);
    // 1,200.00 over 6 months = 200.00/month, minus 80.00 already put aside.
    expect(l.monthlyReserves('2026-11'), 12000);
  });
}
