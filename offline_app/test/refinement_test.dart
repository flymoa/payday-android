import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:flutter/material.dart';
import 'package:payday_local/brand.dart';
import 'package:payday_local/main.dart';

void main(){
 test('money input preserves exact centimes and rejects silent rounding',(){
  expect(parseMoneyCents('7169,25'),716925);
  expect(parseMoneyCents('0.01'),1);
  expect(parseMoneyCents('0'),isNull);
  expect(parseMoneyCents('0',allowZero:true),0);
  for(final bad in ['0.001','12.345','NaN','Infinity','-10','1,200.00','1000000000.01']){
   expect(parseMoneyCents(bad),isNull,reason:bad);
  }
 });
 test('record search combines text with type without hiding notes or bill IDs',(){
  final row=<String,Object?>{'type':'Expense','description':'Market','category':'Groceries','note':'Weekly shop','bill_id':'ABC-12'};
  expect(matchesRecord(row,' weekly ','Expense'),isTrue);
  expect(matchesRecord(row,'abc-12','All'),isTrue);
  expect(matchesRecord(row,'Market','Income'),isFalse);
  expect(matchesRecord(row,'rent','All'),isFalse);
 });
 for(final brightness in Brightness.values){
  testWidgets('approved brand renders on a narrow ${brightness.name} screen',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,640));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    home:Scaffold(appBar:AppBar(title:const PaydayBrand(),actions:[IconButton(onPressed:(){},icon:const Icon(Icons.dark_mode))]))));
   await tester.pumpAndSettle();
   expect(tester.takeException(),isNull);
   expect(find.byType(PaydayMark),findsOneWidget);
  });
 }
 for(final brightness in Brightness.values){
  testWidgets('all main tabs fit a narrow ${brightness.name} phone',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final month=monthKey(DateTime.now());
   final fixture=<String,List<RowData>>{
    'categories':[{'name':'Groceries','group_name':'Essential'}],
    'transactions':[{'id':1,'type':'Income','category':'Salary','date':'$month-01','amount':700000},
     {'id':2,'type':'Expense','category':'Groceries','description':'Market','date':'$month-02','amount':20000}],
    'budgets':[{'month':month,'category':'Groceries','amount':60000}],
   };
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();
   expect(tester.takeException(),isNull);
   for(final label in ['Records','Budgets','Savings','Home']){
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,reason:label);
   }
  });
 }

}

