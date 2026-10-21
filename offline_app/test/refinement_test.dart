import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:flutter/material.dart';
import 'package:payday_local/brand.dart';

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
   expect(find.byType(Image),findsOneWidget);
  });
 }
}
