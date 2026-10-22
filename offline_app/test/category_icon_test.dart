import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/category_icon.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/finance.dart';
void main(){
 const categories=['Housing','Utilities','Groceries','Transport','Health','Family','Eating out','Shopping','Subscriptions','Leisure','Debt payment','Other','Custom'];
 for(final brightness in Brightness.values){
  testWidgets('category vectors paint and fit Home and Budgets in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final month=monthKey(DateTime.now());
   final fixture=<String,List<RowData>>{
    'categories':[for(final c in categories){'name':c,'group_name':'Essential'}],
    'budgets':[for(final c in categories){'month':month,'category':c,'amount':10000}],
   };
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();
   expect(find.byType(PaydayCategoryIcon),findsNWidgets(categories.length+4));
   for(final c in categories){
    await tester.ensureVisible(find.text(c));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,reason:c);
   }
   await tester.tap(find.text('Budgets').last);await tester.pumpAndSettle();
   expect(find.byType(PaydayCategoryIcon),findsNWidgets(categories.length+2));
   for(final c in categories){
    await tester.ensureVisible(find.text(c));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,reason:c);
   }
  });
 }
}
