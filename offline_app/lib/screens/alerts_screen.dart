// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

/// One thing that needs the user's attention, shown under the bell.
typedef PaydayAlert=({String key,IconData icon,String title,String subtitle,bool urgent,VoidCallback? onTap,Widget? actions});

extension _AlertsScreen on _FinanceState {
 /// Bills due within three days (or late), reserves that still need money this
 /// month, and an overdue backup. Ordered by urgency.
 List<PaydayAlert> alertsFor(Map<String,List<RowData>> d){
  final out=<PaydayAlert>[];
  final now=DateTime.now(),today=DateTime(now.year,now.month,now.day),l=Ledger(d);
  final bills=list(d,'bills').where((b)=>l.billCountsFor(b,monthKey(now))&&billOutstanding(val(b,'amount'),l.billPaid(b))>0).toList()
   ..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  for(final b in bills){
   final due=DateTime.tryParse(st(b,'due'));if(due==null)continue;
   final days=DateTime(due.year,due.month,due.day).difference(today).inDays;
   if(days>3)continue;
   final owed=money(billOutstanding(val(b,'amount'),l.billPaid(b)));
   final when=days<0?'{0} · overdue':days==0?'{0} · today':days==1?'{0} · tomorrow':'{0} · in {1} days';
   out.add((key:'alert-bill-${st(b,'code')}',icon:Icons.receipt_long_outlined,
    title:'{0} is due on {1}'.replaceAll('{0}',isolate(st(b,'name'))).replaceAll('{1}',shortDay(st(b,'due'))),
    subtitle:language=='ar'&&days>1?'$owed · بعد ${arabicDays(days,after:true)}':when.replaceAll('{0}',owed).replaceAll('{1}','$days'),
    urgent:days<=0,onTap:(){Navigator.of(context).maybePop();openTool(0);},actions:null));
  }
  for(final r in list(d,'reserves')){
   final s=reserveState(d,r);
   if(!s.active||s.needed==0)continue;
   if(!s.overdue&&s.remainingThisMonth==0)continue;
   out.add((key:'alert-reserve-${val(r,'id')}',icon:Icons.savings_outlined,title:isolate(st(r,'name')),subtitle:s.guidance,
    urgent:s.overdue,onTap:(){Navigator.of(context).maybePop();openTool(1);},actions:null));
  }
  final key=monthKey(now);
  for(final n in nearLimit(d,key)){
   out.add((key:'alert-budget-${n.$1}',icon:Icons.pie_chart_outline,title:'{0} reached 80%'.replaceAll('{0}',categoryLabel(context,n.$1)),
    subtitle:'{0} left'.replaceAll('{0}',money(n.$3-n.$2)),urgent:false,onTap:(){Navigator.of(context).maybePop();setState((){page=2;subTab[2]=0;});},actions:null));
  }
  for(final r in daretsOf(d)){
   if(r.finished||r.paid.contains(key)||key.compareTo(r.start)<0)continue;
   out.add((key:'alert-daret-${r.id}',icon:Icons.autorenew,title:isolate(r.name),subtitle:'{0} to pay this month'.replaceAll('{0}',money(r.amount)),
    urgent:false,onTap:(){Navigator.of(context).maybePop();openTool(8);},actions:null));
  }
  final cycle=cycleOf(d,now);
  final paydaySoon=cycle.nextPayday.difference(today).inDays<=2||today.difference(cycle.start).inDays<=2;
  if(paydaySoon){
   for(final k in kridiOf(d).where((k)=>k.iOwe&&k.balance>0&&k.kind!='loan'&&k.remind)){
    out.add((key:'alert-kridi-${k.id}',icon:k.kind=='shop'?Icons.storefront_outlined:Icons.people_outline,title:isolate(k.name),
     subtitle:'You owe {0} · payday'.replaceAll('{0}',money(k.balance)),urgent:false,onTap:(){Navigator.of(context).maybePop();openTool(7);},actions:null));
   }
  }
  final backup=backupReminder(d);
  if(backup.visible){
   out.add((key:'home-backup',icon:Icons.ios_share,
    title:backup.lastExport==null?'No backup yet':'Last backup {0}'.replaceAll('{0}',uiDay(backup.lastExport!.toLocal())),
    subtitle:'Your records live only on this phone. Export a backup to keep them safe.',urgent:false,onTap:null,
    // Wraps to two lines on narrow screens or large text instead of overflowing.
    actions:Wrap(alignment:WrapAlignment.end,spacing:PaydaySpace.sm,runSpacing:PaydaySpace.xs,children:[
     TextButton(key:ValueKey('home-backup-snooze'),onPressed:snoozeBackup,child:LText('Remind tomorrow')),
     FilledButton(onPressed:exportingBackup||restoringBackup?null:exportBackup,
      child:LText(exportingBackup?'Exporting…':'Export',maxLines:1)),
    ])));
  }
  out.sort((a,b)=>(b.urgent?1:0)-(a.urgent?1:0));
  return out;
 }

 Widget alertRow(PaydayAlert a)=>Material(key:ValueKey(a.key),color:Colors.transparent,child:InkWell(onTap:a.onTap,child:Padding(
  padding:EdgeInsets.symmetric(horizontal:PaydaySpace.md+2,vertical:PaydaySpace.md),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    iconTile(a.icon,size:36,color:a.urgent?danger:null),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText(a.title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,fontSize:15,color:ink)),
     SizedBox(height:2),
     LText(a.subtitle,maxLines:3,style:TextStyle(fontSize:PaydayType.caption,color:a.urgent?danger:muted,fontWeight:a.urgent?FontWeight.w700:FontWeight.w400)),
    ])),
    if(a.onTap!=null)...[SizedBox(width:4),PaydayAppIcon(Icons.chevron_right,size:18,color:muted)],
   ]),
   if(a.actions!=null)Padding(padding:EdgeInsetsDirectional.only(start:48,top:PaydaySpace.sm),child:SizedBox(width:double.infinity,child:a.actions!)),
  ]))));

 Widget alertsBody(Map<String,List<RowData>> d){
  final alerts=alertsFor(d);
  if(alerts.isEmpty){
   return Padding(padding:EdgeInsets.only(top:PaydaySpace.xl*2),child:Column(children:[
    iconTile(Icons.check_circle_outline,size:56),SizedBox(height:PaydaySpace.md),
    LText('You are all caught up',style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:18,color:ink)),
    SizedBox(height:PaydaySpace.xs),
    LText('Bills, reserves and backups that need you will show here.',textAlign:TextAlign.center,style:TextStyle(color:muted)),
   ]));
  }
  return Padding(padding:EdgeInsets.only(top:PaydaySpace.sm),child:groupedRows([for(final a in alerts)alertRow(a)]));
 }

 /// The bell in the header: a small count when something needs attention.
 Widget alertsButton()=>FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
  // Only what appeared since the bell was last opened is counted.
  final count=snap.hasData?unseenAlerts(snap.data!):0;
  return Stack(clipBehavior:Clip.none,children:[
   IconButton(key:ValueKey('home-bell-button'),tooltip:tr(context,'Notifications'),onPressed:openAlerts,
    style:IconButton.styleFrom(backgroundColor:surface,side:BorderSide(color:line),fixedSize:Size(44,44)),
    icon:PaydayAppIcon(Icons.notifications_none,size:22)),
   if(count>0)PositionedDirectional(top:2,end:2,child:IgnorePointer(child:Container(key:ValueKey('home-bell-badge'),
    constraints:BoxConstraints(minWidth:18),height:18,padding:EdgeInsets.symmetric(horizontal:5),
    decoration:BoxDecoration(color:paydaySaffron,borderRadius:BorderRadius.circular(9),border:Border.all(color:Theme.of(context).scaffoldBackgroundColor,width:1.5)),
    child:Center(child:Text(count>9?'9+':'$count',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:PaydayColors.ink,height:1)))))),
  ]);
 });

 static const alertsSeenKey='alerts_seen';
 String alertSignature(PaydayAlert a)=>'${a.key}|${a.title}';
 int unseenAlerts(Map<String,List<RowData>> d){
  final raw=Ledger(d).setting(alertsSeenKey);
  Set<String> seen;
  try{seen=seenAlerts??(raw==null?<String>{}:Set<String>.from(jsonDecode(raw) as List));}catch(_){seen=<String>{};}
  return alertsFor(d).where((a)=>!seen.contains(alertSignature(a))).length;
 }
 Future<void> openAlerts()async{
  if(alertsOpen)return;
  alertsOpen=true;
  // Opening the bell marks everything on it as seen; the number comes back only for new items.
  try{
   final d=await store.snapshot();
   if(!mounted)return;
   final signatures=[for(final a in alertsFor(d))alertSignature(a)];
   setState(()=>seenAlerts=signatures.toSet());
   await store.setSetting(alertsSeenKey,jsonEncode(signatures));
  }catch(_){}
  try{
   await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder:(_)=>SettingsHomePage(refresh:settingsRefresh,
    title:'Notifications',closeTooltip:'Close notifications',listKey:'alerts-list',
    builder:(page)=>FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(page,snap){
     if(snap.hasError)return Padding(padding:EdgeInsets.all(PaydaySpace.xl),child:LText('Could not load notifications.'));
     if(!snap.hasData)return SizedBox(height:200);
     return alertsBody(snap.data!);
    }))));
  }finally{alertsOpen=false;}
 }
}
