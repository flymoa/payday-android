import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/category_icon.dart';
import 'package:payday_local/add_button.dart';
void main(){
 test('recent entries cross month and year boundaries, exclude old and future dates',(){
  final rows=[
   {'id':1,'date':'2026-12-31'},
   {'id':2,'date':'2027-01-01'},
   {'id':3,'date':'2027-01-01'},
   {'id':4,'date':'2026-12-30'},
   {'id':5,'date':'2027-01-02'},
  ];
  expect(recentActivityRows(rows,DateTime(2027,1,1,23)).map((r)=>r['id']),[3,2,1]);
  expect(recentActivityRows([{'date':'2028-02-29'}],DateTime(2028,3,1)),hasLength(1));
 });
 for(final brightness in Brightness.values){
  testWidgets('Home activity uses relative dates, category artwork and transparent rows in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
   final now=DateTime.now();final today=dayKey(now),yesterday=dayKey(DateTime(now.year,now.month,now.day-1));
   final fixture=<String,List<RowData>>{'transactions':[
    {'id':1,'date':today,'type':'Expense','category':'Subscriptions','description':'Internet','amount':30000},
    {'id':2,'date':yesterday,'type':'Expense','category':'Transport','description':'Taxi','amount':2500},
    {'id':3,'date':dayKey(DateTime(now.year,now.month,now.day-2)),'type':'Expense','category':'Groceries','description':'Old shop','amount':1000},
   ]};
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(initialData:Future.value(fixture))));
   await tester.pumpAndSettle();
   expect(find.text('Subscriptions · Today'),findsOneWidget);expect(find.text('Transport · Yesterday'),findsOneWidget);
   expect(find.text('Old shop'),findsNothing);
   expect(find.byWidgetPredicate((w)=>w is PaydayCategoryIcon&&w.category=='Subscriptions'),findsOneWidget);
   final internet=find.text('Internet');
   expect(find.ancestor(of:internet,matching:find.byType(Card)),findsNothing);
   final rowMaterial=find.ancestor(of:internet,matching:find.byType(Material)).first;
   expect(tester.widget<Material>(rowMaterial).color,Colors.transparent);
   await tester.tap(find.text('Records').last);await tester.pumpAndSettle();
   final search=find.widgetWithText(TextField,'Search records');
   expect(tester.getSize(search).height,lessThanOrEqualTo(48));
   await tester.enterText(search,'Internet');await tester.pumpAndSettle();
   expect(find.text('Internet'),findsOneWidget);expect(find.text('Taxi'),findsNothing);
   await tester.tap(find.byTooltip('Clear search'));await tester.pumpAndSettle();
   expect(tester.takeException(),isNull);
  });
 }
 testWidgets('add button visibly presses and opens once without a delay',(tester)async{
  var taps=0;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Center(child:PaydayAddButton(onPressed:()=>taps++)))));
  final target=find.byType(PaydayAddButton);
  final gesture=await tester.startGesture(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds:120));
  expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,lessThan(1));
  await gesture.up();await tester.pumpAndSettle();
  expect(taps,1);expect(tester.takeException(),isNull);
 });
}
