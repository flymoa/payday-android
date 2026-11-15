import 'package:payday_local/app_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/settings_pages.dart';
import 'package:payday_local/settings_preferences_pages.dart';
import 'package:payday_local/backup_settings_page.dart';

void main(){
 for(final brightness in Brightness.values){
  testWidgets('every settings destination is a full page and Back returns to the drawer in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   await t.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(_)async{},
    initialPreferences:AppPreferences(appearance:brightness==Brightness.dark?ThemeMode.dark:ThemeMode.light)));
   await t.pumpAndSettle();
   await t.tap(find.byKey(const ValueKey('home-settings-button')));await t.pumpAndSettle();
   for(final title in ['Theme','Notifications','App lock','Currency','Money settings','Backups & data','About & Help']){
    final entry=find.text(title);await t.ensureVisible(entry);await t.pumpAndSettle();await t.tap(entry);await t.pumpAndSettle();
    final scaffold=find.byType(SettingsPageScaffold);expect(scaffold,findsOneWidget,reason:title);
    expect(t.getSize(scaffold).width,320,reason:'$title must fill the screen');
    expect(find.byTooltip('Back to Settings'),findsOneWidget);
    expect(find.byType(BottomSheet),findsNothing);expect(find.byType(AlertDialog),findsNothing);
    if(title=='Currency'||title=='Backups & data'){
     await t.binding.handlePopRoute();
    }else{await t.tap(find.byTooltip('Back to Settings'));}
    await t.pumpAndSettle();expect(find.text('Settings'),findsOneWidget);expect(find.byType(SettingsPageScaffold),findsNothing);
   }
   await t.tap(find.byTooltip('Close settings'));await t.pumpAndSettle();
   expect(find.text('Settings'),findsNothing);expect(t.takeException(),isNull);
  });
  testWidgets('money form validates, keeps failed edits and returns only after save in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   var success=false,calls=0;int? savedBuffer,savedOpening;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(1.5)),child:child!),
    home:Builder(builder:(c)=>Scaffold(body:TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute<void>(builder:(_)=>MoneySettingsPage(
     currency:'EUR',buffer:20000,openingSavings:10000,onSave:(buffer,opening)async{calls++;savedBuffer=buffer;savedOpening=opening;return success;}))),child:const Text('Open'))))));
   await t.tap(find.text('Open'));await t.pumpAndSettle();
   await t.enterText(find.byType(TextFormField).first,'-1');await t.tap(find.text('Save settings'));await t.pumpAndSettle();expect(calls,0);
   await t.enterText(find.byType(TextFormField).first,'300.505');await t.tap(find.text('Save settings'));await t.pumpAndSettle();expect(calls,0);
   await t.enterText(find.byType(TextFormField).first,'300,50');await t.tap(find.text('Save settings'));await t.pumpAndSettle();
   expect(calls,1);expect(find.byType(MoneySettingsPage),findsOneWidget);expect(savedBuffer,30050);expect(savedOpening,10000);
   success=true;await t.tap(find.text('Save settings'));await t.pumpAndSettle();expect(calls,2);expect(find.text('Open'),findsOneWidget);
   expect(t.takeException(),isNull);
  });
 }
 testWidgets('backup actions refresh status, disable duplicates and preserve the full page',(t)async{
  final done=Completer<void>();var exports=0;
  await t.pumpWidget(MaterialApp(home:BackupSettingsPage(initialStatus:'No export recorded yet',
   refreshStatus:()async=>'Last export: 2026-10-23',onExport:()async{exports++;await done.future;},onRestore:()async{})));
  await t.tap(find.text('Export backup'));await t.pump();
  expect(t.widget<OutlinedButton>(find.byKey(const ValueKey('export-backup'))).onPressed,isNull);
  expect(t.widget<OutlinedButton>(find.byKey(const ValueKey('restore-backup'))).onPressed,isNull);
  expect(t.widget<IconButton>(find.byWidgetPredicate((w)=>w is IconButton&&w.tooltip=='Back to Settings')).onPressed,isNull);
  done.complete();await t.pumpAndSettle();expect(exports,1);expect(find.text('Last export: 2026-10-23'),findsOneWidget);
  expect(find.byType(BackupSettingsPage),findsOneWidget);expect(t.takeException(),isNull);
 });
}
