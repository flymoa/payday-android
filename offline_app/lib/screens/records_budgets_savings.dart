// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _RecordsBudgetsSavings on _FinanceState {
 Widget recordTile(RowData t){final type=st(t,'type');return tile(st(t,'description').isEmpty?categoryLabel(context,st(t,'category')):st(t,'description'),'${displayDay(context,st(t,'date'))} · ${categoryLabel(context,st(t,'category'))} · ${tr(context,type)}',money(val(t,'amount')),rawTitle:true,leading:PaydayCategoryIcon(st(t,'category')),tone:type=='Income'?jade:amber,onTap:()=>transactionForm(t));}
 Widget records(Map<String,List<RowData>> d){
  final all=recordAllMonths?(list(d,'transactions').toList()..sort((a,b){final x=st(b,'date').compareTo(st(a,'date'));return x!=0?x:val(b,'id').compareTo(val(a,'id'));})):monthTransactions(d);
  final ts=all.where((t)=>(matchesRecord(t,recordQuery,recordType)||(recordType=='All'||st(t,'type')==recordType)&&categoryLabel(context,st(t,'category')).toLowerCase().contains(recordQuery.trim().toLowerCase()))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Transactions',subtitle:recordAllMonths?'${ts.length} of ${all.length} entries · All months':'${ts.length} of ${all.length} entries · ${monthLabel(selected)}'),
   TextField(controller:search,onChanged:(v)=>setState(()=>recordQuery=v),
    style:TextStyle(fontSize:13),
    decoration:InputDecoration(hintText:tr(context,'Search records'),isDense:true,
     contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:10),
     prefixIconConstraints:BoxConstraints(minWidth:36,minHeight:36),
     suffixIconConstraints:BoxConstraints(minWidth:36,minHeight:36),
     prefixIcon:Padding(padding:EdgeInsets.all(9),child:PaydayAppIcon(Icons.search,size:18,color:muted)),
     suffixIcon:recordQuery.isEmpty?null:IconButton(
      tooltip:tr(context,'Clear search'),visualDensity:VisualDensity.compact,icon:PaydayAppIcon(Icons.close,size:16),
      onPressed:(){search.clear();setState(()=>recordQuery='');}))),
   SizedBox(height:10),
   SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:
    [Padding(padding:EdgeInsetsDirectional.only(end:8),child:FilterChip(key:ValueKey('records-all-months'),label:LText('All months'),
      selected:recordAllMonths,onSelected:(v)=>setState(()=>recordAllMonths=v))),
    ...['All','Expense','Income','Savings out','Savings in'].map((type)=>Padding(
     padding:EdgeInsetsDirectional.only(end:8),child:ChoiceChip(label:LText(type),
      selected:recordType==type,onSelected:(_)=>setState(()=>recordType=type))))])),
   SizedBox(height:10),
   ...ts.map(recordTile),
   if(ts.isEmpty)Padding(padding:EdgeInsets.all(24),child:LText(all.isEmpty?
    'No entries this month. Tap + to add your first transaction.':
    'No matching entries. Change the search or type filter.')),
  ]);
 }
 List<String> hiddenCategories(Map<String,List<RowData>> d){
  final row=list(d,'settings').where((r)=>st(r,'key')=='hidden_categories').firstOrNull;
  return row==null?<String>[]:List<String>.from(jsonDecode(st(row,'value')));
 }
 List<String> categoryChoices(Map<String,List<RowData>> d,String type,{String? existing})=>transactionCategories(
  type:type,configured:list(d,'categories').where((r)=>st(r,'group_name')!='Income').map((r)=>st(r,'name')),
  incomeConfigured:list(d,'categories').where((r)=>st(r,'group_name')=='Income').map((r)=>st(r,'name')),
  hidden:hiddenCategories(d),history:list(d,'transactions'),existingCategory:existing);
 List<RowData> spendingCategories(Map<String,List<RowData>> d){
  final rows=list(d,'categories').where((r)=>st(r,'group_name')!='Income').toList();
  for(final b in list(d,'budgets').where((r)=>st(r,'month')==month&&val(r,'amount')>0)){
   final name=st(b,'category');
   if(!['Income plan','Savings goal'].contains(name)&&!rows.any((r)=>st(r,'name')==name)){
    rows.add({'name':name,'group_name':'Previous category'});
   }
  }
  return rows;
 }
 /// Name and budget on top, then spent and remaining on their
 /// own wrapping line, so nothing is cut off however long the amounts are.
 Widget budgetCategoryCard(String name,String group,int spent,int budget,VoidCallback onTap){
  final over=budget>0&&spent>budget;
  final status=budget<=0?(spent>0?'No budget set':''):over?'Over by ${money(spent-budget)}':spent==budget?'Fully spent':'Left ${money(budget-spent)}';
  final tone=over?Colors.deepOrange:jade;
  return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Padding(padding:EdgeInsets.fromLTRB(14,12,14,12),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
     PaydayCategoryIcon(name,size:38),SizedBox(width:12),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      LText(name,category:true,style:TextStyle(fontWeight:FontWeight.w700)),
      LText(group,style:TextStyle(color:muted,fontSize:12)),
     ])),
     SizedBox(width:8),
     Flexible(child:LText(money(budget),textAlign:TextAlign.end,style:TextStyle(fontWeight:FontWeight.w800,color:ink))),
    ]),
    if(budget>0||spent>0)...[
     SizedBox(height:8),
     Wrap(spacing:14,runSpacing:2,children:[
      LText('Spent ${money(spent)}',style:TextStyle(color:muted,fontSize:13)),
      if(status.isNotEmpty)LText(status,style:TextStyle(color:tone,fontSize:13,fontWeight:FontWeight.w700)),
     ]),
    ],
   ]))));
 }
 Widget budgets(Map<String,List<RowData>> d){
  final categories=spendingCategories(d),ts=monthTransactions(d);
  final assigned=assignedBudgetCents(list(d,'budgets'),month);
  final inc=budgetFor(d,month,'Income plan'),goal=budgetFor(d,month,'Savings goal');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Monthly budget',subtitle:'A separate plan for ${monthLabel(selected)}'),
   OutlinedButton.icon(onPressed:()=>copyBudgetForm(d),icon:PaydayAppIcon(Icons.copy_outlined),label:LText('Copy last month’s budget')),
   SizedBox(height:8),
   Row(children:[metric('Planned income',money(inc),Icons.trending_up),metric('Assigned',money(assigned),Icons.check_circle_outline)]),
   Card(child:Padding(padding:EdgeInsets.all(16),child:LText(
    inc==0&&assigned==0?'Set planned income to start assigning your budget.':
    inc==assigned?'No more money to assign. Your income is fully assigned.':
    assigned>inc?'Over-assigned by ${money(assigned-inc)}. Reduce budgets or increase planned income.':
    'Available to assign: ${money(inc-assigned)}',
    style:TextStyle(fontWeight:FontWeight.bold,color:inc-assigned>=0?jade:Colors.deepOrange)))),
   tile('Income plan','Expected monthly income',money(inc),leading:PaydayCategoryIcon('Income plan'),onTap:()=>budgetForm(d,'Income plan')),
   tile('Savings goal','Monthly savings target',money(goal),leading:PaydayCategoryIcon('Savings goal'),onTap:()=>budgetForm(d,'Savings goal')),
   header('Spending categories'),
   ...categories.map((c){final name=st(c,'name'),b=budgetFor(d,month,name);
    final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    return budgetCategoryCard(name,st(c,'group_name'),spent,b,()=>budgetForm(d,name));
   }),
   SizedBox(height:12),FilledButton.tonalIcon(onPressed:()=>categoryForm(),icon:PaydayAppIcon(Icons.add),label:LText('Add category'))
  ]);
 }
 Widget savings(Map<String,List<RowData>> d){
  final pool=totalPool(d),used=allocated(d),goals=list(d,'goals'),allocations=list(d,'allocations');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Savings & goals',subtitle:'Allocations divide your savings; they never add new savings'),
   Row(children:[metric('Total saved',money(pool),Icons.account_balance_wallet_outlined),metric('Unassigned',money(pool-used),Icons.savings_outlined)]),
   header('Your goals',action:FilledButton.tonalIcon(onPressed:()=>goalForm(null),icon:PaydayAppIcon(Icons.add),label:LText('New'))),
   ...goals.map((g){final sum=allocations.where((x)=>val(x,'goal_id')==val(g,'id')).fold(0,(n,x)=>n+val(x,'amount'));
    final target=val(g,'target');return Card(child:Padding(padding:EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(st(g,'name'),style:TextStyle(fontWeight:FontWeight.w800))),IconButton(tooltip:tr(context,'Edit goal'),onPressed:()=>goalForm(g),icon:PaydayAppIcon(Icons.edit_outlined))]),
    LText('${money(sum)} / ${money(target)}',style:TextStyle(color:muted)),
    SizedBox(height:9),LinearProgressIndicator(value:(sum/target).clamp(0,1).toDouble(),minHeight:8,borderRadius:BorderRadius.circular(8)),
    SizedBox(height:5),LText('Still needed: ${money((target-sum).clamp(0,target).toInt())}'),
    Align(alignment:AlignmentDirectional.centerEnd,child:TextButton.icon(onPressed:()=>allocationForm(d,g),icon:PaydayAppIcon(Icons.add),label:LText('Allocate'))),
   ])));}),
   header('Allocations for ${monthLabel(selected)}'),
   ...allocations.where((x)=>st(x,'month')==month).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;return tile(g==null?tr(context,'Goal deleted'):st(g,'name'),month,money(val(a,'amount')),rawTitle:true,onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))),icon:Icons.check_circle_outline);}),
   if(allocations.where((x)=>st(x,'month')==month).isEmpty)Padding(padding:EdgeInsets.all(10),child:LText('After closing the month, allocate confirmed savings to your goals.')),
   SizedBox(height:10),FilledButton.tonalIcon(onPressed:()=>setState((){page=4;moreSection=4;}),icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText('Review ${monthLabel(selected)}'))
  ]);
 }
}
