import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'offline_store.dart';

const backupReminderPreference='backup_notifications_enabled';
const backupNotificationTitle='PAYDAY';
const backupNotificationBody='Keep your records safe. Open PAYDAY to save a backup.';

abstract class ReminderPlatform {
 Future<void> initialize();
 Future<bool> allowed();
 Future<bool> requestPermission();
 Future<void> scheduleWeekly();
 Future<void> cancel();
 Future<void> sendTest();
 Future<void> openSettings();
}

class AndroidReminderPlatform implements ReminderPlatform {
 final plugin=FlutterLocalNotificationsPlugin();
 Future<void>? _initializing;
 static const reminderId=21001,testId=21002,channelId='payday_backup_reminders';
 static const details=NotificationDetails(android:AndroidNotificationDetails(
  channelId,'Backup reminders',channelDescription:'Optional weekly reminders to save a PAYDAY backup',
  icon:'payday_notification',importance:Importance.low,priority:Priority.low,
  playSound:false,enableVibration:false,visibility:NotificationVisibility.private));
 AndroidFlutterLocalNotificationsPlugin? get android=>plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
 @override Future<void> initialize()async{
  if(_initializing!=null)return _initializing!;
  final task=_initialize();_initializing=task;
  try{await task;}catch(_){_initializing=null;rethrow;}
 }
 Future<void> _initialize()async{
  final initialized=await plugin.initialize(settings:const InitializationSettings(android:AndroidInitializationSettings('payday_notification')));
  if(initialized!=true||android==null)throw StateError('Notifications are unavailable.');
  await android!.createNotificationChannel(const AndroidNotificationChannel(channelId,'Backup reminders',
   description:'Optional weekly reminders to save a PAYDAY backup',importance:Importance.low,playSound:false,enableVibration:false));
 }
 @override Future<bool> allowed()async{
  if(await android?.areNotificationsEnabled()!=true)return false;
  final channels=await android?.getNotificationChannels();
  return !(channels??<AndroidNotificationChannel>[]).any((c)=>c.id==channelId&&c.importance==Importance.none);
 }
 @override Future<bool> requestPermission()async{
  await android?.requestNotificationsPermission();return allowed();
 }
 @override Future<void> scheduleWeekly()=>plugin.periodicallyShow(id:reminderId,title:backupNotificationTitle,body:backupNotificationBody,
  repeatInterval:RepeatInterval.weekly,notificationDetails:details,androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle);
 @override Future<void> cancel()async{await plugin.cancel(id:reminderId);await plugin.cancel(id:testId);}
 @override Future<void> sendTest()=>plugin.show(id:testId,title:backupNotificationTitle,body:'Your backup reminders are ready.',notificationDetails:details);
 @override Future<void> openSettings()async{await android?.openAppNotificationSettings();}
}

class BackupNotificationState {
 const BackupNotificationState({required this.enabled,required this.allowed});
 final bool enabled,allowed;
}

/// This preference is device-local and never enabled by restoring a backup.
class BackupNotifications {
 BackupNotifications(this.store,{ReminderPlatform? platform}):platform=platform??AndroidReminderPlatform();
 final OfflineStore store;
 final ReminderPlatform platform;
 static bool get supported=>Platform.isAndroid;
 Future<void> _tail=Future.value();
 Future<T> _serial<T>(Future<T> Function() operation){
  final result=_tail.then((_)=>operation());
  _tail=result.then<void>((_){},onError:(Object error,StackTrace stack){});
  return result;
 }
 Future<bool> _enabled()async=>(await store.table('settings')).any((r)=>r['key']==backupReminderPreference&&r['value']=='1');
 Future<BackupNotificationState> read()=>_serial(()async{
  await platform.initialize();return BackupNotificationState(enabled:await _enabled(),allowed:await platform.allowed());
 });
 Future<void> setEnabled(bool enabled)=>_serial(()async{
  await platform.initialize();
  final previous=await _enabled();
  if(enabled&&!await platform.requestPermission())throw const FormatException('Allow notifications in Android settings to enable reminders.');
  try{
   if(enabled){await platform.scheduleWeekly();}else{await platform.cancel();}
   await store.setSetting(backupReminderPreference,enabled?'1':'0');
  }catch(_){
   // Restore the previous schedule if either scheduling or storage failed.
   try{if(previous){await platform.scheduleWeekly();}else{await platform.cancel();}}catch(_){}
   rethrow;
  }
 });
 Future<void> resetAfterExport()=>_serial(()async{
  if(!await _enabled())return;
  await platform.initialize();
  if(await platform.allowed()){
   await platform.cancel();await platform.scheduleWeekly();
  }
 });
 Future<void> sendTest()=>_serial(()async{
  await platform.initialize();
  if(!await _enabled()||!await platform.allowed())throw const FormatException('Enable reminders and allow Android notifications first.');
  await platform.sendTest();
 });
 Future<void> openSettings()=>_serial(()async{await platform.initialize();await platform.openSettings();});
}
