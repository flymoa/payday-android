// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _HomeScreen on _FinanceState {
 String homeDigits(int cents)=>localizedNumber(cents,language,grouped:true);
 String get decimalSeparator=>language=='fr'?',':'.';
 String homeMonthName()=>localizedMonth(selected,language);
 Widget homeSummary(String label,int value,String glyph){
  return Expanded(child:Container(
   padding:EdgeInsets.all(13),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(19),
    border:Border.all(color:line)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    PaydayCategoryIcon(glyph,size:38),
    SizedBox(height:11),
    LText(label,maxLines:2,style:TextStyle(color:muted,fontSize:12,height:1.2)),
    SizedBox(height:8),
    FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
     child:Row(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.baseline,
      textBaseline:TextBaseline.alphabetic,children:[
      LText(homeDigits(value),style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:homeNavy)),
      SizedBox(width:5),
      LText(currency,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:homeText)),
     ])),
   ]),
  ));
 }
 Widget homeQuickAction(String label,String glyph,VoidCallback onPressed){
  return Expanded(child:InkWell(
   borderRadius:BorderRadius.circular(15),onTap:onPressed,
   child:Padding(padding:EdgeInsets.symmetric(vertical:4),child:Column(children:[
    if(glyph=='budgets')Container(key:ValueKey('home-budget-icon'),width:52,height:52,padding:EdgeInsets.all(10.4),
     decoration:BoxDecoration(shape:BoxShape.circle,color:isDark?Color(0xff234D3D):Color(0xffDDEBE2)),
     child:PaydayAppIcon(Icons.pie_chart_outline,size:31.2))
    else PaydayCategoryIcon(glyph,size:52),
    SizedBox(height:7),
    LText(label,maxLines:2,textAlign:TextAlign.center,
     style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:homeText)),
   ])),
  ));
 }
 Widget homeCategory(String category,int spent,int limit){
  final status=categoryBudgetStatus(spent,limit);
  final isOver=status==CategoryBudgetStatus.overBudget;
  final isNear=status==CategoryBudgetStatus.nearLimit;
  final isSpent=status==CategoryBudgetStatus.fullySpent;
  final isUnbudgeted=status==CategoryBudgetStatus.unbudgeted;
  final statusColor=isOver?homeOver:(isNear||isSpent||isUnbudgeted)?homeNear:homeGreen;
  final progress=limit<=0?(spent>0?1.0:0.0):(spent/limit).clamp(0,1).toDouble();
  final description=isOver?'Over budget':
    isUnbudgeted?'No budget set':isSpent?'Fully spent':isNear?'Near limit':'${(spent*100/limit).round()}% used';
  return Container(
   margin:EdgeInsets.only(bottom:10),padding:EdgeInsets.all(15),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(19),
    border:Border.all(color:isOver?Color(0xffE9BEB8):line)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
     PaydayCategoryIcon(category,size:34),SizedBox(width:10),
     Expanded(child:LText(category,category:true,style:TextStyle(color:ink,
      fontWeight:FontWeight.w700,fontSize:14))),
     if(isOver)Padding(padding:EdgeInsetsDirectional.only(end:4),
      child:PaydayAppIcon(Icons.error_outline,color:homeOver,size:17)),
     LText(description,style:TextStyle(color:isOver?homeOver:
      (isNear||isSpent||isUnbudgeted)?(isDark?homeNear:Color(0xff996522)):homeText,
      fontWeight:FontWeight.w700,fontSize:12)),
    ]),
    SizedBox(height:9),
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Expanded(flex:6,child:LText('${homeDigits(spent)} / ${homeDigits(limit)} $currency',
      maxLines:2,style:TextStyle(color:homeText,fontSize:12))),
     SizedBox(width:5),
     Flexible(flex:5,child:LText(isOver?'Over by ${homeDigits(spent-limit)} $currency':
      isUnbudgeted?'Set a budget':'${homeDigits(limit-spent)} $currency left',
      textAlign:TextAlign.end,softWrap:true,
      style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,
       color:isOver?homeOver:homeText))),
    ]),
    SizedBox(height:11),
    ClipRRect(borderRadius:BorderRadius.circular(12),
     child:LinearProgressIndicator(value:progress,minHeight:9,
      color:statusColor,
      backgroundColor:isDark?Theme.of(context).colorScheme.surfaceContainerHigh:isOver?Color(0xffF4D9D4):Color(0xffE9F0EB))),
    if(isOver)Padding(padding:EdgeInsets.only(top:10),
      child:LText('Exceeded your budget by ${homeDigits(spent-limit)} $currency '
       '(${((spent/limit-1)*100).round()}% over).',
       style:TextStyle(color:homeOver,fontSize:12))),
   ]),
  );
 }
 Widget navMonth()=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[
  IconButton(onPressed:()=>shift(-1),icon:PaydayAppIcon(Icons.chevron_left)),
  Flexible(child:LText(monthLabel(selected),textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold,fontSize:16))),
  IconButton(onPressed:()=>shift(1),icon:PaydayAppIcon(Icons.chevron_right)),
 ]);
 Widget bottomItem(String label,IconData icon,int index)=>Expanded(child:TextButton(
  style:TextButton.styleFrom(padding:EdgeInsets.symmetric(vertical:10,horizontal:2),foregroundColor:page==index?jade:muted),
  onPressed:()=>setState((){page=index;moreSection=null;}),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Container(width:22,height:3,decoration:BoxDecoration(color:page==index?paydaySaffron:Colors.transparent,borderRadius:BorderRadius.circular(4))),
   SizedBox(height:7),PaydayAppIcon(icon,size:24),SizedBox(height:5),LText(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
  ])));

 Widget balanceTap(String label,VoidCallback onTap,Widget child)=>Semantics(
  button:true,label:tr(context,label),child:InkWell(onTap:onTap,
   borderRadius:BorderRadius.circular(12),child:Padding(
    padding:EdgeInsets.symmetric(vertical:4),child:child)));

 Future<void> balanceDetails(MonthlyBalance balance,bool showSafe)async{
  Widget calculation(String label,int amount,{bool total=false})=>Padding(
   padding:EdgeInsets.symmetric(vertical:10),child:Row(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
     Expanded(child:LText(label,style:TextStyle(fontWeight:total?FontWeight.w800:FontWeight.w500))),
     SizedBox(width:12),Flexible(child:LText('${amount>0&&!total?'+ ':''}${money(amount)}',
      textAlign:TextAlign.end,style:TextStyle(fontWeight:total?FontWeight.w800:FontWeight.w600))),
    ]));
  await sheet(showSafe?'Safe to spend':'Available this month',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText(monthLabel(selected),style:TextStyle(color:muted)),
    SizedBox(height:12),
    LText('Based on recorded money for this month, not your bank account balance or planned income.'),
    SizedBox(height:8),
    calculation('Income received',balance.income),
    calculation('Expenses recorded',-balance.expenses),
    calculation('Net savings transfers',-balance.savingsNet),
    calculation('Net reserve transfers',-balance.reserveNet),
    Divider(),calculation('Available this month',balance.available,total:true),
    if(showSafe)...[
     calculation('Unpaid bills due this month',-balance.unpaidBills),
     calculation('Savings goal still to fund',-balance.savingsGap),
     calculation('Reserve contributions still to fund',-balance.reserveHold),
     calculation('Cash buffer',-balance.buffer),
     Divider(),calculation('Safe to spend',balance.safe,total:true),
     if(balance.safe<0)LText('Your remaining commitments exceed available money by ${money(-balance.safe)}.'),
     SizedBox(height:12),
     LText('Paid bill amounts are already in expenses. Only unpaid amounts are held here. Savings and reserve transfers reduce the remaining amounts still to fund.'),
     SizedBox(height:12),
     LText('Category budgets are spending limits shown separately; their unused amounts are not deducted here. Check your category budget before a purchase.'),
    ]else...[
     SizedBox(height:12),LText('Positive transfers move money into savings or reserves; withdrawals add it back. Bills, remaining goals and your cash buffer are held in Safe to spend.'),
    ],
    SizedBox(height:16),Align(alignment:AlignmentDirectional.centerEnd,
     child:TextButton(onPressed:()=>Navigator.pop(c),child:LText('Got it'))),
   ]));
 }

 MonthlyBalance monthlyBalance(Map<String,List<RowData>> d){
  final ts=monthTransactions(d);
  final saved=sumType(ts,'Savings out')-sumType(ts,'Savings in');
  return MonthlyBalance(income:sumType(ts,'Income'),expenses:sumType(ts,'Expense'),
   savingsNet:saved,reserveNet:reserveNetForMonth(d,month),unpaidBills:unpaidBills(d),
   savingsGap:(budgetFor(d,month,'Savings goal')-saved).clamp(0,1000000000).toInt(),
   reserveHold:monthlyReserves(d),buffer:buffer(d));
 }
 BackupReminder backupReminder(Map<String,List<RowData>> d){
  String? setting(String key)=>list(d,'settings').where((r)=>st(r,'key')==key).firstOrNull?['value']?.toString();
  final hasData=['transactions','budgets','bills','goals','allocations','reserves','reserve_movements','month_closes']
   .any((t)=>list(d,t).isNotEmpty);
  return BackupReminder(now:DateTime.now(),hasData:hasData,
   lastExport:setting('last_backup_export'),snoozeUntil:setting('backup_snooze_until'));
 }
 String backupDateLabel(BackupReminder reminder)=>reminder.lastExport==null?
  'No export recorded yet':'Last export: ${uiDay(reminder.lastExport!.toLocal())}';
 Future<void> snoozeBackup()async{
  await execute(()=>store.setSetting('backup_snooze_until',DateTime.now().add(Duration(days:1)).toUtc().toIso8601String()));
 }
 Widget backupReminderCard(Map<String,List<RowData>> d){
  final reminder=backupReminder(d);
  if(!reminder.visible)return SizedBox.shrink();
  return Padding(padding:EdgeInsets.only(top:16),child:Card(margin:EdgeInsets.zero,
   child:Padding(padding:EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[PaydayAppIcon(Icons.ios_share,color:jade,size:20),SizedBox(width:8),
     Expanded(child:LText('Keep a backup',style:TextStyle(fontWeight:FontWeight.w700)))]),
    SizedBox(height:6),LText(backupDateLabel(reminder),style:TextStyle(color:muted,fontSize:12)),
    SizedBox(height:4),LText('Save a copy somewhere you can access if you lose or reset this phone.',style:TextStyle(fontSize:12,color:muted)),
    Wrap(spacing:10,children:[TextButton(onPressed:exportingBackup||restoringBackup?null:exportBackup,
     child:LText(exportingBackup?'Exporting…':'Export backup')),
     TextButton(onPressed:snoozeBackup,child:LText('Remind tomorrow'))]),
   ]))));
 }

 Widget home(Map<String,List<RowData>> d){
  final ts=monthTransactions(d),balance=monthlyBalance(d);
  final recent=recentActivityRows(list(d,'transactions'),DateTime.now());
  final categories=spendingCategories(d).where((c)=>budgetFor(d,month,st(c,'name'))>0||ts.any((t)=>st(t,'type')=='Expense'&&st(t,'category')==st(c,'name'))).toList();
  Widget section(String title,String action,VoidCallback tap)=>Padding(padding:EdgeInsets.only(top:23,bottom:12),child:Row(children:[
   Expanded(child:LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:21,fontWeight:FontWeight.w800))),TextButton(onPressed:tap,child:LText(action,style:TextStyle(fontWeight:FontWeight.w700)))]));
  final heroInk=paydaySand;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   navMonth(),SizedBox(height:12),
   Container(width:double.infinity,padding:EdgeInsets.all(22),decoration:BoxDecoration(color:paydayEmerald,borderRadius:BorderRadius.circular(30)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     balanceTap('Explain available balance',()=>balanceDetails(balance,false),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:LText('Available this month',style:TextStyle(color:Color(0xffB8D0BF),fontWeight:FontWeight.w700))),
       PaydayAppIcon(Icons.info_outline,color:heroInk,size:18)]),
      SizedBox(height:16),FittedBox(fit:BoxFit.scaleDown,child:Text.rich(TextSpan(children:[TextSpan(text:homeDigits(balance.available).split(decimalSeparator).first,style:TextStyle(fontSize:48)),TextSpan(text:'$decimalSeparator${homeDigits(balance.available).split(decimalSeparator).last} $currency',style:TextStyle(fontSize:23,color:Color(0xffB8D0BF)))]),textDirection:TextDirection.ltr,style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,color:heroInk))),
      SizedBox(height:16),MonthUsageBar(value:balance.usedFraction,
       trackColor:heroInk.withValues(alpha:.18),fillColor:heroInk.withValues(alpha:.55),markerColor:paydaySaffron),
      SizedBox(height:10),Wrap(spacing:16,runSpacing:5,children:[LText('Spent ${money(balance.expenses)}',style:TextStyle(color:Color(0xffB8D0BF),fontSize:12,fontWeight:FontWeight.w600)),
       LText('Income ${money(balance.income)}',style:TextStyle(color:Color(0xffB8D0BF),fontSize:12,fontWeight:FontWeight.w600))]),
     ])),
     Divider(color:heroInk.withValues(alpha:.18),height:24),
     SafeToSpendRow(amount:money(balance.safe),color:heroInk,onTap:()=>balanceDetails(balance,true)),
    ])),
   SizedBox(height:20),Row(children:[
    homeQuickAction('Expense','expense',()=>transactionForm(null)),homeQuickAction('Income','income',()=>transactionForm(null,initialType:'Income')),
    homeQuickAction('Budgets','budgets',()=>setState(()=>page=2)),homeQuickAction('Save','savings',()=>setState(()=>page=3)),
   ]),
   backupReminderCard(d),
   section('Budgets','See all',()=>setState(()=>page=2)),
   if(categories.isEmpty)Padding(padding:EdgeInsets.all(12),child:LText('No spending or category budgets for this month.')),
   ...categories.map((c){final name=st(c,'name');final spent=ts.where((t)=>st(t,'type')=='Expense'&&st(t,'category')==name).fold(0,(n,t)=>n+val(t,'amount'));return homeCategory(name,spent,budgetFor(d,month,name));}),
   section('Recent activity','See all',()=>setState(()=>page=1)),
   ...recent.map(recentActivityTile),if(recent.isEmpty)Padding(padding:EdgeInsets.symmetric(vertical:12),child:LText('No activity today or yesterday.')),
  ]);
 }
 Widget recentActivityTile(RowData row){
  final category=st(row,'category'),type=st(row,'type');
  final title=st(row,'description').isEmpty?categoryLabel(context,category):st(row,'description');
  final outgoing=type=='Expense'||type=='Savings out';
  return Material(color:Colors.transparent,child:InkWell(
   borderRadius:BorderRadius.circular(14),onTap:()=>transactionForm(row),
   child:Padding(padding:EdgeInsets.symmetric(vertical:10),child:Row(children:[
    PaydayCategoryIcon(category,size:42),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     SizedBox(height:3),LText('${categoryLabel(context,category)} · ${tr(context,recentActivityDay(st(row,'date'),DateTime.now()))}',
      style:TextStyle(fontSize:12,color:muted)),
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.32),
     child:FittedBox(fit:BoxFit.scaleDown,child:LText('${outgoing?'−':'+'}${money(val(row,'amount'))}',
      style:TextStyle(fontWeight:FontWeight.w700,color:ink)))),
   ]))));
 }
}
