import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/backup_cipher.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/hijri.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/wallets.dart';

class WalletStore extends OfflineStore {
  WalletStore(Database database) : super(database: database);
  @override
  Future<void> close() async {}
}

Future<Database> walletDb() async {
  final db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  await db.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER, balance_ok INTEGER, extra INTEGER, opening_balance INTEGER)');
  await db.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, type TEXT, category TEXT, amount INTEGER, description TEXT, note TEXT, bill_id TEXT, account TEXT NOT NULL DEFAULT 'Cash')");
  return db;
}

void main() {
  sqfliteFfiInit();

  group('Hijri dates (approximate, for planning)', () {
    test('known dates land within two days of the published calendar', () {
      // 1 Ramadan 1447 was 18 or 19 February 2026 depending on sighting.
      final ramadan = const HijriDate(1447, 9, 1).toGregorian();
      expect(ramadan.difference(DateTime(2026, 2, 18)).inDays.abs(), lessThanOrEqualTo(2));
      // Eid al-Adha 1447 (10 Dhu al-Hijja) was around 27 May 2026.
      final eid = const HijriDate(1447, 12, 10).toGregorian();
      expect(eid.difference(DateTime(2026, 5, 27)).inDays.abs(), lessThanOrEqualTo(2));
    });
    test('converting there and back returns the same day', () {
      for (var d = DateTime(2025, 1, 1); d.isBefore(DateTime(2028, 1, 1)); d = d.add(const Duration(days: 37))) {
        final h = HijriDate.fromGregorian(d);
        expect(h.toGregorian(), DateTime(d.year, d.month, d.day), reason: '$d');
        expect(h.day, inInclusiveRange(1, 30));
      }
    });
    test('season presets always fall after today', () {
      final today = DateTime(2026, 11, 15);
      for (final p in SeasonPreset.values) {
        final due = seasonDueDate(p, today);
        expect(due.isAfter(today), isTrue, reason: p.name);
        expect(due.difference(today).inDays, lessThan(400), reason: p.name);
      }
      expect(seasonDueDate(SeasonPreset.backToSchool, today), DateTime(2027, 9, 1));
      expect(seasonDueDate(SeasonPreset.summer, DateTime(2026, 3, 1)), DateTime(2026, 7, 1));
      // Ramadan 1448 starts around 7–8 February 2027: money is due the day before.
      expect(seasonDueDate(SeasonPreset.ramadan, today).difference(DateTime(2027, 2, 7)).inDays.abs(), lessThanOrEqualTo(2));
    });
  });

  test('spending pace flags only the current month and only before the near-limit state', () {
    final now = DateTime(2026, 11, 10); // a third of the month
    final month = DateTime(2026, 11);
    expect(spendingAheadOfPace(spent: 60000, budget: 100000, month: month, now: now), isTrue);
    expect(spendingAheadOfPace(spent: 30000, budget: 100000, month: month, now: now), isFalse);
    expect(spendingAheadOfPace(spent: 90000, budget: 100000, month: month, now: now), isFalse, reason: 'near limit takes over');
    expect(spendingAheadOfPace(spent: 60000, budget: 100000, month: DateTime(2026, 10), now: now), isFalse);
    expect(spendingAheadOfPace(spent: 60000, budget: 0, month: month, now: now), isFalse);
  });

  test('wallet balances use only entries made after setup, plus transfers', () {
    const setup = WalletSetup(cash: 30000, bank: 800000, afterId: 2, date: '2026-11-15');
    final tx = [
      {'id': 1, 'type': 'Expense', 'amount': 99999, 'account': 'Cash'}, // before setup: ignored
      {'id': 3, 'type': 'Expense', 'amount': 4500, 'account': 'Cash'},
      {'id': 4, 'type': 'Income', 'amount': 1250000, 'account': 'Bank'},
      {'id': 5, 'type': 'Savings out', 'amount': 100000, 'account': 'Bank'},
      {'id': 6, 'type': 'Expense', 'amount': 1000}, // no wallet: Cash
    ];
    const transfers = [WalletTransfer(id: 'a', date: '2026-11-15', from: 'Bank', amount: 50000)];
    expect(walletBalances(setup, tx, transfers), {'Cash': 30000 - 4500 - 1000 + 50000, 'Bank': 800000 + 1250000 - 100000 - 50000});
  });

  test('store: setup starts after existing entries, transfers save, and restarting clears them', () async {
    final db = await walletDb();
    addTearDown(db.close);
    final store = WalletStore(db);
    final today = dayKey(DateTime.now());
    await store.saveTransaction(date: today, type: 'Expense', category: 'Groceries', amount: 100, description: '', note: '', billId: '');
    await store.saveWalletSetup(cash: 20000, bank: 500000);
    await store.saveTransaction(date: today, type: 'Expense', category: 'Groceries', amount: 2500, description: '', note: '', billId: '', account: 'Bank');
    await store.addWalletTransfer(from: 'Bank', amount: 10000, date: today);
    Future<Map<String, int>> balances() async {
      final settings = {for (final r in await db.query('settings')) r['key']: r['value']?.toString()};
      return walletBalances(WalletSetup.decode(settings[walletSetupKey])!, await db.query('transactions'), decodeTransfers(settings[walletTransfersKey]));
    }
    expect(await balances(), {'Cash': 30000, 'Bank': 487500});
    await expectLater(store.addWalletTransfer(from: 'Cash', amount: 0, date: today), throwsA(isA<ArgumentError>()));
    await expectLater(store.saveTransaction(date: today, type: 'Expense', category: 'X', amount: 1, description: '', note: '', billId: '', account: 'Card'),
        throwsA(isA<ArgumentError>()));
    await store.saveWalletSetup(cash: 1000, bank: 2000);
    expect(await balances(), {'Cash': 1000, 'Bank': 2000});
  });

  test('a new schema-3 backup passes the backup check that restore uses', () async {
    final db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    for (final name in localTables) {
      await db.execute(name == 'settings' ? 'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)' : 'CREATE TABLE $name(id INTEGER)');
    }
    final raw = await WalletStore(db).exportJson();
    expect((jsonDecode(raw) as Map)['schema_version'], 3);
    expect(() => BackupCipher.validatePlain(raw), returnsNormally);
  });

  testWidgets('Cash & Bank stays hidden until set up, then shows on Home and in the add form', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final month = monthKey(DateTime.now());
    final data = <String, List<RowData>>{
      'transactions': [
        {'id': 1, 'date': '$month-01', 'type': 'Income', 'category': 'Salary', 'amount': 1000000, 'account': 'Bank'},
      ],
      'categories': [
        {'name': 'Groceries', 'group_name': 'Essential'},
      ],
      'settings': [],
    };
    await t.pumpWidget(MaterialApp(home: FinanceScreen(initialData: Future.value(data))));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-wallets')), findsNothing);
    data['settings'] = [
      {'key': walletSetupKey, 'value': '{"cash":30000,"bank":500000,"after_id":0,"date":"$month-01"}'},
    ];
    await t.pumpWidget(MaterialApp(home: FinanceScreen(key: UniqueKey(), initialData: Future.value(data))));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-wallets')), findsOneWidget);
    expect(find.text('300.00 MAD'), findsOneWidget);
    expect(find.text('15,000.00 MAD'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
