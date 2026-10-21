import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';
void main(){
 int remaining({int contribution=0,int funded=0,DateTime? month,DateTime? start})=>reserveThisMonthRemaining(
  target:240000,fundedBeforeMonth:funded,netContributedThisMonth:contribution,
  due:DateTime(2027,3,31),start:start??DateTime(2027,1),month:month??DateTime(2027,1));
 test('monthly suggestion falls as real deposits are recorded',(){
  expect(remaining(),80000);expect(remaining(contribution:30000),50000);
  expect(remaining(contribution:80000),0);expect(remaining(contribution:240000),0);
  expect(remaining(funded:80000,month:DateTime(2027,2)),80000);
 });
 test('before start and after due month need separate guidance',(){
  expect(remaining(month:DateTime(2026,12)),0);
  expect(remaining(month:DateTime(2027,4)),0);
  expect(remaining(month:DateTime(2027,3),funded:160000),80000);
 });
 for(final brightness in Brightness.values){
  testWidgets('fully spent status and reserve guidance fit ${brightness.name} phone',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final now=DateTime.now();final m=monthKey(now);
   final fixture=<String,List<RowData>>{
    'categories':[{'name':'Groceries','group_name':'Essential'}],
    'transactions':[{'type':'Expense','category':'Groceries','date':'$m-01','amount':50000}],
    'budgets':[{'month':m,'category':'Groceries','amount':50000}],
    'reserves':[{'id':1,'name':'Insurance','target':240000,'funded':0,'start_month':m,'due':dayKey(DateTime(now.year,now.month+3,0))}],
   };
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'Home');
   expect(find.text('Fully spent'),findsOneWidget);expect(find.text('Near limit'),findsNothing);
   await tester.tap(find.text('More').last);await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'More');
   await tester.tap(find.text('Occasional expenses'));await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'Reserves');
   expect(find.text('How reserves work'),findsOneWidget);
   expect(find.text('Still to set aside this month: 800.00 MAD'),findsOneWidget);
   await tester.ensureVisible(find.text('Still to set aside this month: 800.00 MAD'));await tester.pumpAndSettle();
   expect(tester.takeException(),isNull);
  });
 }
}
