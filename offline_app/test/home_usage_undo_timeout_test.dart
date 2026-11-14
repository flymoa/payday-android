import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/month_usage_bar.dart';

MonthlyBalance balance({int income=0,int expenses=0,int savings=0,int reserves=0})=>
 MonthlyBalance(income:income,expenses:expenses,savingsNet:savings,reserveNet:reserves,
  unpaidBills:0,savingsGap:0,reserveHold:0,buffer:0);

class TimeoutStore extends OfflineStore {
 RowData? record={'id':1,'date':dayKey(DateTime.now()),'type':'Expense',
  'category':'Groceries','description':'Market','amount':10000,'note':'','bill_id':''};
 @override Future<Map<String,List<RowData>>> snapshot()async=>{
  'transactions':[if(record!=null)record!],
  'categories':[{'name':'Groceries','group_name':'Essential'}],
 };
 @override Future<RowData?> deleteTransactionForUndo(int id)async{
  final old=record;record=null;return old;
 }
 @override Future<void> restoreDeletedTransaction(RowData row)async{record=row;}
 @override Future<void> close()async{}
}

void main(){
 test('usage starts empty, grows with spending, and caps at fully used',(){
  expect(balance().usedFraction,0);
  expect(balance(income:100000).usedFraction,0);
  expect(balance(income:100000,expenses:25000).usedFraction,.25);
  expect(balance(income:100000,expenses:75000).usedFraction,.75);
  expect(balance(income:100000,expenses:120000).usedFraction,1);
  expect(balance(expenses:100).usedFraction,1);
  expect(balance(income:100000,expenses:0).usedFraction,0);
 });
 test('progress reconciles with available cash including savings and reserves',(){
  for(final b in [balance(income:100000,expenses:20000,savings:10000,reserves:5000),
    balance(income:100000,expenses:20000,savings:-10000,reserves:-5000)]){
   expect(b.fundsReceived-b.fundsUsed,b.available);
   expect(b.usedFraction,b.fundsUsed/b.fundsReceived);
  }
 });
 testWidgets('Home usage reflects selected month and resets without its transactions',(tester)async{
  final now=DateTime.now();
  final previous=DateTime(now.year,now.month-1,1);
  final old={'id':1,'date':dayKey(previous),'type':'Expense','category':'Groceries','amount':90000};
  final income={'id':2,'date':dayKey(now),'type':'Income','category':'Salary','amount':100000};
  final expense={'id':3,'date':dayKey(now),'type':'Expense','category':'Groceries','amount':25000};
  for(final example in [(<RowData>[old],0.0),(<RowData>[old,income],0.0),(<RowData>[old,income,expense],.25)]){
   await tester.pumpWidget(MaterialApp(home:FinanceScreen(key:UniqueKey(),
    initialData:Future.value({'transactions':example.$1}))));
   await tester.pumpAndSettle();
   expect(tester.widget<MonthUsageBar>(find.byType(MonthUsageBar)).value,example.$2);
   expect(tester.takeException(),isNull);
  }
 });
 for(final brightness in Brightness.values){
  testWidgets('Undo disappears automatically after five seconds in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(430,1000));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final store=TimeoutStore();
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    home:FinanceScreen(store:store,initialData:store.snapshot())));
   await tester.pumpAndSettle();
   await tester.tap(find.text('Records').last);await tester.pumpAndSettle();
   await tester.tap(find.text('Market'));await tester.pumpAndSettle();
   await tester.ensureVisible(find.text('Delete transaction'));
   await tester.tap(find.text('Delete transaction'));await tester.pumpAndSettle();
   await tester.tap(find.text('Delete').last);
   for(var i=0;i<20&&find.text('Undo').evaluate().isEmpty;i++){
    await tester.pump(const Duration(milliseconds:50));
   }
   await tester.pumpAndSettle();
   expect(find.text('Undo'),findsOneWidget);
   final snackbar=tester.widget<SnackBar>(find.byType(SnackBar));
   expect(snackbar.persist,isFalse);expect(snackbar.duration,const Duration(seconds:5));
   await tester.pump(const Duration(seconds:4));
   expect(find.text('Undo'),findsOneWidget);
   await tester.pump(const Duration(milliseconds:1200));
   await tester.pump(const Duration(milliseconds:300));
   expect(find.text('Undo'),findsNothing);
   expect(store.record,isNull);
   expect(tester.takeException(),isNull);
  });
 }
}
