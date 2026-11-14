import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:payday_local/app_language.dart';
import 'package:payday_local/localization.dart';
import 'package:payday_local/bill_reminders.dart';
import 'package:payday_local/backup_notifications.dart';
import 'bill_reminders_test.dart' show BillTestStore,FakeBillPlatform,bill;
import 'backup_notifications_test.dart' show FakeReminderPlatform;
class LanguageBillPlatform extends FakeBillPlatform implements NotificationLanguagePlatform{
 String language='en';
 @override void setLanguage(String value){language=value;}
}
class LanguageBackupPlatform extends FakeReminderPlatform implements NotificationLanguagePlatform{
 String language='en';
 @override void setLanguage(String value){language=value;}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();tzdata.initializeTimeZones();
 test('services refresh saved language without permission requests, financial edits or export dates',()async{
  final store=BillTestStore()..bills=[bill('A','2026-11-10')];final billPlatform=LanguageBillPlatform();
  final backupPlatform=LanguageBackupPlatform();final service=BillReminders(store,platform:billPlatform,clock:()=>DateTime(2026,10,27));
  await service.configure(enabled:true,leadDays:1);final payload=billPlatform.scheduled.values.single.payload;
  final requests=billPlatform.requests;store.settings['app_language']='fr';
  await service.synchronize();expect(billPlatform.language,'fr');expect(billPlatform.requests,requests);expect(billPlatform.scheduled.values.single.payload,payload);
  final backups=BackupNotifications(store,platform:backupPlatform);await backups.synchronizeLanguage();
  expect(backupPlatform.language,'fr');expect(backupPlatform.scheduled,0);expect(backupPlatform.requests,0);
  store.settings[backupReminderPreference]='1';await backups.synchronizeLanguage();expect(backupPlatform.scheduled,1);expect(backupPlatform.requests,0);
  expect(store.settings.containsKey('last_backup_export'),isFalse);expect(store.payments,isEmpty);
 });
 test('native pending alarm updates its private body when language changes, keeping its date and ID',()async{
  debugDefaultTargetPlatformOverride=TargetPlatform.android;AndroidFlutterLocalNotificationsPlugin.registerWith();
  addTearDown(()=>debugDefaultTargetPlatformOverride=null);
  const channel=MethodChannel('dexterous.com/flutter/local_notifications');final calls=<MethodCall>[];
  final zone=tz.getLocation('Africa/Casablanca');// The plugin rejects past dates using the real clock, so schedule well ahead of today.
  final ahead=tz.TZDateTime.now(zone).add(const Duration(days:30));
  final reminder=BillReminder(at:tz.TZDateTime(zone,ahead.year,ahead.month,ahead.day,9));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,(call)async{
   calls.add(call);if(call.method=='pendingNotificationRequests')return [{'id':reminder.id,'title':'PAYDAY','body':billNotificationBody,'payload':reminder.payload}];
   if(call.method=='getActiveNotifications')return <Map<String,Object?>>[];return true;
  });
  addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,null));
  final platform=AndroidBillReminderPlatform()..setLanguage('fr');await platform.replace([reminder]);
  final scheduled=calls.singleWhere((c)=>c.method=='zonedSchedule').arguments as Map;
  expect(scheduled['id'],reminder.id);expect(scheduled['body'],translateMessage(billNotificationBody,'fr'));
  expect(scheduled['payload'],'${reminder.payload}|fr');expect(calls.where((c)=>c.method.contains('request')),isEmpty);
 });
}
