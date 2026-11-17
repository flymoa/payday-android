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
   final changeColor=before<=0?muted:spent>before?(isDark?warn:PaydayColors.statusNearText):jade;
   return Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
    Expanded(child:InkWell(key:ValueKey('category-records-$c'),borderRadius:BorderRadius.circular(PaydayRadius.sm),onTap:()=>openCategoryRecords(c),
     child:Padding(padding:EdgeInsets.symmetric(vertical:6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[Expanded(child:LText(categoryLabel(context,c),style:TextStyle(fontWeight:FontWeight.w700))),SizedBox(width:8),
      Flexible(child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
       child:LText('${plain(spent)} · ${(share*100).round()}%',style:TextStyle(fontWeight:FontWeight.w700))))]),
     SizedBox(height:5),
     PaydayProgress(value:share),
     SizedBox(height:3),LText(change,style:TextStyle(color:changeColor,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),
    ])))),
    IconButton(key:ValueKey('category-history-$c'),tooltip:tr(context,'Last 12 months'),onPressed:()=>categoryHistory(d,c),
     icon:PaydayAppIcon(Icons.bar_chart_rounded,size:20)),
   ]);
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
  Widget figure(String label,int value,Color color)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(label,maxLines:1,style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),SizedBox(height:2),
   FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
    child:LText(plain(value),style:TextStyle(fontFamily:'Bricolage',fontSize:17,fontWeight:FontWeight.w800,color:color))),
  ]));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   PaydayPanel(margin:EdgeInsets.only(bottom:4),child:Row(children:[
    figure('Income',balance.income,ink),SizedBox(width:8),figure('Spent',balance.expenses,ink),SizedBox(width:8),
    figure('Saved',balance.savingsNet,jade)])),
   Padding(padding:EdgeInsets.fromLTRB(6,4,6,0),child:LText(closed?'Month-close checks saved':ended?'Ready to review':'Month in progress',
    style:TextStyle(color:jade,fontWeight:FontWeight.w700,fontSize:PaydayType.caption))),
   if(tx.isEmpty)Padding(padding:EdgeInsets.symmetric(vertical:12),child:LText('No transactions recorded for this month. Bills and plans can still have outstanding amounts.')),
   header('Where it went'),
   if(review.spending.isEmpty)Padding(padding:EdgeInsets.all(12),child:LText('No spending recorded.'))
   else groupedRows(spendingBreakdown(d,review).map((w)=>Padding(padding:EdgeInsetsDirectional.fromSTEB(14,4,4,4),child:w)).toList()),
   SizedBox(height:12),
   // Closing the month.
   PaydayPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[iconTile(Icons.fact_check_outlined,size:36),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText('Close ${localizedMonth(selected,language)}',style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     LText(ended?'Check entries and your balance, then confirm.':'Month-close checks are available after the month ends.',
      style:TextStyle(color:muted,fontSize:PaydayType.caption)),
    ]))]),
    SizedBox(height:12),
    SizedBox(width:double.infinity,child:FilledButton.icon(
     onPressed:ended?()=>monthCloseForm(d):null,icon:PaydayAppIcon(Icons.fact_check_outlined),label:LText(closed?'Review close checks':'Continue to close checks'))),
   ])),
   header('Check before closing'),
   tile('Unpaid bills',balance.unpaidBills>0?'Due this month and still outstanding':'No outstanding bills due this month',money(balance.unpaidBills),
    icon:Icons.receipt_long_outlined,onTap:()=>openTool(0)),
   tile('Savings still to fund','Remaining part of this month’s savings goal',money(balance.savingsGap),icon:Icons.savings_outlined),
   tile('Reserves still to fund','Remaining planned contributions for this month',money(balance.reserveHold),icon:Icons.beach_access_outlined),
   ...over.map((c)=>tile(c,'Over budget',money((review.spending[c]??0)-budgetFor(d,month,c)),categoryTitle:true,icon:Icons.error_outline,tone:danger)),
   ...unbudgeted.map((c)=>tile(c,'Spending without a category budget',money(review.spending[c]??0),categoryTitle:true,icon:Icons.info_outline,tone:amber)),
   if(over.isEmpty&&unbudgeted.isEmpty)Padding(padding:EdgeInsets.all(12),child:LText('No category budget issues in recorded spending.')),
   if(projectedMonthSpend(spentSoFar:balance.expenses,month:selected,now:DateTime.now()) case final projected?)
    tile('Spending forecast','If you keep spending at this pace until the month ends',money(projected),icon:Icons.trending_up,
     tone:balance.income>0&&projected>balance.income?danger:null),
   header('Balances'),
   PaydayPanel(child:Column(children:[
    lineItem('Income received',balance.income),lineItem('Spending',balance.expenses),
    lineItem('Net savings transfers',balance.savingsNet),lineItem('Net reserve transfers',balance.reserveNet),
    Divider(),lineItem('Available this month',balance.available),lineItem('Safe to spend',balance.safe),
   ])),
   TextButton.icon(onPressed:()=>balanceDetails(balance,true),icon:PaydayAppIcon(Icons.info_outline),label:LText('Explain these balances')),
   LText('Review your records and compare with your actual cash or bank balance. This summary does not verify that every transaction has been entered.',
    style:TextStyle(color:muted,fontSize:PaydayType.caption)),
  ]);
 }
 WalletSetup? walletSetupOf(Map<String,List<RowData>> d)=>WalletSetup.decode(Ledger(d).setting(walletSetupKey));
 List<WalletTransfer> walletTransfersOf(Map<String,List<RowData>> d)=>decodeTransfers(Ledger(d).setting(walletTransfersKey));
 Map<String,int> walletBalancesOf(Map<String,List<RowData>> d){
  final setup=walletSetupOf(d);
  return setup==null?{'Cash':0,'Bank':0}:walletBalances(setup,list(d,'transactions'),walletTransfersOf(d));
 }
 Widget walletBalanceCard(String wallet,int amount)=>Expanded(child:PaydayPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[PaydayAppIcon(wallet=='Cash'?Icons.payments_outlined:Icons.account_balance_wallet_outlined,size:20),SizedBox(width:8),
   Expanded(child:LText(wallet,style:TextStyle(color:muted,fontWeight:FontWeight.w700)))]),
  SizedBox(height:8),
  FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
   child:LText(plain(amount),style:TextStyle(fontFamily:'Bricolage',fontSize:22,fontWeight:FontWeight.w800,color:amount<0?danger:ink))),
  LText(currency,style:TextStyle(color:muted,fontSize:PaydayType.caption)),
 ])));
 /// Cash & Bank: optional; switched on by entering today's balances.
 Widget moreWallets(Map<String,List<RowData>> d){
  final setup=walletSetupOf(d);
  if(setup==null){
   return PaydayPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText('See what you have in your pocket and in the bank.',style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
    SizedBox(height:6),
    LText('Enter what you have right now. From then on, each new entry moves the right wallet.',style:TextStyle(color:muted)),
    SizedBox(height:14),
    SizedBox(width:double.infinity,child:FilledButton.icon(key:ValueKey('wallet-start'),onPressed:()=>walletSetupForm(null),
     icon:PaydayAppIcon(Icons.add),label:LText('Start tracking'))),
   ]));
  }
  final balances=walletBalancesOf(d),transfers=walletTransfersOf(d)..sort((a,b)=>b.date.compareTo(a.date));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    walletBalanceCard('Cash',balances['Cash']!),SizedBox(width:10),walletBalanceCard('Bank',balances['Bank']!)])),
   SizedBox(height:12),
   SizedBox(width:double.infinity,child:FilledButton.icon(key:ValueKey('wallet-transfer'),style:FilledButton.styleFrom(minimumSize:Size.fromHeight(50)),
    onPressed:()=>walletTransferForm(),icon:PaydayAppIcon(Icons.repeat),label:LText('Transfer'))),
   SizedBox(height:12),
   if(transfers.isEmpty)PaydayEmpty(icon:Icons.repeat,message:'No transfers yet.')
   else groupedRows([for(final t in transfers)listRow(leading:iconTile(Icons.repeat),
    title:rowTitle(t.from=='Bank'?'Bank → Cash':'Cash → Bank'),subtitle:shortDay(t.date),amount:plain(t.amount),
    onTap:()=>confirmDelete('Delete transfer?',()=>store.deleteWalletTransfer(t.id)))]),
   Align(alignment:AlignmentDirectional.centerStart,child:TextButton(onPressed:()=>walletSetupForm(balances),child:LText('Correct balances'))),
   Padding(padding:EdgeInsets.symmetric(horizontal:8),child:LText('Tracking since ${uiDay(DateTime.tryParse(setup.date)??DateTime.now())}. Only entries added after you set the balances change them.',
    style:TextStyle(color:muted,fontSize:PaydayType.caption))),
  ]);
 }
 Future<void> walletSetupForm(Map<String,int>? current)async{
  final cash=TextEditingController(text:current==null?'':inputNumber(current['Cash']!.clamp(0,100000000000).toInt()));
  final bank=TextEditingController(text:current==null?'':inputNumber(current['Bank']!.clamp(0,100000000000).toInt()));
  await sheet(current==null?'Start tracking':'Correct balances',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   if(current!=null)Padding(padding:EdgeInsets.only(bottom:12),child:LText('Correcting balances starts again from the amounts you enter. Past transfers are cleared.',style:TextStyle(color:muted))),
   field(cash,'Cash you have now ($currency)',number:true),field(bank,'Money in the bank now ($currency)',number:true),
  ]),footer:(c,rebuild)=>FilledButton(key:ValueKey('wallet-save'),onPressed:()async{
   final a=amount(cash,allowZero:true),b=amount(bank,allowZero:true);
   if(a==null||b==null)return inputError('Enter a valid amount of zero or more.');
   final ok=await execute(()=>store.saveWalletSetup(cash:a,bank:b));if(ok&&c.mounted)Navigator.pop(c);
  },child:LText('Save balances')));
 }
 Future<void> walletTransferForm()async{
  var from='Bank';var date=DateTime.now();final value=TextEditingController();
  await sheet('Transfer',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Wrap(spacing:8,runSpacing:8,children:[
    PaydayPill(key:ValueKey('transfer-bank-cash'),label:'Bank → Cash',selected:from=='Bank',onTap:()=>rebuild(()=>from='Bank')),
    PaydayPill(key:ValueKey('transfer-cash-bank'),label:'Cash → Bank',selected:from=='Cash',onTap:()=>rebuild(()=>from='Cash')),
   ]),
   SizedBox(height:8),LText('Withdrawing cash? Choose Bank → Cash.',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
   SizedBox(height:14),field(value,'Amount ($currency)',number:true),
   TextButton.icon(icon:PaydayAppIcon(Icons.edit_calendar_outlined),onPressed:()async{
    final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime.now());if(p!=null)rebuild(()=>date=p);},
    label:LText('Transfer date: ${uiDay(date)}')),
  ]),footer:(c,rebuild)=>FilledButton(key:ValueKey('transfer-save'),onPressed:()async{
   final n=amount(value);if(n==null)return inputError('Enter a valid positive amount.');
   final ok=await execute(()=>store.addWalletTransfer(from:from,amount:n,date:dayKey(date)));if(ok&&c.mounted)Navigator.pop(c);
  },child:LText('Record transfer')));
 }
 List<RecurringRule> rulesOf(Map<String,List<RowData>> d)=>decodeRules(list(d,'settings').where((r)=>st(r,'key')==recurringSettingKey).firstOrNull?['value']?.toString());
 Widget moreRecurring(Map<String,List<RowData>> d){
  final rules=rulesOf(d);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Padding(padding:EdgeInsets.fromLTRB(4,0,4,10),child:LText('Added on their day each month when you open Payday. Closed months are skipped.',
    style:TextStyle(color:muted))),
   if(rules.isEmpty)PaydayEmpty(icon:Icons.repeat,message:'No recurring entries yet. Add your salary or a subscription.')
   else groupedRows([for(final r in rules)Builder(builder:(_){
    final incoming=r.type=='Income'||r.type=='Savings in';
    final wallet=walletSetupOf(d)!=null&&r.account!=null?' · ${tr(context,r.account!)}':'';
    return listRow(onTap:()=>recurringForm(d,r),leading:PaydayCategoryIcon(r.category,size:38),
     title:rowTitle(r.description.isEmpty?categoryLabel(context,r.category):r.description,raw:true),
     subtitle:'${categoryLabel(context,r.category)} · ${tr(context,'Day')} ${r.day}$wallet',
     amount:'${incoming?'+':'−'}${plain(r.amount)}',amountColor:incoming?jade:ink);
   })]),
   listAction('Add recurring entry',Icons.add,()=>recurringForm(d,null),key:ValueKey('recurring-add')),
  ]);
 }
 Future<void> recurringForm(Map<String,List<RowData>> d,RecurringRule? existing)async{
  var type=existing?.type??'Expense';
  var cats=categoryChoices(d,type);
  var category=existing?.category??(cats.isEmpty?'Other':cats.first);
  var day=existing?.day??1;
  var account=existing?.account;
  final wallets=walletSetupOf(d)!=null;
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
   if(wallets)...[
    DropdownButtonFormField<String>(key:ValueKey('recurring-wallet'),initialValue:account??(type=='Income'?'Bank':'Cash'),
     decoration:InputDecoration(labelText:tr(context,'Wallet')),
     items:walletNames.map((w)=>DropdownMenuItem(value:w,child:LText(w))).toList(),
     onChanged:(v){if(v!=null)rebuild(()=>account=v);}),
    SizedBox(height:12),
   ],
   DropdownButtonFormField<int>(initialValue:day,decoration:InputDecoration(labelText:tr(context,'Day of month')),
    items:List.generate(28,(i)=>DropdownMenuItem(value:i+1,child:Text('${i+1}'))).toList(),
    onChanged:(v){if(v!=null)rebuild(()=>day=v);}),
   SizedBox(height:8),
   if(existing==null)LText('Starts this month. If the day has already passed, this month\'s entry is added now.',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
   SizedBox(height:12),
   FilledButton(onPressed:()async{
    final n=amount(amt);if(n==null)return inputError('Enter a positive amount.');
    final rules=rulesOf(await store.snapshot());
    final rule=RecurringRule(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),type:type,category:category,
     description:desc.text.trim(),amount:n,day:day,start:existing?.start??month0(),last:existing?.last,
     account:wallets?(account??(type=='Income'?'Bank':'Cash')):existing?.account);
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
  final bills=list(d,'bills').where((b)=>st(b,'due').startsWith(month)).toList()..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  int owedFor(RowData b)=>billOutstanding(val(b,'amount'),billPaid(d,b));
  final total=bills.fold<int>(0,(n,b)=>n+val(b,'amount')),owed=bills.fold<int>(0,(n,b)=>n+owedFor(b));
  final now=DateTime.now(),today=DateTime(now.year,now.month,now.day);
  // Unpaid first by due date, paid ones after.
  final ordered=[...bills.where((b)=>owedFor(b)>0),...bills.where((b)=>owedFor(b)==0)];
  Widget billRow(RowData b){
   final remain=owedFor(b),paid=billPaid(d,b),amount=val(b,'amount');
   final due=DateTime.tryParse(st(b,'due'));
   final days=due==null?0:DateTime(due.year,due.month,due.day).difference(today).inDays;
   final when=remain==0?'':days<0?' · overdue':days==0?' · today':days==1?' · tomorrow':days<=7?' · in $days days':'';
   return listRow(key:ValueKey('bill-${st(b,'code')}'),onTap:()=>billForm(b),
    leading:iconTile(remain==0?Icons.check_circle_outline:Icons.receipt_long_outlined),title:rowTitle(st(b,'name'),raw:true),
    subtitle:remain==0?'Paid ${shortDay(st(b,'due'))}':'Due ${shortDay(st(b,'due'))}$when',
    amount:plain(amount),
    status:remain==0?'Paid':paid>0?'${plain(paid)} paid':'Not paid',
    statusColor:remain==0?jade:(isDark?warn:PaydayColors.statusNearText),
    progress:remain>0&&paid>0?paid/amount:null,progressColor:warn);
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   if(bills.isNotEmpty)summaryLine('Still to pay',money(owed),below:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    PaydayProgress(value:total<=0?0.0:(total-owed)/total),SizedBox(height:8),
    LText('${money(total-owed)} of ${money(total)} paid',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
   ])),
   if(bills.isEmpty)PaydayEmpty(icon:Icons.receipt_long_outlined,message:'No bills due this month.')
   else groupedRows(ordered.map(billRow).toList()),
   listAction('Add a bill',Icons.add,()=>billForm(null),key:ValueKey('bills-add')),
  ]);
 }
 /// Everything about one reserve: progress, this month's guidance and its actions.
 ({int held,int needed,int goal,int remainingThisMonth,String guidance,bool overdue,bool active,int next,int contributed}) reserveState(Map<String,List<RowData>> d,RowData r){
  final now=DateTime.now(),todayMonth=monthKey(now);
  final held=reserveFundedAt(d,r,todayMonth);
  final goal=val(r,'target');
  final needed=(goal-held).clamp(0,goal).toInt();
  final contributed=reserveNetForMonth(d,todayMonth,reserveId:val(r,'id'));
  final next=reserveNextMonthTopUp(target:goal,currentlyFunded:held,due:parseDay(st(r,'due')),selectedMonth:now);
  final due=parseDay(st(r,'due')),start=monthFromKey(st(r,'start_month'));
  final before=reserveFundedAt(d,r,monthKey(DateTime(now.year,now.month-1)));
  final remainingThisMonth=reserveThisMonthRemaining(target:goal,fundedBeforeMonth:before,
   netContributedThisMonth:contributed,due:due,start:start,month:now);
  final active=todayMonth.compareTo(monthKey(start))>=0;
  final overdue=todayMonth.compareTo(monthKey(due))>0;
  final guidance=needed==0?'Target fully funded':!active?'Starts ${monthLabel(start)}':
   overdue?'Past due · still needed: ${money(needed)}':
   remainingThisMonth==0?'This month is funded':'Still to set aside this month: ${money(remainingThisMonth)}';
  return (held:held,needed:needed,goal:goal,remainingThisMonth:remainingThisMonth,guidance:guidance,overdue:overdue,active:active,next:next,contributed:contributed);
 }
 Future<void> reserveDetails(Map<String,List<RowData>> d,RowData r)async{
  final s=reserveState(d,r);
  final held=s.held,needed=s.needed,goal=s.goal,guidance=s.guidance,overdue=s.overdue,active=s.active,next=s.next,contributed=s.contributed;
  await sheet(st(r,'name'),(c,rebuild)=>Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(st(r,'name'),
       style:TextStyle(color:ink,fontSize:17,fontWeight:FontWeight.w800))),
       IconButton(onPressed:(){Navigator.pop(c);reserveForm(r);},tooltip:tr(context,'Edit reserve goal'),
         icon:PaydayAppIcon(Icons.edit_outlined)),
      ]),
      LText('Due ${displayDay(context,st(r,'due'))} · ${hijriLabel(parseDay(st(r,'due')))}',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
      SizedBox(height:12),
      LText('Saved',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
      SizedBox(height:4),
      FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
       child:LText(money(held),style:TextStyle(color:jade,fontWeight:FontWeight.w900,fontSize:28))),
      SizedBox(height:4),
      LText('of ${money(goal)} target',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
      SizedBox(height:14),
      PaydayProgress(value:goal==0?0.0:held/goal),
      SizedBox(height:8),
      Wrap(alignment:WrapAlignment.spaceBetween,spacing:16,runSpacing:4,children:[
       LText('${goal==0?0:(held*100/goal).clamp(0,100).floor()}% funded',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
       LText('${money(needed)} remaining',style:TextStyle(color:ink,fontWeight:FontWeight.w600,fontSize:PaydayType.caption)),
      ]),
      SizedBox(height:14),
      Container(width:double.infinity,padding:EdgeInsets.all(12),
       decoration:BoxDecoration(color:(overdue&&needed>0?danger:jade).withValues(alpha:.07),
        borderRadius:BorderRadius.circular(PaydayRadius.md)),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        LText(guidance,style:TextStyle(fontWeight:FontWeight.w700,color:overdue&&needed>0?danger:jade,fontSize:13)),
        if(active&&!overdue&&needed>0&&next>0)...[
         SizedBox(height:4),LText('Next month: ${money(next)} suggested',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
        ],
       ])),
      if(contributed!=0)Padding(padding:EdgeInsets.only(top:8),
       child:LText('Net added this month: ${money(contributed)}',style:TextStyle(fontSize:PaydayType.caption,color:muted))),
      SizedBox(height:16),
      SizedBox(width:double.infinity,child:FilledButton.icon(
       onPressed:needed<=0?null:(){Navigator.pop(c);reserveMovementForm(r,'add');},
       icon:PaydayAppIcon(Icons.add),label:LText('Add money'))),
      SizedBox(height:4),
      Wrap(alignment:WrapAlignment.spaceBetween,spacing:12,children:[
       TextButton.icon(onPressed:held<=0?null:(){Navigator.pop(c);reserveMovementForm(r,'release');},
        icon:PaydayAppIcon(Icons.remove,size:18),label:LText('Take out')),
       TextButton.icon(onPressed:(){Navigator.pop(c);reserveHistoryForm(r);},
        icon:PaydayAppIcon(Icons.history,size:18),label:LText('History')),
      ]),
     ]));
 }
 Future<void> reservesHelp()async{
  await sheet('How reserves work',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText('The monthly amount is a suggestion, not an automatic transfer. Tap Add money when you actually set it aside. Your recorded transfers reduce what is still needed this month.'),
   SizedBox(height:10),LText('When paying the expense: Take out the money you use, then record the purchase as an Expense. Taking money out alone does not record spending.'),
  ]));
 }
 Widget moreReserves(Map<String,List<RowData>> d){
  final reserves=list(d,'reserves');
  final thisMonth=reserves.fold<int>(0,(n,r)=>n+reserveState(d,r).remainingThisMonth);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   summaryLine('Put aside this month',money(thisMonth),key:ValueKey('reserves-summary'),
    trailing:IconButton(key:ValueKey('reserves-help'),tooltip:tr(context,'How reserves work'),onPressed:reservesHelp,
     icon:PaydayAppIcon(Icons.info_outline,size:20,color:muted))),
   if(reserves.isEmpty)PaydayPanel(child:LText('Create a reserve for a vacation, annual bill or future purchase. '
      'Record each deposit to see progress and reduce your spendable cash.'))
   else groupedRows([for(final r in reserves)Builder(builder:(_){
    final s=reserveState(d,r);
    return listRow(key:ValueKey('reserve-${val(r,'id')}'),onTap:()=>reserveDetails(d,r),leading:iconTile(Icons.beach_access_outlined),
     title:rowTitle(st(r,'name'),raw:true),
     subtitle:'Ready by ${shortDay(st(r,'due'))} · ${hijriLabel(parseDay(st(r,'due')))}',
     amount:s.needed==0?null:s.remainingThisMonth>0?money(s.remainingThisMonth):null,
     status:s.needed==0?'Funded':s.overdue?'Past due':s.remainingThisMonth>0?'this month':'Done this month',
     statusColor:s.overdue&&s.needed>0?danger:s.needed==0||s.remainingThisMonth==0?jade:null,
     progress:s.goal==0?0.0:s.held/s.goal);
   })]),
   listAction('New reserve',Icons.add,()=>reserveForm(null),key:ValueKey('reserves-add')),
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
    textAlign:TextAlign.center,style:TextStyle(fontSize:PaydayType.caption,color:muted)))]),
   SizedBox(height:8),
   Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    Container(width:10,height:10,color:jade),SizedBox(width:4),LText('Income',style:TextStyle(fontSize:PaydayType.caption)),SizedBox(width:16),
    Container(width:10,height:10,color:spendColor),SizedBox(width:4),LText('Spent',style:TextStyle(fontSize:PaydayType.caption)),
   ]),
  ])));
 }
 Widget moreYear(Map<String,List<RowData>> d){
  final tx=list(d,'transactions');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   PaydayPanel(margin:EdgeInsets.only(bottom:12),child:yearChart(tx)),
   groupedRows(List.generate(12,(i){final m=monthKey(DateTime(selected.year,i+1));
    final rows=tx.where((r)=>st(r,'date').startsWith(m));
    final inc=sumType(rows,'Income'),exp=sumType(rows,'Expense'),savings=sumType(rows,'Savings out')-sumType(rows,'Savings in');
    return listRow(leading:iconTile(Icons.calendar_today_outlined,size:36),title:rowTitle(localizedMonth(DateTime(selected.year,i+1),language),raw:true),
     subtitle:'Income ${money(inc)} · Spent ${money(exp)}',amount:plain(savings),status:'Saved',amountColor:savings>0?jade:ink,
     onTap:(){setState((){selected=DateTime(selected.year,i+1);subTab[1]=1;});});
   })),
  ]);
 }
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
    Expanded(child:PaydayProgress(value:top<=0?0.0:totals[i]/top)),
    SizedBox(width:10),
    SizedBox(width:110,child:Text(money(totals[i]),textAlign:TextAlign.end)),
   ])),
  ]));
 }
}
