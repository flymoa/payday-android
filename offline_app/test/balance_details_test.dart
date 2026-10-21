import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';

void main(){
 for(final brightness in Brightness.values){
  testWidgets('both balance explanations work on a narrow ${brightness.name} phone',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final month=monthKey(DateTime.now());
   final fixture=<String,List<RowData>>{
    'transactions':[
     {'type':'Income','date':'$month-01','amount':100000},
     {'type':'Expense','date':'$month-02','amount':20000},
     {'type':'Income','date':'2020-01-01','amount':999999},
    ],
   };
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();
   await tester.tap(find.text('Available this month'));
   await tester.pumpAndSettle();
   expect(find.text('Income received'),findsOneWidget);
   expect(find.text('+ 1000.00 MAD'),findsOneWidget);
   expect(find.text('800.00 MAD'),findsOneWidget);
   expect(tester.takeException(),isNull);
   await tester.ensureVisible(find.text('Got it'));
   await tester.tap(find.text('Got it'));
   await tester.pumpAndSettle();
   await tester.tap(find.text('Safe to spend · Tap for details'));
   await tester.pumpAndSettle();
   expect(find.text('Cash buffer'),findsOneWidget);
   expect(find.text('600.00 MAD'),findsOneWidget);
   expect(find.textContaining('Category budgets are spending limits'),findsOneWidget);
   expect(tester.takeException(),isNull);
  });
 }
}
