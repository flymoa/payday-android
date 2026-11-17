import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';
void main(){
 test('ranked expenses exclude income and savings with stable ties',(){
  final review=MonthlyReview([
   {'type':'Expense','category':'Food','amount':1000},
   {'type':'Expense','category':'Food','amount':2000},
   {'type':'Expense','category':'Housing','amount':3000},
   {'type':'Savings out','category':'Savings','amount':90000},
   {'type':'Income','category':'Salary','amount':90000},
  ]);
  expect(review.spending,{'Food':3000,'Housing':3000});
  expect(review.rankedCategories,['Food','Housing']);
 });
 for(final brightness in Brightness.values){
  testWidgets('monthly review filters month and flags issues in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final now=DateTime.now();final m=monthKey(now);
   final fixture=<String,List<RowData>>{
    'transactions':[
     {'type':'Income','category':'Salary','date':'$m-01','amount':100000},
     {'type':'Expense','category':'Food','date':'$m-02','amount':20000},
     {'type':'Expense','category':'Other','date':'$m-02','amount':1000},
     {'type':'Expense','category':'Old expense','date':'2020-01-01','amount':999999},
    ],
    'budgets':[{'month':m,'category':'Food','amount':10000}],
   };
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();await tester.tap(find.byKey(const ValueKey('bottom-1')));await tester.pumpAndSettle();
   await tester.tap(find.byKey(const ValueKey('subtab-1-1')));await tester.pumpAndSettle();
   expect(find.text('790.00 MAD'),findsOneWidget);
   expect(find.text('Over budget'),findsOneWidget);
   expect(find.text('Spending without a category budget'),findsOneWidget);
   expect(find.text('Old expense'),findsNothing);
   await tester.ensureVisible(find.text('Continue to close checks'));await tester.pumpAndSettle();
   final close=find.ancestor(of:find.text('Continue to close checks'),matching:find.byWidgetPredicate((w)=>w is FilledButton)).first;
   expect(tester.widget<FilledButton>(close).onPressed,isNull);
   expect(tester.takeException(),isNull);
   await tester.ensureVisible(find.byTooltip('Previous month'));await tester.pumpAndSettle();
   await tester.tap(find.byTooltip('Previous month'));await tester.pumpAndSettle();
   expect(find.text('Ready to review'),findsOneWidget);
   expect(find.text('No transactions recorded for this month. Bills and plans can still have outstanding amounts.'),findsOneWidget);
   await tester.ensureVisible(find.text('Continue to close checks'));await tester.pumpAndSettle();
   expect(tester.widget<FilledButton>(find.ancestor(of:find.text('Continue to close checks'),matching:find.byWidgetPredicate((w)=>w is FilledButton)).first).onPressed,isNotNull);
   expect(tester.takeException(),isNull);
  });
 }
}
