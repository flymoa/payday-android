import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:payday_local/backup_notifications.dart';
import 'package:payday_local/notification_settings_page.dart';
import 'package:payday_local/reserve_reminders.dart';
import 'backup_notifications_test.dart' show MemoryReminderStore,FakeReminderPlatform;
import 'reserve_reminders_test.dart' show ReserveTestStore,FakeReservePlatform;
void main(){
 tzdata.initializeTimeZones();
 for(final brightness in Brightness.values){
  testWidgets('reserve reminders opt-in, timing and test remain usable in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   final store=ReserveTestStore();final platform=FakeReservePlatform()..permission=false;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(1.4)),child:child!),
    home:NotificationSettingsPage(reminders:BackupNotifications(MemoryReminderStore(),platform:FakeReminderPlatform()),reserves:ReserveReminders(store,platform:platform))));
   await t.pumpAndSettle();final toggle=find.byKey(const ValueKey('reserve-notifications-toggle'));
   expect(t.widget<SwitchListTile>(toggle).value,isFalse);expect(platform.requests,0);
   await t.tap(toggle);await t.pumpAndSettle();expect(t.widget<SwitchListTile>(toggle).value,isFalse);
   expect(find.textContaining('Allow reserve reminders'),findsOneWidget);
   platform.permission=true;await t.tap(toggle);await t.pumpAndSettle();
   expect(t.widget<SwitchListTile>(toggle).value,isTrue);
   for(final day in [15,25,1]){
    final timing=find.byKey(const ValueKey('reserve-reminder-day'));await t.ensureVisible(timing);await t.tap(timing);await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('reserve-day-$day')));await t.pumpAndSettle();expect(store.settings[reserveReminderDayKey],'$day');
   }
   await t.ensureVisible(find.text('Test reserve reminder'));await t.tap(find.text('Test reserve reminder'));await t.pumpAndSettle();expect(platform.tests,1);
   await t.tap(find.byTooltip('About notifications'));await t.pumpAndSettle();expect(find.textContaining('No money is moved automatically'),findsOneWidget);
   await t.ensureVisible(find.text('Got it'));await t.tap(find.text('Got it'));await t.pumpAndSettle();
   await t.ensureVisible(toggle);await t.tap(toggle);await t.pumpAndSettle();expect(find.byKey(const ValueKey('reserve-reminder-day')),findsNothing);
   expect(t.takeException(),isNull);
  });
 }
}
