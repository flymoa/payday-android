import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/ledger.dart';

class LockStore extends OfflineStore {
  LockStore(Database database) : super(database: database);
  @override
  Future<void> close() async {}
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late LockStore store;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
    await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
    await db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, target INTEGER NOT NULL)');
    await db.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL)');
    await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.insert('settings', {'key': 'opening_savings', 'value': '0'});
    await db.insert('goals', {'id': 1, 'name': 'Holiday', 'target': 1000000});
    store = LockStore(db);
  });
  tearDown(() async {
    await db.close();
  });

  Future<void> closeMonth(String month, {int extra = 0}) => db.insert('month_closes',
      {'month': month, 'entries_ok': 1, 'balance_ok': 1, 'extra': extra, 'opening_balance': 0},
      conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> save(String date, {int? id}) => store.saveTransaction(
      id: id, date: date, type: 'Expense', category: 'Groceries',
      amount: 1000, description: '', note: '', billId: '');
  Future<int> seedExpense(String date) => db.insert('transactions',
      {'date': date, 'type': 'Expense', 'category': 'Groceries', 'description': '', 'amount': 500, 'note': '', 'bill_id': ''});

  group('closed month lock', () {
    test('open months can be changed', () async {
      await closeMonth('2026-08');
      await save('2026-09-05');
      final id = await seedExpense('2026-09-06');
      await save('2026-09-07', id: id);
      await store.removeTransaction(id);
      expect(await db.query('transactions'), hasLength(1));
    });

    test('adding to a closed month is rejected', () async {
      await closeMonth('2026-09');
      await expectLater(save('2026-09-05'), throwsA(isA<StateError>()));
      expect(await db.query('transactions'), isEmpty);
    });

    test('editing, moving out of, or deleting in a closed month is rejected', () async {
      final id = await seedExpense('2026-09-06');
      await closeMonth('2026-09');
      await expectLater(save('2026-09-07', id: id), throwsA(isA<StateError>()));
      await expectLater(save('2026-10-07', id: id), throwsA(isA<StateError>()));
      await expectLater(store.removeTransaction(id), throwsA(isA<StateError>()));
      await expectLater(store.deleteTransactionForUndo(id), throwsA(isA<StateError>()));
      final row = (await db.query('transactions')).single;
      expect(row['date'], '2026-09-06');
      expect(row['amount'], 500);
    });

    test('moving a transaction into a closed month is rejected', () async {
      final id = await seedExpense('2026-10-06');
      await closeMonth('2026-09');
      await expectLater(save('2026-09-20', id: id), throwsA(isA<StateError>()));
      expect((await db.query('transactions')).single['date'], '2026-10-06');
    });

    test('a half-confirmed close does not lock the month', () async {
      await db.insert('month_closes', {'month': '2026-09', 'entries_ok': 1, 'balance_ok': 0, 'extra': 0, 'opening_balance': 0});
      await save('2026-09-05');
      expect(await db.query('transactions'), hasLength(1));
    });

    test('reopening unlocks the month and keeps the entered values', () async {
      await closeMonth('2026-09', extra: 2500);
      await expectLater(save('2026-09-05'), throwsA(isA<StateError>()));
      await store.reopenMonth('2026-09');
      await save('2026-09-05');
      final close = (await db.query('month_closes')).single;
      expect(close['entries_ok'], 0);
      expect(close['balance_ok'], 0);
      expect(close['extra'], 2500);
    });
  });

  group('allocations', () {
    test('rejects an open month, unknown goal and amounts above unassigned savings', () async {
      await db.insert('transactions', {'date': '2026-09-01', 'type': 'Savings out', 'category': 'Savings', 'amount': 100000});
      await expectLater(store.allocate('2026-09', 1, 1000), throwsA(isA<StateError>()));
      await closeMonth('2026-09');
      await expectLater(store.allocate('2026-09', 99, 1000), throwsA(isA<StateError>()));
      await store.allocate('2026-09', 1, 60000);
      await expectLater(store.allocate('2026-09', 1, 40001), throwsA(isA<StateError>()));
      await store.allocate('2026-09', 1, 40000);
      expect(await db.query('allocations'), hasLength(2));
    });

    test('lowering extra savings cannot leave goals over-allocated', () async {
      await closeMonth('2026-09', extra: 50000);
      await store.allocate('2026-09', 1, 30000);
      await expectLater(
          store.saveMonthClose('2026-09', entriesOk: true, balanceOk: true, extra: 20000, openingBalance: 0),
          throwsA(isA<StateError>()));
      expect((await db.query('month_closes')).single['extra'], 50000);
      await store.saveMonthClose('2026-09', entriesOk: true, balanceOk: true, extra: 30000, openingBalance: 0);
      expect((await db.query('month_closes')).single['extra'], 30000);
    });

    test('a month with allocations cannot be reopened', () async {
      await closeMonth('2026-09', extra: 50000);
      await store.allocate('2026-09', 1, 10000);
      await expectLater(store.reopenMonth('2026-09'), throwsA(isA<StateError>()));
      expect((await db.query('month_closes')).single['entries_ok'], 1);
    });

    test('reopening cannot shrink the pool below existing allocations', () async {
      await closeMonth('2026-08', extra: 50000);
      await closeMonth('2026-09', extra: 0);
      await store.allocate('2026-09', 1, 30000);
      await expectLater(store.reopenMonth('2026-08'), throwsA(isA<StateError>()));
      expect((await db.query('month_closes', where: 'month=?', whereArgs: ['2026-08'])).single['entries_ok'], 1);
      await db.delete('allocations');
      await store.reopenMonth('2026-08');
      expect((await db.query('month_closes', where: 'month=?', whereArgs: ['2026-08'])).single['entries_ok'], 0);
    });

    test('deleting a goal removes its allocations and frees the money', () async {
      await closeMonth('2026-09', extra: 50000);
      await db.insert('goals', {'id': 2, 'name': 'Computer', 'target': 500000});
      await store.allocate('2026-09', 1, 30000);
      await store.allocate('2026-09', 2, 20000);
      await store.deleteGoal(1);
      expect(await db.query('goals'), hasLength(1));
      final left = await db.query('allocations');
      expect(left, hasLength(1));
      expect(left.single['goal_id'], 2);
      await store.allocate('2026-09', 2, 30000);
    });
  });

  test('closing with carry-over saves it for next month; re-saving or reopening clears it', () async {
    Future<String?> carry() async => (await db.query('settings', where: 'key=?', whereArgs: [budgetCarryKey('2026-10')])).firstOrNull?['value'] as String?;
    await store.saveMonthClose('2026-09', entriesOk: true, balanceOk: true, extra: 0, openingBalance: 0, carryToNext: {'Groceries': 2000});
    expect(await carry(), '{"Groceries":2000}');
    await store.saveMonthClose('2026-09', entriesOk: true, balanceOk: true, extra: 0, openingBalance: 0, carryToNext: const {});
    expect(await carry(), isNull);
    await store.saveMonthClose('2026-09', entriesOk: true, balanceOk: true, extra: 0, openingBalance: 0, carryToNext: {'Groceries': 2000});
    await store.reopenMonth('2026-09');
    expect(await carry(), isNull);
  });
}
