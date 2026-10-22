import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/app_lock.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';

class LockStore extends OfflineStore{
 LockStore(Database db):super(database:db);
 bool failSave=false,failLoad=false;
 int snapshots=0;
 @override Future<void> close()async{}
 @override Future<Map<String,List<RowData>>> snapshot()async{snapshots++;return super.snapshot();}
 @override Future<AppPreferences> loadAppPreferences()async{
  if(failLoad)throw StateError('Settings unavailable');
  return super.loadAppPreferences();
 }
 @override Future<void> saveAppPreferences(AppPreferences prefs)async{
  if(failSave)throw StateError('Disk full');
  await super.saveAppPreferences(prefs);
 }
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();sqfliteFfiInit();
 late Database db;late LockStore store;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  for(final table in localTables.where((t)=>t!='settings')){await db.execute('CREATE TABLE $table(id INTEGER,amount INTEGER)');}
  store=LockStore(db);
 });
 tearDown(()async{await db.close();});
 test('invalid security preference fails closed',(){
  expect(()=>AppPreferences.fromRows([{'key':'app_lock_enabled','value':'invalid'}]),throwsFormatException);
 });
 test('backups omit device lock and restore cannot turn local lock on or off',()async{
  await store.saveAppPreferences(const AppPreferences(appLock:true,currency:'EUR'));
  await db.insert('transactions',{'id':1,'amount':12345});
  final exported=jsonDecode(await store.exportJson()) as Map<String,dynamic>;
  final settings=exported['tables']['settings'] as List;
  expect(settings.any((dynamic r)=>r['key']=='app_lock_enabled'),isFalse);
  settings.add({'key':'app_lock_enabled','value':'0'});
  await store.importJson(jsonEncode(exported));
  expect((await store.loadAppPreferences()).appLock,isTrue);
  expect((await store.loadAppPreferences()).currency,'EUR');
  expect(await db.query('transactions'),[{'id':1,'amount':12345}]);
  await db.delete('settings',where:'key=?',whereArgs:['app_lock_enabled']);
  settings.last={'key':'app_lock_enabled','value':'1'};
  await store.importJson(jsonEncode(exported));
  expect((await store.loadAppPreferences()).appLock,isFalse);
 });
 Future<void> openSettings(WidgetTester tester)async{
  await tester.tap(find.byKey(const ValueKey('home-settings-logo')));await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('app-lock-setting')));await tester.pumpAndSettle();
 }
 testWidgets('settings exists only behind Home logo; More and edge swipe do not open it',(tester)async{
  await tester.pumpWidget(PaydayLocal(store:store));await tester.pumpAndSettle();
  await tester.dragFrom(const Offset(1,200),const Offset(280,0));await tester.pumpAndSettle();
  expect(find.text('Theme'),findsNothing);
  await tester.tap(find.text('More'));await tester.pumpAndSettle();
  expect(find.text('Settings'),findsNothing);expect(find.byKey(const ValueKey('home-settings-logo')),findsNothing);
  expect(find.text('Bills & payments'),findsOneWidget);
  await tester.dragFrom(const Offset(1,200),const Offset(280,0));await tester.pumpAndSettle();
  expect(find.text('Theme'),findsNothing);
  await tester.tap(find.text('Home'));await tester.pumpAndSettle();await openSettings(tester);
  expect(find.text('Settings'),findsOneWidget);expect(find.text('App lock'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
 testWidgets('enable and disable require authentication; canceled and failed saves keep policy',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,900));addTearDown(()=>tester.binding.setSurfaceSize(null));
  var allow=false,calls=0;final privacy=<bool>[];
  final lock=AppLockController(authenticate:(_)async{calls++;return allow;},privacyWriter:(value)async{privacy.add(value);});
  await tester.pumpWidget(PaydayLocal(store:store,appLockController:lock));await tester.pumpAndSettle();await openSettings(tester);
  final toggle=find.byKey(const ValueKey('app-lock-setting'));
  await tester.tap(toggle);await tester.pumpAndSettle();
  expect(calls,1);expect(lock.enabled,isFalse);expect((await store.loadAppPreferences()).appLock,isFalse);expect(privacy,isEmpty);
  allow=true;store.failSave=true;
  await tester.tap(toggle);await tester.pumpAndSettle();
  expect(lock.enabled,isFalse);expect((await store.loadAppPreferences()).appLock,isFalse);expect(privacy,[true,false]);
  store.failSave=false;
  await tester.tap(toggle);await tester.pumpAndSettle();
  expect(lock.enabled,isTrue);expect((await store.loadAppPreferences()).appLock,isTrue);
  allow=false;
  await tester.tap(toggle);await tester.pumpAndSettle();
  expect(lock.enabled,isTrue);expect((await store.loadAppPreferences()).appLock,isTrue);
  allow=true;
  await tester.tap(toggle);await tester.pumpAndSettle();
  expect(lock.enabled,isFalse);expect((await store.loadAppPreferences()).appLock,isFalse);expect(privacy.last,isFalse);
  expect(tester.takeException(),isNull);
 });
 for(final brightness in Brightness.values){
  testWidgets('lock hides routes and draft, blocks Back, preserves form after unlock in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
   final draft=TextEditingController(text:'Private draft');addTearDown(draft.dispose);
   final lock=AppLockController(enabled:true,authenticate:(_)async=>true,privacyWriter:(_)async{});
   addTearDown(lock.dispose);
   final routes=AppLockRouteGuard(lock);addTearDown(routes.dispose);
   await tester.pumpWidget(MaterialApp(navigatorObservers:[routes],theme:ThemeData(brightness:brightness),builder:(context,child)=>PaydayLockGate(controller:lock,child:child!),
    home:Builder(builder:(context)=>Scaffold(body:TextButton(onPressed:()=>showDialog<void>(context:context,builder:(_)=>AlertDialog(
     title:const Text('Private form'),content:TextField(controller:draft))),child:const Text('Edit'))))));
   expect(find.text('PAYDAY is locked'),findsOneWidget);expect(find.text('Edit'),findsNothing);
   await tester.tap(find.text('Unlock'));await tester.pumpAndSettle();
   await tester.tap(find.text('Edit'));await tester.pumpAndSettle();
   expect(find.text('Private form'),findsOneWidget);
   final formRoute=ModalRoute.of(tester.element(find.text('Private form')))!;
   lock.didChangeAppLifecycleState(AppLifecycleState.inactive);await tester.pump();
   lock.didChangeAppLifecycleState(AppLifecycleState.paused);await tester.pump();
   expect(find.text('Private form'),findsNothing);expect(find.text('Private draft'),findsNothing);
   expect(formRoute.popDisposition,RoutePopDisposition.doNotPop);
   await tester.binding.handlePopRoute();await tester.pumpAndSettle();
   lock.didChangeAppLifecycleState(AppLifecycleState.resumed);await tester.pumpAndSettle();
   expect(find.text('Private form'),findsNothing);
   await tester.tap(find.text('Unlock'));await tester.pumpAndSettle();
   expect(find.text('Private form'),findsOneWidget);expect(draft.text,'Private draft');
   expect(tester.takeException(),isNull);
  });
 }
 testWidgets('cold launch protects Home; cancel, errors and repeated taps never bypass lock',(tester)async{
  var calls=0;var result=Completer<bool>();
  final lock=AppLockController(enabled:true,authenticate:(_){calls++;return result.future;},privacyWriter:(_)async{});
  await tester.pumpWidget(PaydayLocal(store:store,initialPreferences:const AppPreferences(appLock:true),appLockController:lock));await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('home-settings-logo')),findsNothing);
  await tester.tap(find.text('Unlock'));await tester.pump();
  await lock.unlock();expect(calls,1);
  result.complete(false);await tester.pumpAndSettle();
  expect(lock.locked,isTrue);expect(find.text('Authentication canceled. Please try again.'),findsOneWidget);
  result=Completer<bool>();
  await tester.tap(find.text('Unlock'));await tester.pump();
  // Native device-PIN UI can pause/resume without launching another auth request.
  lock.didChangeAppLifecycleState(AppLifecycleState.inactive);
  lock.didChangeAppLifecycleState(AppLifecycleState.paused);
  lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
  result.complete(true);await tester.pumpAndSettle();
  expect(calls,2);expect(find.byKey(const ValueKey('home-settings-logo')),findsOneWidget);
  lock.didChangeAppLifecycleState(AppLifecycleState.inactive);await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('home-settings-logo')),findsNothing);
  lock.didChangeAppLifecycleState(AppLifecycleState.resumed);await tester.pumpAndSettle();
  result=Completer<bool>();await tester.tap(find.text('Unlock'));await tester.pump();
  result.completeError(const AppLockProblem('Set a screen lock in Android Settings, then try again.'));await tester.pumpAndSettle();
  expect(lock.locked,isTrue);expect(find.textContaining('Set a screen lock'),findsOneWidget);
  expect(tester.takeException(),isNull);
 });
 testWidgets('startup settings failure never opens financial records and supports retry',(tester)async{
  store.failLoad=true;
  await tester.pumpWidget(PaydayStartup(store:store));await tester.pumpAndSettle();
  expect(find.byType(FinanceScreen),findsNothing);expect(store.snapshots,0);
  expect(find.text('Try again'),findsOneWidget);
  store.failLoad=false;await tester.tap(find.text('Try again'));await tester.pumpAndSettle();
  expect(find.byType(FinanceScreen),findsOneWidget);expect(store.snapshots,greaterThan(0));
  expect(tester.takeException(),isNull);
 });
}
