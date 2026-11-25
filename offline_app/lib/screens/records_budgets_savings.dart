// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _RecordsBudgetsSavings on _FinanceState {
 /// One record row. Money coming in is green with a plus; money going out is ink with a minus.
 Widget recordTile(RowData t,{bool showWallet=false,int afterId=0}){
  final type=st(t,'type'),category=st(t,'category');
  final incoming=type=='Income'||type=='Savings in'||type==kridiIn;
  return Material(color:Colors.transparent,child:InkWell(onTap:()=>transactionForm(t),
   // The amount may use up to 40% of the row itself (not of the screen), then shrinks.
   child:Padding(padding:EdgeInsets.symmetric(horizontal:PaydaySpace.md+2,vertical:PaydaySpace.md),child:LayoutBuilder(builder:(context,box)=>Row(children:[
    PaydayCategoryIcon(category,size:40),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(st(t,'description').isEmpty?categoryLabel(context,category):st(t,'description'),
      maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     SizedBox(height:3),
     LText('${categoryLabel(context,category)}${walletOf(t).isEmpty?' · ${tr(context,type)}':walletOf(t)}',maxLines:2,overflow:TextOverflow.ellipsis,
      style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.4),
     child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
      child:LText('${incoming?'+':'−'}${plain(val(t,'amount'))}',
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
    groupedRows([for(final t in entry.value)recordTile(t,showWallet:wallets!=null,afterId:wallets?.afterId??0)]),
   ],
  ];
 }
 Widget records(Map<String,List<RowData>> d){
  final all=recordAllMonths?(list(d,'transactions').toList()..sort((a,b){final x=st(b,'date').compareTo(st(a,'date'));return x!=0?x:val(b,'id').compareTo(val(a,'id'));})):monthTransactions(d);
  final ts=all.where((t)=>(matchesRecord(t,recordQuery,recordType)||(recordType=='All'||st(t,'type')==recordType)&&categoryLabel(context,st(t,'category')).toLowerCase().contains(recordQuery.trim().toLowerCase()))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   TextField(controller:search,onChanged:(v)=>setState(()=>recordQuery=v),
    style:TextStyle(fontSize:15),
    decoration:InputDecoration(hintText:tr(context,'Search records'),isDense:true,
     contentPadding:EdgeInsets.symmetric(horizontal:14,vertical:12),
     prefixIconConstraints:BoxConstraints(minWidth:36,minHeight:36),
     suffixIconConstraints:BoxConstraints(minWidth:36,minHeight:36),
     prefixIcon:Padding(padding:EdgeInsets.all(9),child:PaydayAppIcon(Icons.search,size:18,color:muted)),
     suffixIcon:recordQuery.isEmpty?null:IconButton(
      tooltip:tr(context,'Clear search'),visualDensity:VisualDensity.compact,icon:PaydayAppIcon(Icons.close,size:16),
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
  // Three figures spread across the full line: first at the start edge, middle centred, last at the end edge.
  Widget figure(String label,String value,{Color? color,int edge=-1}){
   final cross=edge<0?CrossAxisAlignment.start:edge>0?CrossAxisAlignment.end:CrossAxisAlignment.center;
   final align=edge<0?AlignmentDirectional.centerStart:edge>0?AlignmentDirectional.centerEnd:AlignmentDirectional.center;
   return Expanded(child:Column(crossAxisAlignment:cross,children:[
    FittedBox(fit:BoxFit.scaleDown,alignment:align,
     child:LText(label,maxLines:1,softWrap:false,style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700))),SizedBox(height:4),
    FittedBox(fit:BoxFit.scaleDown,alignment:align,
     child:LText(value,maxLines:1,style:PaydayText.figure.copyWith(color:color??ink))),
   ]));
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // How much of the planned income already has a job.
   Padding(key:ValueKey('budget-summary'),padding:EdgeInsetsDirectional.fromSTEB(0,PaydaySpace.sm,0,PaydaySpace.lg),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     figure('Planned income',plain(inc)),SizedBox(width:8),
     figure('Budgeted',plain(assigned),edge:0),SizedBox(width:8),
     figure(left<0?'Over-assigned':'Not assigned',plain(left.abs()),color:left<0?danger:jade,edge:1),
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
     // Three states: enough (green), under 100 DH a day until payday (amber), nothing left (red).
     // Never negative: once the budgets are spent there is simply nothing left.
     final now=DateTime.now();
     final current=selected.year==now.year&&selected.month==now.month;
     final days=current?cycleOf(d,now).daysToPayday(now).clamp(1,62).toInt():0;
     final perDay=days>0?left~/days:0;
     final empty=left<=0,low=!empty&&current&&perDay<10000;
     final tone=empty?danger:low?saffronText:jade;
     final title=empty?"You've spent all your budgets":low?'Not much left':'Left to spend in your budgets';
     final String? note;
     if(!current){note=null;}
     else if(empty){note=days==1?'Payday tomorrow':language=='ar'?'الراتب بعد ${arabicDays(days,after:true)}':'$days days to payday';}
     else{note='About ${localizedWhole(perDay,language)} ${currencyLabel(currency,language)} a day until payday';}
     return Padding(padding:EdgeInsets.only(top:PaydaySpace.md),child:Container(key:ValueKey('budget-left'),width:double.infinity,
      padding:EdgeInsets.all(PaydaySpace.md+2),
      decoration:BoxDecoration(color:tone.withValues(alpha:isDark?0.18:0.13),borderRadius:BorderRadius.circular(PaydayRadius.lg)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Row(children:[
        PaydayAppIcon(empty?Icons.close:low?Icons.info_outline:Icons.payments_outlined,size:18,color:tone),SizedBox(width:PaydaySpace.sm),
        Flexible(child:LText(title,key:ValueKey('budget-left-title'),maxLines:2,style:TextStyle(color:tone,fontSize:PaydayType.caption,fontWeight:FontWeight.w700))),
       ]),
       SizedBox(height:PaydaySpace.xs),
       FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText(money(left),key:ValueKey('budget-left-amount'),style:PaydayText.figure.copyWith(color:tone,fontSize:PaydayType.figure+4))),
       if(note!=null)Padding(padding:EdgeInsets.only(top:PaydaySpace.sm),child:Container(
        padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.sm+2,3,PaydaySpace.sm+2,3),
        decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(PaydayRadius.sm)),
        child:LText(note,key:ValueKey('budget-left-note'),style:TextStyle(color:tone,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)))),
      ])));
    }),
    if(inc==0&&assigned==0||assigned>inc)...[SizedBox(height:10),LText(
     inc==0&&assigned==0?'Set planned income to start assigning your budget.':
     'Over-assigned by ${money(assigned-inc)}. Reduce budgets or increase planned income.',
     style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:assigned>inc?danger:muted))],
   ])),
   budgetAlertBanner(d),
   if(categories.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending or category budgets for this month.')
   else groupedRows(separate:true,[for(final c in categories)Builder(builder:(_){
    final name=st(c,'name');
    final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    return homeCategory(name,spent,budgetFor(d,month,name),onTap:()=>budgetForm(d,name));
   })]),
   listAction('Add category',Icons.add,()=>categoryForm()),
   Align(alignment:AlignmentDirectional.centerStart,child:TextButton.icon(onPressed:()=>copyBudgetForm(d),
    icon:PaydayAppIcon(Icons.copy_outlined,size:18),label:LText('Copy last month’s budget'))),
   header('Income & savings plan'),
   groupedRows([
    planRow('Income plan','Expected monthly income',money(inc),()=>budgetForm(d,'Income plan')),
    planRow('Savings goal','Monthly savings target',money(goal),()=>budgetForm(d,'Savings goal')),
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
     FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
      child:LText(money(pool),style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.display,fontWeight:FontWeight.w800,color:paydaySand,letterSpacing:-1,fontFeatures:PaydayText.tabular))),
     SizedBox(height:4),
     LText('${thisMonth>=0?'+':'−'}${money(thisMonth.abs())} this month',style:TextStyle(color:PaydayColors.heroMuted)),
     if(pool-used>0)LText('Unassigned: ${money(pool-used)}',style:TextStyle(color:PaydayColors.heroMuted,fontSize:PaydayType.caption)),
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
     title:rowTitle(st(g,'name'),raw:true),subtitle:'${money(sum)} / ${money(target)}',
     amount:'${target<=0?0:(sum*100/target).clamp(0,100).round()}%',progress:target<=0?0.0:sum/target);
   })]),
   SizedBox(height:8),
   header('Allocations for ${monthLabel(now)}'),
   if(allocations.any((x)=>st(x,'month')==current))groupedRows([...allocations.where((x)=>st(x,'month')==current).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;return tile(divider:false,g==null?tr(context,'Goal deleted'):st(g,'name'),monthLabel(now),money(val(a,'amount')),rawTitle:true,onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))),icon:Icons.check_circle_outline);})]),
   if(allocations.where((x)=>st(x,'month')==current).isEmpty)Padding(padding:EdgeInsets.all(10),child:LText('After closing the month, allocate confirmed savings to your goals.')),
   SizedBox(height:10),FilledButton.tonalIcon(onPressed:(){setState(()=>selected=DateTime(now.year,now.month));openTool(4);},icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText('Review ${monthLabel(now)}'))
  ]);
 }
}
