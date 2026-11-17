// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _HomeScreen on _FinanceState {
 String homeDigits(int cents)=>localizedNumber(cents,language,grouped:true);
 String get decimalSeparator=>language=='fr'?',':'.';
 /// One budget row inside the grouped Budgets panel on Home.
 /// Tap a row to see this month's records for the category.
 Widget homeCategory(String category,int spent,int limit,{VoidCallback? onTap}){
  final status=categoryBudgetStatus(spent,limit);
  final isOver=status==CategoryBudgetStatus.overBudget;
  final isNear=status==CategoryBudgetStatus.nearLimit;
  final isSpent=status==CategoryBudgetStatus.fullySpent;
  final isUnbudgeted=status==CategoryBudgetStatus.unbudgeted;
  final ahead=status==CategoryBudgetStatus.withinBudget&&spendingAheadOfPace(spent:spent,budget:limit,month:selected,now:DateTime.now());
  final caution=isNear||isSpent||isUnbudgeted||ahead;
  final statusColor=isOver?danger:caution?warn:homeGreen;
  final noteColor=isOver?danger:caution?(isDark?warn:PaydayColors.statusNearText):homeText;
  final progress=limit<=0?(spent>0?1.0:0.0):(spent/limit).clamp(0,1).toDouble();
  final description=isOver?'Over budget':
    isUnbudgeted?'No budget set':isSpent?'Fully spent':isNear?'Near limit':ahead?'Spending fast':'${(spent*100/limit).round()}% used';
  return Material(color:Colors.transparent,
   child:InkWell(key:ValueKey('home-category-$category'),
    onTap:onTap??()=>openCategoryRecords(category),child:Padding(
   padding:EdgeInsets.symmetric(horizontal:14,vertical:13),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    // Name on the left, status pinned to the right edge of the row.
    // The status only shrinks (never wraps) if the phone's text is very large.
    LayoutBuilder(builder:(context,box)=>Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
     PaydayCategoryIcon(category,size:36),SizedBox(width:10),
     Expanded(child:LText(category,category:true,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:ink,
      fontWeight:FontWeight.w700,fontSize:15))),
     SizedBox(width:8),
     if(isOver)Padding(padding:EdgeInsetsDirectional.only(end:4),
      child:PaydayAppIcon(Icons.error_outline,color:danger,size:17)),
     ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.5),
      child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
       child:LText(description,maxLines:1,style:TextStyle(color:noteColor,
        fontWeight:FontWeight.w700,fontSize:PaydayType.caption)))),
    ])),
    SizedBox(height:9),
    Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
     Expanded(flex:6,child:LText('${homeDigits(spent)} / ${homeDigits(limit)} $currency',
      maxLines:2,style:TextStyle(color:homeText,fontSize:PaydayType.caption))),
     SizedBox(width:5),
     Expanded(flex:5,child:LText(isOver?'Over by ${homeDigits(spent-limit)} $currency':
      isUnbudgeted?'Set a budget':'${homeDigits(limit-spent)} $currency left',
      textAlign:TextAlign.end,softWrap:true,
      style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,
       color:isOver?danger:homeText))),
    ]),
    SizedBox(height:10),
    PaydayProgress(value:progress,color:statusColor,
     trackColor:isOver?(isDark?PaydayColors.darkStatusOverTrack:PaydayColors.statusOverTrack):null),
   ]),
  )));
 }
 /// Month switcher shown at the top of each page.
 Widget navMonth()=>Center(child:Material(color:surface,clipBehavior:Clip.antiAlias,
  shape:StadiumBorder(side:BorderSide(color:line)),
  child:Row(mainAxisSize:MainAxisSize.min,children:[
   IconButton(tooltip:tr(context,'Previous month'),onPressed:()=>shift(-1),icon:PaydayAppIcon(Icons.chevron_left)),
   Flexible(child:Padding(padding:EdgeInsets.symmetric(horizontal:6),child:LText(monthLabel(selected),textAlign:TextAlign.center,
    style:TextStyle(fontWeight:FontWeight.w800,fontSize:15,color:ink)))),
   IconButton(tooltip:tr(context,'Next month'),onPressed:()=>shift(1),icon:PaydayAppIcon(Icons.chevron_right)),
  ])));
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

 Widget balanceTap(String label,VoidCallback onTap,Widget child)=>Semantics(
  button:true,label:tr(context,label),child:InkWell(onTap:onTap,
   borderRadius:BorderRadius.circular(PaydayRadius.md),child:Padding(
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
  return Padding(padding:EdgeInsets.only(top:16),child:Card(margin:EdgeInsets.zero,
   child:Padding(padding:EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[PaydayAppIcon(Icons.ios_share,color:jade,size:20),SizedBox(width:8),
     Expanded(child:LText('Keep a backup',style:TextStyle(fontWeight:FontWeight.w700)))]),
    SizedBox(height:6),LText(backupDateLabel(reminder),style:TextStyle(color:muted,fontSize:PaydayType.caption)),
    SizedBox(height:4),LText('Save a copy somewhere you can access if you lose or reset this phone.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    Wrap(spacing:10,children:[TextButton(onPressed:exportingBackup||restoringBackup?null:exportBackup,
     child:LText(exportingBackup?'Exporting…':'Export backup')),
     TextButton(onPressed:snoozeBackup,child:LText('Remind tomorrow'))]),
   ]))));
 }

 Widget home(Map<String,List<RowData>> d){
  final ts=monthTransactions(d),balance=monthlyBalance(d);
  final recent=recentActivityRows(list(d,'transactions'),DateTime.now());
  final categories=spendingCategories(d).where((c)=>budgetFor(d,month,st(c,'name'))>0||ts.any((t)=>st(t,'type')=='Expense'&&st(t,'category')==st(c,'name'))).toList();
  Widget section(String title,String action,VoidCallback tap)=>Padding(padding:EdgeInsetsDirectional.fromSTEB(4,22,0,8),child:Row(children:[
   Expanded(child:LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:21,fontWeight:FontWeight.w800,color:ink))),TextButton(onPressed:tap,child:LText(action,style:TextStyle(fontWeight:FontWeight.w700)))]));
  const heroInk=paydaySand;
  Widget heroStat(IconData icon,String label,String value)=>Expanded(child:Container(
   padding:EdgeInsets.symmetric(horizontal:12,vertical:10),
   decoration:BoxDecoration(color:heroInk.withValues(alpha:.10),borderRadius:BorderRadius.circular(PaydayRadius.md)),
   child:Row(children:[PaydayAppIcon(icon,color:paydaySaffron,size:18),SizedBox(width:8),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
     LText(label,style:TextStyle(color:PaydayColors.heroMuted,fontSize:PaydayType.caption,fontWeight:FontWeight.w600)),
     SizedBox(height:2),
     FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
      child:LText(value,style:TextStyle(color:heroInk,fontFamily:'Bricolage',fontSize:15,fontWeight:FontWeight.w800))),
    ]))])));
  final now=DateTime.now();
  final current=selected.year==now.year&&selected.month==now.month;
  final daysLeft=DateTime(now.year,now.month+1,0).day-now.day+1;
  final nextBill=current?nextDueBill(d,now):null;
  Widget heroFigure(String label,String value)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(label,maxLines:1,style:TextStyle(color:PaydayColors.heroMuted,fontSize:PaydayType.caption,fontWeight:FontWeight.w600)),
   SizedBox(height:2),
   FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
    child:LText(value,style:TextStyle(color:heroInk,fontFamily:'Bricolage',fontSize:15,fontWeight:FontWeight.w800))),
  ]));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // Home shows this month; the switcher appears only after another month was picked elsewhere.
   if(!current)...[navMonth(),SizedBox(height:12)],
   // Hero: what can still be spent, then the month at a glance, on emerald in both themes.
   Material(key:ValueKey('home-hero'),color:Colors.transparent,borderRadius:BorderRadius.circular(PaydayRadius.hero),clipBehavior:Clip.antiAlias,
    child:Ink(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
      colors:[PaydayColors.heroTop,PaydayColors.heroBottom])),
     child:InkWell(onTap:()=>balanceDetails(balance,true),child:Padding(padding:EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Row(children:[Expanded(child:LText('Safe to spend',style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700))),
        LText(!current?monthLabel(selected):daysLeft==1?'Last day of the month':'$daysLeft days left',
         style:TextStyle(color:PaydayColors.heroMuted,fontWeight:FontWeight.w700,fontSize:PaydayType.caption))]),
       SizedBox(height:10),FittedBox(fit:BoxFit.scaleDown,child:Text.rich(TextSpan(children:[TextSpan(text:homeDigits(balance.safe).split(decimalSeparator).first,style:TextStyle(fontSize:48)),TextSpan(text:'$decimalSeparator${homeDigits(balance.safe).split(decimalSeparator).last} $currency',style:TextStyle(fontSize:23,color:PaydayColors.heroMuted))]),textDirection:TextDirection.ltr,style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,color:heroInk))),
       SizedBox(height:14),MonthUsageBar(value:balance.usedFraction,
        trackColor:heroInk.withValues(alpha:.18),fillColor:heroInk.withValues(alpha:.55),markerColor:paydaySaffron),
       SizedBox(height:14),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        heroFigure('Income',money(balance.income)),SizedBox(width:10),
        heroFigure('Spent',money(balance.expenses)),SizedBox(width:10),
        heroFigure('Bills ahead',money(balance.unpaidBills)),
       ]),
      ]))))),
   // Available money stays one tap away; the hero above explains Safe to spend.
   Padding(padding:EdgeInsets.only(top:6),child:balanceTap('Explain available balance',()=>balanceDetails(balance,false),
    Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Row(children:[
     Expanded(child:LText('Available this month',style:TextStyle(color:muted,fontWeight:FontWeight.w600,fontSize:PaydayType.small))),
     LText(money(balance.available),style:TextStyle(color:ink,fontFamily:'Bricolage',fontWeight:FontWeight.w800)),
     SizedBox(width:6),PaydayAppIcon(Icons.info_outline,size:16,color:muted),
    ])))),
   // Cash & Bank at a glance, once tracking is on.
   if(walletSetupOf(d) case final setup?)Padding(padding:EdgeInsets.only(top:12),child:PaydayPanel(padding:EdgeInsets.zero,child:Material(color:Colors.transparent,
    child:InkWell(key:ValueKey('home-wallets'),onTap:()=>openTool(6),child:Padding(padding:EdgeInsets.symmetric(horizontal:16,vertical:14),
     child:Builder(builder:(_){
      final b=walletBalances(setup,list(d,'transactions'),walletTransfersOf(d));
      Widget one(String w)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       LText(w,style:TextStyle(color:muted,fontSize:PaydayType.caption,fontWeight:FontWeight.w700)),SizedBox(height:2),
       FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText(money(b[w]!),
        style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:17,color:b[w]!<0?danger:ink)))]));
      return Row(children:[one('Cash'),SizedBox(width:12),one('Bank'),PaydayAppIcon(Icons.chevron_right,color:muted)]);
     })))))),
   if(nextBill!=null)nextBillCard(d,nextBill),
   backupReminderCard(d),
   section('Budgets','See all',()=>setState(()=>page=2)),
   if(categories.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending or category budgets for this month.')
   else PaydayPanel(padding:EdgeInsets.zero,child:Column(children:[
    for(var i=0;i<categories.length;i++)...[
     if(i>0)Divider(height:1,thickness:1,indent:14,endIndent:14,color:line),
     homeCategory(st(categories[i],'name'),
      ts.where((t)=>st(t,'type')=='Expense'&&st(t,'category')==st(categories[i],'name')).fold(0,(n,t)=>n+val(t,'amount')),
      budgetFor(d,month,st(categories[i],'name'))),
    ],
   ])),
   section('Recent activity','See all',()=>setState(()=>page=1)),
   if(recent.isEmpty)PaydayEmpty(icon:Icons.receipt_long_outlined,message:'No activity today or yesterday.')
   else PaydayPanel(padding:EdgeInsets.symmetric(horizontal:14,vertical:4),child:Column(children:[
    for(var i=0;i<recent.length;i++)...[
     if(i>0)Divider(height:1,thickness:1,color:line),
     recentActivityTile(recent[i]),
    ],
   ])),
  ]);
 }
 /// The next bill still owed this month, if it is overdue or due within a week.
 RowData? nextDueBill(Map<String,List<RowData>> d,DateTime now){
  final l=Ledger(d),today=DateTime(now.year,now.month,now.day);
  final owed=list(d,'bills').where((b)=>st(b,'due').startsWith(monthKey(now))&&billOutstanding(val(b,'amount'),l.billPaid(b))>0).toList()
   ..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  final due=owed.isEmpty?null:DateTime.tryParse(st(owed.first,'due'));
  return due==null||due.difference(today).inDays>7?null:owed.first;
 }
 Widget nextBillCard(Map<String,List<RowData>> d,RowData bill){
  final owed=billOutstanding(val(bill,'amount'),Ledger(d).billPaid(bill));
  final due=DateTime.parse(st(bill,'due')),now=DateTime.now();
  final days=DateTime(due.year,due.month,due.day).difference(DateTime(now.year,now.month,now.day)).inDays;
  final when=days<0?'{0} · overdue':days==0?'{0} · due today':days==1?'{0} · due tomorrow':'{0} · due in {1} days';
  final text=when.replaceAll('{0}',money(owed)).replaceAll('{1}','$days');
  return Padding(padding:EdgeInsets.only(top:12),child:Material(key:ValueKey('home-next-bill'),
   color:isDark?const Color(0xff2E2618):const Color(0xffFFF3DC),clipBehavior:Clip.antiAlias,
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.card),
    side:BorderSide(color:isDark?const Color(0xff4A3B22):const Color(0xffF1D9A8))),
   child:InkWell(onTap:()=>openTool(0),child:Padding(padding:EdgeInsets.symmetric(horizontal:14,vertical:12),child:Row(children:[
    Container(width:38,height:38,decoration:BoxDecoration(color:isDark?const Color(0xff3A3020):const Color(0xffFBE3B5),borderRadius:BorderRadius.circular(PaydayRadius.md)),
     child:Center(child:PaydayAppIcon(Icons.notifications_none,size:20,color:isDark?warn:PaydayColors.statusNearText))),
    SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(st(bill,'name'),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     SizedBox(height:2),
     LText(text,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:isDark?warn:PaydayColors.statusNearText)),
    ])),
    PaydayAppIcon(Icons.chevron_right,color:muted),
   ])))));
 }
 Widget recentActivityTile(RowData row){
  final category=st(row,'category'),type=st(row,'type');
  final title=st(row,'description').isEmpty?categoryLabel(context,category):st(row,'description');
  final outgoing=type=='Expense'||type=='Savings out';
  return Material(color:Colors.transparent,child:InkWell(
   borderRadius:BorderRadius.circular(14),onTap:()=>transactionForm(row),
   child:Padding(padding:EdgeInsets.symmetric(vertical:11),child:LayoutBuilder(builder:(context,box)=>Row(children:[
    PaydayCategoryIcon(category,size:42),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     SizedBox(height:3),LText('${categoryLabel(context,category)} · ${tr(context,recentActivityDay(st(row,'date'),DateTime.now()))}',
      style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    ])),SizedBox(width:8),
    ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.4),
     child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,child:LText('${outgoing?'−':'+'}${money(val(row,'amount'))}',
      style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w700,color:outgoing?ink:jade)))),
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
   pageBuilder:(c,_,__)=>SafeArea(child:Center(child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:28),
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
