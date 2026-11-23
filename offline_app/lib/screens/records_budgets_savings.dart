// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _RecordsBudgetsSavings on _FinanceState {
 /// One record row. Money coming in is green with a plus; money going out is ink with a minus.
 /// The day is the section header, so the second line never repeats it; without a
 /// description the category is already the title, so only the wallet (or a savings
 /// direction) is left to say.
 Widget recordTile(RowData t,{bool showWallet=false,int afterId=0}){
  final type=st(t,'type'),category=st(t,'category');
  final incoming=type=='Income'||type=='Savings in';
  final detail=rowDetail(t);
  final subtitle=detail.isNotEmpty?detail:type.startsWith('Savings')?tr(context,type):'';
  return Material(color:Colors.transparent,child:InkWell(onTap:()=>transactionForm(t),
   // The amount may use up to 40% of the row itself (not of the screen), then shrinks.
   child:Padding(padding:EdgeInsets.symmetric(horizontal:PaydaySpace.md+2,vertical:PaydaySpace.md),child:LayoutBuilder(builder:(context,box)=>Row(children:[
    PaydayCategoryIcon(category,size:40),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(st(t,'description').isEmpty?categoryLabel(context,category):st(t,'description'),
      maxLines:2,overflow:TextOverflow.ellipsis,style:PaydayText.rowTitle.copyWith(color:ink)),
     if(subtitle.isNotEmpty)...[SizedBox(height:3),
      LText(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:PaydayType.caption,color:muted))],
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.4),
     child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
      child:LText('${incoming?'+':'−'}${listMoney(val(t,'amount'))}',
       style:PaydayText.amount.copyWith(color:incoming?jade:ink)))),
   ])))));
 }
 /// Records grouped by day, newest first, each day in its own panel.
 List<Widget> recordDays(List<RowData> rows,{WalletSetup? wallets,bool showHeaders=true}){
  final now=DateTime.now();
  final today=dayKey(now),yesterday=dayKey(DateTime(now.year,now.month,now.day-1));
  final days=<String,List<RowData>>{};
  for(final t in rows){days.putIfAbsent(st(t,'date'),()=><RowData>[]).add(t);}
  return [
   for(final entry in days.entries)...[
    if(showHeaders)Padding(padding:EdgeInsetsDirectional.fromSTEB(6,12,6,6),child:Text(
     (entry.key==today?'${tr(context,'Today')} · ${shortDay(entry.key)}':entry.key==yesterday?'${tr(context,'Yesterday')} · ${shortDay(entry.key)}':shortDay(entry.key)).toUpperCase(),
     style:TextStyle(color:muted,fontWeight:FontWeight.w700,fontSize:PaydayType.caption,letterSpacing:language=='ar'?0:.4))),
    groupedRows(card:true,[for(final t in entry.value)recordTile(t,showWallet:wallets!=null,afterId:wallets?.afterId??0)]),
   ],
  ];
 }
 Widget records(Map<String,List<RowData>> d){
  final all=recordAllMonths?(list(d,'transactions').toList()..sort((a,b){final x=st(b,'date').compareTo(st(a,'date'));return x!=0?x:val(b,'id').compareTo(val(a,'id'));})):monthTransactions(d);
  final ts=all.where((t)=>(matchesRecord(t,recordQuery,recordType)||(recordType=='All'||st(t,'type')==recordType)&&categoryLabel(context,st(t,'category')).toLowerCase().contains(recordQuery.trim().toLowerCase()))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   TextField(controller:search,onChanged:(v)=>setState(()=>recordQuery=v),
    style:TextStyle(fontSize:PaydayType.body),
    decoration:InputDecoration(hintText:tr(context,'Search records'),isDense:true,
     contentPadding:EdgeInsets.symmetric(horizontal:14,vertical:12),
     prefixIconConstraints:BoxConstraints(minWidth:36,minHeight:36),
     suffixIconConstraints:BoxConstraints(minWidth:PaydayControl.target,minHeight:PaydayControl.target),
     prefixIcon:Padding(padding:EdgeInsets.all(9),child:PaydayAppIcon(Icons.search,size:18,color:muted)),
     suffixIcon:recordQuery.isEmpty?null:IconButton(
      tooltip:tr(context,'Clear search'),style:IconButton.styleFrom(minimumSize:const Size(PaydayControl.target,PaydayControl.target)),icon:PaydayAppIcon(Icons.close,size:16),
      onPressed:(){search.clear();setState(()=>recordQuery='');}))),
   SizedBox(height:10),
   SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:
    [Padding(padding:EdgeInsetsDirectional.only(end:8),child:PaydayPill(key:ValueKey('records-all-months'),label:'All months',
      selected:recordAllMonths,onTap:()=>setState(()=>recordAllMonths=!recordAllMonths))),
    ...['All','Expense','Income','Savings out','Savings in'].map((type)=>Padding(
     padding:EdgeInsetsDirectional.only(end:8),child:PaydayPill(label:type,
      selected:recordType==type,onTap:()=>setState(()=>recordType=type))))])),
   SizedBox(height:4),
   ...recordDays(ts,wallets:WalletSetup.decode(Ledger(d).setting(walletSetupKey))),
   if(ts.isEmpty)Padding(padding:EdgeInsets.only(top:10),child:PaydayEmpty(icon:Icons.receipt_long_outlined,message:all.isEmpty?
    'Nothing yet this month. Tap + to add your first expense.':
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
 /// Name and budget on top, a progress bar, then spent and remaining centred on
 /// their own wrapping line, so nothing is cut off however long the amounts are.
 /// Allocate to a goal or change it.
 Future<void> goalActions(Map<String,List<RowData>> d,RowData g)async{
  await sheet(st(g,'name'),(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   FilledButton.icon(key:ValueKey('goal-allocate'),onPressed:(){Navigator.pop(c);allocationForm(d,g);},icon:PaydayAppIcon(Icons.add),label:LText('Allocate')),
   SizedBox(height:8),
   OutlinedButton.icon(key:ValueKey('goal-edit'),onPressed:(){Navigator.pop(c);goalForm(g);},icon:PaydayAppIcon(Icons.edit_outlined),label:LText('Edit goal')),
  ]));
 }
 /// Plan rows use the shared row, so long amounts shrink instead of breaking the layout.
 Widget planRow(String title,String subtitle,String value,VoidCallback onTap)=>listRow(onTap:onTap,
  leading:PaydayCategoryIcon(title,size:38),title:rowTitle(title),subtitle:subtitle,amount:value);
 Widget budgets(Map<String,List<RowData>> d){
  final categories=spendingCategories(d),ts=monthTransactions(d);
  final assigned=assignedBudgetCents(list(d,'budgets'),month);
  final inc=budgetFor(d,month,'Income plan'),goal=budgetFor(d,month,'Savings goal'),left=inc-assigned;
  final quiet=TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w600,fontFeatures:PaydayText.tabular);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // How much of the planned income already has a job. One figure leads ("Not
   // assigned"); the two inputs that produce it sit under it as a quiet line.
   Padding(key:ValueKey('budget-summary'),padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.sm,PaydaySpace.xs,PaydaySpace.lg),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText(left<0?'Over-assigned':'Not assigned',style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),
    SizedBox(height:PaydaySpace.xs),
    FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText(summaryMoney(left.abs()),key:ValueKey('budget-not-assigned'),maxLines:1,
     style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.figure,fontWeight:FontWeight.w800,letterSpacing:-.5,fontFeatures:PaydayText.tabular,color:left<0?danger:jade))),
    SizedBox(height:PaydaySpace.xs),
    Wrap(spacing:PaydaySpace.md,runSpacing:PaydaySpace.xs,children:[
     LText('{0} {1}'.replaceAll('{0}',tr(context,'Planned income')).replaceAll('{1}',summaryMoney(inc)),style:quiet),
     LText('{0} {1}'.replaceAll('{0}',tr(context,'Budgeted')).replaceAll('{1}',summaryMoney(assigned)),style:quiet),
    ]),
    // What is still unspent across the category budgets this month.
    Builder(builder:(_){
     var budgeted=0,left=0;
     for(final c in categories){
      final name=st(c,'name'),b=budgetFor(d,month,name);
      if(b<=0)continue;
      final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
      budgeted+=b;left+=(b-spent).clamp(0,b);
     }
     if(budgeted<=0)return const SizedBox.shrink();
     // On the page, under a hairline: a summary, not a separate object.
     return Padding(padding:EdgeInsets.only(top:PaydaySpace.lg),child:DecoratedBox(decoration:BoxDecoration(border:Border(top:BorderSide(color:line))),
      child:Padding(key:ValueKey('budget-left'),padding:EdgeInsets.only(top:PaydaySpace.md),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Wrap(alignment:WrapAlignment.spaceBetween,spacing:8,children:[
        LText('Left to spend in your budgets',style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),
        LText('{0}% used'.replaceAll('{0}','${((budgeted-left)*100/budgeted).round()}'),style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),
       ]),
       SizedBox(height:4),
       FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText('{0} of {1}'.replaceAll('{0}',summaryMoney(left)).replaceAll('{1}',summaryMoney(budgeted)),key:ValueKey('budget-left-amount'),style:PaydayText.amount.copyWith(color:left>0?ink:danger))),
       SizedBox(height:8),
       PaydayProgress(value:((budgeted-left)/budgeted).clamp(0,1).toDouble(),color:left>0?jade:danger),
      ]))));
    }),
    if(inc==0&&assigned==0||assigned>inc)...[SizedBox(height:10),LText(
     inc==0&&assigned==0?'Set planned income to start assigning your budget.':
     'Over-assigned by ${money(assigned-inc)}. Reduce budgets or increase planned income.',
     style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:assigned>inc?danger:muted))],
   ])),
   budgetAlertBanner(d),
   if(categories.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending or category budgets for this month.')
   else groupedRows([for(final c in categories)Builder(builder:(_){
    final name=st(c,'name');
    final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    return homeCategory(name,spent,budgetFor(d,month,name),onTap:()=>budgetForm(d,name));
   })]),
   listAction('Add category',Icons.add,()=>categoryForm()),
   Align(alignment:AlignmentDirectional.centerStart,child:TextButton.icon(onPressed:()=>copyBudgetForm(d),
    icon:PaydayAppIcon(Icons.copy_outlined,size:18),label:LText('Copy last month’s budget'))),
   header('Income & savings plan'),
   groupedRows([
    planRow('Income plan','expected monthly income',listMoney(inc),()=>budgetForm(d,'Income plan')),
    planRow('Savings goal','Monthly savings target',listMoney(goal),()=>budgetForm(d,'Savings goal')),
   ]),
  ]);
 }
 Widget savings(Map<String,List<RowData>> d){
  final pool=totalPool(d),used=allocated(d),goals=list(d,'goals'),allocations=list(d,'allocations');
  // Savings has no month switcher, so everything here is the current month.
  // Reading the month picked on another tab showed allocations for the wrong month.
  final now=DateTime.now(),current=monthKey(now);
  final thisMonth=balanceFor(d,current).savingsNet;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // Everything saved so far, on emerald like Home.
   Container(key:ValueKey('savings-hero'),width:double.infinity,padding:EdgeInsets.all(20),decoration:BoxDecoration(
     color:PaydayColors.hero,
     borderRadius:BorderRadius.circular(PaydayRadius.hero)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText('Total saved',style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700)),
     SizedBox(height:6),
     // Same split amount as the Home hero: integer large, decimals and currency small.
     heroAmount(pool,color:paydaySand,quiet:PaydayColors.heroMuted,key:ValueKey('savings-total')),
     SizedBox(height:4),
     LText('${thisMonth>=0?'+':'−'}${summaryMoney(thisMonth.abs())} this month',style:TextStyle(color:PaydayColors.heroMuted)),
     if(pool-used>0)LText('Unassigned: ${summaryMoney(pool-used)}',style:TextStyle(color:PaydayColors.heroMuted,fontSize:PaydayType.caption)),
    ])),
   SizedBox(height:12),
   Row(children:[
    Expanded(child:FilledButton.icon(key:ValueKey('savings-add'),style:FilledButton.styleFrom(minimumSize:Size.fromHeight(50)),
     onPressed:()=>transactionForm(null,initialType:'Savings out'),icon:PaydayAppIcon(Icons.add,size:20),label:LText('Add money'))),
    SizedBox(width:8),
    Expanded(child:OutlinedButton.icon(key:ValueKey('savings-take'),style:OutlinedButton.styleFrom(minimumSize:Size.fromHeight(50)),
     onPressed:()=>transactionForm(null,initialType:'Savings in'),icon:PaydayAppIcon(Icons.repeat,size:20),label:LText('Take out'))),
   ]),
   header('Goals',action:TextButton(key:ValueKey('goal-new'),onPressed:()=>goalForm(null),child:LText('New goal',style:TextStyle(fontWeight:FontWeight.w700)))),
   if(goals.isEmpty)PaydayEmpty(icon:Icons.savings_outlined,message:'No savings goals yet. Tap New to add one.')
   else groupedRows([for(final g in goals)Builder(builder:(_){
    final sum=allocations.where((x)=>val(x,'goal_id')==val(g,'id')).fold(0,(n,x)=>n+val(x,'amount'));
    final target=val(g,'target');
    return listRow(key:ValueKey('goal-${val(g,'id')}'),onTap:()=>goalActions(d,g),leading:iconTile(Icons.savings_outlined),
     title:rowTitle(st(g,'name'),raw:true),subtitle:'${summaryMoney(sum)} / ${summaryMoney(target)}',
     amount:'${target<=0?0:(sum*100/target).clamp(0,100).round()}%',progress:target<=0?0.0:sum/target);
   })]),
   SizedBox(height:8),
   header('Allocations for ${monthLabel(now)}'),
   if(allocations.any((x)=>st(x,'month')==current))groupedRows([...allocations.where((x)=>st(x,'month')==current).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;
    return listRow(leading:iconTile(Icons.check_circle_outline,size:36),title:rowTitle(g==null?tr(context,'Goal deleted'):st(g,'name'),raw:true),
     subtitle:monthLabel(now),amount:listMoney(val(a,'amount')),onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))));})]),
   if(allocations.where((x)=>st(x,'month')==current).isEmpty)Padding(padding:EdgeInsets.all(10),child:LText('After closing the month, allocate confirmed savings to your goals.')),
   SizedBox(height:10),FilledButton.tonalIcon(onPressed:(){setState(()=>selected=DateTime(now.year,now.month));openTool(4);},icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText('Review ${monthLabel(now)}'))
  ]);
 }
}
