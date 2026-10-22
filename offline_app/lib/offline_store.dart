import 'dart:convert';
import 'finance.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

const defaultCategories = <String,String>{
 'Housing':'Essential','Utilities':'Essential','Groceries':'Essential',
 'Transport':'Essential','Health':'Essential','Family':'Essential',
 'Eating out':'Flexible','Shopping':'Flexible','Leisure':'Flexible',
 'Subscriptions':'Essential','Debt payment':'Essential','Other':'Essential'
};
const localTables = ['transactions','budgets','categories','goals','allocations','bills','month_closes','reserves','reserve_movements','settings'];

class OfflineStore {
 OfflineStore({Database? database}):_database=database;
 Database? _database;
 static Future<void> createReserveMovements(DatabaseExecutor d) async {
  await d.execute("CREATE TABLE reserve_movements("
    "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    "reserve_id INTEGER NOT NULL,"
    "date TEXT NOT NULL,"
    "kind TEXT NOT NULL CHECK(kind IN ('add','release')),"
    "amount INTEGER NOT NULL CHECK(amount>0),"
    "note TEXT NOT NULL DEFAULT '',"
    "FOREIGN KEY(reserve_id) REFERENCES reserves(id))");
  await d.execute('CREATE INDEX ix_reserve_movements_date ON reserve_movements(date)');
  await d.execute('CREATE INDEX ix_reserve_movements_reserve ON reserve_movements(reserve_id)');
 }
 Future<Database> get db async {
  if (_database!=null) return _database!;
  final root = await getDatabasesPath();
  _database=await openDatabase(path.join(root,'payday_local_v1.db'),version:2,onCreate:(d,v) async {
   await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, type TEXT NOT NULL, category TEXT NOT NULL, description TEXT NOT NULL DEFAULT "", amount INTEGER NOT NULL, note TEXT NOT NULL DEFAULT "", bill_id TEXT NOT NULL DEFAULT "")');
   await d.execute('CREATE INDEX ix_transactions_date ON transactions(date)');
   await d.execute('CREATE TABLE budgets(month TEXT NOT NULL, category TEXT NOT NULL, amount INTEGER NOT NULL, PRIMARY KEY(month, category))');
   await d.execute('CREATE TABLE categories(name TEXT PRIMARY KEY, group_name TEXT NOT NULL)');
   await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, target INTEGER NOT NULL)');
   await d.execute('CREATE TABLE allocations(id INTEGER PRIMARY KEY AUTOINCREMENT, month TEXT NOT NULL, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL, FOREIGN KEY(goal_id) REFERENCES goals(id))');
   await d.execute('CREATE TABLE bills(id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, due TEXT NOT NULL, amount INTEGER NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL DEFAULT "")');
   await d.execute('CREATE TABLE month_closes(month TEXT PRIMARY KEY, entries_ok INTEGER NOT NULL DEFAULT 0, balance_ok INTEGER NOT NULL DEFAULT 0, extra INTEGER NOT NULL DEFAULT 0, opening_balance INTEGER NOT NULL DEFAULT 0)');
   await d.execute('CREATE TABLE reserves(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target INTEGER NOT NULL, funded INTEGER NOT NULL DEFAULT 0, due TEXT NOT NULL, start_month TEXT NOT NULL)');
   await createReserveMovements(d);
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
  },onUpgrade:(d,oldVersion,newVersion) async {
   if(oldVersion<2)await createReserveMovements(d);
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
 /// Capture the actual saved row in the same transaction as deletion.
 Future<Map<String,Object?>?> deleteTransactionForUndo(int id)async{
  return (await db).transaction((txn)async{
   final rows=await txn.query('transactions',where:'id=?',whereArgs:[id]);
   if(rows.isEmpty)return null;
   await txn.delete('transactions',where:'id=?',whereArgs:[id]);
   return Map<String,Object?>.from(rows.single);
  });
 }
 Future<void> restoreDeletedTransaction(Map<String,Object?> row)async{
  // Abort on an occupied ID: never replace a newer or restored record.
  await (await db).insert('transactions',row,conflictAlgorithm:ConflictAlgorithm.abort);
 }
 Future<BudgetAssignmentCheck> setBudget(String month,String category,int cents)async{
  if(cents<0||cents>100000000000)throw ArgumentError('Invalid budget amount');
  // Re-read and validate inside the same SQLite transaction as the write.
  // A stale form or a second quick save cannot bypass the monthly cap.
  return (await db).transaction((txn)async{
   final rows=await txn.query('budgets',where:'month=?',whereArgs:[month]);
   final check=checkBudgetAssignment(rows:rows,month:month,category:category,proposed:cents);
   if(!check.allowed)throw BudgetAssignmentException(check);
   await txn.insert('budgets',{'month':month,'category':category,'amount':cents},
    conflictAlgorithm:ConflictAlgorithm.replace);
   return check;
  });
 }
 Future<void> copyBudget(String month,{required String expectedState})async{
  await (await db).transaction((txn)async{
   final rows=await txn.query('budgets');
   if(budgetCopyState(rows,month)!=expectedState){
    throw StateError('Budgets changed. Close this preview and open it again.');
   }
   final plan=BudgetCopyPlan(rows,month);
   if(!plan.allowed)throw StateError('Assignments exceed planned income by ${(plan.exceededBy/100).toStringAsFixed(2)} MAD.');
   for(final row in plan.additions){await txn.insert('budgets',row);}
  });
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
 /// Re-read the saved source and insert the copy in one transaction.
 /// Separate bill IDs keep payments attached to their original month.
 Future<bool> repeatBill(int id,{required Map<String,Object?> expected})async{
  return (await db).transaction((txn)async{
   final rows=await txn.query('bills',where:'id=?',whereArgs:[id]);
   if(rows.isEmpty)throw StateError('This bill no longer exists.');
   final source=rows.single;
   for(final key in ['code','name','due','amount','category','note']){
    if(source[key]!=expected[key])throw StateError('This bill changed. Reopen it before repeating.');
   }
   final due=dayKey(nextBillDue(DateTime.parse(source['due'] as String)));
   final code='REPEAT:$id:${due.substring(0,7)}';
   final existing=await txn.query('bills',where:'code=?',whereArgs:[code]);
   if(existing.isNotEmpty)return false;
   await txn.insert('bills',{
    'code':code,'name':source['name'],'due':due,'amount':source['amount'],
    'category':source['category'],'note':source['note'],
   });
   return true;
  });
 }
 Future<void> removeBill(int id) async => (await db).delete('bills',where:'id=?',whereArgs:[id]);
 Future<void> saveReserve({int? id,required String name,required int target,required int funded,required String due,required String startMonth}) async{
  if(name.trim().isEmpty||target<=0||funded<0)throw ArgumentError('Invalid reserve');
  final v={'name':name,'target':target,'funded':funded,'due':due,'start_month':startMonth};
  final d=await db;
  if(id==null){
    await d.insert('reserves',v);
  }else{
    final old=await d.query('reserves',columns:['funded'],where:'id=?',whereArgs:[id]);
    if(old.isEmpty)throw StateError('Reserve no longer exists.');
    if((old.first['funded'] as num).toInt()!=funded){
      throw StateError('Opening amount cannot be edited; log a deposit or withdrawal instead.');
    }
    final net=await d.rawQuery(
      "SELECT COALESCE(SUM(CASE WHEN kind='add' THEN amount ELSE -amount END),0) AS net FROM reserve_movements WHERE reserve_id=?",
      [id]);
    final fundedNow=funded+(net.single['net'] as num).toInt();
    if(target<fundedNow)throw StateError(
      'Target cannot be lower than the money currently in this reserve.');
    await d.update('reserves',v,where:'id=?',whereArgs:[id]);
  }
 }
 /// Every reserve deposit or withdrawal is kept as a dated ledger entry.
 /// 'funded' on the reserve itself is historical opening funds, not a new transfer.
 Future<void> recordReserveMovement({
  required int reserveId,
  required String date,
  required String kind,
  required int amount,
  required String note,
 }) async {
  if(!['add','release'].contains(kind)||amount<=0||amount>100000000000){
   throw ArgumentError('Enter a valid reserve transfer amount.');
  }
  final parsed=DateTime.tryParse(date);
  if(parsed==null || date.length!=10 || parsed.year<2000 ||
     DateTime(parsed.year,parsed.month,parsed.day).isAfter(DateTime.now())){
   throw ArgumentError('Choose a valid payment date, not a future date.');
  }
  final d=await db;
  await d.transaction((txn) async{
   final rows=await txn.query('reserves',where:'id=?',whereArgs:[reserveId]);
   if(rows.isEmpty)throw StateError('Reserve no longer exists.');
   final reserve=rows.single;
   final movements=await txn.rawQuery(
     "SELECT COALESCE(SUM(CASE WHEN kind='add' THEN amount ELSE -amount END),0) AS net FROM reserve_movements WHERE reserve_id=?",
     [reserveId]);
   final balance=(reserve['funded'] as num).toInt()+(movements.single['net'] as num).toInt();
   if(kind=='release' && amount>balance){
     throw StateError('Cannot withdraw more than the funded amount.');
   }
   if(kind=='add' && amount>(reserve['target'] as num).toInt()-balance){
     throw StateError('This transfer exceeds the reserve target.');
   }
   await txn.insert('reserve_movements',{
     'reserve_id':reserveId,'date':date,'kind':kind,
     'amount':amount,'note':note.trim(),
   });
   // Backdated transfers must not make any point in the funding history negative
   // or over its target; rollback the entire insertion when they do.
   var running=(reserve['funded'] as num).toInt();
   final chronological=await txn.query('reserve_movements',
     columns:['kind','amount'],where:'reserve_id=?',whereArgs:[reserveId],
     orderBy:'date ASC, id ASC');
   for(final movement in chronological){
    final delta=(movement['amount'] as num).toInt();
    running+=(movement['kind']=='add'?delta:-delta);
    if(running<0)throw StateError(
      'Transfer would make the historical reserve balance negative.');
    if(running>(reserve['target'] as num).toInt())throw StateError(
      'Transfer would exceed the reserve target.');
   }
  });
 }
 Future<void> removeReserve(int id) async {
  final d=await db;
  await d.transaction((txn) async{
   final transfers=Sqflite.firstIntValue(await txn.rawQuery(
     'SELECT COUNT(*) FROM reserve_movements WHERE reserve_id=?',[id]))??0;
   if(transfers>0)throw StateError(
     'This reserve has transfer history. Keep it for your records.');
   await txn.delete('reserves',where:'id=?',whereArgs:[id]);
  });
 }
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
  'format':'payday-local','schema_version':2,'exported_at':DateTime.now().toUtc().toIso8601String(),
  'tables':await snapshot()
 });
 Future<void> importJson(String contents) async{
  final raw=jsonDecode(contents);
  if(raw is! Map || raw['format']!='payday-local' ||
    ![1,2].contains(raw['schema_version'])) {
   throw const FormatException('Unsupported Payday backup');
  }
  final tables=raw['tables'];
  final legacy=raw['schema_version']==1;
  if(tables is! Map ||
    localTables.where((t)=>!legacy||t!='reserve_movements')
      .any((t)=>tables[t] is! List)) {
   throw const FormatException('Incomplete backup');
  }
  final d=await db;
  await d.transaction((txn) async{
   // Restoring is one SQLite transaction: either all tables change or none do.
   for(final table in localTables.reversed) {await txn.delete(table);}
   for(final name in localTables){
    for(final item in (legacy && name=='reserve_movements' ? <dynamic>[] : tables[name] as List)){
     if(item is! Map)throw const FormatException('Invalid backup record');
     await txn.insert(name,Map<String,Object?>.from(item));
    }
   }
   // Export reminders belong to this installation, not the imported file.
   await txn.delete('settings',where:'key IN (?, ?)',whereArgs:['last_backup_export','backup_snooze_until']);
  });
 }
 Future<void> close() async { await _database?.close();_database=null; }
}





