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
  testWidgets('Bills and New align, with a clear form title in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:BillsStore(),initialData:Future.value({}))));
   await t.pumpAndSettle();await t.tap(find.text('More'));await t.pumpAndSettle();
   await t.tap(find.text('Bills & payments'));await t.pumpAndSettle();
   expect(find.textContaining('Attach the Bill ID'),findsNothing);
   expect((t.getCenter(find.text('Bills')).dy-t.getCenter(find.text('New')).dy).abs(),lessThan(1));
   await t.tap(find.text('New'));await t.pumpAndSettle();
   expect(find.text('Add a bill'),findsOneWidget);expect(find.text('Add bill'),findsNothing);
   expect(t.takeException(),isNull);
  });
 }
}
