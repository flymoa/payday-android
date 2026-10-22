/// Presentation-only category choices. Persisted transaction types stay intact.
List<String> transactionCategories({required String type,
 required Iterable<String> configured,required Iterable<Map<String,Object?>> history,
 String? existingCategory}){
 final group=type.startsWith('Savings')?'Savings':type;
 bool matches(Map<String,Object?> row)=>group=='Savings'
  ?row['type'].toString().startsWith('Savings'):row['type']==type;
 final expenseNames=configured.map((s)=>s.trim().toLowerCase()).toSet();
 final used=history.where(matches).map((r)=>r['category']?.toString()??'').where((s)=>s.trim().isNotEmpty&&(group=='Expense'||!expenseNames.contains(s.trim().toLowerCase())||s=='Salary'||s=='Savings'));
 final values=<String>{
  if(group=='Income')...['Salary','Freelance','Business','Gifts','Other income'],
  if(group=='Savings')'Savings',
  if(group=='Expense')...configured.where((name)=>!['salary','freelance','business','gifts','savings','other income','income plan','savings goal'].contains(name.trim().toLowerCase())),
  ...used,
  if(existingCategory!=null&&existingCategory.trim().isNotEmpty)existingCategory,
 };
 if(values.isEmpty)values.add(group=='Expense'?'Groceries':group=='Income'?'Salary':'Savings');
 return values.toList();
}
