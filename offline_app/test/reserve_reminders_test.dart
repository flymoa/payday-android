import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/reserve_reminders.dart';

class ReserveTestStore extends OfflineStore {
 final settings=<String,String>{};
 List<Map<String,Object?>> reserves=[],movements=[];
 bool fail=false;
 @override Future<List<Map<String,Object?>>> table(String name)async=>[for(final e in settings.entries){'key':e.key,'value':e.value}];
 @override Future<Map<String,List<Map<String,Object?>>>> reserveReminderSnapshot()async=>{'reserves':reserves,'reserve_movements':movements};
 @override Future<void> saveReserveReminderPreferences({required bool enabled,required int day})async{
  if(fail)throw StateError('storage');settings[reserveReminderEnabledKey]=enabled?'1':'0';settings[reserveReminderDayKey]='$day';
 }
 @override Future<void> close()async{}
}
class FakeReservePlatform implements ReserveReminderPlatform {
 bool permission=true,fail=false;
 int requests=0,tests=0;
 tz.Location zone=tz.getLocation('Africa/Casablanca');
 final scheduled=<int,ReserveReminder>{};
 @override Future<void> initialize()async{}
 @override Future<bool> allowed()async=>permission;
 @override Future<bool> requestPermission()async{requests++;return permission;}
 @override Future<tz.Location> location()async=>zone;
 @override Future<void> replace(List<ReserveReminder> reminders)async{
  if(fail)throw StateError('schedule');scheduled..clear()..addEntries(reminders.map((r)=>MapEntry(r.id,r)));
 }
 @override Future<void> sendTest()async{tests++;}
}
Map<String,Object?> reserve({int id=1,int funded=0,String start='2026-10',String due='2027-01-31'})=>
 {'id':id,'name':'Private insurance','target':12000,'funded':funded,'start_month':start,'due':due};
Map<String,Object?> movement(int amount,{String kind='add',String date='2026-10-23'})=>
 {'reserve_id':1,'kind':kind,'date':date,'amount':amount};
void main(){
 tzdata.initializeTimeZones();final zone=tz.getLocation('Africa/Casablanca');final now=tz.TZDateTime(zone,2026,10,23,8);
 List<ReserveReminder> plan(List<Map<String,Object?>> reserves,{List<Map<String,Object?>> movements=const [],int day=25,DateTime? at,tz.Location? location})=>
  planReserveReminders(data:{'reserves':reserves,'reserve_movements':movements},day:day,now:at??now,location:location??zone);
 test('groups active contributions, skips complete, expired and not-started reserves',(){
  final p=plan([reserve(),reserve(id:2),reserve(id:3,funded:12000),reserve(id:4,due:'2026-09-30'),reserve(id:5,start:'2030-01',due:'2030-12-31')]);
  expect(p.map((r)=>r.at.month),[10,11,12,1]);expect(p.every((r)=>r.at.day==25&&r.at.hour==9),isTrue);
  expect(plan([reserve(funded:12000)]),isEmpty);
  expect(p.every((r)=>!r.payload.contains('Private')&&!r.payload.contains('12000')),isTrue);
 });
 test('monthly contribution suppresses only this month; withdrawal restores the prompt',(){
  final p=plan([reserve()],movements:[movement(3000)]);
  expect(p.first.at.month,11);
  expect(plan([reserve()],movements:[movement(3000),movement(100,kind:'withdraw')]).first.at.month,10);
  expect(plan([reserve()],movements:[movement(12000)]),isEmpty);
  expect(plan([reserve(funded:9000)],movements:[movement(750)]).first.at.month,11);
 });
 test('dated ledger and target changes recalculate future obligations',(){
  expect(plan([reserve()],movements:[movement(3000,date:'2026-09-20')]).first.at.month,10);
  expect(plan([reserve(start:'2026-12')]).first.at.month,12);
  expect(plan([reserve(due:'2026-10-31')]).single.at.month,10);
  expect(plan([reserve(due:'2026-10-31')],at:tz.TZDateTime(zone,2026,10,25,10)),isEmpty);
 });
 test('future-only calendar schedule stays at nine across DST and year boundaries',(){
  final london=tz.getLocation('Europe/London');
  final p=plan([reserve(due:'2028-12-31')],at:tz.TZDateTime(london,2026,10,1),location:london);
  expect(p,hasLength(12));expect(p.first.at.hour,9);expect(p.first.at.timeZoneOffset,Duration.zero);
  expect(p.any((r)=>r.at.year==2027),isTrue);expect(p.every((r)=>ReserveReminder.owns(r.id)),isTrue);
  expect(ReserveReminder.owns(120261025),isFalse);expect(ReserveReminder.owns(21001),isFalse);
  expect(()=>plan([reserve()],day:31),throwsArgumentError);
  expect(plan([reserve(due:'2026-11-31')]),isEmpty);
  expect(plan([reserve(due:'2026-10-20')]),isEmpty);
 });
 test('opt-in denial, disable and permission changes never create financial entries',()async{
  final store=ReserveTestStore()..reserves=[reserve()];final platform=FakeReservePlatform()..permission=false;
  final service=ReserveReminders(store,platform:platform,clock:()=>now);
  await service.synchronize();expect(platform.requests,0);expect(platform.scheduled,isEmpty);
  await expectLater(service.configure(enabled:true,day:25),throwsFormatException);expect(store.settings,isEmpty);
  platform.permission=true;await service.configure(enabled:true,day:25);expect(platform.scheduled,hasLength(4));
  await service.sendTest();expect(platform.tests,1);expect(store.movements,isEmpty);
  await service.configure(enabled:true,day:15);expect(platform.requests,2);
  expect(platform.scheduled.values.first.at.month,11);
  platform.zone=tz.getLocation('America/New_York');await service.synchronize();expect(platform.scheduled.values.first.at.location.name,'America/New_York');
  platform.permission=false;await service.synchronize();expect(platform.scheduled,isEmpty);
  await service.configure(enabled:false,day:15);expect(store.settings[reserveReminderEnabledKey],'0');expect(platform.requests,2);
 });
 test('deposits, withdrawals, deleted reserves and save failures reconcile safely',()async{
  final store=ReserveTestStore()..reserves=[reserve()];final platform=FakeReservePlatform();
  final service=ReserveReminders(store,platform:platform,clock:()=>now);
  await service.configure(enabled:true,day:25);
  store.movements=[movement(3000)];await service.synchronize();expect(platform.scheduled.values.first.at.month,11);
  store.movements.add(movement(1,kind:'withdraw'));await service.synchronize();expect(platform.scheduled.values.first.at.month,10);
  store.fail=true;await expectLater(service.configure(enabled:true,day:1),throwsStateError);
  expect(store.settings[reserveReminderDayKey],'25');expect(platform.scheduled.values.first.at.day,25);
  store.fail=false;platform.fail=true;await expectLater(service.configure(enabled:false,day:25),throwsStateError);
  expect(store.settings[reserveReminderEnabledKey],'1');
  platform.fail=false;store.reserves=[];await service.synchronize();expect(platform.scheduled,isEmpty);
 });
 sqfliteFfiInit();
 test('reserve settings are atomic and device-local through old and new backup restore',()async{
  final db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);addTearDown(db.close);
  for(final name in localTables){await db.execute(name=='settings'?'CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)':'CREATE TABLE $name(id INTEGER)');}
  final store=OfflineStore(database:db);await store.saveReserveReminderPreferences(enabled:true,day:25);
  final exported=jsonDecode(await store.exportJson()) as Map<String,dynamic>;expect(exported['tables']['settings'],isEmpty);
  final tables={for(final name in localTables)name:<Map<String,Object?>>[]};
  tables['settings']=[{'key':reserveReminderEnabledKey,'value':'0'},{'key':reserveReminderDayKey,'value':'1'}];
  for(final version in [1,2]){
   await store.importJson(jsonEncode({'format':'payday-local','schema_version':version,'tables':tables}));
   final prefs=ReserveReminderPreferences.fromRows(await store.table('settings'));expect(prefs.enabled,isTrue);expect(prefs.day,25);
  }
  await db.execute("CREATE TRIGGER reject_day BEFORE INSERT ON settings WHEN NEW.key='reserve_notifications_day' BEGIN SELECT RAISE(ABORT,'failure'); END");
  await expectLater(store.saveReserveReminderPreferences(enabled:false,day:15),throwsA(isA<DatabaseException>()));
  expect(ReserveReminderPreferences.fromRows(await store.table('settings')).enabled,isTrue);
  await db.execute('DROP TRIGGER reject_day');await db.delete('settings');
  tables['settings']=[{'key':reserveReminderEnabledKey,'value':'1'}];
  await store.importJson(jsonEncode({'format':'payday-local','schema_version':2,'tables':tables}));
  expect(ReserveReminderPreferences.fromRows(await store.table('settings')).enabled,isFalse);
 });
}
