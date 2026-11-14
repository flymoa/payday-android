import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/safe_to_spend_row.dart';
import 'package:payday_local/app_icon.dart';
import 'package:payday_local/main.dart';
void main(){
 for(final brightness in Brightness.values){
  testWidgets('compact safe balance remains readable and opens details in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   var calls=0;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:Scaffold(body:Padding(padding:const EdgeInsets.all(38),
    child:SafeToSpendRow(amount:'1234567890.00 MAD',color:Colors.green,onTap:()=>calls++)))));
   expect(find.text('Tap for details'),findsNothing);expect(find.byTooltip('View safe-to-spend details'),findsOneWidget);
   expect(t.getCenter(find.text('Safe to spend')).dy,t.getCenter(find.text('1234567890.00 MAD')).dy);
   await t.tap(find.text('Safe to spend'));await t.pump();expect(calls,1);
   await t.tap(find.text('1234567890.00 MAD'));await t.pump();expect(calls,2);expect(t.takeException(),isNull);
  });
 }
 testWidgets('home shortcut uses the same budget glyph as navigation',(t)async{
  await t.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(_)async{}));
  await t.pumpAndSettle();
  final icon=find.descendant(of:find.byKey(const ValueKey('home-budget-icon')),matching:find.byType(PaydayAppIcon));
  expect(t.widget<PaydayAppIcon>(icon).icon,Icons.pie_chart_outline);
 });
}
