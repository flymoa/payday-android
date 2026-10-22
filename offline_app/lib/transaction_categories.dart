/// Presentation-only category choices. Persisted transaction types stay intact.
List<String> transactionCategories({required String type,
 required Iterable<String> configured,required Iterable<Map<String,Object?>> history,
 String? existingCategory}){
 final group=type.startsWith('Savings')?'Savings':type;
 const reserved=['salary','freelance','business','gifts','savings','other income','income plan','savings goal'];
 final expenseNames=configured.map((s)=>s.trim().toLowerCase()).toSet();
 bool matches(Map<String,Object?> row)=>group=='Savings'
  ?row['type'].toString().startsWith('Savings'):row['type']==type;
 bool allowed(String name){
  if(name.trim().isEmpty)return false;
  final normalized=name.trim().toLowerCase();
  if(group=='Expense')return !reserved.contains(normalized);
  return !expenseNames.contains(normalized)||normalized=='salary'||normalized=='savings';
 }
 final used=history.where(matches).map((r)=>r['category']?.toString()??'').where(allowed);
 final values=<String>{
  if(group=='Income')...['Salary','Freelance','Business','Gifts','Other income'],
  if(group=='Savings')'Savings',
  if(group=='Expense')...configured.where((name)=>!reserved.contains(name.trim().toLowerCase())),
  ...used,
  if(existingCategory!=null&&existingCategory.trim().isNotEmpty)existingCategory,
 };
 if(values.isEmpty)values.add(group=='Expense'?'Groceries':group=='Income'?'Salary':'Savings');
 return values.toList();
}
