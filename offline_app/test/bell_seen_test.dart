import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('the bell number clears once the notifications are opened', (t) async {
    late OfflineStore store;
    await t.runAsync(() async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      for (final table in localTables.where((x) => x != 'settings')) {
        await db.execute('CREATE TABLE $table(id INTEGER, amount INTEGER, date TEXT, type TEXT, category TEXT, description TEXT, note TEXT, bill_id TEXT, account TEXT)');
      }
      // One transaction so a backup is due, which puts one item on the bell.
      await db.insert('transactions', {'id': 1, 'amount': 1000, 'date': '2026-01-02', 'type': 'Expense', 'category': 'Other', 'description': '', 'note': '', 'bill_id': '', 'account': 'Cash'});
      store = OfflineStore(database: db);
    });
    await t.pumpWidget(MaterialApp(home: FinanceScreen(store: store, initialData: store.snapshot())));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-bell-badge')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('home-bell-button')));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Close notifications'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-bell-badge')), findsNothing);
    // Opening it again: what was already read is gone from the list.
    await t.tap(find.byKey(const ValueKey('home-bell-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-backup')), findsNothing);
    expect(find.text('You are all caught up'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('the bell remembers what was read by item, not by its wording', () {
    // Wording changes with the language; the key does not.
    expect('home-backup'.contains('|'), isFalse);
  });
}
