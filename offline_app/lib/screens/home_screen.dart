// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _HomeScreen on _FinanceState {
 String homeDigits(int cents)=>localizedNumber(cents,language,grouped:true);
 /// One budget row: status under the name, "spent / budget" on the right and a bar below.
 /// Tap a row to see this month's records for the category (Budgets passes its own action).
 Widget homeCategory(String category,int spent,int limit,{VoidCallback? onTap}){
  final status=categoryBudgetStatus(spent,limit);
  final isOver=status==CategoryBudgetStatus.overBudget;
  final isNear=status==CategoryBudgetStatus.nearLimit;
  final isSpent=status==CategoryBudgetStatus.fullySpent;
  final isUnbudgeted=status==CategoryBudgetStatus.unbudgeted;
  final ahead=status==CategoryBudgetStatus.withinBudget&&spendingAheadOfPace(spent:spent,budget:limit,month:selected,now:DateTime.now());
  final caution=isNear||ahead;
  final barColor=isOver?danger:isSpent?muted:caution?warn:homeGreen;
  final noteColor=isOver?danger:caution?saffronText:null;
  final left='${money(limit-spent)} left';
  final description=isOver?'Over by ${money(spent-limit)}':isUnbudgeted?'No budget set':isSpent?'Fully spent':
   isNear?'Near limit · $left':ahead?'Spending fast · $left':left;
  return listRow(key:ValueKey('home-category-$category'),onTap:onTap??()=>openCategoryRecords(category),
   leading:PaydayCategoryIcon(category,size:38),title:rowTitle(category,category:true),
   subtitle:description,subtitleColor:noteColor,
   amount:language=='ar'?(isUnbudgeted?homeDigits(spent):'${homeDigits(spent)} / ${homeDigits(limit)}')
    :isUnbudgeted?money(spent):'${plain(spent)} / ${money(limit)}',amountColor:muted,
   progress:limit<=0?(spent>0?1.0:0.0):spent/limit,progressColor:barColor,
   trackColor:isOver?(isDark?PaydayColors.darkStatusOverTrack:PaydayColors.statusOverTrack):null);
 }
 /// Month switcher shown at the top of pages that depend on the month.
 /// With [year], the Year tab steps a whole year and shows only the year.
 Widget navMonth({bool year=false})=>Material(color:isDark?PaydayControl.fillDark:PaydayControl.fillLight,clipBehavior:Clip.antiAlias,
  shape:const StadiumBorder(),
  child:Row(children:[
   IconButton(key:ValueKey(year?'nav-year-previous':'nav-month-previous'),tooltip:tr(context,year?'Previous year':'Previous month'),onPressed:()=>shift(year?-12:-1),icon:PaydayAppIcon(Icons.chevron_left)),
   Expanded(child:LText(year?'${selected.year}':localizedMonth(selected,language),key:ValueKey('nav-period-label'),textAlign:TextAlign.center,maxLines:1,
    style:TextStyle(fontWeight:FontWeight.w700,fontSize:15,color:ink))),
   IconButton(key:ValueKey(year?'nav-year-next':'nav-month-next'),tooltip:tr(context,year?'Next year':'Next month'),onPressed:()=>shift(year?12:1),icon:PaydayAppIcon(Icons.chevron_right)),
  ]));
 Widget bottomItem(String label,IconData icon,int index)=>Expanded(child:TextButton(key:ValueKey('bottom-$index'),
  style:TextButton.styleFrom(padding:EdgeInsets.symmetric(vertical:6,horizontal:2),foregroundColor:page==index?jade:muted,
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg))),
  onPressed:()=>setState(()=>page=index),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Container(padding:EdgeInsets.symmetric(horizontal:12,vertical:5),
    decoration:BoxDecoration(color:page==index?jade.withValues(alpha:.14):Colors.transparent,borderRadius:BorderRadius.circular(PaydayRadius.lg)),
    child:PaydayAppIcon(icon,size:22)),
   SizedBox(height:4),
   // One line always: long translations (e.g. French "Historique") shrink slightly instead of wrapping.
   FittedBox(fit:BoxFit.scaleDown,child:LText(label,key:ValueKey('bottom-label-$index'),maxLines:1,softWrap:false,
    style:TextStyle(fontSize:PaydayType.caption,fontWeight:page==index?FontWeight.w800:FontWeight.w600))),
  ])));

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
     calculation('Unpaid bills, including overdue',-balance.unpaidBills),
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

 MonthlyBalance monthlyBalance(Map<String,List<RowData>> d)=>balanceFor(d,month);
 /// Same calculation as the selected month, for any month (the widget uses this month).
 MonthlyBalance balanceFor(Map<String,List<RowData>> d,String key){
  final ts=monthTransactionsFor(d,key);
  final saved=sumType(ts,'Savings out')-sumType(ts,'Savings in');
  final l=Ledger(d);
  return MonthlyBalance(income:sumType(ts,'Income'),expenses:sumType(ts,'Expense'),
   savingsNet:saved,reserveNet:l.reserveNetForMonth(key),unpaidBills:l.unpaidBills(key),
   savingsGap:(budgetFor(d,key,'Savings goal')-saved).clamp(0,1000000000).toInt(),
   reserveHold:l.monthlyReserves(key),buffer:buffer(d));
 }
 Future<void> updateHomeWidget()async{
  if(!Platform.isAndroid)return;
  try{
   final d=await store.snapshot();
   final show=Ledger(d).setting(homeWidgetAmountKey)=='1';
   final safe=balanceFor(d,monthKey(DateTime.now())).safe;
   await pushHomeWidget(homeWidgetText(showAmount:show,appLock:widget.preferences.appLock||Ledger(d).setting('app_lock_enabled')=='1',
    safeToSpend:money(safe),translate:(s)=>translateMessage(s,language)));
  }catch(_){}
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
  // One quiet row at the end of Home: housekeeping should not outrank money.
  final label=reminder.lastExport==null?tr(context,'No backup yet')
   :tr(context,'Last backup {0}'.replaceAll('{0}',uiDay(reminder.lastExport!.toLocal())));
  return Padding(key:ValueKey('home-backup'),padding:EdgeInsets.only(top:PaydaySpace.xl),child:Column(children:[
   SizedBox(height:48,child:Row(children:[
    PaydayAppIcon(Icons.ios_share,color:muted,size:18),SizedBox(width:PaydaySpace.sm),
    Expanded(child:LText(label,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:muted,fontSize:PaydayType.caption))),
    IconButton(key:ValueKey('home-backup-snooze'),tooltip:tr(context,'Remind tomorrow'),onPressed:snoozeBackup,
     icon:PaydayAppIcon(Icons.schedule,size:20,color:muted)),
    // Longer labels (e.g. Arabic at large text sizes) shrink instead of overflowing.
    Flexible(child:TextButton(onPressed:exportingBackup||restoringBackup?null:exportBackup,
     child:FittedBox(fit:BoxFit.scaleDown,child:LText(exportingBackup?'Exporting…':'Export',maxLines:1,style:TextStyle(fontWeight:FontWeight.w700))))),
   ])),
  ]));
 }

 Widget home(Map<String,List<RowData>> d){
  final ts=monthTransactions(d),balance=monthlyBalance(d);
  final recent=recentActivityRows(list(d,'transactions'),DateTime.now());
  final categories=spendingCategories(d).where((c)=>budgetFor(d,month,st(c,'name'))>0||ts.any((t)=>st(t,'type')=='Expense'&&st(t,'category')==st(c,'name'))).toList();
  // Section headers sit on the page, not in boxes; a loose gap above separates groups.
  Widget section(String title,String action,VoidCallback tap)=>Padding(padding:EdgeInsetsDirectional.fromSTEB(0,PaydaySpace.xl+PaydaySpace.xs,0,0),child:Row(children:[
   Expanded(child:LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink))),TextButton(onPressed:tap,child:LText(action,style:TextStyle(fontWeight:FontWeight.w700)))]));
  const heroInk=paydaySand;
  final now=DateTime.now();
  final current=selected.year==now.year&&selected.month==now.month;
  // Home counts down to payday, not to the end of the calendar month.
  final toPayday=cycleOf(d,now).daysToPayday(now);
  final nextBill=current?nextDueBill(d,now):null;
  final unit=currencyLabel(currency,language);
  String whole(int cents)=>'${localizedWhole(cents,language)} $unit';
  const heroTabular=TextStyle(fontFeatures:PaydayText.tabular);
  Widget heroFigure(String label,String value)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(label,maxLines:1,style:TextStyle(color:PaydayColors.heroMuted,fontSize:PaydayType.caption,fontWeight:FontWeight.w600)),
   SizedBox(height:PaydaySpace.xs),
   FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
    child:LText(value,style:PaydayText.amount.copyWith(color:heroInk))),
  ]));
  // Hero amount: integer at display size, decimals and currency lifted and muted like a price tag.
  final digits=homeDigits(balance.safe).split(',');
  final lifted=TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.heroDecimals,fontWeight:FontWeight.w600,color:PaydayColors.heroMuted,letterSpacing:0,fontFeatures:PaydayText.tabular);
  final nudge=current?darijaNudge(balance.safe,toPayday,balance.usedFraction,language):null;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // Home shows this month; the switcher appears only after another month was picked elsewhere.
   if(!current)...[navMonth(),SizedBox(height:PaydaySpace.md)],
   // Hero: the one dominant object on Home. Flat emerald in both themes. Tap for the details.
   Material(key:ValueKey('home-hero'),color:PaydayColors.hero,borderRadius:BorderRadius.circular(PaydayRadius.hero),clipBehavior:Clip.antiAlias,
    child:InkWell(onTap:()=>balanceDetails(balance,true),child:Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.lg+PaydaySpace.xs,PaydaySpace.lg+PaydaySpace.xs,PaydaySpace.lg+PaydaySpace.xs,PaydaySpace.lg+PaydaySpace.xs),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(flex:3,child:LText('Safe to spend',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700))),
       SizedBox(width:PaydaySpace.sm),
       Expanded(flex:2,child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,child:LText(
        !current?monthLabel(selected):toPayday==1?'Payday tomorrow':language=='ar'?'الراتب بعد ${arabicDays(toPayday,after:true)}':'$toPayday days to payday',maxLines:1,
        style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700,fontSize:PaydayType.caption))))]),
      SizedBox(height:PaydaySpace.sm),
      FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:Text.rich(TextSpan(children:[
        TextSpan(text:digits.first),
        TextSpan(text:',${digits.last}',style:lifted),
        TextSpan(text:' $unit',style:lifted.copyWith(fontFamily:language=='ar'?'PlexArabic':'DMSans')),
       ]),
       // In Arabic the number reads first from the right, then درهم.
       textDirection:language=='ar'?TextDirection.rtl:TextDirection.ltr,
       style:heroTabular.copyWith(fontFamily:'Bricolage',fontSize:PaydayType.hero,height:1.05,fontWeight:FontWeight.w800,color:heroInk,letterSpacing:-1.5))),
      SizedBox(height:PaydaySpace.lg),
      // How much of the month's money is already used: sand on emerald, saffron stays reserved for the add button.
      PaydayProgress(key:ValueKey('home-usage-bar'),value:balance.usedFraction.clamp(0,1).toDouble(),color:heroInk,trackColor:heroInk.withValues(alpha:.18),height:6),
      SizedBox(height:PaydaySpace.lg),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
       heroFigure('Income',whole(balance.income)),SizedBox(width:PaydaySpace.md),
       heroFigure('Spent',whole(balance.expenses)),SizedBox(width:PaydaySpace.md),
       heroFigure('Bills ahead',whole(balance.unpaidBills)),
      ]),
     ])))),
   if(nudge!=null)Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.md,0,0),
    child:LText(nudge,key:ValueKey('home-nudge'),style:TextStyle(color:muted,fontWeight:FontWeight.w600))),
   // Cash & Bank at a glance, once tracking is on: plain row on the page, no box.
   if(walletSetupOf(d) case final setup?)Padding(padding:EdgeInsets.only(top:PaydaySpace.lg),child:contentCard(
    InkWell(key:ValueKey('home-wallets'),onTap:()=>openTool(6),child:Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.md+2,PaydaySpace.md,PaydaySpace.sm,PaydaySpace.md),
     child:Builder(builder:(_){
      final b=walletBalances(setup,list(d,'transactions'),walletTransfersOf(d));
      Widget one(String w)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Row(children:[PaydayAppIcon(w=='Cash'?Icons.payments_outlined:Icons.account_balance_wallet_outlined,size:16,color:muted),SizedBox(width:PaydaySpace.sm),
        Flexible(child:LText(w=='Cash'?'Cash in hand':'In the bank',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w600)))]),SizedBox(height:PaydaySpace.xs),
       FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText(money(b[w]!),
        style:PaydayText.amount.copyWith(color:b[w]!<0?danger:ink)))]));
      return Row(children:[one('Cash'),SizedBox(width:PaydaySpace.md),one('Bank'),PaydayAppIcon(Icons.chevron_right,color:muted)]);
     }))))),
   if(nextBill!=null)nextBillCard(d,nextBill),
   section('Budgets','See all',()=>setState(()=>page=2)),
   if(categories.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending or category budgets for this month.')
   else groupedRows(separate:true,[
    for(final c in categories)
     homeCategory(st(c,'name'),
      ts.where((t)=>st(t,'type')=='Expense'&&st(t,'category')==st(c,'name')).fold(0,(n,t)=>n+val(t,'amount')),
      budgetFor(d,month,st(c,'name'))),
   ]),
   section('Recent','See all',()=>setState(()=>page=1)),
   if(recent.isEmpty)PaydayEmpty(icon:Icons.receipt_long_outlined,message:'No activity today or yesterday.')
   else groupedRows([for(final r in recent)recentActivityTile(r)]),
   backupReminderCard(d),
  ]);
 }
 /// The next bill still owed (this month's, or an older one never paid), if it is overdue or due within a week.
 RowData? nextDueBill(Map<String,List<RowData>> d,DateTime now){
  final l=Ledger(d),today=DateTime(now.year,now.month,now.day);
  final owed=list(d,'bills').where((b)=>l.billCountsFor(b,monthKey(now))&&billOutstanding(val(b,'amount'),l.billPaid(b))>0).toList()
   ..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  final due=owed.isEmpty?null:DateTime.tryParse(st(owed.first,'due'));
  return due==null||due.difference(today).inDays>7?null:owed.first;
 }
 Widget nextBillCard(Map<String,List<RowData>> d,RowData bill){
  final owed=billOutstanding(val(bill,'amount'),Ledger(d).billPaid(bill));
  final due=DateTime.parse(st(bill,'due')),now=DateTime.now();
  final days=DateTime(due.year,due.month,due.day).difference(DateTime(now.year,now.month,now.day)).inDays;
  final when=days<0?'{0} · overdue':days==0?'{0} · today':days==1?'{0} · tomorrow':'{0} · in {1} days';
  final text=language=='ar'&&days>1?'${money(owed)} · بعد ${arabicDays(days,after:true)}':when.replaceAll('{0}',money(owed)).replaceAll('{1}','$days');
  final title='{0} is due on {1}'.replaceAll('{0}',isolate(st(bill,'name'))).replaceAll('{1}',shortDay(st(bill,'due')));
  final urgent=saffronText;
  // An inline row, not a tinted card: the amount line carries the urgency colour.
  return Padding(padding:EdgeInsets.only(top:PaydaySpace.xs),child:Material(key:ValueKey('home-next-bill'),color:Colors.transparent,
   child:InkWell(onTap:()=>openTool(0),child:Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.md,0,PaydaySpace.md),child:Row(children:[
    PaydayAppIcon(Icons.notifications_none,size:20,color:urgent),
    SizedBox(width:PaydaySpace.md),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText(title,maxLines:2,style:TextStyle(fontWeight:FontWeight.w600,color:ink)),
     SizedBox(height:PaydaySpace.xs/2),
     LText(text,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:urgent,fontFeatures:PaydayText.tabular)),
    ])),
    PaydayAppIcon(Icons.chevron_right,color:muted),
   ])))));
 }
 Widget recentActivityTile(RowData row){
  final category=st(row,'category'),type=st(row,'type');
  final title=st(row,'description').isEmpty?categoryLabel(context,category):st(row,'description');
  final outgoing=type=='Expense'||type=='Savings out';
  return Material(color:Colors.transparent,child:InkWell(
   onTap:()=>transactionForm(row),
   child:Padding(padding:EdgeInsetsDirectional.symmetric(horizontal:PaydaySpace.md+2,vertical:PaydaySpace.md),child:LayoutBuilder(builder:(context,box)=>Row(children:[
    PaydayCategoryIcon(category,size:40),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w600,color:ink)),
     SizedBox(height:3),LText('${categoryLabel(context,category)}${walletOf(row)} · ${tr(context,recentActivityDay(st(row,'date'),DateTime.now()))}',
      style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.4),
     child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,child:LText('${outgoing?'−':'+'}${plain(val(row,'amount'))}',
      style:PaydayText.amount.copyWith(color:outgoing?ink:jade)))),
   ])))));
 }
 /// Pop-up with every record of one category in the selected month.
 /// Scales and fades in from the centre; instant when Android animations are off.
 Future<void> openCategoryRecords(String category)async{
  final reduce=MediaQuery.disableAnimationsOf(context);
  await showGeneralDialog<void>(context:context,barrierDismissible:true,
   barrierLabel:tr(context,'Close'),barrierColor:Colors.black.withValues(alpha:.35),
   transitionDuration:reduce?Duration.zero:const Duration(milliseconds:280),
   transitionBuilder:(c,animation,_,child){
    final curve=CurvedAnimation(parent:animation,curve:Curves.easeOutCubic,reverseCurve:Curves.easeInCubic);
    return FadeTransition(opacity:curve,child:ScaleTransition(scale:Tween(begin:.92,end:1.0).animate(curve),child:child));
   },
   pageBuilder:(c,_,_)=>SafeArea(child:Center(child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:28),
    child:Material(color:surface,borderRadius:BorderRadius.circular(PaydayRadius.sheet),clipBehavior:Clip.antiAlias,
     child:ConstrainedBox(constraints:BoxConstraints(maxWidth:520,maxHeight:MediaQuery.sizeOf(c).height*.8),
      child:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(c,snap){
       final d=snap.data;
       if(d==null)return const SizedBox(height:160);
       final rows=monthTransactions(d).where((t)=>st(t,'type')=='Expense'&&st(t,'category')==category).toList();
       final spent=rows.fold<int>(0,(n,t)=>n+val(t,'amount')),limit=budgetFor(d,month,category);
       return Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Padding(padding:const EdgeInsetsDirectional.fromSTEB(18,16,8,6),child:Row(children:[
         PaydayCategoryIcon(category,size:40),const SizedBox(width:12),
         Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          LText(category,category:true,style:TextStyle(fontWeight:FontWeight.w800,fontSize:18,color:ink)),
          LText(monthLabel(selected),style:TextStyle(color:muted,fontSize:PaydayType.caption)),
         ])),
         IconButton(tooltip:tr(context,'Close'),onPressed:()=>Navigator.pop(c),icon:const PaydayAppIcon(Icons.close)),
        ])),
        Padding(padding:const EdgeInsets.fromLTRB(18,0,18,12),child:LText(
         limit>0?'${money(spent)} of ${money(limit)} · ${rows.length} records':'${money(spent)} · ${rows.length} records',
         style:TextStyle(color:homeText,fontWeight:FontWeight.w700))),
        Divider(height:1,color:line),
        Flexible(child:rows.isEmpty
         ?Padding(padding:const EdgeInsets.all(28),child:LText('No records in this category this month.',textAlign:TextAlign.center,style:TextStyle(color:muted)))
         :ListView.builder(shrinkWrap:true,padding:const EdgeInsets.fromLTRB(10,8,10,12),itemCount:rows.length,
          itemBuilder:(c,i)=>recordTileForDialog(rows[i],c))),
       ]);
      })))))),
  );
 }
 /// Same row as Records; editing closes the pop-up first so the form opens on top.
 Widget recordTileForDialog(RowData t,BuildContext dialog)=>ListTile(
  title:Text(st(t,'description').isEmpty?categoryLabel(context,st(t,'category')):st(t,'description'),
   maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),
  subtitle:LText(displayDay(context,st(t,'date'))),
  trailing:LText(money(val(t,'amount')),style:TextStyle(fontWeight:FontWeight.w800,color:ink)),
  onTap:(){Navigator.pop(dialog);transactionForm(t);});
}
