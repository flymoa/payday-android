import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/transaction_categories.dart';

class CategoryTestStore extends OfflineStore {
 CategoryTestStore(Database db):super(database:db);
 @override Future<Map<String,List<Map<String,Object?>>>> snapshot()async=>{
  for(final name in ['categories','budgets','settings','transactions'])name:await table(name),
 };
 @override Future<void> close()async{}
}

void main(){
 sqfliteFfiInit();
 late Database db;
 late CategoryTestStore store;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE categories(name TEXT PRIMARY KEY,group_name TEXT NOT NULL)');
  await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  await db.execute('CREATE TABLE budgets(month TEXT,category TEXT,amount INTEGER,PRIMARY KEY(month,category))');
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY,type TEXT,category TEXT,date TEXT,amount INTEGER)');
  await db.insert('categories',{'name':'Groceries','group_name':'Essential'});
  store=CategoryTestStore(db);
 });
 tearDown(()async{await db.close();});
 test('deletion frees only selected month and preserves records and other plans',()async{
  for(final month in ['2026-09','2026-10','2026-11']){
   await db.insert('budgets',{'month':month,'category':'Groceries','amount':30000});
  }
  await db.insert('transactions',{'id':1,'type':'Expense','category':'Groceries','date':'2026-10-01','amount':5000});
  await store.deleteCategory('Groceries',month:'2026-10');
  expect(await store.table('categories'),isEmpty);
  expect((await store.table('budgets')).map((r)=>r['month']),['2026-09','2026-11']);
  expect((await store.table('transactions')).single['category'],'Groceries');
  final hidden=await OfflineStore.hiddenCategoryNames(db);
  expect(transactionCategories(type:'Expense',configured:[],history:await store.table('transactions'),hidden:hidden),isNot(contains('Groceries')));
  expect(transactionCategories(type:'Expense',configured:[],history:[],hidden:hidden,existingCategory:'Groceries'),contains('Groceries'));
  await store.addCategory('Groceries','Essential');
  expect(await OfflineStore.hiddenCategoryNames(db),isEmpty);
 });
 test('income names can be added, deleted and restored without resurrecting defaults',()async{
  await store.addCategory('Consulting','Income');
  await expectLater(store.addCategory(' consulting ','Income'),throwsStateError);
  await store.deleteCategory('Salary',month:'2026-10');
  final hidden=await OfflineStore.hiddenCategoryNames(db);
  final income=transactionCategories(type:'Income',configured:['Groceries'],incomeConfigured:['Consulting'],history:[{'type':'Income','category':'Salary'}],hidden:hidden);
  expect(income,contains('Consulting'));expect(income,isNot(contains('Salary')));
  expect(transactionCategories(type:'Expense',configured:['Groceries'],incomeConfigured:['Consulting'],history:[]),isNot(contains('Consulting')));
  await store.addCategory('Salary','Income');
  expect(await OfflineStore.hiddenCategoryNames(db),isEmpty);
  await expectLater(store.deleteCategory('Income plan',month:'2026-10'),throwsArgumentError);
 });
 testWidgets('budget category offers confirmed deletion and income plan offers category management',(tester)async{
  await tester.binding.setSurfaceSize(const Size(430,1100));
  addTearDown(()=>tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home:FinanceScreen(store:store)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Budgets').last);await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Groceries'));await tester.tap(find.text('Groceries'));await tester.pumpAndSettle();
  await tester.tap(find.text('Delete category'));await tester.pumpAndSettle();
  await tester.tap(find.text('Cancel'));await tester.pumpAndSettle();
  expect(await store.table('categories'),hasLength(1));
  await tester.tap(find.text('Delete category'));await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton,'Delete category'));await tester.pumpAndSettle();
  expect(await store.table('categories'),isEmpty);
  await tester.tap(find.text('Income plan'));await tester.pumpAndSettle();
  await tester.tap(find.text('Manage income categories'));await tester.pumpAndSettle();
  expect(find.text('Income categories'),findsOneWidget);
  await tester.tap(find.text('Add income category'));await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField,'Name'),'Consulting');
  await tester.tap(find.widgetWithText(FilledButton,'Add category').last);await tester.pumpAndSettle();
  expect(find.text('Consulting'),findsOneWidget);
  await tester.ensureVisible(find.byTooltip('Delete Consulting'));await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Delete Consulting'));await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton,'Delete category'));await tester.pumpAndSettle();
  expect(find.text('Consulting'),findsNothing);
  final rows=await store.table('settings');
  expect(jsonDecode(rows.single['value'] as String),contains('consulting'));
  expect(tester.takeException(),isNull);
 });
}
