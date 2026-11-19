import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/ledger.dart';
import 'package:payday_local/offline_store.dart';

Future<Database> openTestDb() async {
  final db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER, balance_ok INTEGER, extra INTEGER, opening_balance INTEGER)');
  await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, name TEXT, due TEXT, amount INTEGER, category TEXT, note TEXT, repeat_monthly INTEGER NOT NULL DEFAULT 0)');
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, type TEXT, category TEXT, amount INTEGER, description TEXT, note TEXT, bill_id TEXT)');
  return db;
}

void main() {
  sqfliteFfiInit();

  test('renaming a bill ID keeps its payments, and a taken ID is refused clearly', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    final store = OfflineStore(database: db);
    final today = dayKey(DateTime.now());
    await store.saveBill(code: 'NET', name: 'Internet', due: today, amount: 30000, category: 'Utilities', note: '');
    await store.saveBill(code: 'WATER', name: 'Water', due: today, amount: 10000, category: 'Utilities', note: '');
    await store.saveTransaction(date: today, type: 'Expense', category: 'Utilities', amount: 30000, description: '', note: '', billId: 'NET');
    await store.saveBill(id: 1, code: 'NET-2026', name: 'Internet', due: today, amount: 30000, category: 'Utilities', note: '');
    final ledger = Ledger({'bills': await db.query('bills'), 'transactions': await db.query('transactions')});
    final bill = (await db.query('bills', where: 'id=1')).single;
    expect(bill['code'], 'NET-2026');
    expect(ledger.billPaid(bill), 30000, reason: 'the payment must follow the renamed bill');
    expect(ledger.unpaidBills(monthKey(DateTime.now())), 10000);
    await expectLater(
        store.saveBill(id: 2, code: 'NET-2026', name: 'Water', due: today, amount: 10000, category: 'Utilities', note: ''),
        throwsA(isA<StateError>().having((e) => e.message, 'message', OfflineStore.billIdTakenMessage)));
    await expectLater(
        store.saveBill(code: 'WATER', name: 'Copy', due: today, amount: 1, category: 'Utilities', note: ''),
        throwsA(isA<StateError>()));
  });

  test('future payment dates are refused, but an existing future record can still be edited', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    final store = OfflineStore(database: db);
    final now = DateTime.now();
    final tomorrow = dayKey(DateTime(now.year, now.month, now.day + 1));
    await expectLater(
        store.saveTransaction(date: tomorrow, type: 'Expense', category: 'Groceries', amount: 100, description: '', note: '', billId: ''),
        throwsA(isA<ArgumentError>()));
    await store.saveTransaction(date: dayKey(now), type: 'Expense', category: 'Groceries', amount: 100, description: '', note: '', billId: '');
    expect(await db.query('transactions'), hasLength(1));
    final old = await db.insert('transactions', {'date': tomorrow, 'type': 'Expense', 'category': 'Groceries', 'amount': 100, 'description': '', 'note': '', 'bill_id': ''});
    await store.saveTransaction(id: old, date: tomorrow, type: 'Expense', category: 'Groceries', amount: 250, description: 'fixed', note: '', billId: '');
    expect((await db.query('transactions', where: 'id=?', whereArgs: [old])).single['amount'], 250);
    await expectLater(
        store.saveTransaction(date: 'not-a-date', type: 'Expense', category: 'Groceries', amount: 100, description: '', note: '', billId: ''),
        throwsA(isA<ArgumentError>()));
  });

  test('a backup with a wrongly typed row is refused and current records stay', () async {
    final db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    for (final name in localTables) {
      await db.execute(name == 'settings'
          ? 'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)'
          : 'CREATE TABLE $name(id INTEGER, date TEXT, amount INTEGER, month TEXT)');
    }
    await db.insert('transactions', {'id': 1, 'date': '2026-10-01', 'amount': 500});
    final store = OfflineStore(database: db);
    Map<String, Object?> backup(Map<String, Object?> row) => {
          'format': 'payday-local', 'schema_version': 2,
          'tables': {for (final name in localTables) name: name == 'transactions' ? [row] : <Object?>[]},
        };
    for (final bad in [
      {'id': 2, 'date': '2026-10-02', 'amount': '120'},
      {'id': 2, 'date': '2026-10-02', 'amount': 12.5},
      {'id': 2, 'date': '02/10/2026', 'amount': 120},
      {'id': 2, 'date': '2026-10-02', 'amount': [1]},
    ]) {
      await expectLater(store.importJson(jsonEncode(backup(bad))), throwsA(isA<FormatException>()), reason: '$bad');
      expect(await db.query('transactions'), [{'id': 1, 'date': '2026-10-01', 'amount': 500, 'month': null}]);
    }
    await store.importJson(jsonEncode(backup({'id': 2, 'date': '2026-10-02', 'amount': 120})));
    expect((await db.query('transactions')).single['amount'], 120);
  });
}
