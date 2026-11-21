import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/offline_store.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late OfflineStore store;
  final today = DateTime(2026, 11, 21);
  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "", account TEXT NOT NULL DEFAULT "Cash")');
    await db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, target INTEGER NOT NULL)');
    await db.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL)');
    await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
    await db.execute('CREATE TABLE reserves(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target INTEGER NOT NULL, funded INTEGER NOT NULL DEFAULT 0, due TEXT NOT NULL, start_month TEXT NOT NULL)');
    await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await OfflineStore.createReserveMovements(db);
    store = OfflineStore(database: db);
  });
  tearDown(() async => db.close());

  Future<int> reserve(String name, int target, int funded) =>
      db.insert('reserves', {'name': name, 'target': target, 'funded': funded, 'due': '2027-02-17', 'start_month': '2026-09'});

  test('an unfinished reserve becomes a savings goal with the same name, target and money', () async {
    final id = await reserve('Ramadan', 300000, 100000);
    await db.insert('reserve_movements', {'reserve_id': id, 'date': '2026-10-02', 'kind': 'add', 'amount': 50000});
    expect(await store.deleteReserveKeepingMoney(id, now: today), 150000);
    expect(await db.query('reserves'), isEmpty);
    expect(await db.query('reserve_movements'), isEmpty);
    final goal = (await db.query('goals')).single;
    expect(goal['name'], 'Ramadan');
    expect(goal['target'], 300000);
    final allocation = (await db.query('allocations')).single;
    expect(allocation['goal_id'], goal['id']);
    expect(allocation['amount'], 150000);
    final move = (await db.query('transactions')).single;
    expect(move['type'], 'Savings out');
    expect(move['amount'], 150000);
    expect(move['date'], '2026-11-21');
    expect(move['description'], 'Ramadan');
  });

  test('an empty unfinished reserve still leaves its goal behind', () async {
    final id = await reserve('Aid', 200000, 0);
    expect(await store.deleteReserveKeepingMoney(id, now: today), 0);
    expect((await db.query('goals')).single['target'], 200000);
    expect(await db.query('transactions'), isEmpty);
    expect(await db.query('allocations'), isEmpty);
  });

  test('a goal with the same name is reused and its target raised if needed', () async {
    final goal = await db.insert('goals', {'name': 'Ramadan', 'target': 50000});
    await db.insert('allocations', {'month': '2026-10', 'goal_id': goal, 'amount': 40000});
    final id = await reserve('Ramadan', 300000, 100000);
    await store.deleteReserveKeepingMoney(id, now: today);
    final goals = await db.query('goals');
    expect(goals, hasLength(1));
    expect(goals.single['target'], 140000);
    expect((await db.query('allocations')).fold<int>(0, (n, r) => n + (r['amount'] as int)), 140000);
  });

  test('a fully funded reserve is removed without touching savings', () async {
    final id = await reserve('School', 100000, 100000);
    expect(await store.deleteReserveKeepingMoney(id, now: today), 0);
    expect(await db.query('reserves'), isEmpty);
    expect(await db.query('goals'), isEmpty);
    expect(await db.query('transactions'), isEmpty);
  });

  test('a closed current month blocks the move and changes nothing', () async {
    await db.insert('month_closes', {'month': '2026-11', 'entries_ok': 1, 'balance_ok': 1});
    final id = await reserve('Ramadan', 300000, 100000);
    await expectLater(store.deleteReserveKeepingMoney(id, now: today), throwsStateError);
    expect(await db.query('reserves'), hasLength(1));
    expect(await db.query('goals'), isEmpty);
  });
}
