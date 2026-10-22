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
 @override Future<Map<String,List<RowData>>> snapshot()async=>{'settings':await table('settings')};
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
  store=PreferencesStore(db);
 });
 tearDown(()async{await db.close();});
 test('fresh and unrecognized settings keep light mode and the opening enabled',(){
  for(final rows in [<RowData>[],<RowData>[{'key':'app_appearance','value':'unknown'}]]){
   final prefs=AppPreferences.fromRows(rows);
   expect(prefs.appearance,ThemeMode.light);expect(prefs.openingAnimation,isTrue);
   expect(prefs.reduceMotion,isFalse);
  }
 });
 test('preferences reload from SQLite and writes roll back together',()async{
  const saved=AppPreferences(appearance:ThemeMode.dark,openingAnimation:false,reduceMotion:true);
  await store.saveAppPreferences(saved);
  final reloaded=await store.loadAppPreferences();
  expect(reloaded.values,saved.values);
  await db.execute("CREATE TRIGGER reject_preference BEFORE INSERT ON settings WHEN NEW.key='app_reduce_motion' BEGIN SELECT RAISE(ABORT,'test failure'); END");
  await expectLater(store.saveAppPreferences(const AppPreferences()),throwsA(isA<DatabaseException>()));
  expect((await store.loadAppPreferences()).values,saved.values);
 });

 Future<void> openSettings(WidgetTester tester)async{
  await tester.tap(find.text('More'));await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Settings'));await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));await tester.pumpAndSettle();
 }
 Future<void> chooseTheme(WidgetTester tester,String name)async{
  await tester.tap(find.text('Theme'));await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);await tester.pumpAndSettle();
 }
 testWidgets('settings persist across restart, system theme follows device, intro does not replay',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));
  addTearDown(()=>tester.binding.setSurfaceSize(null));
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(PaydayLocal(store:store,initialPreferences:await store.loadAppPreferences()));
  await tester.pumpAndSettle();
  final slogan=tester.widget<Text>(find.text(paydaySlogan));
  expect(slogan.maxLines,1);expect(slogan.softWrap,isFalse);
  expect(slogan.style!.fontWeight,FontWeight.w700);expect(slogan.style!.fontSize,14);
  await openSettings(tester);
  await chooseTheme(tester,'Dark');
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.dark);
  expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
  await chooseTheme(tester,'System');
  tester.platformDispatcher.platformBrightnessTestValue=Brightness.dark;
  await tester.pumpAndSettle();
  expect(Theme.of(tester.element(find.byType(FinanceScreen))).brightness,Brightness.dark);
  tester.platformDispatcher.platformBrightnessTestValue=Brightness.light;
  await tester.pumpAndSettle();
  expect(Theme.of(tester.element(find.byType(FinanceScreen))).brightness,Brightness.light);
  await tester.tap(find.byKey(const ValueKey('opening-animation-setting')));await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('reduce-motion-setting')));
  await tester.tap(find.byKey(const ValueKey('reduce-motion-setting')));await tester.pumpAndSettle();
  final saved=await store.loadAppPreferences();
  expect(saved.appearance,ThemeMode.system);expect(saved.openingAnimation,isFalse);expect(saved.reduceMotion,isTrue);
  expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
  await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
  await tester.pumpWidget(PaydayLocal(store:store,initialPreferences:saved));
  expect(find.byKey(const ValueKey('payday-opening-overlay')),findsNothing);
  await tester.pumpAndSettle();
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.system);
  expect(MediaQuery.disableAnimationsOf(tester.element(find.byType(FinanceScreen))),isTrue);
  await openSettings(tester);
  await tester.ensureVisible(find.text('Backups & data'));await tester.pumpAndSettle();
  await tester.tap(find.text('Backups & data'));await tester.pumpAndSettle();
  expect(find.text('Export backup'),findsOneWidget);expect(find.text('Restore'),findsOneWidget);
  expect(find.text('Back to Settings'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
 testWidgets('failed preference save keeps the active and saved appearance unchanged',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));
  addTearDown(()=>tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(PaydayLocal(store:store));await tester.pumpAndSettle();
  await openSettings(tester);store.failSave=true;
  await chooseTheme(tester,'Dark');
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.light);
  expect((await store.loadAppPreferences()).appearance,ThemeMode.light);
  expect(find.text('Could not save preferences. Please try again.'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
}
