import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:payday_local/bill_reminders.dart';
import 'package:payday_local/offline_store.dart';

class FakeBillPlatform implements BillReminderPlatform {
 bool permission=true,fail=false;
 int requests=0,tests=0;
 tz.Location zone=tz.getLocation('Africa/Casablanca');
 final scheduled=<int,BillReminder>{};
 @override Future<void> initialize()async{}
 @override Future<bool> allowed()async=>permission;
 @override Future<bool> requestPermission()async{requests++;return permission;}
 @override Future<tz.Location> location()async=>zone;
 @override Future<void> replace(List<BillReminder> reminders)async{
  if(fail)throw StateError('schedule');
  scheduled..clear()..addEntries(reminders.map((r)=>MapEntry(r.id,r)));
 }
 @override Future<void> sendTest()async{tests++;}
}
class BillTestStore extends OfflineStore {
 final settings=<String,String>{};
 List<Map<String,Object?>> bills=[],payments=[];
 bool fail=false;
 @override Future<List<Map<String,Object?>>> table(String name)async=>[for(final e in settings.entries){'key':e.key,'value':e.value}];
 @override Future<Map<String,List<Map<String,Object?>>>> billReminderSnapshot()async=>{'bills':bills,'transactions':payments};
 @override Future<void> saveBillReminderPreferences({required bool enabled,required int leadDays})async{
  if(fail)throw StateError('storage');settings[billReminderEnabledKey]=enabled?'1':'0';settings[billReminderLeadKey]='$leadDays';
 }
 @override Future<Map<String,List<Map<String,Object?>>>> snapshot()async=>{'settings':await table('settings'),'bills':bills,'transactions':payments};
 @override Future<void> setSetting(String key,String value)async{if(fail)throw StateError('storage');settings[key]=value;}
 @override Future<void> close()async{}
}
Map<String,Object?> bill(String code,String due,{int amount=1000})=>{'code':code,'due':due,'amount':amount};
Map<String,Object?> payment(String code,int amount,{String type='Expense'})=>{'type':type,'bill_id':code,'amount':amount};
void main(){
 tzdata.initializeTimeZones();
 final zone=tz.getLocation('Africa/Casablanca');
 final now=tz.TZDateTime(zone,2026,10,23,8);
 List<BillReminder> plan(List<Map<String,Object?>> bills,{List<Map<String,Object?>> payments=const [],int days=1,DateTime? at,tz.Location? location})=>
  planBillReminders(data:{'bills':bills,'transactions':payments},leadDays:days,now:at??now,location:location??zone);
 test('due date, one day and three days use local calendar dates at nine',(){
  for(final days in [0,1,3]){
   final p=plan([bill('A','2026-11-01')],days:days).single;
   expect(p.at.hour,9);expect(p.at.location.name,'Africa/Casablanca');
   expect(p.at.day,days==0?1:days==1?31:29);expect(p.at.month,days==0?11:10);
  }
 });
 test('full/overpayment removes reminders, partial stays and non-expense links do not pay',(){
  final bills=[bill('A','2026-11-10'),bill('B','2026-11-11'),bill('C','2026-11-12'),bill('D','2026-11-13')];
  final p=plan(bills,payments:[payment('A',400),payment('A',600),payment('B',1100),payment('C',999),payment('D',1000,type:'Income')]);
  expect(p.map((r)=>r.at.day),[11,12]);
 });
 test('grouping, invalid dates, past times and one-year horizon prevent duplicate/stale alerts',(){
  final p=plan([bill('A','2026-11-10'),bill('B','2026-11-10'),bill('old','2026-10-20'),bill('bad','2026-11-31'),bill('far','2030-01-01')]);
  expect(p,hasLength(1));expect(BillReminder.owns(p.single.id),isTrue);expect(BillReminder.owns(21001),isFalse);
  expect(plan([bill('A','2026-10-24')],at:tz.TZDateTime(zone,2026,10,23,10)),isEmpty);
 });
 test('DST, leap day and year boundaries retain nine AM',(){
  final london=tz.getLocation('Europe/London');
  final a=plan([bill('A','2026-10-26')],location:london,at:tz.TZDateTime(london,2026,10,20)).single;
  expect(a.at.day,25);expect(a.at.hour,9);expect(a.at.timeZoneOffset,Duration.zero);
  final b=plan([bill('A','2028-03-01')],at:tz.TZDateTime(zone,2028,2,1)).single;
  expect(b.at.month,2);expect(b.at.day,29);
  final c=plan([bill('A','2027-01-01')],days:3).single;expect(c.at.month,12);expect(c.at.day,29);
 });
 test('off by default; opt-in denied does not save; disabling clears and never requests again',()async{
  final store=BillTestStore()..bills=[bill('A','2026-11-10')];final platform=FakeBillPlatform()..permission=false;
  final service=BillReminders(store,platform:platform,clock:()=>now);
  await service.synchronize();expect(platform.requests,0);expect(platform.scheduled,isEmpty);
  await expectLater(service.configure(enabled:true,leadDays:1),throwsFormatException);expect(store.settings,isEmpty);
  platform.permission=true;await service.configure(enabled:true,leadDays:1);expect(platform.scheduled,hasLength(1));
  expect(platform.requests,2);await service.configure(enabled:true,leadDays:3);expect(platform.requests,2);
  await service.sendTest();expect(platform.tests,1);
  await service.configure(enabled:false,leadDays:3);expect(platform.scheduled,isEmpty);expect((await service.read()).preferences.enabled,isFalse);
 });
 test('payment, Undo, delete, edit and repeated sync converge without duplicate dates',()async{
  final store=BillTestStore()..bills=[bill('A','2026-11-10'),bill('B','2026-11-10')];final platform=FakeBillPlatform();
  final service=BillReminders(store,platform:platform,clock:()=>now);
  await service.configure(enabled:true,leadDays:1);expect(platform.scheduled,hasLength(1));
  store.payments=[payment('A',1000)];await service.synchronize();expect(platform.scheduled,hasLength(1));
  store.payments.add(payment('B',1000));await service.synchronize();expect(platform.scheduled,isEmpty);
  store.payments.removeLast();await service.synchronize();expect(platform.scheduled,hasLength(1));
  store.bills=[bill('A','2026-11-10')];await service.synchronize();expect(platform.scheduled,isEmpty);
  store.bills=[bill('B','2026-12-01')];await service.synchronize();expect(platform.scheduled.values.single.at.month,11);
  await service.synchronize();expect(platform.scheduled,hasLength(1));
 });
 test('storage and schedule failures leave preference unchanged and roll back the plan',()async{
  final store=BillTestStore()..bills=[bill('A','2026-11-10')];final platform=FakeBillPlatform();final service=BillReminders(store,platform:platform,clock:()=>now);
  await service.configure(enabled:true,leadDays:1);final old=platform.scheduled.values.single.payload;
  store.fail=true;await expectLater(service.configure(enabled:true,leadDays:3),throwsStateError);
  expect(platform.scheduled.values.single.payload,old);expect(store.settings[billReminderLeadKey],'1');
  store.fail=false;platform.fail=true;await expectLater(service.configure(enabled:false,leadDays:1),throwsStateError);
  expect(store.settings[billReminderEnabledKey],'1');
 });
 test('changing device zone and permission resynchronizes without new permission requests',()async{
  final store=BillTestStore()..bills=[bill('A','2026-11-10')];final platform=FakeBillPlatform();final service=BillReminders(store,platform:platform,clock:()=>now);
  await service.configure(enabled:true,leadDays:1);final old=platform.scheduled.values.single.payload;
  platform.zone=tz.getLocation('America/New_York');await service.synchronize();expect(platform.scheduled.values.single.payload,isNot(old));
  platform.permission=false;await service.synchronize();expect(platform.scheduled,isEmpty);
  platform.permission=true;await service.synchronize();expect(platform.scheduled,hasLength(1));expect(platform.requests,1);
 });
 sqfliteFfiInit();
 test('device-local bill flags survive legacy/current restore and cannot be imported',()async{
  final db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);addTearDown(db.close);
  for(final name in localTables){await db.execute(name=='settings'?'CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)':'CREATE TABLE $name(id INTEGER)');}
  final store=OfflineStore(database:db);await store.saveBillReminderPreferences(enabled:true,leadDays:3);
  final exported=jsonDecode(await store.exportJson()) as Map<String,dynamic>;expect(exported['tables']['settings'],isEmpty);
  final tables={for(final name in localTables)name:<Map<String,Object?>>[]};
  tables['settings']=[{'key':billReminderEnabledKey,'value':'0'},{'key':billReminderLeadKey,'value':'0'}];
  for(final version in [1,2]){
   await store.importJson(jsonEncode({'format':'payday-local','schema_version':version,'tables':tables}));
   expect(BillReminderPreferences.fromRows(await store.table('settings')).enabled,isTrue);
   expect(BillReminderPreferences.fromRows(await store.table('settings')).leadDays,3);
  }
  await db.delete('settings');tables['settings']=[{'key':billReminderEnabledKey,'value':'1'}];
  await store.importJson(jsonEncode({'format':'payday-local','schema_version':2,'tables':tables}));
  expect(BillReminderPreferences.fromRows(await store.table('settings')).enabled,isFalse);
 });
 test('real SQLite payment edits, deletion, Undo and bill edits update the plan',()async{
  final db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);addTearDown(db.close);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT UNIQUE,name TEXT,due TEXT,amount INTEGER,category TEXT,note TEXT,repeat_monthly INTEGER NOT NULL DEFAULT 0)');
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,date TEXT,type TEXT,category TEXT,amount INTEGER,description TEXT,note TEXT,bill_id TEXT)');
  final store=OfflineStore(database:db);final platform=FakeBillPlatform();final service=BillReminders(store,platform:platform,clock:()=>now);
  await store.saveBill(code:'A',name:'Private internet bill',due:'2026-11-10',amount:1000,category:'Subscriptions',note:'');
  await service.configure(enabled:true,leadDays:1);expect(platform.scheduled,hasLength(1));
  await store.saveTransaction(date:'2026-10-23',type:'Expense',category:'Subscriptions',amount:1000,description:'Private title',note:'',billId:'A');
  await service.synchronize();expect(platform.scheduled,isEmpty);
  final removed=await store.deleteTransactionForUndo(1);await service.synchronize();expect(platform.scheduled,hasLength(1));
  await store.restoreDeletedTransaction(removed!);await service.synchronize();expect(platform.scheduled,isEmpty);
  await store.saveTransaction(id:1,date:'2026-10-23',type:'Expense',category:'Subscriptions',amount:400,description:'Private title',note:'',billId:'A');
  await service.synchronize();expect(platform.scheduled,hasLength(1));
  await store.saveBill(id:1,code:'A',name:'Private internet bill',due:'2026-11-20',amount:1000,category:'Subscriptions',note:'');
  await service.synchronize();expect(platform.scheduled.values.single.at.day,19);
  await store.removeBill(1);await service.synchronize();expect(platform.scheduled,isEmpty);
 });

}
