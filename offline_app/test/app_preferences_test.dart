import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/brand.dart';
import 'package:payday_local/offline_store.dart';

class PreferencesStore extends OfflineStore {
 PreferencesStore(Database db):super(database:db);
 bool failSave=false;
 @override Future<void> close()async{}
 @override Future<void> saveAppPreferences(AppPreferences preferences)async{
  if(failSave)throw StateError('Storage unavailable');
  await super.saveAppPreferences(preferences);
 }
}
void main(){
 sqfliteFfiInit();
 late Database db;
 late PreferencesStore store;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  for(final table in localTables.where((t)=>t!='settings')){
   await db.execute('CREATE TABLE $table(id INTEGER,amount INTEGER)');
  }
  store=PreferencesStore(db);
 });
 tearDown(()async{await db.close();});
 test('legacy motion flags are ignored, missing and unknown currency stays MAD',(){
  for(final rows in [<RowData>[],<RowData>[{'key':'app_appearance','value':'unknown'},
   {'key':'currency','value':'unknown'},{'key':'app_opening_animation','value':'0'},
   {'key':'app_reduce_motion','value':'1'}]]){
   final prefs=AppPreferences.fromRows(rows);
   expect(prefs.appearance,ThemeMode.light);expect(prefs.currency,'MAD');
   expect(prefs.values.keys,unorderedEquals(['app_appearance','currency','app_lock_enabled','app_language']));
  }
 });
 test('preferences persist atomically and currency travels in backup without changing amounts',()async{
  await db.insert('transactions',{'id':1,'amount':12345});
  await db.insert('settings',{'key':'app_opening_animation','value':'0'});
  const saved=AppPreferences(appearance:ThemeMode.dark,currency:'EUR');
  await store.saveAppPreferences(saved);
  expect((await store.loadAppPreferences()).values,saved.values);
  expect(await db.query('settings',where:'key=?',whereArgs:['app_opening_animation']),isEmpty);
  await db.execute("CREATE TRIGGER reject_preference BEFORE INSERT ON settings WHEN NEW.key='currency' BEGIN SELECT RAISE(ABORT,'test failure'); END");
  await expectLater(store.saveAppPreferences(const AppPreferences()),throwsA(isA<DatabaseException>()));
  expect((await store.loadAppPreferences()).values,saved.values);
  await db.execute('DROP TRIGGER reject_preference');
  final backup=await store.exportJson();
  await store.saveAppPreferences(const AppPreferences(currency:'GBP'));
  await store.importJson(backup);
  expect((await store.loadAppPreferences()).currency,'EUR');
  expect(await db.query('transactions'),[{'id':1,'amount':12345}]);
  final legacy=jsonDecode(backup) as Map<String,dynamic>;
  (legacy['tables']['settings'] as List).removeWhere((dynamic r)=>r['key']=='currency');
  await store.importJson(jsonEncode(legacy));
  expect((await store.loadAppPreferences()).currency,'MAD');
 });
 test('money settings save atomically and reject invalid values',()async{
  await store.saveMoneySettings(buffer:20000,openingSavings:10000);
  await db.execute("CREATE TRIGGER reject_opening BEFORE INSERT ON settings WHEN NEW.key='opening_savings' BEGIN SELECT RAISE(ABORT,'test failure'); END");
  await expectLater(store.saveMoneySettings(buffer:30000,openingSavings:40000),throwsA(isA<DatabaseException>()));
  final values={for(final r in await db.query('settings'))r['key']:r['value']};
  expect(values['buffer'],'20000');expect(values['opening_savings'],'10000');
  await expectLater(store.saveMoneySettings(buffer:-1,openingSavings:0),throwsArgumentError);
 });
 test('all supported currencies retain exact minor unit formatting',(){
  for(final code in paydayCurrencies.keys){
   expect(formatMoney(12345,code),'123.45 $code');
   expect(formatMoney(-12345,code),'-123.45 $code');
  }
 });
 Future<void> openSettings(WidgetTester tester)async{
  await tester.tap(find.byKey(const ValueKey('home-settings-button')));await tester.pumpAndSettle();
 }
 Future<void> chooseTheme(WidgetTester tester,String name)async{
  await tester.tap(find.text('Theme'));await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);await tester.pumpAndSettle();
 }
 Future<void> chooseCurrency(WidgetTester tester,String code)async{
  await tester.ensureVisible(find.byKey(const ValueKey('currency-setting')));await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('currency-setting')));await tester.pumpAndSettle();
  await tester.tap(find.text(code).last);await tester.pumpAndSettle();
 }
 testWidgets('settings button opens a full Settings page, theme persists, no motion toggles and Back closes it',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));
  addTearDown(()=>tester.binding.setSurfaceSize(null));
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(PaydayLocal(store:store));await tester.pumpAndSettle();
  expect(find.byIcon(Icons.menu),findsNothing);
  // Home's top bar carries the brand, as on the design canvas.
  expect(find.byType(PaydayBrand),findsOneWidget);
  await openSettings(tester);
  // Settings is a full page now, not a side drawer.
  expect(find.byType(Drawer),findsNothing);expect(find.text('Settings'),findsOneWidget);
  expect(find.text('General'),findsOneWidget);expect(find.text('Privacy & security'),findsOneWidget);
  expect(find.text('Opening animation'),findsNothing);expect(find.text('Reduce motion'),findsNothing);
  expect(find.text('App lock'),findsOneWidget);
  await chooseTheme(tester,'Dark');
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.dark);
  expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
  await chooseTheme(tester,'System');
  tester.platformDispatcher.platformBrightnessTestValue=Brightness.dark;await tester.pumpAndSettle();
  expect(Theme.of(tester.element(find.byType(FinanceScreen,skipOffstage:false))).brightness,Brightness.dark);
  tester.platformDispatcher.platformBrightnessTestValue=Brightness.light;await tester.pumpAndSettle();
  expect(Theme.of(tester.element(find.byType(FinanceScreen,skipOffstage:false))).brightness,Brightness.light);
  await tester.ensureVisible(find.text('Backups & data'));await tester.pumpAndSettle();
  await tester.tap(find.text('Backups & data'));await tester.pumpAndSettle();
  expect(find.text('Export backup'),findsOneWidget);expect(find.text('Restore'),findsOneWidget);
  await tester.tap(find.byTooltip('Back to Settings'));await tester.pumpAndSettle();
  expect(find.text('Theme'),findsOneWidget);
  await tester.binding.handlePopRoute();await tester.pumpAndSettle();
  expect(find.text('Theme'),findsNothing);
  await openSettings(tester);await tester.tap(find.byTooltip('Close settings'));await tester.pumpAndSettle();
  expect(find.text('Theme'),findsNothing);
  expect(tester.takeException(),isNull);
 });
 testWidgets('currency confirmation, cancel, persistence, forms and cold launch ignore old flags',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));addTearDown(()=>tester.binding.setSurfaceSize(null));
  await db.insert('settings',{'key':'app_opening_animation','value':'0'});
  await db.insert('settings',{'key':'app_reduce_motion','value':'1'});
  await tester.pumpWidget(PaydayLocal(store:store,initialPreferences:await store.loadAppPreferences()));
  expect(find.byKey(const ValueKey('payday-opening-overlay')),findsOneWidget);
  await tester.pumpAndSettle();
  expect(MediaQuery.disableAnimationsOf(tester.element(find.byType(FinanceScreen,skipOffstage:false))),isFalse);
  await openSettings(tester);
  await chooseCurrency(tester,'EUR');
  expect(find.textContaining('100,00 DH becomes 100,00 EUR'),findsOneWidget);
  await tester.tap(find.text('Cancel'));await tester.pumpAndSettle();
  expect((await store.loadAppPreferences()).currency,'MAD');
  await tester.tap(find.byTooltip('Back to Settings'));await tester.pumpAndSettle();
  for(final code in ['EUR','GBP','USD']){
   await chooseCurrency(tester,code);
   await tester.tap(find.widgetWithText(FilledButton,'Use $code'));await tester.pumpAndSettle();
   expect((await store.loadAppPreferences()).currency,code);
   expect(find.text('${paydayCurrencies[code]} · $code'),findsOneWidget);
  }
  final saved=await store.loadAppPreferences();
  await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
  await tester.pumpWidget(PaydayLocal(store:store,initialPreferences:saved));await tester.pumpAndSettle();
  expect(find.textContaining(' USD'),findsWidgets);
  final semantics=tester.ensureSemantics();
  await tester.tap(find.bySemanticsLabel('Add transaction'));await tester.pumpAndSettle();
  expect(find.text('Amount (USD)'),findsOneWidget);
  semantics.dispose();
  expect(tester.takeException(),isNull);
 });
 testWidgets('failed saves keep both active and stored theme and currency',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));addTearDown(()=>tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(PaydayLocal(store:store));await tester.pumpAndSettle();
  await openSettings(tester);store.failSave=true;
  await chooseTheme(tester,'Dark');
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.light);
  expect((await store.loadAppPreferences()).appearance,ThemeMode.light);
  await tester.tap(find.byTooltip('Back to Settings'));await tester.pumpAndSettle();
  await chooseCurrency(tester,'EUR');
  await tester.tap(find.widgetWithText(FilledButton,'Use EUR'));await tester.pumpAndSettle();
  expect((await store.loadAppPreferences()).currency,'MAD');
  expect(find.text('Currency'),findsOneWidget);
  await tester.tap(find.byTooltip('Back to Settings'));await tester.pumpAndSettle();
  expect(find.text('Moroccan dirham · MAD'),findsOneWidget);
  expect(find.text('Could not save preferences. Please try again.'),findsWidgets);
  expect(tester.takeException(),isNull);
 });
}


