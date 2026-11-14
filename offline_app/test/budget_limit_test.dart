import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/main.dart';

Map<String,Object?> row(String month,String category,int amount)=>
 {'month':month,'category':category,'amount':amount};

class _BudgetStore extends OfflineStore {
 _BudgetStore(Database db):super(database:db);
 @override Future<void> close()async{} // The test fixture owns this database.
 @override Future<Map<String,List<RowData>>> snapshot()async=>{
  'budgets':await table('budgets'),
  'categories':[
   {'name':'Groceries','group_name':'Essential'},
   {'name':'Transport','group_name':'Essential'},
  ],
 };
}

void main(){
 const month='2026-10';
 final base=[row(month,'Income plan',100000),row(month,'Transport',70000)];
 BudgetAssignmentCheck check(List<Map<String,Object?>> rows,String category,int n)=>
  checkBudgetAssignment(rows:rows,month:month,category:category,proposed:n);
 test('300 MAD available rejects 400 with exact maximum and overage',(){
  final c=check(base,'Groceries',40000);
  expect(c.allowed,isFalse);expect(c.maximum,30000);expect(c.exceededBy,10000);
  expect(c.message,contains('300.00 MAD'));expect(c.message,contains('100.00 MAD'));
 });
 test('assigning exactly the remainder reaches the income cap',(){
  final c=check(base,'Groceries',30000);
  expect(c.allowed,isTrue);expect(c.fullyAssigned,isTrue);expect(c.remaining,0);
 });
 test('fully assigned month blocks new spending and savings budgets',(){
  final rows=[...base,row(month,'Groceries',30000)];
  for(final category in ['Shopping','Savings goal']){
   final c=check(rows,category,1);
   expect(c.allowed,isFalse);expect(c.maximum,0);expect(c.message,contains('No more money to assign'));
  }
 });
 test('editing credits the current category amount and allows reductions',(){
  final rows=[...base,row(month,'Groceries',20000)];
  expect(check(rows,'Groceries',30000).allowed,isTrue);
  expect(check(rows,'Groceries',30000).maximum,30000);
  expect(check(rows,'Groceries',31000).exceededBy,1000);
  expect(check(rows,'Groceries',10000).remaining,20000);
 });
 test('savings goal and stored categories share the same pool',(){
  final rows=[...base,row(month,'Savings goal',10000),row(month,'Custom category',5000)];
  expect(check(rows,'Groceries',15000).fullyAssigned,isTrue);
  expect(check(rows,'Groceries',15001).allowed,isFalse);
  expect(assignedBudgetCents(rows,month),85000);
 });
 test('other months and years never consume this month income',(){
  final rows=[...base,row('2026-09','Groceries',900000),row('2027-10','Savings goal',900000)];
  expect(check(rows,'Groceries',30000).allowed,isTrue);
 });
 test('income reductions cannot underfund assigned budgets; zero plan blocks assignments',(){
  final c=check(base,'Income plan',60000);
  expect(c.allowed,isFalse);expect(c.message,contains('700.00 MAD'));expect(c.exceededBy,10000);
  expect(check([],'Groceries',1).allowed,isFalse);
  expect(check([],'Groceries',0).allowed,isTrue);
 });
 test('existing over-assignment is surfaced rather than silently saved',(){
  final rows=[row(month,'Income plan',10000),row(month,'Transport',20000)];
  final c=check(rows,'Groceries',0);
  expect(c.allowed,isFalse);expect(c.message,contains('Other budgets already exceed'));
  expect(check(rows,'Transport',10000).allowed,isTrue);
 });

 sqfliteFfiInit();
 late Database db;
 late OfflineStore store;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE budgets(month TEXT NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL, PRIMARY KEY(month,category))');
  store=OfflineStore(database:db);
 });
 tearDown(()async{if(db.isOpen)await db.close();});
 test('SQLite rejects invalid saves without altering existing rows',()async{
  await store.setBudget(month,'Income plan',100000);
  await store.setBudget(month,'Transport',70000);
  await expectLater(store.setBudget(month,'Groceries',40000),throwsA(isA<BudgetAssignmentException>()));
  expect(await db.query('budgets',where:'category=?',whereArgs:['Groceries']),isEmpty);
  await store.setBudget(month,'Groceries',30000);
  await expectLater(store.setBudget(month,'Income plan',90000),throwsA(isA<BudgetAssignmentException>()));
  expect((await db.query('budgets',where:'category=?',whereArgs:['Income plan'])).single['amount'],100000);
 });
 test('two concurrent saves cannot overspend the same remainder',()async{
  await store.setBudget(month,'Income plan',100000);
  await store.setBudget(month,'Transport',70000);
  final results=await Future.wait([
   store.setBudget(month,'Groceries',20000).then((_)=>true,onError:(Object e)=>false),
   store.setBudget(month,'Savings goal',20000).then((_)=>true,onError:(Object e)=>false),
  ]);
  expect(results.where((ok)=>ok).length,1);
  expect(assignedBudgetCents(await db.query('budgets'),month),90000);
 });
 testWidgets('save popup shows maximum and overage, keeps input, then confirms full assignment',(tester)async{
  await tester.binding.setSurfaceSize(const Size(320,800));
  addTearDown(()=>tester.binding.setSurfaceSize(null));
  final selected=monthKey(DateTime.now());
  await store.setBudget(selected,'Income plan',100000);
  await store.setBudget(selected,'Transport',70000);
  await tester.pumpWidget(MaterialApp(home:FinanceScreen(store:_BudgetStore(db))));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Budgets').last);await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Groceries'));await tester.pumpAndSettle();
  await tester.tap(find.text('Groceries'));await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField),'400');
  await tester.tap(find.text('Save budget'));await tester.pumpAndSettle();
  expect(find.text('Budget limit reached'),findsOneWidget);
  expect(find.textContaining('You exceeded this limit by 100.00 MAD.'),findsOneWidget);
  expect(await db.query('budgets',where:'category=?',whereArgs:['Groceries']),isEmpty);
  await tester.tap(find.text('OK'));await tester.pumpAndSettle();
  expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,'400');
  await tester.enterText(find.byType(TextField),'300');
  await tester.tap(find.text('Save budget'));await tester.pumpAndSettle();
  for(var attempt=0;attempt<40&&find.text('No more money to assign').evaluate().isEmpty;attempt++){
   await tester.pump(const Duration(milliseconds:50));
  }
  expect(find.text('No more money to assign'),findsOneWidget,
   reason:tester.widgetList<Text>(find.byType(Text)).map((t)=>t.data??'').join(' | '));
  expect((await db.query('budgets',where:'category=?',whereArgs:['Groceries'])).single['amount'],30000);
  await tester.tap(find.text('OK'));await tester.pumpAndSettle();
  expect(find.byType(TextField),findsNothing);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
 });
}
