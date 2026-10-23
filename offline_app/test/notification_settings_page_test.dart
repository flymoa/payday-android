import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/backup_notifications.dart';
import 'package:payday_local/notification_settings_page.dart';
import 'backup_notifications_test.dart' show MemoryReminderStore,FakeReminderPlatform;
void main(){
 for(final brightness in Brightness.values){
  testWidgets('quiet notifications settings handles opt-in, test, blocked permission and info in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   final store=MemoryReminderStore();final platform=FakeReminderPlatform()..permission=false;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(1.4)),child:child!),
    home:NotificationSettingsPage(reminders:BackupNotifications(store,platform:platform))));
   await t.pumpAndSettle();expect(find.text(backupNotificationExplanation),findsNothing);expect(platform.requests,0);
   await t.tap(find.byKey(const ValueKey('backup-notifications-toggle')));await t.pumpAndSettle();
   expect(t.widget<SwitchListTile>(find.byType(SwitchListTile)).value,isFalse);
   expect(find.textContaining('Allow notifications in Android'),findsOneWidget);
   platform.permission=true;
   await t.tap(find.byKey(const ValueKey('backup-notifications-toggle')));await t.pumpAndSettle();
   expect(t.widget<SwitchListTile>(find.byType(SwitchListTile)).value,isTrue);
   await t.tap(find.text('Send a test'));await t.pumpAndSettle();expect(platform.tests,1);
   await t.tap(find.byTooltip('About notifications'));await t.pumpAndSettle();
   expect(find.text(backupNotificationExplanation),findsOneWidget);
   await t.ensureVisible(find.text('Got it'));await t.tap(find.text('Got it'));await t.pumpAndSettle();
   await t.tap(find.byType(SwitchListTile));await t.pumpAndSettle();expect(store.value,'0');
   expect(t.takeException(),isNull);
  });
 }
}
