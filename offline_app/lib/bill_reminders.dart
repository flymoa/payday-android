import 'localization.dart';
import 'app_language.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'offline_store.dart';

const billReminderEnabledKey='bill_notifications_enabled';
const billReminderLeadKey='bill_notifications_lead_days';
const billNotificationBody='You have a bill to review. Open PAYDAY for details.';
const billReminderChoices={0:'On the due date',1:'1 day before',3:'3 days before'};

class BillReminderPreferences {
 const BillReminderPreferences({this.enabled=false,this.leadDays=1});
 final bool enabled;
 final int leadDays;
 factory BillReminderPreferences.fromRows(Iterable<Map<String,Object?>> rows){
  final values={for(final r in rows)r['key']:r['value']?.toString()};
  final days=int.tryParse(values[billReminderLeadKey]??'')??1;
  return BillReminderPreferences(enabled:values[billReminderEnabledKey]=='1',leadDays:billReminderChoices.containsKey(days)?days:1);
 }
}

class BillReminder {
 const BillReminder({required this.at});
 final tz.TZDateTime at;
 int get id=>100000000+at.year*10000+at.month*100+at.day;
 String get payload=>'payday-bill-v1|${at.millisecondsSinceEpoch}|${at.location.name}';
 static bool owns(int id)=>id>=100000000&&id<200000000;
}

/// Matches the app's bill-payment rule: all linked Expense entries, across months.
/// One private notification per local day, with a rolling one-year horizon.
List<BillReminder> planBillReminders({required Map<String,List<Map<String,Object?>>> data,
 required int leadDays,required DateTime now,required tz.Location location}){
 if(!billReminderChoices.containsKey(leadDays))throw ArgumentError('Unsupported reminder timing');
 int amount(Map<String,Object?> row)=>int.tryParse('${row['amount']}')??0;
 final paid=<String,int>{};
 for(final row in data['transactions']??<Map<String,Object?>>[]){
  if(row['type']!='Expense')continue;
  final code=row['bill_id']?.toString()??'';
  if(code.isNotEmpty)paid[code]=(paid[code]??0)+amount(row);
 }
 final localNow=tz.TZDateTime.from(now,location);
 final horizon=tz.TZDateTime(location,localNow.year+1,localNow.month,localNow.day,23,59,59);
 final byDay=<int,BillReminder>{};
 for(final bill in data['bills']??<Map<String,Object?>>[]){
  final code=bill['code']?.toString()??'';
  if(code.isEmpty||amount(bill)<=0||(paid[code]??0)>=amount(bill))continue;
  final text=bill['due']?.toString()??'';
  if(!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text))continue;
  final due=DateTime.tryParse(text);
  if(due==null||'${due.year.toString().padLeft(4,'0')}-${due.month.toString().padLeft(2,'0')}-${due.day.toString().padLeft(2,'0')}'!=text)continue;
  // Calendar subtraction, not elapsed hours: 9 AM stays 9 AM across DST.
  final at=tz.TZDateTime(location,due.year,due.month,due.day-leadDays,9);
  if(!at.isAfter(localNow)||at.isAfter(horizon))continue;
  final reminder=BillReminder(at:at);byDay[reminder.id]=reminder;
 }
 return byDay.values.toList()..sort((a,b)=>a.at.compareTo(b.at));
}

abstract class BillReminderPlatform {
 Future<void> initialize();
 Future<bool> allowed();
 Future<bool> requestPermission();
 Future<tz.Location> location();
 Future<void> replace(List<BillReminder> reminders);
 Future<void> sendTest();
}

class AndroidBillReminderPlatform implements BillReminderPlatform,NotificationLanguagePlatform {
 String language='en';
 @override void setLanguage(String value){final next=supportedLanguage(value);if(next!=language){language=next;_initializing=null;}}
 final plugin=FlutterLocalNotificationsPlugin();
 static bool _zonesReady=false;
 Future<void>? _initializing;
 static const channelId='payday_bill_reminders',testId=22002;
 static const details=NotificationDetails(android:AndroidNotificationDetails(channelId,'Bill reminders',
  channelDescription:'Optional reminders for unpaid PAYDAY bills',icon:'payday_notification',
  importance:Importance.low,priority:Priority.low,playSound:false,enableVibration:false,visibility:NotificationVisibility.private));
 NotificationDetails get localizedDetails=>NotificationDetails(android:AndroidNotificationDetails(channelId,translateMessage('Bill reminders',language),
  channelDescription:translateMessage('Optional reminders for unpaid PAYDAY bills',language),icon:'payday_notification',
  importance:Importance.low,priority:Priority.low,playSound:false,enableVibration:false,visibility:NotificationVisibility.private));
 AndroidFlutterLocalNotificationsPlugin? get android=>plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
 @override Future<void> initialize()async{
  if(_initializing!=null)return _initializing!;
  final task=_initialize();_initializing=task;
  try{await task;}catch(_){_initializing=null;rethrow;}
 }
 Future<void> _initialize()async{
  final result=await plugin.initialize(settings:const InitializationSettings(android:AndroidInitializationSettings('payday_notification')));
  if(result!=true||android==null)throw StateError('Notifications are unavailable.');
  await android!.createNotificationChannel(AndroidNotificationChannel(channelId,translateMessage('Bill reminders',language),
   description:translateMessage('Optional reminders for unpaid PAYDAY bills',language),importance:Importance.low,playSound:false,enableVibration:false));
 }
 @override Future<bool> allowed()async{
  if(await android?.areNotificationsEnabled()!=true)return false;
  final channels=await android?.getNotificationChannels();
  return !(channels??<AndroidNotificationChannel>[]).any((c)=>c.id==channelId&&c.importance==Importance.none);
 }
 @override Future<bool> requestPermission()async{await android?.requestNotificationsPermission();return allowed();}
 @override Future<tz.Location> location()async{
  if(!_zonesReady){tzdata.initializeTimeZones();_zonesReady=true;}
  final zone=await FlutterTimezone.getLocalTimezone();
  // Do not silently substitute UTC for an unknown device zone.
  return tz.getLocation(zone.identifier);
 }
 @override Future<void> replace(List<BillReminder> reminders)async{
  final pending=await plugin.pendingNotificationRequests();
  final active=await plugin.getActiveNotifications();
  final wanted={for(final r in reminders)r.id:r};
  final owned={...pending.map((r)=>r.id),...active.map((r)=>r.id)}.whereType<int>().where(BillReminder.owns);
  for(final id in owned){if(!wanted.containsKey(id))await plugin.cancel(id:id);}
  if(reminders.isEmpty)await plugin.cancel(id:testId);
  final existing={for(final r in pending)r.id:r.payload};
  for(final reminder in reminders){
   final payload=language=='en'?reminder.payload:'${reminder.payload}|$language';
   if(existing[reminder.id]==payload)continue;
   // Clear an earlier notification with the same day ID before replacing it.
   await plugin.cancel(id:reminder.id);
   await plugin.zonedSchedule(id:reminder.id,title:'PAYDAY',body:translateMessage(billNotificationBody,language),
    scheduledDate:reminder.at,notificationDetails:localizedDetails,payload:payload,
    androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle);
  }
 }
 @override Future<void> sendTest()=>plugin.show(id:testId,title:'PAYDAY',body:translateMessage(billNotificationBody,language),notificationDetails:localizedDetails);
}

class BillNotificationState {
 const BillNotificationState({required this.preferences,required this.allowed});
 final BillReminderPreferences preferences;
 final bool allowed;
}

class BillReminders {
 BillReminders(this.store,{BillReminderPlatform? platform,DateTime Function()? clock})
  :platform=platform??AndroidBillReminderPlatform(),clock=clock??DateTime.now;
 final OfflineStore store;
 final BillReminderPlatform platform;
 final DateTime Function() clock;
 static bool get supported=>Platform.isAndroid;
 Future<void> _applyLanguage()async{
  if(platform is NotificationLanguagePlatform){
   final rows=await store.table('settings');
   final language=rows.where((r)=>r['key']=='app_language').map((r)=>r['value']?.toString()).firstOrNull;
   (platform as NotificationLanguagePlatform).setLanguage(supportedLanguage(language));
  }
 }
 Future<void> _tail=Future.value();
 Future<T> _serial<T>(Future<T> Function() operation){
  final result=_tail.then((_)=>operation());
  _tail=result.then<void>((_){},onError:(Object error,StackTrace stack){});return result;
 }
 Future<BillReminderPreferences> _preferences()async=>BillReminderPreferences.fromRows(await store.table('settings'));
 Future<List<BillReminder>> _plan(int days)async{
  final zone=await platform.location();
  return planBillReminders(data:await store.billReminderSnapshot(),leadDays:days,now:clock(),location:zone);
 }
 Future<BillNotificationState> read()=>_serial(()async{
  await _applyLanguage();await platform.initialize();return BillNotificationState(preferences:await _preferences(),allowed:await platform.allowed());
 });
 Future<void> synchronize()=>_serial(()async{
  final preferences=await _preferences();await _applyLanguage();await platform.initialize();
  final enabled=preferences.enabled&&await platform.allowed();
  await platform.replace(enabled?await _plan(preferences.leadDays):[]);
 });
 Future<void> configure({required bool enabled,required int leadDays})=>_serial(()async{
  if(!billReminderChoices.containsKey(leadDays))throw const FormatException('Choose a valid reminder time.');
  final previous=await _preferences();await _applyLanguage();await platform.initialize();
  if(enabled){
   final allowed=previous.enabled?await platform.allowed():await platform.requestPermission();
   if(!allowed)throw const FormatException('Allow bill reminders in Android notification settings first.');
  }
  try{
   await platform.replace(enabled?await _plan(leadDays):[]);
   await store.saveBillReminderPreferences(enabled:enabled,leadDays:leadDays);
  }catch(_){
   try{await platform.replace(previous.enabled&&await platform.allowed()?await _plan(previous.leadDays):[]);}catch(_){}
   rethrow;
  }
 });
 Future<void> sendTest()=>_serial(()async{
  await _applyLanguage();await platform.initialize();
  if(!(await _preferences()).enabled||!await platform.allowed())throw const FormatException('Enable bill reminders and allow Android notifications first.');
  await platform.sendTest();
 });
}

