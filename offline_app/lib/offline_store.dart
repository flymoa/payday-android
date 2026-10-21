import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'finance.dart';

const defaultCategories = <String,String>{
 'Housing':'Essential','Utilities':'Essential','Groceries':'Essential',
 'Transport':'Essential','Health':'Essential','Family':'Essential',
 'Eating out':'Flexible','Shopping':'Flexible','Leisure':'Flexible',
 'Subscriptions':'Essential','Debt payment':'Essential','Other':'Essential'
};
const localTables = ['transactions','budgets','categories','goals','allocations','bills','month_closes','reserves','settings'];

class OfflineStore {
 Database? _database;
 Future<Database> get db async {
  if (_database!=null) return _database!;
  final root = await getDatabasesPath();
  _database=await openDatabase(path.join(root,'payday_local_v1.db'),version:1,onCreate:(d,v) async {
   await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
   await d.execute('CREATE INDEX ix_transactions_date ON transactions(date)');
   await d.execute('CREATE TABLE budgets(month TEXT NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL, PRIMARY KEY(month, category))');
   await d.execute('CREATE TABLE categories(name TEXT PRIMARY KEY, group_name TEXT NOT NULL)');
   await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, target INTEGER NOT NULL)');
   await d.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL, FOREIGN KEY(goal_id) REFERENCES goals(id))');
   await d.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, due TEXT NOT NULL, amount INTEGER NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL DEFAULT "")');
   await d.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
   await d.execute('CREATE TABLE reserves(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target INTEGER NOT NULL, funded INTEGER NOT NULL DEFAULT 0, due TEXT NOT NULL, start_month TEXT NOT NULL)');
   await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
   final batch=d.batch();
   for(final c in defaultCategories.entries) { batch.insert('categories',{'name':c.key,'group_name':c.value}); }
   for(final g in [('Emergency fund',2000000),('Holiday',1500000),('New computer',1500000)]) {
    batch.insert('goals',{'name':g.$1,'target':g.$2});
   }
   for(final entry in {'buffer':'20000','opening_savings':'0','opening_cash':'0','salary_day':'1','currency':'MAD'}.entries){
    batch.insert('settings',{'key':entry.key,'value':entry.value});
   }
   await batch.commit(noResult:true);
  });
  return _database!;
 }
 Future<List<Map<String,Object?>>> table(String name) async {
  if(!localTables.contains(name)) throw ArgumentError('Unknown table');
  return (await (await db).query(name)).map((r)=>Map<String,Object?>.from(r)).toList();
 }
 Future<Map<String,List<Map<String,Object?>>>> snapshot() async {
  final result=<String,List<Map<String,Object?>>>{};
  for(final tableName in localTables) {result[tableName]=await table(tableName);}
  return result;
 }
 Future<void> saveTransaction({int? id,required String date,required String type,required String category,required int amount,required String description,required String note,required String billId}) async{
  if(!['Income','Expense','Savings out','Savings in'].contains(type) || amount<=0)throw ArgumentError('Invalid entry');
  final values={'date':date,'type':type,'category':category,'amount':amount,'description':description,'note':note,'bill_id':billId};
  final d=await db;
  if(id==null){await d.insert('transactions',values);}else{await d.update('transactions',values,where:'id=?',whereArgs:[id]);}
 }
 Future<void> removeTransaction(int id) async => (await db).delete('transactions',where:'id=?',whereArgs:[id]);
 Future<void> setBudget(String month,String category,int cents) async{
  if(cents<0)throw ArgumentError('Negative budget');
  await (await db).insert('budgets',{'month':month,'category':category,'amount':cents},conflictAlgorithm:ConflictAlgorithm.replace);
 }
 Future<void> saveGoal({int? id,required String name,required int target}) async{
  if(name.trim().isEmpty || target<=0) throw ArgumentError('Invalid goal');
  final d=await db;
  if(id==null){await d.insert('goals',{'name':name.trim(),'target':target});}
  else{await d.update('goals',{'name':name.trim(),'target':target},where:'id=?',whereArgs:[id]);}
 }
 Future<void> allocate(String month,int goalId,int amount) async {
  if(amount<=0)throw ArgumentError('Invalid allocation');
  await (await db).insert('allocations',{'month':month,'goal_id':goalId,'amount':amount});
 }
 Future<void> deleteAllocation(int id) async => (await db).delete('allocations',where:'id=?',whereArgs:[id]);
 Future<void> saveBill({int? id,required String code,required String name,required String due,required int amount,required String category,required String note}) async{
  if(code.trim().isEmpty||name.trim().isEmpty||amount<=0)throw ArgumentError('Invalid bill');
  final v={'code':code.trim(),'name':name.trim(),'due':due,'amount':amount,'category':category,'note':note};
  final d=await db;
  if(id==null){await d.insert('bills',v);}else{await d.update('bills',v,where:'id=?',whereArgs:[id]);}
 }
 Future<void> removeBill(int id) async => (await db).delete('bills',where:'id=?',whereArgs:[id]);
 Future<void> saveReserve({int? id,required String name,required int target,required int funded,required String due,required String startMonth}) async{
  if(name.trim().isEmpty||target<=0||funded<0)throw ArgumentError('Invalid reserve');
  final v={'name':name,'target':target,'funded':funded,'due':due,'start_month':startMonth};
  final d=await db;
  if(id==null){await d.insert('reserves',v);}else{await d.update('reserves',v,where:'id=?',whereArgs:[id]);}
 }
 Future<void> removeReserve(int id) async => (await db).delete('reserves',where:'id=?',whereArgs:[id]);
 Future<void> saveMonthClose(String month,{required bool entriesOk,required bool balanceOk,required int extra,required int openingBalance}) async {
  if(extra<0)throw ArgumentError('Invalid savings');
  await (await db).insert('month_closes',{
    'month':month,'entries_ok':entriesOk?1:0,'balance_ok':balanceOk?1:0,
    'extra':extra,'opening_balance':openingBalance
  }, conflictAlgorithm:ConflictAlgorithm.replace);
 }
 Future<void> setSetting(String key,String value) async =>
   (await db).insert('settings',{'key':key,'value':value},conflictAlgorithm:ConflictAlgorithm.replace);
 Future<void> addCategory(String name,String group) async{
  if(name.trim().isEmpty || !['Essential','Flexible'].contains(group))throw ArgumentError('Invalid category');
  await (await db).insert('categories',{'name':name.trim(),'group_name':group});
 }
 Future<String> exportJson() async => const JsonEncoder.withIndent('  ').convert({
  'format':'payday-local','schema_version':1,'exported_at':DateTime.now().toUtc().toIso8601String(),
  'tables':await snapshot()
 });
 Future<void> importJson(String contents) async{
  final raw=jsonDecode(contents);
  if(raw is! Map || raw['format']!='payday-local'||raw['schema_version']!=1)throw const FormatException('Unsupported Payday backup');
  final tables=raw['tables'];
  if(tables is! Map || localTables.any((t)=>tables[t] is! List))throw const FormatException('Incomplete backup');
  final d=await db;
  await d.transaction((txn) async{
   // Restoring is one SQLite transaction: either all tables change or none do.
   for(final table in localTables.reversed) {await txn.delete(table);}
   for(final name in localTables){
    for(final item in tables[name] as List){
     if(item is! Map)throw const FormatException('Invalid backup record');
     await txn.insert(name,Map<String,Object?>.from(item));
    }
   }
  });
 }
 Future<void> close() async { await _database?.close();_database=null; }
}
