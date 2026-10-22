import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/offline_store.dart';
class BackupStore extends OfflineStore{
 BackupStore(Database db):super(database:db);
 @override Future<void> close()async{}
 @override Future<Map<String,List<RowData>>> snapshot()async=>{
  'settings':await table('settings'),
  'transactions':[{'type':'Income','category':'Salary','date':'${monthKey(DateTime.now())}-01','amount':10000}],
 };
 @override Future<String> exportJson()async=>'{}';
}
void main(){
 final now=DateTime.utc(2026,10,22,12);
 test('reminders need data and become due at seven days',(){
  expect(BackupReminder(now:now,hasData:false).visible,isFalse);
  expect(BackupReminder(now:now,hasData:true).visible,isTrue);
  expect(BackupReminder(now:now,hasData:true,lastExport:'invalid').visible,isTrue);
  expect(BackupReminder(now:now,hasData:true,lastExport:now.subtract(const Duration(days:7)).toIso8601String()).visible,isTrue);
  expect(BackupReminder(now:now,hasData:true,lastExport:now.subtract(const Duration(days:6)).toIso8601String()).visible,isFalse);
 });
 test('snooze expires without changing last export and future dates do not suppress reminders',(){
  expect(BackupReminder(now:now,hasData:true,snoozeUntil:now.add(const Duration(hours:1)).toIso8601String()).visible,isFalse);
  expect(BackupReminder(now:now,hasData:true,snoozeUntil:now.toIso8601String()).visible,isTrue);
  expect(BackupReminder(now:now,hasData:true,lastExport:now.add(const Duration(days:1)).toIso8601String()).visible,isTrue);
 });
 sqfliteFfiInit();late Database db;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
 });
 tearDown(()async{await db.close();});
 for(final status in [ShareResultStatus.success,ShareResultStatus.dismissed]){
  for(final brightness in Brightness.values){
   testWidgets('export ${status.name} handles date and reminder in ${brightness.name}',(tester)async{
    await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
    final store=BackupStore(db);var calls=0;
    await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(
     store:store,initialData:store.snapshot(),backupShare:(json)async{calls++;return ShareResult('test',status);} )));
    await tester.pumpAndSettle();await tester.ensureVisible(find.text('Export backup'));await tester.pumpAndSettle();
    await tester.tap(find.text('Export backup'));
    for(var i=0;i<30;i++){await tester.pump(const Duration(milliseconds:50));}
    expect(calls,1);
    final exported=await db.query('settings',where:'key=?',whereArgs:['last_backup_export']);
    if(status==ShareResultStatus.success){expect(exported,isNotEmpty);expect(find.text('Keep a backup'),findsNothing);}
    else{expect(exported,isEmpty);expect(find.text('Keep a backup'),findsOneWidget);}
    expect(tester.takeException(),isNull);
   });
  }
 }
 testWidgets('remind tomorrow persists snooze without marking an export',(tester)async{
  final store=BackupStore(db);
  await tester.pumpWidget(MaterialApp(home:FinanceScreen(store:store,initialData:store.snapshot())));
  await tester.pumpAndSettle();await tester.ensureVisible(find.text('Remind tomorrow'));await tester.pumpAndSettle();
  await tester.tap(find.text('Remind tomorrow'));
  for(var i=0;i<30;i++){await tester.pump(const Duration(milliseconds:50));}
  expect(find.text('Keep a backup'),findsNothing);
  expect(await db.query('settings',where:'key=?',whereArgs:['last_backup_export']),isEmpty);
  expect(await db.query('settings',where:'key=?',whereArgs:['backup_snooze_until']),isNotEmpty);
 });
 test('restore clears imported export dates and snoozes',()async{
  for(final table in localTables.where((t)=>t!='settings')){await db.execute('CREATE TABLE $table(id INTEGER)');}
  final tables={for(final table in localTables)table:<Map<String,Object?>>[]};
  tables['settings']=[{'key':'last_backup_export','value':now.toIso8601String()},
   {'key':'backup_snooze_until','value':now.add(const Duration(days:1)).toIso8601String()},
   {'key':'buffer','value':'20000'}];
  await OfflineStore(database:db).importJson(jsonEncode({'format':'payday-local','schema_version':2,'tables':tables}));
  expect(await db.query('settings'),[{'key':'buffer','value':'20000'}]);
 });
}
