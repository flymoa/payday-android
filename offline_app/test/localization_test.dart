import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/app_language.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/localization.dart';
import 'package:payday_local/translations.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/opening.dart';
import 'package:payday_local/brand.dart';

class LocaleTestStore extends OfflineStore{
 LocaleTestStore(Database database):super(database:database);
 @override Future<void> close()async{}
}
void main(){
 test('all catalog placeholders are complete and dynamic messages translate',(){
  expect(translateMessage('Settings','fr'),'Paramètres');
  expect(translateMessage('Settings','ar'),'الإعدادات');
  expect(translateMessage('Due: 2026-10-27','fr'),'Échéance : 2026-10-27');
  expect(translateMessage('Available to assign: 300.00 MAD','ar'),'المتاح للتخصيص: 300.00 MAD');
  expect(translateMessage('Bad state: Invalid entry','fr'),'Écriture invalide');
  expect(translateMessage('Original custom label','ar'),'Original custom label');
  for(final entry in paydayTranslations.entries){
   final placeholders=RegExp(r'\{\d+\}').allMatches(entry.key).map((m)=>m.group(0)).toSet();
   expect(entry.value,hasLength(2));
   for(final value in entry.value){expect(value,isNotEmpty);expect(RegExp(r'\{\d+\}').allMatches(value).map((m)=>m.group(0)).toSet(),placeholders,reason:entry.key);}
  }
 });
 test('formatting changes display only and unknown languages retain English',(){
  expect(supportedLanguage('unknown'),'en');expect(AppPreferences.fromRows([]).language,'en');
  expect(localizedMoney(12345,'MAD','fr'),'123,45 MAD');expect(localizedMoney(-12345,'GBP','en'),'-123.45 GBP');
  expect(localizedMoney(12345,'EUR','ar'),'123.45 EUR');
  expect(localizedNumber(123456,'fr',grouped:true),'1\u202f234,56');
  expect(localizedDay(DateTime(2026,10,27),'ar'),'27 أكتوبر 2026');
 });
 sqfliteFfiInit();
 test('language persists and backup restore never translates stored names or monetary units',()async{
  final db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);addTearDown(db.close);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  for(final name in localTables.where((t)=>t!='settings')){await db.execute('CREATE TABLE $name(id INTEGER,name TEXT,amount INTEGER)');}
  final store=LocaleTestStore(db);
  await db.insert('transactions',{'id':1,'name':'Settings','amount':12345});
  await store.saveAppPreferences(const AppPreferences(language:'ar',currency:'EUR',appearance:ThemeMode.dark));
  final raw=await store.exportJson();await store.saveAppPreferences(const AppPreferences(language:'fr'));
  await store.importJson(raw);final saved=await store.loadAppPreferences();expect(saved.language,'ar');expect(saved.currency,'EUR');expect(saved.appearance,ThemeMode.dark);
  expect(await db.query('transactions'),[{'id':1,'name':'Settings','amount':12345}]);
  final old=jsonDecode(raw) as Map<String,dynamic>;(old['tables']['settings'] as List).removeWhere((r)=>r['key']=='app_language');
  await store.importJson(jsonEncode(old));expect((await store.loadAppPreferences()).language,'en');
 });
 for(final code in ['fr','ar']){
  for(final brightness in Brightness.values){
   testWidgets('$code keeps palette, mark, navigation and custom record text in ${brightness.name}',(t)async{
    await t.binding.setSurfaceSize(const Size(320,850));addTearDown(()=>t.binding.setSurfaceSize(null));
    final now=DateTime.now();final date='${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final data=<String,List<RowData>>{'transactions':[
     {'id':1,'date':date,'type':'Income','category':'Salary','amount':800000,'description':'My salary','bill_id':'','note':''},
     {'id':2,'date':date,'type':'Expense','category':'Groceries','amount':15000,'description':'Settings','bill_id':'','note':''},
    ]};
    await t.pumpWidget(PaydayLocal(initialPreferences:AppPreferences(language:code,appearance:brightness==Brightness.dark?ThemeMode.dark:ThemeMode.light),initialData:Future.value(data),preferencesWriter:(_)async{}));
    await t.pumpAndSettle();expect(find.text(translateMessage('Available this month',code)),findsOneWidget);
    expect(find.text('Settings'),findsOneWidget,reason:'A user-entered transaction title must remain verbatim');
    final home=t.element(find.byType(FinanceScreen));expect(Directionality.of(home),code=='ar'?TextDirection.rtl:TextDirection.ltr);
    expect(find.byType(PaydayMark),findsOneWidget);expect(Theme.of(home).scaffoldBackgroundColor,brightness==Brightness.dark?const Color(0xff101D17):paydaySand);
    await t.tap(find.byKey(const ValueKey('home-settings-logo')));await t.pumpAndSettle();
    expect(find.text(translateMessage('Settings',code)),findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('language-setting')));await t.tap(find.byKey(const ValueKey('language-setting')));await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('language-en')),findsOneWidget);expect(find.byKey(const ValueKey('language-fr')),findsOneWidget);expect(find.byKey(const ValueKey('language-ar')),findsOneWidget);
    await t.tap(find.byTooltip(translateMessage('Back to Settings',code)));await t.pumpAndSettle();
    expect(find.text(translateMessage('Settings',code)),findsOneWidget);expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
    expect(t.takeException(),isNull);
   });
  }
 }
 testWidgets('language selection persists, switches direction immediately and never replays opening',(t)async{
  AppPreferences? saved;
  await t.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(value)async{saved=value;}));await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('home-settings-logo')));await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('language-setting')));await t.pumpAndSettle();await t.tap(find.byKey(const ValueKey('language-ar')));await t.pumpAndSettle();
  expect(saved!.language,'ar');expect(t.widget<MaterialApp>(find.byType(MaterialApp)).locale,const Locale('ar'));
  expect(find.text('الإعدادات'),findsOneWidget);expect(find.byType(PaydayOpening),findsOneWidget);expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
  expect(t.takeException(),isNull);
 });
 testWidgets('failed language save retains the active language and keeps selection open',(t)async{
  await t.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(_)async{throw StateError('storage');}));await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('home-settings-logo')));await t.pumpAndSettle();await t.tap(find.byKey(const ValueKey('language-setting')));await t.pumpAndSettle();
  await t.tap(find.byKey(const ValueKey('language-ar')));await t.pumpAndSettle();
  expect(t.widget<MaterialApp>(find.byType(MaterialApp)).locale,const Locale('en'));expect(find.byKey(const ValueKey('language-ar')),findsOneWidget);
  expect(find.text('Could not save preferences. Please try again.'),findsWidgets);expect(t.takeException(),isNull);
 });
 testWidgets('native date picker is localized with Arabic right-to-left direction',(t)async{
  await t.pumpWidget(MaterialApp(locale:const Locale('ar'),supportedLocales:const [Locale('ar')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
   home:Builder(builder:(c)=>Scaffold(body:TextButton(onPressed:()=>showDatePicker(context:c,initialDate:DateTime(2026,10,27),firstDate:DateTime(2020),lastDate:DateTime(2030)),child:const Text('Open'))))));
  await t.pumpAndSettle();await t.tap(find.text('Open'));await t.pumpAndSettle();
  final context=t.element(find.byType(DatePickerDialog));expect(Directionality.of(context),TextDirection.rtl);expect(MaterialLocalizations.of(context).cancelButtonLabel,isNot('Cancel'));expect(t.takeException(),isNull);
 });
}
