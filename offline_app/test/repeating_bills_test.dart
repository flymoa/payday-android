import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payday_local/offline_store.dart';

void main(){
 sqfliteFfiInit();late Database db;late OfflineStore store;
 setUp(()async{
  db=await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
  await db.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT NOT NULL UNIQUE,name TEXT NOT NULL,due TEXT NOT NULL,amount INTEGER NOT NULL,category TEXT NOT NULL,note TEXT NOT NULL DEFAULT "",repeat_monthly INTEGER NOT NULL DEFAULT 0)');
  await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY,bill_id TEXT,amount INTEGER)');
  store=OfflineStore(database:db);
 });
 tearDown(()async{await db.close();});

 Future<List<String>> dues()async=>(await db.query('bills',orderBy:'due')).map((b)=>b['due'] as String).toList();

 test('a repeating bill gets one copy per new month, same day, new month and year',()async{
  await store.saveBill(code:'LYDEC',name:'Lydec',due:'2026-11-01',amount:41280,category:'Housing',note:'',repeatMonthly:true);
  expect(await store.applyRepeatingBills(DateTime(2027,1,15)),2);
  expect(await dues(),['2026-11-01','2026-12-01','2027-01-01']);
  // Running again (every app start) never duplicates a month.
  expect(await store.applyRepeatingBills(DateTime(2027,1,20)),0);
  expect((await db.query('bills')).length,3);
  // Copies are one-off bills of their own; only the source repeats.
  expect((await db.query('bills',where:'repeat_monthly=1')).length,1);
 });

 test('the day is clamped in short months but kept afterwards',()async{
  await store.saveBill(code:'RENT',name:'Rent',due:'2026-01-31',amount:300000,category:'Housing',note:'',repeatMonthly:true);
  await store.applyRepeatingBills(DateTime(2026,3,1));
  expect(await dues(),['2026-01-31','2026-02-28','2026-03-31']);
 });

 test('one-off bills and a month already repeated by hand are left alone',()async{
  await store.saveBill(code:'ONCE',name:'Once',due:'2026-11-01',amount:5000,category:'Other',note:'');
  expect(await store.applyRepeatingBills(DateTime(2027,1,1)),0);
  await store.saveBill(code:'INWI',name:'Inwi',due:'2026-11-05',amount:5000,category:'Other',note:'',repeatMonthly:true);
  final inwi=(await db.query('bills',where:'code=?',whereArgs:['INWI'])).single;
  expect(await store.repeatBill(inwi['id'] as int,expected:inwi),isTrue); // manual December copy
  expect(await store.applyRepeatingBills(DateTime(2026,12,10)),0);
  expect((await db.query('bills',where:"name='Inwi'")).length,2);
 });
}
