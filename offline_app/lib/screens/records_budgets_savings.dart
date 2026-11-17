// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _RecordsBudgetsSavings on _FinanceState {
 /// One record row. Money coming in is green with a plus; money going out is ink with a minus.
 Widget recordTile(RowData t,{bool showWallet=false,int afterId=0}){
  final type=st(t,'type'),category=st(t,'category');
  final incoming=type=='Income'||type=='Savings in';
  return Material(color:Colors.transparent,child:InkWell(onTap:()=>transactionForm(t),
   // The amount may use up to 40% of the row itself (not of the screen), then shrinks.
   child:Padding(padding:EdgeInsets.symmetric(horizontal:14,vertical:11),child:LayoutBuilder(builder:(context,box)=>Row(children:[
    PaydayCategoryIcon(category,size:40),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(st(t,'description').isEmpty?categoryLabel(context,category):st(t,'description'),
      maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     SizedBox(height:3),
     LText('${categoryLabel(context,category)} · ${tr(context,type)}${showWallet&&val(t,'id')>afterId?' · ${tr(context,st(t,'account')=='Bank'?'Bank':'Cash')}':''}',maxLines:2,overflow:TextOverflow.ellipsis,
      style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.4),
     child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
      child:LText('${incoming?'+':'−'}${money(val(t,'amount'))}',
       style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w700,color:incoming?jade:ink)))),
   ])))));
 }
 /// Records grouped by day, newest first, each day in its own panel.
 List<Widget> recordDays(List<RowData> rows,{WalletSetup? wallets}){
  final now=DateTime.now();
  final today=dayKey(now),yesterday=dayKey(DateTime(now.year,now.month,now.day-1));
  final days=<String,List<RowData>>{};
  for(final t in rows){days.putIfAbsent(st(t,'date'),()=><RowData>[]).add(t);}
  return [
   for(final entry in days.entries)...[
    Padding(padding:EdgeInsetsDirectional.fromSTEB(6,12,6,8),child:Row(children:[
     Expanded(child:LText(entry.key==today?'Today':entry.key==yesterday?'Yesterday':displayDay(context,entry.key),
      style:TextStyle(color:muted,fontWeight:FontWeight.w800,fontSize:PaydayType.small))),
     if(sumType(entry.value,'Expense')>0)...[SizedBox(width:8),Expanded(child:LText('Spent ${money(sumType(entry.value,'Expense'))}',
      textAlign:TextAlign.end,style:TextStyle(color:muted,fontSize:PaydayType.caption)))],
    ])),
    PaydayPanel(padding:EdgeInsets.zero,child:Column(children:[
     for(var i=0;i<entry.value.length;i++)...[
      if(i>0)Divider(height:1,thickness:1,indent:14,endIndent:14,color:line),
      recordTile(entry.value[i],showWallet:wallets!=null,afterId:wallets?.afterId??0),
     ],
    ])),
   ],
  ];
 }
 Widget records(Map<String,List<RowData>> d){
  final all=recordAllMonths?(list(d,'transactions').toList()..sort((a,b){final x=st(b,'date').compareTo(st(a,'date'));return x!=0?x:val(b,'id').compareTo(val(a,'id'));})):monthTransactions(d);
  final ts=all.where((t)=>(matchesRecord(t,recordQuery,recordType)||(recordType=='All'||st(t,'type')==recordType)&&categoryLabel(context,st(t,'category')).toLowerCase().contains(recordQuery.trim().toLowerCase()))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Transactions',subtitle:recordAllMonths?'${ts.length} of ${all.length} entries · All months':'${ts.length} of ${all.length} entries · ${monthLabel(selected)}'),
   TextField(controller:search,onChanged:(v)=>setState(()=>recordQuery=v),
    style:TextStyle(fontSize:13),
    decoration:InputDecoration(hintText:tr(context,'Search records'),isDense:true,fillColor:surface,
     contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:10),
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
 Widget planRow(String title,String subtitle,String value,VoidCallback onTap)=>ListTile(
  contentPadding:EdgeInsets.symmetric(horizontal:14,vertical:4),leading:PaydayCategoryIcon(title),
  title:LText(title,style:TextStyle(fontWeight:FontWeight.w700)),
  subtitle:LText(subtitle,maxLines:2,overflow:TextOverflow.ellipsis),
  trailing:LText(value,style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,color:ink)),onTap:onTap);
 Widget budgets(Map<String,List<RowData>> d){
  final categories=spendingCategories(d),ts=monthTransactions(d);
  final assigned=assignedBudgetCents(list(d,'budgets'),month);
  final inc=budgetFor(d,month,'Income plan'),goal=budgetFor(d,month,'Savings goal'),left=inc-assigned;
  Widget figure(String label,String value,{Color? color,bool end=false})=>Expanded(child:Column(
   crossAxisAlignment:end?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[
    LText(label,maxLines:1,style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),SizedBox(height:2),
    FittedBox(fit:BoxFit.scaleDown,alignment:end?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,
     child:LText(value,style:TextStyle(fontFamily:'Bricolage',fontSize:17,fontWeight:FontWeight.w800,color:color??ink))),
   ]));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // How much of the planned income already has a job.
   PaydayPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     figure('Planned income',money(inc)),SizedBox(width:8),
     figure('Budgeted',money(assigned)),SizedBox(width:8),
     figure(left<0?'Over-assigned':'Not assigned',money(left.abs()),color:left<0?danger:jade,end:true),
    ]),
    SizedBox(height:12),
    PaydayProgress(value:inc<=0?(assigned>0?1.0:0.0):assigned/inc,color:assigned>inc?danger:jade),
    SizedBox(height:10),
    LText(
     inc==0&&assigned==0?'Set planned income to start assigning your budget.':
     inc==assigned?'No more money to assign. Your income is fully assigned.':
     assigned>inc?'Over-assigned by ${money(assigned-inc)}. Reduce budgets or increase planned income.':
     'Available to assign: ${money(inc-assigned)}',
     style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:inc-assigned>=0?muted:danger)),
   ])),
   header('Spending categories'),
   if(categories.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending or category budgets for this month.')
   else PaydayPanel(padding:EdgeInsets.zero,child:Column(children:[
    for(var i=0;i<categories.length;i++)...[
     if(i>0)Divider(height:1,thickness:1,indent:14,endIndent:14,color:line),
     Builder(builder:(_){
      final name=st(categories[i],'name');
      final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
      return homeCategory(name,spent,budgetFor(d,month,name),onTap:()=>budgetForm(d,name));
     }),
    ],
   ])),
   SizedBox(height:10),
   Wrap(spacing:8,runSpacing:8,children:[
    FilledButton.tonalIcon(onPressed:()=>categoryForm(),icon:PaydayAppIcon(Icons.add),label:LText('Add category')),
    OutlinedButton.icon(onPressed:()=>copyBudgetForm(d),icon:PaydayAppIcon(Icons.copy_outlined),label:LText('Copy last month’s budget')),
   ]),
   header('Income & savings plan'),
   PaydayPanel(padding:EdgeInsets.zero,child:Material(color:Colors.transparent,child:Column(children:[
    planRow('Income plan','Expected monthly income',money(inc),()=>budgetForm(d,'Income plan')),
    Divider(height:1,thickness:1,indent:14,endIndent:14,color:line),
    planRow('Savings goal','Monthly savings target',money(goal),()=>budgetForm(d,'Savings goal')),
   ]))),
  ]);
 }
 Widget savings(Map<String,List<RowData>> d){
  final pool=totalPool(d),used=allocated(d),goals=list(d,'goals'),allocations=list(d,'allocations');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // Everything saved so far, on emerald like Home, and how much of it has no goal yet.
   Container(width:double.infinity,padding:EdgeInsets.all(20),decoration:BoxDecoration(
     gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[PaydayColors.heroTop,PaydayColors.heroBottom]),
     borderRadius:BorderRadius.circular(PaydayRadius.hero)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText('Total saved',style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700)),
     SizedBox(height:8),
     FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
      child:LText(money(pool),style:TextStyle(fontFamily:'Bricolage',fontSize:34,fontWeight:FontWeight.w800,color:paydaySand))),
     SizedBox(height:12),
     PaydayProgress(value:pool<=0?0.0:used/pool,color:paydaySaffron,trackColor:paydaySand.withValues(alpha:.18)),
     SizedBox(height:10),
     Row(children:[Expanded(child:LText('Unassigned',style:TextStyle(color:PaydayColors.heroMuted))),SizedBox(width:8),
      Expanded(child:LText(money(pool-used),textAlign:TextAlign.end,style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,color:paydaySand)))]),
    ])),
   Padding(padding:EdgeInsets.fromLTRB(4,8,4,0),child:LText('Allocations divide your savings; they never add new savings',
    style:TextStyle(color:muted,fontSize:PaydayType.caption))),
   header('Your goals',action:FilledButton.tonalIcon(onPressed:()=>goalForm(null),icon:PaydayAppIcon(Icons.add),label:LText('New'))),
   if(goals.isEmpty)PaydayEmpty(icon:Icons.savings_outlined,message:'No savings goals yet. Tap New to add one.'),
   ...goals.map((g){final sum=allocations.where((x)=>val(x,'goal_id')==val(g,'id')).fold(0,(n,x)=>n+val(x,'amount'));
    final target=val(g,'target');return PaydayPanel(margin:EdgeInsets.only(bottom:10),padding:EdgeInsetsDirectional.fromSTEB(16,8,8,8),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(st(g,'name'),style:TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:ink))),IconButton(tooltip:tr(context,'Edit goal'),onPressed:()=>goalForm(g),icon:PaydayAppIcon(Icons.edit_outlined))]),
    Padding(padding:EdgeInsetsDirectional.only(end:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText('${money(sum)} / ${money(target)}',style:TextStyle(color:muted)),
     SizedBox(height:9),PaydayProgress(value:target<=0?0.0:sum/target),
     SizedBox(height:7),LText('Still needed: ${money((target-sum).clamp(0,target).toInt())}',style:TextStyle(fontWeight:FontWeight.w600)),
    ])),
    Align(alignment:AlignmentDirectional.centerEnd,child:TextButton.icon(onPressed:()=>allocationForm(d,g),icon:PaydayAppIcon(Icons.add),label:LText('Allocate'))),
   ]));}),
   header('Allocations for ${monthLabel(selected)}'),
   ...allocations.where((x)=>st(x,'month')==month).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;return tile(g==null?tr(context,'Goal deleted'):st(g,'name'),month,money(val(a,'amount')),rawTitle:true,onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))),icon:Icons.check_circle_outline);}),
   if(allocations.where((x)=>st(x,'month')==month).isEmpty)Padding(padding:EdgeInsets.all(10),child:LText('After closing the month, allocate confirmed savings to your goals.')),
   SizedBox(height:10),FilledButton.tonalIcon(onPressed:()=>openTool(4),icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText('Review ${monthLabel(selected)}'))
  ]);
 }
}
