import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
class GroupStore extends OfflineStore{
 Map<String,Object?>? saved;
 @override Future<Map<String,List<RowData>>> snapshot()async=>{'categories':[
  {'name':'Groceries','group_name':'Essential'},{'name':'Housing','group_name':'Essential'},
 ]};
 @override Future<void> close()async{}
 @override Future<void> saveTransaction({int? id,required String date,required String type,required String category,required int amount,required String description,required String note,required String billId,String? account})async{
  saved={'type':type,'category':category,'amount':amount};
 }
}
void main(){
 for(final brightness in Brightness.values){
  for(final type in ['Income','Savings out','Savings in']){
   testWidgets('$type uses filtered categories and preserves accounting in ${brightness.name}',(tester)async{
    await tester.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>tester.binding.setSurfaceSize(null));
    final store=GroupStore();
    await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:store,initialData:store.snapshot())));
    await tester.pumpAndSettle();final semantics=tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Add transaction'));await tester.pumpAndSettle();semantics.dispose();
    final group=type=='Income'?'Income':'Savings';
    final headerButtons=find.descendant(of:find.byType(BottomSheet),matching:find.widgetWithText(TextButton,group));
    await tester.tap(headerButtons.first);await tester.pumpAndSettle();
    final grid=find.byKey(const ValueKey('transaction-category-grid'));
    expect(find.descendant(of:grid,matching:find.text('Groceries')),findsNothing);
    expect(find.descendant(of:grid,matching:find.text(type=='Income'?'Salary':'Savings')),findsOneWidget);
    if(type=='Savings in'){await tester.tap(find.text('Take from savings'));await tester.pumpAndSettle();}
    final amount=find.widgetWithText(TextField,'Amount (DH)');await tester.ensureVisible(amount);await tester.pumpAndSettle();await tester.enterText(amount,'100.25');
    await tester.tap(find.byKey(const ValueKey('save-transaction')));await tester.pumpAndSettle();
    expect(store.saved,{'type':type,'category':type=='Income'?'Salary':'Savings','amount':10025});
    expect(tester.takeException(),isNull);
   });
  }
 }
}
