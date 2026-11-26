import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/offline_store.dart';

class TestStore extends OfflineStore {
  TestStore(Database database) : super(database: database);
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late TestStore store;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
    await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
    await db.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL)');
    await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.insert('settings', {'key': 'opening_savings', 'value': '0'});
    store = TestStore(db);
  });
  tearDown(() => db.close());

  Future<void> move(String type, int amount, {int? id}) => store.saveTransaction(
      id: id, date: '2026-09-05', type: type, category: 'Savings', amount: amount, description: '', note: '', billId: '');
  Future<int> rows() async => (await db.query('transactions')).length;

  test('cannot take out more than is saved', () async {
    await move('Savings out', 700000);
    await expectLater(move('Savings in', 9999900), throwsA(isA<StateError>()));
    expect(await rows(), 1);
  });

  test('can take out exactly what is saved', () async {
    await move('Savings out', 700000);
    await move('Savings in', 700000);
    expect(await rows(), 2);
  });

  test('money assigned to goals cannot be taken out', () async {
    await move('Savings out', 700000);
    await db.insert('allocations', {'month': '2026-09', 'goal_id': 1, 'amount': 600000});
    await expectLater(move('Savings in', 200000), throwsA(isA<StateError>()));
    await move('Savings in', 100000);
  });

  test('shrinking a deposit below what was taken out is refused', () async {
    await move('Savings out', 700000);
    final id = (await db.query('transactions')).single['id'] as int;
    await move('Savings in', 500000);
    await expectLater(move('Savings out', 100000, id: id), throwsA(isA<StateError>()));
  });

  test('other entries still save when savings are already negative', () async {
    await db.insert('transactions', {'date': '2026-09-01', 'type': 'Savings in', 'category': 'Savings', 'amount': 500});
    await store.saveTransaction(date: '2026-09-05', type: 'Expense', category: 'Groceries', amount: 100, description: '', note: '', billId: '');
    expect(await rows(), 2);
  });
}
