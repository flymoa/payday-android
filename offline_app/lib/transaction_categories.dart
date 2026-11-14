/// Presentation-only category choices. Persisted transaction types stay intact.
List<String> transactionCategories({required String type,
 required Iterable<String> configured,required Iterable<Map<String,Object?>> history,
 Iterable<String> incomeConfigured=const [],Iterable<String> hidden=const [],
 String? existingCategory}){
 final group=type.startsWith('Savings')?'Savings':type;
 const reserved=['salary','freelance','business','gifts','savings','other income','income plan','savings goal'];
 final expenseNames=configured.map((s)=>s.trim().toLowerCase()).toSet();
 final incomeNames=incomeConfigured.map((s)=>s.trim().toLowerCase()).toSet();
 final hiddenNames=hidden.map((s)=>s.trim().toLowerCase()).toSet();
 bool matches(Map<String,Object?> row)=>group=='Savings'
  ?row['type'].toString().startsWith('Savings'):row['type']==type;
 bool allowed(String name){
  if(name.trim().isEmpty)return false;
  final normalized=name.trim().toLowerCase();
  if(hiddenNames.contains(normalized))return false;
  if(group=='Expense')return !reserved.contains(normalized)&&!incomeNames.contains(normalized);
  return !expenseNames.contains(normalized)||normalized=='salary'||normalized=='savings';
 }
 final used=history.where(matches).map((r)=>r['category']?.toString()??'').where(allowed);
 final values=<String>{
  if(group=='Income')...['Salary','Freelance','Business','Gifts','Other income'],
  if(group=='Income')...incomeConfigured,
  if(group=='Savings')'Savings',
  if(group=='Expense')...configured.where(allowed),
  ...used,
 };
 values.removeWhere((name)=>hiddenNames.contains(name.trim().toLowerCase()));
 if(existingCategory!=null&&existingCategory.trim().isNotEmpty)values.add(existingCategory);
 if(values.isEmpty){
  final fallback=group=='Expense'?'Groceries':group=='Income'?'Salary':'Savings';
  values.add(hiddenNames.contains(fallback.toLowerCase())?'Uncategorized':fallback);
 }
 return values.toList();
}

