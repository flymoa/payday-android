// Runs the real app on an Android emulator (see the emulator job in CI).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:payday_local/add_button.dart';
import 'package:payday_local/main.dart' as app;
import 'package:payday_local/db_encryption.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

Future<void> settle(WidgetTester t, {int seconds = 4}) async {
  // The opening animation and progress indicators can keep frames scheduled,
  // so pump for a fixed time instead of pumpAndSettle.
  for (var i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester t, Finder finder, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 10 && finder.evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: 'Timed out waiting for $finder');
}

/// Waits for the app and, on a fresh install, goes through the welcome pages.
Future<void> openApp(WidgetTester t) async {
  final ready = find.byType(PaydayAddButton), welcome = find.byKey(const ValueKey('welcome-start'));
  for (var i = 0; i < 300 && ready.evaluate().isEmpty && welcome.evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  if (welcome.evaluate().isNotEmpty) {
    await t.tap(welcome);
    await settle(t, seconds: 1);
    await t.tap(find.byKey(const ValueKey('welcome-finish')));
    await settle(t, seconds: 2);
  }
  await waitFor(t, ready);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an existing unencrypted database is encrypted with all data kept', (t) async {
    final file = '${await cipher.getDatabasesPath()}/migration_check.db';
    final key = 'ab' * 32;
    await cipher.deleteDatabase(file);
    final plain = await cipher.openDatabase(file, version: 3, onCreate: (d, v) async {
      await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY, description TEXT)');
      await d.insert('transactions', {'description': 'before encryption'});
    });
    await plain.close();
    expect(await fileIsPlainSqlite(file), isTrue);

    expect(await encryptDatabaseIfNeeded(file, key), isTrue);
    expect(await fileIsPlainSqlite(file), isFalse);
    final db = await cipher.openDatabase(file, password: key, singleInstance: false);
    expect((await db.query('transactions')).single['description'], 'before encryption');
    expect(await db.getVersion(), 3);
    await db.close();

    expect(await encryptDatabaseIfNeeded(file, key), isFalse, reason: 'second run is a no-op');
    await expectLater(() async {
      final wrong = await cipher.openDatabase(file, password: 'cd' * 32, singleInstance: false);
      try { await wrong.query('transactions'); } finally { await wrong.close(); }
    }(), throwsA(anything));
    await cipher.deleteDatabase(file);
  });

  testWidgets('add an expense on a fresh install and see it on Home', (t) async {
    app.main();
    await openApp(t);
    await settle(t);

    await t.tap(find.byType(PaydayAddButton));
    await settle(t, seconds: 2);
    await t.enterText(find.widgetWithText(TextField, 'Amount (DH)'), '12.50');
    await t.ensureVisible(find.byKey(const ValueKey('transaction-more-details')));
    await t.tap(find.byKey(const ValueKey('transaction-more-details')));
    await settle(t, seconds: 1);
    await t.enterText(find.widgetWithText(TextField, 'Description'), 'Emulator coffee');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t, seconds: 1);
    await t.tap(find.byKey(const ValueKey('save-transaction')));
    await settle(t, seconds: 3);

    await waitFor(t, find.text('Emulator coffee'));
    expect(find.textContaining('12,50'), findsWidgets);
    final real = '${await cipher.getDatabasesPath()}/payday_local_v1.db';
    expect(await fileIsPlainSqlite(real), isFalse, reason: 'app database must be encrypted');
  });

  testWidgets('every tab and the monthly review open on a device', (t) async {
    app.main();
    await openApp(t);
    await settle(t);
    for (final tab in [1, 2, 3, 4, 0]) {
      final item = find.byKey(ValueKey('bottom-$tab'));
      if (item.evaluate().isEmpty) continue;
      await t.tap(item.first);
      await settle(t, seconds: 1);
      expect(t.takeException(), isNull, reason: 'tab $tab');
    }
    final records = find.byKey(const ValueKey('bottom-1'));
    await waitFor(t, records);
    {
      await t.tap(records.first);
      await settle(t, seconds: 1);
      await t.tap(find.byKey(const ValueKey('subtab-1-1')));
      await settle(t, seconds: 1);
      await waitFor(t, find.text('Check before closing'));
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('switching to French translates the app on a device', (t) async {
    app.main();
    await openApp(t);
    await settle(t);
    await t.tap(find.byKey(const ValueKey('bottom-0')).first);
    await settle(t, seconds: 1);
    await t.tap(find.byKey(const ValueKey('home-settings-button')));
    await settle(t, seconds: 2);
    await t.tap(find.byKey(const ValueKey('language-setting')));
    await settle(t, seconds: 2);
    await t.tap(find.text('French'));
    await settle(t, seconds: 3);
    await waitFor(t, find.text('Paramètres'));
    expect(t.takeException(), isNull);
  });
}
