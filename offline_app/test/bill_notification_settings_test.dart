import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:payday_local/app_icon.dart';
import 'package:payday_local/backup_notifications.dart';
import 'package:payday_local/bill_reminders.dart';
import 'package:payday_local/notification_settings_page.dart';
import 'backup_notifications_test.dart' show MemoryReminderStore,FakeReminderPlatform;
import 'bill_reminders_test.dart' show BillTestStore,FakeBillPlatform;
void main(){
 tzdata.initializeTimeZones();
 for(final brightness in Brightness.values){
  testWidgets('bill opt-in, timing and test work with matching icons in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   final backup=FakeReminderPlatform();final store=BillTestStore();final platform=FakeBillPlatform()..permission=false;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(1.4)),child:child!),
    home:NotificationSettingsPage(reminders:BackupNotifications(MemoryReminderStore(),platform:backup),bills:BillReminders(store,platform:platform))));
   await t.pumpAndSettle();final toggle=find.byKey(const ValueKey('bill-notifications-toggle'));
   expect(t.widget<SwitchListTile>(toggle).value,isFalse);expect(platform.requests,0);
   final icon=find.descendant(of:toggle,matching:find.byType(PaydayAppIcon));expect(t.widget<PaydayAppIcon>(icon).icon,Icons.event_note_outlined);
   await t.tap(toggle);await t.pumpAndSettle();expect(t.widget<SwitchListTile>(toggle).value,isFalse);
   expect(find.textContaining('Allow bill reminders'),findsOneWidget);
   platform.permission=true;await t.tap(toggle);await t.pumpAndSettle();
   expect(t.widget<SwitchListTile>(toggle).value,isTrue);
   for(final days in [0,3,1]){
    await t.ensureVisible(find.byKey(const ValueKey('bill-reminder-timing')));await t.tap(find.byKey(const ValueKey('bill-reminder-timing')));await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('bill-timing-$days')));await t.pumpAndSettle();
    expect(store.settings[billReminderLeadKey],'$days');expect(platform.requests,2);
   }
   await t.ensureVisible(find.text('Send a test'));await t.tap(find.text('Send a test'));await t.pumpAndSettle();
   expect(platform.tests,1);expect(backup.tests,0);
   await t.tap(find.byTooltip('About notifications'));await t.pumpAndSettle();
   expect(find.textContaining(billNotificationExplanation),findsOneWidget);
   await t.ensureVisible(find.text('Got it'));await t.tap(find.text('Got it'));await t.pumpAndSettle();
   await t.ensureVisible(toggle);await t.tap(toggle);await t.pumpAndSettle();expect(t.widget<SwitchListTile>(toggle).value,isFalse);
   expect(find.byKey(const ValueKey('bill-reminder-timing')),findsNothing);expect(t.takeException(),isNull);
  });
 }
}
