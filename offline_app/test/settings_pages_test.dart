import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/build_info.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/settings_pages.dart';

void main(){
 test('About release details match the APK source version',(){
  final source=File('pubspec.yaml').readAsStringSync();
  final match=RegExp(r'^version:\s*(\S+)\s*$',multiLine:true).firstMatch(source)!;
  expect('$paydayVersion+$paydayBuildNumber',match.group(1));
 });
 for(final brightness in Brightness.values){
  testWidgets('security keeps explanation behind info icon and preserves failed changes in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
   var succeed=false,calls=0;
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(1.4)),child:child!),
    home:SecuritySettingsPage(initialEnabled:false,onChanged:(value)async{calls++;return succeed;})));
   await tester.pumpAndSettle();
   expect(find.text(appLockExplanation),findsNothing);
   final toggle=find.byKey(const ValueKey('app-lock-setting'));
   await tester.tap(toggle);await tester.pumpAndSettle();
   expect(calls,1);expect(tester.widget<SwitchListTile>(toggle).value,isFalse);
   succeed=true;await tester.tap(toggle);await tester.pumpAndSettle();
   expect(tester.widget<SwitchListTile>(toggle).value,isTrue);
   await tester.tap(find.byTooltip('About app lock'));await tester.pumpAndSettle();
   expect(find.text(appLockExplanation),findsOneWidget);
   await tester.ensureVisible(find.text('Got it'));await tester.tap(find.text('Got it'));await tester.pumpAndSettle();
   expect(find.text(appLockExplanation),findsNothing);
   expect(tester.widget<SwitchListTile>(toggle).value,isTrue);
   expect(tester.takeException(),isNull);
  });
  testWidgets('About help is readable, topics open on demand, and returns to Settings in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(1.4)),child:child!),
    home:Builder(builder:(context)=>Scaffold(body:TextButton(onPressed:()=>Navigator.push(context,
     MaterialPageRoute<void>(builder:(_)=>const AboutHelpPage())),child:const Text('Settings'))))));
   await tester.tap(find.text('Settings'));await tester.pumpAndSettle();
   expect(find.text('Version $paydayVersion · Build $paydayBuildNumber'),findsOneWidget);
   expect(find.textContaining('Payday works without an account'),findsNothing);
   await tester.ensureVisible(find.text('Privacy & security'));await tester.pumpAndSettle();
   await tester.tap(find.text('Privacy & security'));await tester.pumpAndSettle();
   expect(find.textContaining('Payday works without an account'),findsOneWidget);
   await tester.ensureVisible(find.text('Got it'));await tester.tap(find.text('Got it'));await tester.pumpAndSettle();
   await tester.tap(find.byTooltip('Back to Settings'));await tester.pumpAndSettle();
   expect(find.text('Settings'),findsOneWidget);expect(tester.takeException(),isNull);
  });
 }
 testWidgets('settings routes return to the Settings page and leave the tabs untouched',(tester)async{
  await tester.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(_)async{}));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('home-settings-button')));await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('security-setting')));await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('security-setting')));await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('app-lock-setting')),findsOneWidget);
  await tester.binding.handlePopRoute();await tester.pumpAndSettle();
  expect(find.text('Settings'),findsOneWidget);expect(find.byKey(const ValueKey('app-lock-setting')),findsNothing);
  await tester.ensureVisible(find.byKey(const ValueKey('about-help-setting')));await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('about-help-setting')));await tester.pumpAndSettle();
  expect(find.text('About Payday'),findsOneWidget);expect(find.text('Getting started'),findsOneWidget);
  await tester.binding.handlePopRoute();await tester.pumpAndSettle();
  expect(find.text('Settings'),findsOneWidget);
  await tester.tap(find.byTooltip('Close settings'));await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('bottom-2')));await tester.pumpAndSettle();
  expect(find.text('Settings'),findsNothing);expect(find.text('About Payday'),findsNothing);
  expect(tester.takeException(),isNull);
 });
}
