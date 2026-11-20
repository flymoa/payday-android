import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
Map<String,Object?> row(String m,String c,int n)=>{'month':m,'category':c,'amount':n};
class CopyStore extends OfflineStore{
 CopyStore(Database db):super(database:db);
 @override Future<void> close()async{}
 @override Future<Map<String,List<RowData>>> snapshot()async=>{'budgets':await table('budgets')};
}
void main(){
 sqfliteFfiInit();
 late Database db;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  await db.execute('CREATE TABLE budgets(month TEXT NOT NULL,category TEXT NOT NULL,amount INTEGER NOT NULL,PRIMARY KEY(month,category))');
 });
 tearDown(()async{if(db.isOpen)await db.close();});
 test('January uses December of prior year and preserves explicit zero',(){
  final p=BudgetCopyPlan([row('2026-12','Income plan',10000),row('2026-12','Food',5000),
   row('2027-01','Food',0),row('2025-12','Other',90000)],'2027-01');
  expect(p.sourceMonth,'2026-12');expect(p.additions.length,1);
  expect(p.income,10000);expect(p.assigned,0);expect(p.allowed,isTrue);
 });
 test('existing income caps the merged plan including savings',(){
  final p=BudgetCopyPlan([row('2026-09','Income plan',10000),row('2026-09','Savings goal',5000),
   row('2026-10','Income plan',6000),row('2026-10','Food',2000)],'2026-10');
  expect(p.income,6000);expect(p.assigned,7000);expect(p.allowed,isFalse);expect(p.exceededBy,1000);
  expect(p.additions.single['category'],'Savings goal');
 });
 test('empty source produces no changes',(){expect(BudgetCopyPlan([],'2026-10').additions,isEmpty);});
 test('copy is atomic, preserves target and is repeatable without duplication',()async{
  for(final r in [row('2026-09','Income plan',10000),row('2026-09','Food',5000),row('2026-09','Savings goal',1000),row('2026-10','Food',2000)]){await db.insert('budgets',r);}
  final store=OfflineStore(database:db);
  final before=await db.query('budgets');
  await store.copyBudget('2026-10',expectedState:budgetCopyState(before,'2026-10'));
  final after=await db.query('budgets');
  expect(after.where((r)=>r['month']=='2026-10').length,3);
  expect(after.firstWhere((r)=>r['month']=='2026-10'&&r['category']=='Food')['amount'],2000);
  expect(after.where((r)=>r['month']=='2026-09').toList(),before.where((r)=>r['month']=='2026-09').toList());
  await store.copyBudget('2026-10',expectedState:budgetCopyState(after,'2026-10'));
  expect((await db.query('budgets')).length,after.length);
 });
 test('over cap or changed preview writes nothing',()async{
  for(final r in [row('2026-09','Food',5000),row('2026-10','Income plan',1000)]){await db.insert('budgets',r);}
  final store=OfflineStore(database:db);final before=await db.query('budgets');
  final state=budgetCopyState(before,'2026-10');
  await db.insert('settings',{'key':'currency','value':'EUR'});
  await expectLater(store.copyBudget('2026-10',expectedState:state),throwsA(isA<StateError>().having((e)=>e.message,'currency-aware overage',contains('40.00 EUR'))));
  expect(await db.query('budgets'),before);
  await db.update('budgets',{'amount':10000},where:'category=?',whereArgs:['Income plan']);
  await expectLater(store.copyBudget('2026-10',expectedState:state),throwsStateError);
  expect((await db.query('budgets')).length,2);
 });
 for(final brightness in Brightness.values){
  testWidgets('copy preview saves on a narrow ${brightness.name} phone',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final m=monthKey(DateTime.now());final date=monthFromKey(m);
   final prev=monthKey(DateTime(date.year,date.month-1));
   for(final r in [row(prev,'Income plan',10000),row(prev,'Savings goal',2000)]){await db.insert('budgets',r);}
   final store=CopyStore(db);
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:store,initialData:store.snapshot())));
   await tester.pumpAndSettle();await tester.tap(find.text('Budgets').last);await tester.pumpAndSettle();
   await tester.ensureVisible(find.text('Copy last month’s budget'));await tester.pumpAndSettle();
   await tester.tap(find.text('Copy last month’s budget'));await tester.pumpAndSettle();
   expect(find.text('Assigned after copy: 20,00 DH'),findsOneWidget);
   expect((await db.query('budgets')).length,2);
   await tester.tap(find.text('Copy budget'));
   for(var i=0;i<40;i++){await tester.pump(const Duration(milliseconds:50));}
   expect((await db.query('budgets')).where((r)=>r['month']==m).length,2);
   expect(find.text('Copy budget'),findsNothing);
   expect(tester.takeException(),isNull);
  });
 }
}
