// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _MoreScreen on _FinanceState {
 List<Widget> spendingBreakdown(Map<String,List<RowData>> d,MonthlyReview review){
  final total=review.spending.values.fold<int>(0,(n,v)=>n+v);
  if(total<=0)return const [];
  final previous=MonthlyReview(monthTransactionsFor(d,monthKey(DateTime(selected.year,selected.month-1)))).spending;
  return review.rankedCategories.map((c){
   final spent=review.spending[c]!,before=previous[c]??0,share=spent/total;
   final change=before<=0?'New this month':spent>=before?'+${money(spent-before)} vs last month':'−${money(before-spent)} vs last month';
   return InkWell(key:ValueKey('category-history-$c'),borderRadius:BorderRadius.circular(PaydayRadius.sm),onTap:()=>categoryHistory(d,c),
    child:Padding(padding:EdgeInsets.symmetric(vertical:6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:LText(categoryLabel(context,c),style:TextStyle(fontWeight:FontWeight.w700))),
     LText('${money(spent)} · ${(share*100).round()}%',style:TextStyle(fontWeight:FontWeight.w700))]),
    SizedBox(height:5),
    LinearProgressIndicator(value:share,minHeight:8,borderRadius:BorderRadius.circular(PaydayRadius.sm)),
    SizedBox(height:3),LText(change,style:TextStyle(color:muted,fontSize:12)),
   ])));
  }).toList();
 }
 Widget monthlyReview(Map<String,List<RowData>> d){
  final balance=monthlyBalance(d);
  final tx=monthTransactions(d);
  final review=MonthlyReview(tx);
  final closed=list(d,'month_closes').any((r)=>st(r,'month')==month&&val(r,'entries_ok')==1&&val(r,'balance_ok')==1);
  final ended=selected.isBefore(DateTime(DateTime.now().year,DateTime.now().month));
  final categories={...list(d,'budgets').where((r)=>st(r,'month')==month)
   .map((r)=>st(r,'category')).where((c)=>c!='Income plan'&&c!='Savings goal'),...review.spending.keys};
  final over=categories.where((c)=>budgetFor(d,month,c)>0&&(review.spending[c]??0)>budgetFor(d,month,c)).toList()..sort();
  final unbudgeted=review.spending.keys.where((c)=>budgetFor(d,month,c)<=0).toList()..sort();
  Widget lineItem(String label,int value)=>Padding(padding:EdgeInsets.symmetric(vertical:8),
   child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:LText(label)),
    SizedBox(width:12),Flexible(child:LText(money(value),textAlign:TextAlign.end,
     style:TextStyle(fontWeight:FontWeight.w700)))]));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Monthly review',subtitle:'Recorded activity for ${monthLabel(selected)}'),
   Row(children:[IconButton(tooltip:tr(context,'Previous month'),onPressed:()=>shift(-1),icon:PaydayAppIcon(Icons.chevron_left)),
    Expanded(child:LText(monthLabel(selected),textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold))),
    IconButton(tooltip:tr(context,'Next month'),onPressed:()=>shift(1),icon:PaydayAppIcon(Icons.chevron_right))]),
   LText(closed?'Month-close checks saved':ended?'Ready to review':'Month in progress',style:TextStyle(color:jade,fontWeight:FontWeight.w700)),
   if(tx.isEmpty)Padding(padding:EdgeInsets.symmetric(vertical:12),child:LText('No transactions recorded for this month. Bills and plans can still have outstanding amounts.')),
   Card(child:Padding(padding:EdgeInsets.all(16),child:Column(children:[
    lineItem('Income received',balance.income),lineItem('Spending',balance.expenses),
    lineItem('Net savings transfers',balance.savingsNet),lineItem('Net reserve transfers',balance.reserveNet),
    Divider(),lineItem('Available this month',balance.available),lineItem('Safe to spend',balance.safe),
   ]))),
   TextButton.icon(onPressed:()=>balanceDetails(balance,true),icon:PaydayAppIcon(Icons.info_outline),label:LText('Explain these balances')),
   header('Check before closing'),
   tile('Unpaid bills',balance.unpaidBills>0?'Due this month and still outstanding':'No outstanding bills due this month',money(balance.unpaidBills),
    icon:Icons.receipt_long_outlined,onTap:()=>setState(()=>moreSection=0)),
   tile('Savings still to fund','Remaining part of this month’s savings goal',money(balance.savingsGap),icon:Icons.savings_outlined),
   tile('Reserves still to fund','Remaining planned contributions for this month',money(balance.reserveHold),icon:Icons.beach_access_outlined),
   ...over.map((c)=>tile(c,'Over budget',money((review.spending[c]??0)-budgetFor(d,month,c)),categoryTitle:true,icon:Icons.error_outline,tone:Colors.deepOrange)),
   ...unbudgeted.map((c)=>tile(c,'Spending without a category budget',money(review.spending[c]??0),categoryTitle:true,icon:Icons.info_outline,tone:amber)),
   if(over.isEmpty&&unbudgeted.isEmpty)Padding(padding:EdgeInsets.all(12),child:LText('No category budget issues in recorded spending.')),
   if(projectedMonthSpend(spentSoFar:balance.expenses,month:selected,now:DateTime.now()) case final projected?)
    tile('Spending forecast','If you keep spending at this pace until the month ends',money(projected),icon:Icons.trending_up,
     tone:balance.income>0&&projected>balance.income?homeOver:null),
   header('Spending by category'),
   ...spendingBreakdown(d,review),
   if(review.spending.isEmpty)Padding(padding:EdgeInsets.all(12),child:LText('No spending recorded.')),
   SizedBox(height:12),LText('Review your records and compare with your actual cash or bank balance. This summary does not verify that every transaction has been entered.'),
   SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(
    onPressed:ended?()=>monthCloseForm(d):null,icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText(closed?'Review close checks':'Continue to close checks'))),
   if(!ended)Padding(padding:EdgeInsets.symmetric(vertical:8),child:LText('Month-close checks are available after the month ends.')),
  ]);
 }

 Widget more(Map<String,List<RowData>> d) {
  if(moreSection==null) {
   final count=list(d,'bills').where((b)=>st(b,'due').startsWith(month)).length;
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    header('More tools',subtitle:'Select a section to see its details.'),
    moreLink('Bills & payments','Due dates, outstanding balances and partial payments',
      Icons.receipt_long_outlined,0,count.toString()+' this month'),
    moreLink('Occasional expenses','Vacations, insurance, gifts and future expense reserves',
      Icons.beach_access_outlined,1,list(d,'reserves').length.toString()+' reserves'),
    moreLink('Monthly review','Review spending, commitments and month-close checks',
      Icons.fact_check_outlined,4,monthLabel(selected)),
    moreLink('Year overview','Income, spending and savings across the year',
      Icons.bar_chart_rounded,2,selected.year.toString()),
    moreLink('Recurring entries','Salary, rent and subscriptions added automatically each month',
      Icons.repeat,5,decodeRules(list(d,'settings').where((r)=>st(r,'key')==recurringSettingKey).firstOrNull?['value']?.toString()).length.toString()+' active'),
    SizedBox(height:15),
    Padding(padding:EdgeInsets.all(8),child:LText(
      'All your financial records stay on this device, with no Google account or internet required.',
      style:TextStyle(color:muted,fontSize:12))),
   ]);
  }
  Widget section;
  switch(moreSection) {
   case 0:section=moreBills(d);break;
   case 1:section=moreReserves(d);break;
   case 2:section=moreYear(d);break;
   case 4:section=monthlyReview(d);break;
   case 5:section=moreRecurring(d);break;
   default:section=const SizedBox.shrink();
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   TextButton.icon(onPressed:()=>setState(()=>moreSection=null),
    icon:PaydayAppIcon(Icons.arrow_back),label:LText('Back to More')),
   section,
  ]);
 }
 Widget moreLink(String name,String description,IconData symbol,int section,String summary)=>
  Card(clipBehavior:Clip.antiAlias,child:InkWell(
   onTap:()=>setState(()=>moreSection=section),
   child:Padding(padding:EdgeInsets.all(16),child:Row(children:[
    Container(width:48,height:48,
     decoration:BoxDecoration(color:jade.withValues(alpha:.10),borderRadius:BorderRadius.circular(14)),
     child:PaydayAppIcon(symbol,color:jade)),
    SizedBox(width:14),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText(name,style:TextStyle(fontWeight:FontWeight.w800,color:ink,fontSize:16)),
     SizedBox(height:4),LText(description,style:TextStyle(color:muted,fontSize:12)),
     SizedBox(height:7),LText(summary,style:TextStyle(color:jade,fontSize:12,fontWeight:FontWeight.w700)),
    ])),
    PaydayAppIcon(Icons.chevron_right,color:muted)
   ])),
  ));
 List<RecurringRule> rulesOf(Map<String,List<RowData>> d)=>decodeRules(list(d,'settings').where((r)=>st(r,'key')==recurringSettingKey).firstOrNull?['value']?.toString());
 Widget moreRecurring(Map<String,List<RowData>> d){
  final rules=rulesOf(d);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Recurring entries',subtitle:'Added on their day each month when you open Payday. Closed months are skipped.',
    action:FilledButton.tonalIcon(onPressed:()=>recurringForm(d,null),icon:PaydayAppIcon(Icons.add),label:LText('New'))),
   ...rules.map((r)=>tile(r.description.isEmpty?categoryLabel(context,r.category):r.description,
    '${tr(context,r.type)} · ${tr(context,'Day')} ${r.day}',money(r.amount),rawTitle:true,icon:Icons.repeat,onTap:()=>recurringForm(d,r))),
   if(rules.isEmpty)Padding(padding:EdgeInsets.all(8),child:LText('No recurring entries yet. Add your salary or a subscription.')),
  ]);
 }
 Future<void> recurringForm(Map<String,List<RowData>> d,RecurringRule? existing)async{
  var type=existing?.type??'Expense';
  var cats=categoryChoices(d,type);
  var category=existing?.category??(cats.isEmpty?'Other':cats.first);
  var day=existing?.day??1;
  final desc=TextEditingController(text:existing?.description??'');
  final amt=TextEditingController(text:existing==null?'':inputNumber(existing.amount));
  Future<void> saveAll(List<RecurringRule> rules,BuildContext c)async{
   final ok=await execute(()=>store.saveRecurringRules(rules));
   if(ok){await runRecurring();if(c.mounted)Navigator.pop(c);}
  }
  await sheet(existing==null?'New recurring entry':'Edit recurring entry',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   DropdownButtonFormField<String>(initialValue:type,decoration:InputDecoration(labelText:tr(context,'Type')),
    items:['Expense','Income','Savings out','Savings in'].map((v)=>DropdownMenuItem(value:v,child:LText(v))).toList(),
    onChanged:(v){if(v==null)return;rebuild((){type=v;cats=categoryChoices(d,v);if(!cats.contains(category))category=cats.isEmpty?'Other':cats.first;});}),
   SizedBox(height:12),
   DropdownButtonFormField<String>(initialValue:cats.contains(category)?category:null,decoration:InputDecoration(labelText:tr(context,'Category')),
    items:cats.map((v)=>DropdownMenuItem(value:v,child:Text(categoryLabel(context,v)))).toList(),
    onChanged:(v){if(v!=null)rebuild(()=>category=v);}),
   SizedBox(height:12),
   field(desc,'Description'),field(amt,'Amount ($currency)',number:true),
   DropdownButtonFormField<int>(initialValue:day,decoration:InputDecoration(labelText:tr(context,'Day of month')),
    items:List.generate(28,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))).toList(),
    onChanged:(v){if(v!=null)rebuild(()=>day=v);}),
   SizedBox(height:8),
   if(existing==null)LText('Starts this month. If the day has already passed, this month\'s entry is added now.',style:TextStyle(color:muted,fontSize:12)),
   SizedBox(height:12),
   FilledButton(onPressed:()async{
    final n=amount(amt);if(n==null)return inputError('Enter a positive amount.');
    final rules=rulesOf(await store.snapshot());
    final rule=RecurringRule(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),type:type,category:category,
     description:desc.text.trim(),amount:n,day:day,start:existing?.start??month0(),last:existing?.last);
    await saveAll([...rules.where((r)=>r.id!=rule.id),rule],c);
   },child:LText('Save recurring entry')),
   if(existing!=null)TextButton(onPressed:()async{
    final rules=rulesOf(await store.snapshot());
    await saveAll(rules.where((r)=>r.id!=existing.id).toList(),c);
   },child:LText('Stop this recurring entry')),
  ]));
 }
 String month0()=>monthKey(DateTime.now());
 Widget moreBills(Map<String,List<RowData>> d){
  final bills=list(d,'bills')..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Bills',action:FilledButton.tonalIcon(onPressed:()=>billForm(null),icon:PaydayAppIcon(Icons.add),label:LText('New'))),
   ...bills.where((b)=>st(b,'due').startsWith(month)).map((b){final remain=billOutstanding(val(b,'amount'),billPaid(d,b));
    return tile(st(b,'name'),'${displayDay(context,st(b,'due'))} · ID ${st(b,'code')} · Paid ${money(billPaid(d,b))}',remain==0?'Paid':money(remain),rawTitle:true,icon:remain==0?Icons.check_circle_outline:Icons.event_outlined,tone:remain==0?jade:amber,onTap:()=>billForm(b));
   }),
   if(!bills.any((b)=>st(b,'due').startsWith(month)))Padding(padding:EdgeInsets.all(8),child:LText('No bills due this month.'))
  ]);
 }
 Widget moreReserves(Map<String,List<RowData>> d){
  final reserves=list(d,'reserves');
  final now=DateTime.now();
  final todayMonth=monthKey(now);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Occasional expenses',subtitle:'Real money set aside, tracked separately from spending.',
    action:IconButton.filledTonal(onPressed:()=>reserveForm(null),
     icon:PaydayAppIcon(Icons.add),tooltip:tr(context,'Create a reserve'))),
   Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText('How reserves work',style:TextStyle(fontWeight:FontWeight.bold)),
    SizedBox(height:8),LText('The monthly amount is a suggestion, not an automatic transfer. Tap Add money when you actually set it aside. Your recorded transfers reduce what is still needed this month.'),
    SizedBox(height:8),LText('When paying the expense: Take out the money you use, then record the purchase as an Expense. Taking money out alone does not record spending.'),
   ]))),
   LText('Guidance for ${monthLabel(now)}',style:TextStyle(fontWeight:FontWeight.w700)),
   SizedBox(height:8),
   if(reserves.isEmpty)Card(child:Padding(padding:EdgeInsets.all(18),
    child:LText('Create a reserve for a vacation, annual bill or future purchase. '
      'Record each deposit to see progress and reduce your spendable cash.'))),
   ...reserves.map((r){
    final held=reserveFundedAt(d,r,todayMonth);
    final needed=(val(r,'target')-held).clamp(0,val(r,'target')).toInt();
    final contributed=reserveNetForMonth(d,todayMonth,reserveId:val(r,'id'));
    final next=reserveNextMonthTopUp(
      target:val(r,'target'),currentlyFunded:held,
      due:parseDay(st(r,'due')),selectedMonth:now);
    final goal=val(r,'target');
    final due=parseDay(st(r,'due'));
    final start=monthFromKey(st(r,'start_month'));
    final before=reserveFundedAt(d,r,monthKey(DateTime(now.year,now.month-1)));
    final remainingThisMonth=reserveThisMonthRemaining(target:goal,fundedBeforeMonth:before,
     netContributedThisMonth:contributed,due:due,start:start,month:now);
    final active=todayMonth.compareTo(monthKey(start))>=0;
    final overdue=todayMonth.compareTo(monthKey(due))>0;
    final guidance=needed==0?'Target fully funded':!active?'Starts ${monthLabel(start)}':
     overdue?'Past due · still needed: ${money(needed)}':
     remainingThisMonth==0?'This month is funded':'Still to set aside this month: ${money(remainingThisMonth)}';
    return Card(child:Padding(padding:EdgeInsets.all(16),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(st(r,'name'),
       style:TextStyle(color:ink,fontSize:17,fontWeight:FontWeight.w800))),
       IconButton(onPressed:()=>reserveForm(r),tooltip:tr(context,'Edit reserve goal'),
         icon:PaydayAppIcon(Icons.edit_outlined)),
      ]),
      LText('Due ${displayDay(context,st(r,'due'))}',style:TextStyle(color:muted,fontSize:12)),
      SizedBox(height:12),
      LText('Saved',style:TextStyle(color:muted,fontSize:12)),
      SizedBox(height:4),
      FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
       child:LText(money(held),style:TextStyle(color:jade,fontWeight:FontWeight.w900,fontSize:28))),
      SizedBox(height:4),
      LText('of ${money(goal)} target',style:TextStyle(color:muted,fontSize:12)),
      SizedBox(height:14),
      LinearProgressIndicator(value:goal==0?0:(held/goal).clamp(0,1).toDouble(),
       minHeight:7,borderRadius:BorderRadius.circular(10),backgroundColor:cream,color:jade),
      SizedBox(height:8),
      Wrap(alignment:WrapAlignment.spaceBetween,spacing:16,runSpacing:4,children:[
       LText('${goal==0?0:(held*100/goal).clamp(0,100).floor()}% funded',style:TextStyle(color:muted,fontSize:12)),
       LText('${money(needed)} remaining',style:TextStyle(color:ink,fontWeight:FontWeight.w600,fontSize:12)),
      ]),
      SizedBox(height:14),
      Container(width:double.infinity,padding:EdgeInsets.all(12),
       decoration:BoxDecoration(color:(overdue&&needed>0?Colors.deepOrange:jade).withValues(alpha:.07),
        borderRadius:BorderRadius.circular(PaydayRadius.md)),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        LText(guidance,style:TextStyle(fontWeight:FontWeight.w700,color:overdue&&needed>0?Colors.deepOrange:jade,fontSize:13)),
        if(active&&!overdue&&needed>0&&next>0)...[
         SizedBox(height:4),LText('Next month: ${money(next)} suggested',style:TextStyle(fontSize:12,color:muted)),
        ],
       ])),
      if(contributed!=0)Padding(padding:EdgeInsets.only(top:8),
       child:LText('Net added this month: ${money(contributed)}',style:TextStyle(fontSize:12,color:muted))),
      SizedBox(height:16),
      SizedBox(width:double.infinity,child:FilledButton.icon(
       onPressed:needed<=0?null:()=>reserveMovementForm(r,'add'),
       icon:PaydayAppIcon(Icons.add),label:LText('Add money'))),
      SizedBox(height:4),
      Wrap(alignment:WrapAlignment.spaceBetween,spacing:12,children:[
       TextButton.icon(onPressed:held<=0?null:()=>reserveMovementForm(r,'release'),
        icon:PaydayAppIcon(Icons.remove,size:18),label:LText('Take out')),
       TextButton.icon(onPressed:()=>reserveHistoryForm(r),
        icon:PaydayAppIcon(Icons.history,size:18),label:LText('History')),
      ]),
     ])));
   }),
  ]);
 }
 Widget yearChart(List<RowData> tx){
  final inc=<int>[],exp=<int>[];
  for(var i=1;i<=12;i++){
   final rows=tx.where((r)=>st(r,'date').startsWith(monthKey(DateTime(selected.year,i))));
   inc.add(sumType(rows,'Income'));exp.add(sumType(rows,'Expense'));
  }
  final top=[...inc,...exp].fold<int>(0,(a,b)=>a>b?a:b);
  if(top<=0)return const SizedBox.shrink();
  Widget bar(int v,Color c)=>Expanded(child:Align(alignment:Alignment.bottomCenter,child:FractionallySizedBox(
   heightFactor:(v/top).clamp(0.0,1.0),child:Container(decoration:BoxDecoration(color:c,borderRadius:BorderRadius.vertical(top:Radius.circular(3)))))));
  final spendColor=Theme.of(context).colorScheme.tertiary;
  return Card(child:Padding(padding:EdgeInsets.fromLTRB(12,14,12,10),child:Column(children:[
   Semantics(label:tr(context,'Income and spending by month'),child:SizedBox(height:140,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
    for(var i=0;i<12;i++)Expanded(child:Padding(padding:EdgeInsets.symmetric(horizontal:2),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[bar(inc[i],jade),SizedBox(width:1),bar(exp[i],spendColor)]))),
   ]))),
   SizedBox(height:4),
   Row(children:[for(var i=0;i<12;i++)Expanded(child:Text(localizedMonth(DateTime(selected.year,i+1),language).characters.first,
    textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:muted)))]),
   SizedBox(height:8),
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    Container(width:10,height:10,color:jade),SizedBox(width:4),LText('Income',style:TextStyle(fontSize:12)),SizedBox(width:16),
    Container(width:10,height:10,color:spendColor),SizedBox(width:4),LText('Spent',style:TextStyle(fontSize:12)),
   ]),
  ])));
 }
 Widget moreYear(Map<String,List<RowData>> d){
  final tx=list(d,'transactions');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Year overview',subtitle:'${selected.year} totals from local transactions'),
   yearChart(tx),
   ...List.generate(12,(i){final m=monthKey(DateTime(selected.year,i+1));
    final rows=tx.where((r)=>st(r,'date').startsWith(m));
    final inc=sumType(rows,'Income'),exp=sumType(rows,'Expense'),savings=sumType(rows,'Savings out')-sumType(rows,'Savings in');
    return Card(child:ListTile(title:LText(monthLabel(DateTime(selected.year,i+1))),subtitle:LText('Income ${money(inc)} · Spent ${money(exp)}'),trailing:LText('Saved ${money(savings)}')));
   })
  ]);
 }
 /// Last 12 months of one spending category, ending at the selected month.
 Future<void> categoryHistory(Map<String,List<RowData>> d,String category)async{
  final months=List.generate(12,(i)=>DateTime(selected.year,selected.month-11+i));
  final totals=months.map((m)=>categoryMonthTotal(list(d,'transactions'),category,monthKey(m))).toList();
  final top=totals.fold<int>(0,(a,b)=>a>b?a:b);
  final active=totals.where((v)=>v>0).toList();
  final average=active.isEmpty?0:(active.fold<int>(0,(a,b)=>a+b)/active.length).round();
  await sheet(categoryLabel(context,category),(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText('Last 12 months',style:TextStyle(color:muted)),
   SizedBox(height:6),
   LText('Average in months with spending: ${money(average)}',style:TextStyle(fontWeight:FontWeight.w700)),
   SizedBox(height:12),
   for(var i=months.length-1;i>=0;i--)Padding(padding:EdgeInsets.symmetric(vertical:4),child:Row(children:[
    SizedBox(width:76,child:LText(monthLabel(months[i]))),
    Expanded(child:LinearProgressIndicator(value:top<=0?0:totals[i]/top,minHeight:8,borderRadius:BorderRadius.circular(PaydayRadius.sm))),
    SizedBox(width:10),
    SizedBox(width:110,child:Text(money(totals[i]),textAlign:TextAlign.end)),
   ])),
  ]));
 }
}
