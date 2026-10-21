import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/offline_store.dart';
void main(){
 test('monthly due dates clamp and cross year correctly',(){
  expect(dayKey(nextBillDue(DateTime(2026,1,31))),'2026-02-28');
  expect(dayKey(nextBillDue(DateTime(2028,1,31))),'2028-02-29');
  expect(dayKey(nextBillDue(DateTime(2026,12,15))),'2027-01-15');
 });
 sqfliteFfiInit();late Database db;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT NOT NULL UNIQUE,name TEXT NOT NULL,due TEXT NOT NULL,amount INTEGER NOT NULL,category TEXT NOT NULL,note TEXT NOT NULL)');
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY,bill_id TEXT,amount INTEGER)');
  await db.insert('bills',{'id':1,'code':'RENT','name':'Rent','due':'2026-01-31','amount':300000,'category':'Housing','note':'Monthly'});
  await db.insert('transactions',{'id':1,'bill_id':'RENT','amount':300000});
 });
 tearDown(()async{await db.close();});
 test('concurrent repeats create one unpaid copy and preserve source',()async{
  final store=OfflineStore(database:db);final original=(await db.query('bills')).single;
  final results=await Future.wait([store.repeatBill(1,expected:original),store.repeatBill(1,expected:original)]);
  expect(results.where((x)=>x).length,1);
  final bills=await db.query('bills');expect(bills.length,2);
  final copy=bills.firstWhere((x)=>x['id']!=1);
  expect(copy['due'],'2026-02-28');expect(copy['amount'],300000);
  expect(copy['category'],'Housing');expect(copy['note'],'Monthly');
  expect(copy['code'],isNot('RENT'));
  expect(await db.query('transactions',where:'bill_id=?',whereArgs:[copy['code']]),isEmpty);
  expect((await db.query('transactions')).single['bill_id'],'RENT');
  expect(bills.firstWhere((x)=>x['id']==1),original);
 });
 test('stale preview and deleted sources cannot create copies',()async{
  final store=OfflineStore(database:db);final original=(await db.query('bills')).single;
  await db.update('bills',{'amount':400000},where:'id=1');
  await expectLater(store.repeatBill(1,expected:original),throwsStateError);
  expect((await db.query('bills')).length,1);
  await db.delete('bills',where:'id=1');
  await expectLater(store.repeatBill(1,expected:original),throwsStateError);
  expect(await db.query('bills'),isEmpty);
 });
}
