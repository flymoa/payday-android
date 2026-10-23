import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'offline_store.dart';
import 'finance.dart';

const reserveReminderEnabledKey='reserve_notifications_enabled';
const reserveReminderDayKey='reserve_notifications_day';
const reserveNotificationBody='Time to review your reserve contributions. Open Payday for details.';
const reserveReminderChoices={1:'1st of the month',15:'15th of the month',25:'25th of the month'};

class ReserveReminderPreferences {
 const ReserveReminderPreferences({this.enabled=false,this.day=1});
 final bool enabled;
 final int day;
 factory ReserveReminderPreferences.fromRows(Iterable<Map<String,Object?>> rows){
  final values={for(final r in rows)r['key']:r['value']?.toString()};
  final days=int.tryParse(values[reserveReminderDayKey]??'')??1;
  return ReserveReminderPreferences(enabled:values[reserveReminderEnabledKey]=='1',day:reserveReminderChoices.containsKey(days)?days:1);
 }
}

class ReserveReminder {
 const ReserveReminder({required this.at});
 final tz.TZDateTime at;
 int get id=>200000000+at.year*10000+at.month*100+at.day;
 String get payload=>'payday-reserve-v1|${at.millisecondsSinceEpoch}|${at.location.name}';
 static bool owns(int id)=>id>=200000000&&id<300000000;
}

/// Matches the reserve screen's remaining monthly contribution, without creating transfers.
/// One private reminder per month; completed, not-started and expired reserves are skipped.
List<ReserveReminder> planReserveReminders({required Map<String,List<Map<String,Object?>>> data,
 required int day,required DateTime now,required tz.Location location}){
 if(!reserveReminderChoices.containsKey(day))throw ArgumentError('Unsupported reminder timing');
 int value(Map<String,Object?> row,String key)=>int.tryParse('${row[key]}')??0;
 final localNow=tz.TZDateTime.from(now,location);
 final horizon=tz.TZDateTime(location,localNow.year+1,localNow.month,localNow.day,23,59,59);
 final result=<ReserveReminder>[];
 for(var offset=0;offset<=12;offset++){
  final at=tz.TZDateTime(location,localNow.year,localNow.month+offset,day,9);
  if(!at.isAfter(localNow)||at.isAfter(horizon))continue;
  final month=monthKey(at);
  var needsContribution=false;
  for(final reserve in data['reserves']??<Map<String,Object?>>[]){
   final start=reserve['start_month']?.toString()??'';
   final dueText=reserve['due']?.toString()??'';
   final due=DateTime.tryParse(dueText);
   if(!RegExp(r'^\d{4}-\d{2}$').hasMatch(start)||due==null||dayKey(due)!=dueText)continue;
   if(start.compareTo(month)>0||monthKey(due).compareTo(month)<0||dayKey(at).compareTo(dueText)>0)continue;
   final target=value(reserve,'target');
   var before=value(reserve,'funded'),net=0;
   for(final movement in data['reserve_movements']??<Map<String,Object?>>[]){
    if(movement['reserve_id']!=reserve['id'])continue;
    final date=movement['date']?.toString()??'';
    if(date.length<7)continue;
    final movementMonth=date.substring(0,7);
    final amount=value(movement,'amount')*(movement['kind']=='add'?1:-1);
    if(movementMonth.compareTo(month)<0)before+=amount;
    if(movementMonth==month)net+=amount;
   }
   if(target<=0||before+net>=target)continue;
   if(reserveAdditionalHold(target:target,fundedBeforeMonth:before,
    netContributedThisMonth:net,due:due,month:DateTime(at.year,at.month))>0){
    needsContribution=true;break;
   }
  }
  if(needsContribution)result.add(ReserveReminder(at:at));
 }
 return result;
}

abstract class ReserveReminderPlatform {
 Future<void> initialize();
 Future<bool> allowed();
 Future<bool> requestPermission();
 Future<tz.Location> location();
 Future<void> replace(List<ReserveReminder> reminders);
 Future<void> sendTest();
}

class AndroidReserveReminderPlatform implements ReserveReminderPlatform {
 final plugin=FlutterLocalNotificationsPlugin();
 static bool _zonesReady=false;
 Future<void>? _initializing;
 static const channelId='payday_reserve_reminders',testId=22003;
 static const details=NotificationDetails(android:AndroidNotificationDetails(channelId,'Reserve reminders',
  channelDescription:'Optional reminders for monthly Payday reserve contributions',icon:'payday_notification',
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
  await android!.createNotificationChannel(const AndroidNotificationChannel(channelId,'Reserve reminders',
   description:'Optional reminders for monthly Payday reserve contributions',importance:Importance.low,playSound:false,enableVibration:false));
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
 @override Future<void> replace(List<ReserveReminder> reminders)async{
  final pending=await plugin.pendingNotificationRequests();
  final active=await plugin.getActiveNotifications();
  final wanted={for(final r in reminders)r.id:r};
  final owned={...pending.map((r)=>r.id),...active.map((r)=>r.id)}.whereType<int>().where(ReserveReminder.owns);
  for(final id in owned){if(!wanted.containsKey(id))await plugin.cancel(id:id);}
  if(reminders.isEmpty)await plugin.cancel(id:testId);
  final existing={for(final r in pending)r.id:r.payload};
  for(final reminder in reminders){
   if(existing[reminder.id]==reminder.payload)continue;
   // Clear an earlier notification with the same day ID before replacing it.
   await plugin.cancel(id:reminder.id);
   await plugin.zonedSchedule(id:reminder.id,title:'Payday',body:reserveNotificationBody,
    scheduledDate:reminder.at,notificationDetails:details,payload:reminder.payload,
    androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle);
  }
 }
 @override Future<void> sendTest()=>plugin.show(id:testId,title:'Payday',body:reserveNotificationBody,notificationDetails:details);
}

class ReserveNotificationState {
 const ReserveNotificationState({required this.preferences,required this.allowed});
 final ReserveReminderPreferences preferences;
 final bool allowed;
}

class ReserveReminders {
 ReserveReminders(this.store,{ReserveReminderPlatform? platform,DateTime Function()? clock})
  :platform=platform??AndroidReserveReminderPlatform(),clock=clock??DateTime.now;
 final OfflineStore store;
 final ReserveReminderPlatform platform;
 final DateTime Function() clock;
 static bool get supported=>Platform.isAndroid;
 Future<void> _tail=Future.value();
 Future<T> _serial<T>(Future<T> Function() operation){
  final result=_tail.then((_)=>operation());
  _tail=result.then<void>((_){},onError:(Object error,StackTrace stack){});return result;
 }
 Future<ReserveReminderPreferences> _preferences()async=>ReserveReminderPreferences.fromRows(await store.table('settings'));
 Future<List<ReserveReminder>> _plan(int days)async{
  final zone=await platform.location();
  return planReserveReminders(data:await store.reserveReminderSnapshot(),day:days,now:clock(),location:zone);
 }
 Future<ReserveNotificationState> read()=>_serial(()async{
  await platform.initialize();return ReserveNotificationState(preferences:await _preferences(),allowed:await platform.allowed());
 });
 Future<void> synchronize()=>_serial(()async{
  final preferences=await _preferences();await platform.initialize();
  final enabled=preferences.enabled&&await platform.allowed();
  await platform.replace(enabled?await _plan(preferences.day):[]);
 });
 Future<void> configure({required bool enabled,required int day})=>_serial(()async{
  if(!reserveReminderChoices.containsKey(day))throw const FormatException('Choose a valid reminder time.');
  final previous=await _preferences();await platform.initialize();
  if(enabled){
   final allowed=previous.enabled?await platform.allowed():await platform.requestPermission();
   if(!allowed)throw const FormatException('Allow reserve reminders in Android notification settings first.');
  }
  try{
   await platform.replace(enabled?await _plan(day):[]);
   await store.saveReserveReminderPreferences(enabled:enabled,day:day);
  }catch(_){
   try{await platform.replace(previous.enabled&&await platform.allowed()?await _plan(previous.day):[]);}catch(_){}
   rethrow;
  }
 });
 Future<void> sendTest()=>_serial(()async{
  await platform.initialize();
  if(!(await _preferences()).enabled||!await platform.allowed())throw const FormatException('Enable reserve reminders and allow Android notifications first.');
  await platform.sendTest();
 });
}

