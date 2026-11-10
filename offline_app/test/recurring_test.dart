import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/recurring.dart';

class RecStore extends OfflineStore {
  RecStore(Database d) : super(database: d);
  @override
  Future<void> close() async {}
}

RecurringRule rule({int day = 5, String start = '2026-09', String? last}) => RecurringRule(
    id: 'r1', type: 'Income', category: 'Salary', description: 'Salary', amount: 900000, day: day, start: start, last: last);

void main() {
  test('plans every due month up to today, skipping closed months', () {
    final due = dueRecurringEntries([rule()], DateTime(2026, 11, 10), {'2026-10'});
    expect(due.map((e) => e.date), ['2026-09-05', '2026-11-05']);
    expect(dueRecurringEntries([rule(day: 20)], DateTime(2026, 11, 10), {}).map((e) => e.date), ['2026-09-20', '2026-10-20']);
    expect(dueRecurringEntries([rule(last: '2026-11')], DateTime(2026, 11, 10), {}), isEmpty);
  });

  test('invalid or corrupt rules are ignored', () {
    expect(decodeRules('not json'), isEmpty);
    expect(decodeRules('[{"id":"x","type":"Bad","category":"A","amount":5,"day":3,"start":"2026-01"}]'), isEmpty);
    expect(decodeRules(encodeRules([rule()])).single.amount, 900000);
  });

  group('store', () {
    sqfliteFfiInit();
    late Database db;
    late RecStore store;
    setUp(() async {
      db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
      await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      store = RecStore(db);
    });
    tearDown(() async => db.close());

    test('creates due entries once; repeated runs add nothing', () async {
      await db.insert('month_closes', {'month': '2026-10', 'entries_ok': 1, 'balance_ok': 1});
      await store.saveRecurringRules([rule()]);
      expect(await store.applyRecurring(DateTime(2026, 11, 10)), 2);
      expect(await store.applyRecurring(DateTime(2026, 11, 10)), 0);
      expect(await store.applyRecurring(DateTime(2026, 11, 30)), 0);
      final dates = (await db.query('transactions', orderBy: 'date')).map((r) => r['date']).toList();
      expect(dates, ['2026-09-05', '2026-11-05']);
      expect((await store.recurringRules()).single.last, '2026-11');
      expect(await store.applyRecurring(DateTime(2026, 12, 5)), 1);
    });

    test('a day not yet reached this month waits until it arrives', () async {
      await store.saveRecurringRules([rule(day: 20, start: '2026-11')]);
      expect(await store.applyRecurring(DateTime(2026, 11, 10)), 0);
      expect((await store.recurringRules()).single.last, isNull);
      expect(await store.applyRecurring(DateTime(2026, 11, 20)), 1);
    });
  });
}
