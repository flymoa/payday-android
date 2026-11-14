import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/backup_notifications.dart';
import 'package:payday_local/offline_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MemoryReminderStore extends OfflineStore {
 String value='0';bool fail=false;
 @override Future<List<Map<String,Object?>>> table(String name)async=>[{'key':backupReminderPreference,'value':value}];
 @override Future<void> setSetting(String key,String v)async{if(fail)throw StateError('storage');value=v;}
}
class FakeReminderPlatform implements ReminderPlatform {
 bool permission=true,failSchedule=false;
 int requests=0,scheduled=0,canceled=0,tests=0,settings=0;
 @override Future<void> initialize()async{}
 @override Future<bool> allowed()async=>permission;
 @override Future<bool> requestPermission()async{requests++;return permission;}
 @override Future<void> scheduleWeekly()async{if(failSchedule)throw StateError('schedule');scheduled++;}
 @override Future<void> cancel()async{canceled++;}
 @override Future<void> sendTest()async{tests++;}
 @override Future<void> openSettings()async{settings++;}
}
void main(){
 test('off by default, permission is requested only when enabling, disable cancels',()async{
  final store=MemoryReminderStore(),platform=FakeReminderPlatform();final reminders=BackupNotifications(store,platform:platform);
  expect((await reminders.read()).enabled,isFalse);expect(platform.requests,0);
  await reminders.resetAfterExport();expect(platform.scheduled,0);
  await reminders.setEnabled(true);expect(store.value,'1');expect(platform.requests,1);expect(platform.scheduled,1);
  await reminders.resetAfterExport();expect(platform.scheduled,2);
  await reminders.sendTest();expect(platform.tests,1);
  await reminders.setEnabled(false);expect(store.value,'0');expect(platform.canceled,2);
  await expectLater(reminders.sendTest(),throwsFormatException);
 });
 test('denied permission and schedule errors do not enable reminders; storage failure rolls back',()async{
  final store=MemoryReminderStore(),platform=FakeReminderPlatform()..permission=false;
  final reminders=BackupNotifications(store,platform:platform);
  await expectLater(reminders.setEnabled(true),throwsFormatException);
  expect(store.value,'0');expect(platform.scheduled,0);
  platform.permission=true;store.fail=true;
  await expectLater(reminders.setEnabled(true),throwsStateError);
  expect(store.value,'0');expect(platform.canceled,1);
  store.fail=false;platform.failSchedule=true;
  await expectLater(reminders.setEnabled(true),throwsStateError);expect(store.value,'0');
 });
 test('Android blocking is visible and export cannot request permission',()async{
  final store=MemoryReminderStore()..value='1';final platform=FakeReminderPlatform()..permission=false;
  final reminders=BackupNotifications(store,platform:platform);
  final state=await reminders.read();expect(state.enabled,isTrue);expect(state.allowed,isFalse);
  await reminders.resetAfterExport();expect(platform.scheduled,0);expect(platform.requests,0);
 });
 sqfliteFfiInit();
 test('restore preserves device notification choice and never imports permission intent',()async{
  final db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  addTearDown(db.close);
  for(final name in localTables){await db.execute(name=='settings'?'CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)':'CREATE TABLE $name(id INTEGER)');}
  final store=OfflineStore(database:db);
  await store.setSetting(backupReminderPreference,'1');await store.setSetting('app_lock_enabled','1');
  final exported=jsonDecode(await store.exportJson()) as Map<String,dynamic>;
  expect(exported['tables']['settings'],isEmpty);
  final tables={for(final name in localTables)name:<Map<String,Object?>>[]};
  tables['settings']=[{'key':backupReminderPreference,'value':'0'},{'key':'app_lock_enabled','value':'0'},{'key':'buffer','value':'900'}];
  await store.importJson(jsonEncode({'format':'payday-local','schema_version':2,'tables':tables}));
  var rows=await store.table('settings');
  expect(rows,contains(equals({'key':backupReminderPreference,'value':'1'})));expect(rows,contains(equals({'key':'app_lock_enabled','value':'1'})));
  await db.delete('settings',where:'key=?',whereArgs:[backupReminderPreference]);
  tables['settings']=[{'key':backupReminderPreference,'value':'1'}];
  await store.importJson(jsonEncode({'format':'payday-local','schema_version':2,'tables':tables}));
  rows=await store.table('settings');expect(rows.where((r)=>r['key']==backupReminderPreference),isEmpty);
 });
}
