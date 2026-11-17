import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
class BillsStore extends OfflineStore{
 @override Future<void> close()async{}
 @override Future<Map<String,List<RowData>>> snapshot()async=>{};
}
void main(){
 for(final brightness in Brightness.values){
  testWidgets('Add a bill opens a clearly titled form in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:BillsStore(),initialData:Future.value({}))));
   await t.pumpAndSettle();await t.tap(find.byKey(const ValueKey('bottom-2')));await t.pumpAndSettle();
   await t.tap(find.byKey(const ValueKey('subtab-2-1')));await t.pumpAndSettle();
   expect(find.textContaining('Attach the Bill ID'),findsNothing);
   await t.tap(find.byKey(const ValueKey('bills-add')));await t.pumpAndSettle();
   expect(find.descendant(of:find.byType(BottomSheet),matching:find.text('Add a bill')),findsOneWidget);expect(find.text('Add bill'),findsNothing);
   expect(t.takeException(),isNull);
  });
 }
}
