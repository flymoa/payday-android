import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
class DesignStore extends OfflineStore{
 Map<String,Object?>? saved;
 @override Future<Map<String,List<RowData>>> snapshot()async=>{
  'categories':[{'name':'Groceries','group_name':'Essential'},{'name':'Housing','group_name':'Essential'}],
 };
 @override Future<void> close()async{}
 @override Future<void> saveTransaction({int? id,required String date,required String type,required String category,required int amount,required String description,required String note,required String billId,String? account})async{
  saved={'id':id,'date':date,'type':type,'category':category,'amount':amount,'description':description,'note':note,'bill_id':billId};
 }
}
void main(){
 for(final brightness in Brightness.values){
  testWidgets('new transaction presentation preserves saved fields in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
   final store=DesignStore();
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:store,initialData:store.snapshot())));
   await tester.pumpAndSettle();
   // The raised button uses PAYDAY artwork, so use its existing semantic label.
   final semantics=tester.ensureSemantics();
   await tester.tap(find.bySemanticsLabel('Add transaction'));
   await tester.pumpAndSettle();
   semantics.dispose();
   expect(find.text('Category'),findsOneWidget);
   Future<void> enter(String label,String value)async{
    final field=find.widgetWithText(TextField,label);
    await tester.ensureVisible(field);await tester.pumpAndSettle();await tester.enterText(field,value);
   }
   await enter('Amount (MAD)','312.40');
   // The description and note stay folded behind "+ Note" until asked for.
   expect(find.widgetWithText(TextField,'Description'),findsNothing);
   await tester.ensureVisible(find.byKey(const ValueKey('transaction-more-details')));await tester.pumpAndSettle();
   await tester.tap(find.byKey(const ValueKey('transaction-more-details')));await tester.pumpAndSettle();
   await enter('Description','Weekly shop');await enter('Note (optional)','Original note');await enter('Bill ID (optional)','B001');
   await tester.tap(find.byKey(const ValueKey('save-transaction')));await tester.pumpAndSettle();
   expect(store.saved!['amount'],31240);expect(store.saved!['type'],'Expense');expect(store.saved!['category'],'Groceries');
   expect(store.saved!['description'],'Weekly shop');expect(store.saved!['note'],'Original note');expect(store.saved!['bill_id'],'B001');
   expect(find.byKey(const ValueKey('save-transaction')),findsNothing);expect(tester.takeException(),isNull);
  });
 }
 testWidgets('amount is ready to type and Yesterday dates the entry in one tap',(tester)async{
  await tester.binding.setSurfaceSize(const Size(360,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
  final store=DesignStore();
  await tester.pumpWidget(MaterialApp(home:FinanceScreen(store:store,initialData:store.snapshot())));
  await tester.pumpAndSettle();
  final semantics=tester.ensureSemantics();
  await tester.tap(find.bySemanticsLabel('Add transaction'));
  await tester.pumpAndSettle();
  semantics.dispose();
  final amount=find.widgetWithText(TextField,'Amount (MAD)');
  expect(tester.widget<TextField>(amount).autofocus,isTrue);
  await tester.enterText(amount,'45');
  final yesterday=find.byKey(const ValueKey('transaction-date-yesterday'));
  await tester.ensureVisible(yesterday);await tester.pumpAndSettle();
  await tester.tap(yesterday);await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('save-transaction')));await tester.pumpAndSettle();
  final now=DateTime.now();
  expect(store.saved!['date'],dayKey(DateTime(now.year,now.month,now.day-1)));
  expect(store.saved!['amount'],4500);expect(store.saved!['note'],'');expect(store.saved!['bill_id'],'');
  expect(tester.takeException(),isNull);
 });
}
