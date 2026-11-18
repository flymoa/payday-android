import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:payday_local/bill_reminders.dart';
import 'package:payday_local/main.dart' show FinanceScreen;
import 'bill_reminders_test.dart' show BillTestStore,FakeBillPlatform;
class CountingBillReminders extends BillReminders{
 CountingBillReminders(BillTestStore store):super(store,platform:FakeBillPlatform());
 int calls=0;
 @override Future<void> synchronize()async{calls++;}
}
void main(){
 tzdata.initializeTimeZones();
 testWidgets('startup, resume and a saved change refresh bill reminders',(t)async{
  final store=BillTestStore()..payments=[{'type':'Income','category':'Salary','date':'${DateTime.now().toIso8601String().substring(0,7)}-01','amount':10000}];
  final reminders=CountingBillReminders(store);
  await t.pumpWidget(MaterialApp(home:FinanceScreen(store:store,initialData:store.snapshot(),billReminders:reminders)));
  await t.pumpAndSettle();expect(reminders.calls,1);
  t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await t.pumpAndSettle();expect(reminders.calls,2);
  await t.ensureVisible(find.byKey(const ValueKey('home-backup-snooze')));await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('home-backup-snooze')));await t.pumpAndSettle();
  expect(reminders.calls,3);expect(t.takeException(),isNull);
 });
}
