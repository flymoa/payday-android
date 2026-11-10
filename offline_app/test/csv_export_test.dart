import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/csv_export.dart';
import 'package:payday_local/offline_store.dart';

void main() {
  test('CSV is sorted, escaped, formula-safe and uses exact decimal amounts', () {
    final csv = transactionsCsv([
      {'id': 2, 'date': '2026-10-02', 'type': 'Expense', 'category': 'Groceries', 'description': 'Milk, "fresh"', 'amount': 1205, 'note': '=HYPERLINK(1)', 'bill_id': ''},
      {'id': 1, 'date': '2026-10-01', 'type': 'Income', 'category': 'Salary', 'description': 'راتب', 'amount': 1000000, 'note': 'line\nbreak', 'bill_id': 'B-1'},
    ]);
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).split('\r\n');
    expect(lines[0], 'date,type,category,description,amount,note,bill_id');
    expect(lines[1], '2026-10-01,Income,Salary,راتب,10000.00,"line\nbreak",B-1');
    expect(lines[2], '2026-10-02,Expense,Groceries,"Milk, ""fresh""",12.05,\'=HYPERLINK(1),');
    expect(lines.last, '');
  });

  test('amounts keep centimes and sign', () {
    expect(csvAmount(5), '0.05');
    expect(csvAmount(-12345), '-123.45');
    expect(csvCell('-5'), "'-5");
  });

  test('database upgrade from v2 to v3 keeps data and adds indexes', () async {
    sqfliteFfiInit();
    final path = '${(await databaseFactoryFfiNoIsolate.getDatabasesPath())}/payday_upgrade_test.db';
    await databaseFactoryFfiNoIsolate.deleteDatabase(path);
    final v2 = await databaseFactoryFfiNoIsolate.openDatabase(path, options: OpenDatabaseOptions(version: 2, onCreate: (d, v) async {
      await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
      await d.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL)');
      await d.insert('transactions', {'date': '2026-10-01', 'type': 'Expense', 'category': 'Other', 'amount': 100});
    }));
    await v2.close();
    final v3 = await databaseFactoryFfiNoIsolate.openDatabase(path, options: OpenDatabaseOptions(version: 3,
        onUpgrade: (d, o, n) async { if (o < 3) await OfflineStore.createLookupIndexes(d); }));
    final names = (await v3.rawQuery("SELECT name FROM sqlite_master WHERE type='index'")).map((r) => r['name']).toSet();
    expect(names, containsAll(['ix_transactions_type_bill', 'ix_allocations_goal', 'ix_allocations_month']));
    expect(await v3.query('transactions'), hasLength(1));
    await OfflineStore.createLookupIndexes(v3); // safe to run twice
    await v3.close();
    await databaseFactoryFfiNoIsolate.deleteDatabase(path);
  });
}
