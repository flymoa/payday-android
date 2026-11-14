import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:payday_local/bill_reminders.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();tzdata.initializeTimeZones();
 test('native reconciliation cancels only bill IDs and keeps an unchanged date without duplicates',()async{
  debugDefaultTargetPlatformOverride=TargetPlatform.android;
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  addTearDown(()=>debugDefaultTargetPlatformOverride=null);
  const channel=MethodChannel('dexterous.com/flutter/local_notifications');
  final calls=<MethodCall>[];
  final zone=tz.getLocation('Africa/Casablanca');
  final future=tz.TZDateTime.now(zone).add(const Duration(days:30));
  final reminder=BillReminder(at:tz.TZDateTime(zone,future.year,future.month,future.day,9));
  const oldId=120261001;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,(call)async{
   calls.add(call);
   if(call.method=='pendingNotificationRequests')return [
    {'id':21001,'title':'PAYDAY','body':'backup','payload':null},
    {'id':oldId,'title':'PAYDAY','body':billNotificationBody,'payload':'old'},
    {'id':reminder.id,'title':'PAYDAY','body':billNotificationBody,'payload':reminder.payload},
   ];
   if(call.method=='getActiveNotifications')return <Map<String,Object?>>[];
   return true;
  });
  addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,null));
  final platform=AndroidBillReminderPlatform();await platform.replace([reminder]);
  expect(calls.where((c)=>c.method=='cancel').map((c)=>(c.arguments as Map)['id']),[oldId]);
  expect(calls.where((c)=>c.method=='zonedSchedule'),isEmpty);
  calls.clear();
  final fresh=BillReminder(at:tz.TZDateTime(zone,future.year,future.month,future.day+1,9));
  await platform.replace([reminder,fresh]);
  final scheduled=calls.singleWhere((c)=>c.method=='zonedSchedule').arguments as Map;
  expect(scheduled['id'],fresh.id);expect(scheduled['body'],billNotificationBody);
  expect(scheduled['title'],'PAYDAY');expect(scheduled['payload'],fresh.payload);
  calls.clear();await platform.replace([]);
  final canceled=calls.where((c)=>c.method=='cancel').map((c)=>(c.arguments as Map)['id']);
  expect(canceled,containsAll([oldId,reminder.id,AndroidBillReminderPlatform.testId]));expect(canceled, isNot(contains(21001)));
 });
}
