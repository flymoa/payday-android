import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/main.dart';
class UndoStore extends OfflineStore{
 UndoStore(Database db):super(database:db);
 @override Future<void> close()async{}
 @override Future<Map<String,List<RowData>>> snapshot()async=>{
  'transactions':await table('transactions'),
  'categories':[{'name':'Groceries','group_name':'Essential'}],
 };
}
void main(){
 sqfliteFfiInit();late Database db;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,date TEXT NOT NULL,type TEXT NOT NULL,category TEXT NOT NULL,description TEXT NOT NULL,amount INTEGER NOT NULL,note TEXT NOT NULL,bill_id TEXT NOT NULL)');
  await db.insert('transactions',{'id':1,'date':'${monthKey(DateTime.now())}-01','type':'Expense','category':'Groceries','description':'Market','amount':12345,'note':'Weekly','bill_id':'B001'});
 });
 tearDown(()async{await db.close();});
 test('undo restores exact row including bill link and original ID',()async{
  final store=OfflineStore(database:db);final before=(await db.query('transactions')).single;
  final deleted=await store.deleteTransactionForUndo(1);
  expect(await db.query('transactions'),isEmpty);
  await store.restoreDeletedTransaction(deleted!);
  expect((await db.query('transactions')).single,before);
  await expectLater(store.restoreDeletedTransaction(deleted),throwsA(isA<DatabaseException>()));
  expect((await db.query('transactions')).length,1);
 });
 test('missing deletion is harmless and snapshot reflects latest saved state',()async{
  final store=OfflineStore(database:db);
  expect(await store.deleteTransactionForUndo(99),isNull);
  await db.update('transactions',{'amount':999},where:'id=1');
  final row=await store.deleteTransactionForUndo(1);expect(row!['amount'],999);
 });
 test('undo does not replace a record occupying its former ID',()async{
  final store=OfflineStore(database:db);final row=await store.deleteTransactionForUndo(1);
  await db.insert('transactions',{...row!,'description':'Newer record'});
  await expectLater(store.restoreDeletedTransaction(row),throwsA(isA<DatabaseException>()));
  expect((await db.query('transactions')).single['description'],'Newer record');
 });
 for(final brightness in Brightness.values){
  testWidgets('delete and undo restore Records in ${brightness.name} mode',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final store=UndoStore(db);
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:FinanceScreen(store:store,initialData:store.snapshot())));
   await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'Home');await tester.tap(find.text('Records').last);await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'Records');
   await tester.tap(find.text('Market'));await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:'Edit form');
   await tester.ensureVisible(find.text('Delete transaction'));await tester.tap(find.text('Delete transaction'));await tester.pumpAndSettle();
   await tester.tap(find.text('Delete').last);
   for(var i=0;i<30;i++){await tester.pump(const Duration(milliseconds:50));}
   expect(await db.query('transactions'),isEmpty);
   await tester.tap(find.text('Undo'));
   for(var i=0;i<30;i++){await tester.pump(const Duration(milliseconds:50));}
   expect((await db.query('transactions')).single['description'],'Market');
   expect(find.text('Market'),findsOneWidget);expect(tester.takeException(),isNull);
  });
 }
}
