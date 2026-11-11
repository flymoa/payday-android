import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/backup_settings_page.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/restore_snapshot.dart';

class SnapshotStore extends OfflineStore {
  SnapshotStore(Database database) : super(database: database);
  @override
  Future<void> close() async {}
}

Future<void> createSchema(Database d) async {
  await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
  await d.execute('CREATE TABLE budgets(month TEXT NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL, PRIMARY KEY(month, category))');
  await d.execute('CREATE TABLE categories(name TEXT PRIMARY KEY, group_name TEXT NOT NULL)');
  await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, target INTEGER NOT NULL)');
  await d.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL)');
  await d.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, due TEXT NOT NULL, amount INTEGER NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL DEFAULT "")');
  await d.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
  await d.execute('CREATE TABLE reserves(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target INTEGER NOT NULL, funded INTEGER NOT NULL DEFAULT 0, due TEXT NOT NULL, start_month TEXT NOT NULL)');
  await OfflineStore.createReserveMovements(d);
  await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
}

/// A valid plain backup whose only record is one transaction with this description.
String backupWith(String description) => jsonEncode({
      'format': 'payday-local',
      'schema_version': 2,
      'exported_at': '2026-11-01T10:00:00.000Z',
      'tables': {
        for (final name in localTables) name: <Object?>[],
        'transactions': [
          {'id': 7, 'date': '2026-10-15', 'type': 'Expense', 'category': 'Groceries', 'description': description, 'amount': 4200, 'note': '', 'bill_id': ''}
        ],
      },
    });

void main() {
  sqfliteFfiInit();
  late Database db;
  late SnapshotStore store;
  late Directory dir;
  late RestoreSnapshot snapshot;

  Future<List<String>> descriptions() async =>
      (await db.query('transactions')).map((r) => r['description'] as String).toList();

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    await db.insert('transactions', {'date': '2026-09-01', 'type': 'Expense', 'category': 'Groceries', 'description': 'current data', 'amount': 1000});
    store = SnapshotStore(db);
    dir = Directory.systemTemp.createTempSync('payday-snapshot-test');
    snapshot = RestoreSnapshot(directory: () async => dir);
  });
  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('restore keeps a safety copy and undo brings the previous data back', () async {
    expect(await snapshot.savedAt(), isNull);
    await restoreWithSafetyCopy(store, snapshot, backupWith('from backup'));
    expect(await descriptions(), ['from backup']);
    expect(await snapshot.savedAt(), isNotNull);

    await revertToSnapshot(store, snapshot);
    expect(await descriptions(), ['current data']);
    expect(await snapshot.savedAt(), isNull);
    expect(dir.listSync().where((e) => e.path.endsWith('.tmp')), isEmpty);
  });

  test('a second restore replaces the safety copy with the newest pre-restore data', () async {
    await restoreWithSafetyCopy(store, snapshot, backupWith('first backup'));
    await restoreWithSafetyCopy(store, snapshot, backupWith('second backup'));
    await revertToSnapshot(store, snapshot);
    expect(await descriptions(), ['first backup']);
  });

  test('nothing is replaced when the safety copy cannot be written', () async {
    final broken = RestoreSnapshot(directory: () async => throw const FileSystemException('disk full'));
    await expectLater(restoreWithSafetyCopy(store, broken, backupWith('from backup')), throwsA(isA<StateError>()));
    expect(await descriptions(), ['current data']);
  });

  test('a failed restore leaves the data in place', () async {
    await expectLater(restoreWithSafetyCopy(store, snapshot, '{"format":"payday-local","schema_version":2,"tables":{"transactions":[1]}}'),
        throwsA(anything));
    expect(await descriptions(), ['current data']);
  });

  test('undo without a saved copy is rejected and does not touch data', () async {
    await expectLater(revertToSnapshot(store, snapshot), throwsA(isA<StateError>()));
    expect(await descriptions(), ['current data']);
  });

  test('with a password the copy is encrypted on disk and still undoes the restore', () async {
    final locked = RestoreSnapshot(directory: () async => dir, password: () async => 'ab' * 32);
    await restoreWithSafetyCopy(store, locked, backupWith('from backup'));
    final onDisk = File('${dir.path}/${RestoreSnapshot.fileName}').readAsStringSync();
    expect(onDisk.contains('current data'), isFalse);
    expect(onDisk.contains('payday-encrypted'), isTrue);
    await revertToSnapshot(store, locked);
    expect(await descriptions(), ['current data']);
  });

  test('an older plain copy still undoes when a password is now configured', () async {
    await restoreWithSafetyCopy(store, snapshot, backupWith('from backup'));
    final locked = RestoreSnapshot(directory: () async => dir, password: () async => 'ab' * 32);
    await revertToSnapshot(store, locked);
    expect(await descriptions(), ['current data']);
  });

  testWidgets('Backups page offers Undo last restore only when a copy exists', (t) async {
    var undone = 0;
    DateTime? saved;
    Widget page() => MaterialApp(
        home: BackupSettingsPage(
          key: UniqueKey(),
          initialStatus: 'No export recorded yet',
          refreshStatus: () async => 'No export recorded yet',
          onExport: () async {},
          onRestore: () async {},
          loadSnapshotDate: () async => saved,
          onUndoRestore: () async {
            undone++;
            saved = null;
          },
        ));
    await t.pumpWidget(page());
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('undo-restore')), findsNothing);

    saved = DateTime(2026, 11, 2);
    await t.pumpWidget(page());
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('undo-restore')), findsOneWidget);
    expect(find.textContaining('2026-11-02'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('undo-restore')));
    await t.pumpAndSettle();
    expect(undone, 1);
    expect(find.byKey(const ValueKey('undo-restore')), findsNothing);
  });
}
