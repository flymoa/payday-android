// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

/// Ring chart of spending by category. Each slice keeps a 2° gap so small slices stay readable.
class _DonutPainter extends CustomPainter{
 _DonutPainter(this.values,this.colors,this.track,{this.selected,this.t=0});
 final List<int> values;final List<Color> colors;final Color track;
 /// Tapped slice and how far its animation has run (0 to 1): it thickens while the others fade.
 final int? selected;final double t;
 static const ringShare=.13;
 @override void paint(Canvas canvas,Size size){
  final stroke=size.width*ringShare;
  final grow=stroke*.45;
  final rect=Rect.fromLTWH(stroke/2+grow/2,stroke/2+grow/2,size.width-stroke-grow,size.height-stroke-grow);
  final total=values.fold<int>(0,(a,b)=>a+b);
  canvas.drawArc(rect,0,6.2832,false,Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..color=track);
  if(total<=0)return;
  var start=-1.5708;
  for(var i=0;i<values.length;i++){
   final sweep=6.2832*values[i]/total;
   final gap=values.length>1?0.035:0.0;
   final on=selected==i;
   final color=colors[i%colors.length].withValues(alpha:selected==null||on?1:1-.6*t);
   if(sweep>gap)canvas.drawArc(rect,start+gap/2,sweep-gap,false,Paint()..style=PaintingStyle.stroke..strokeWidth=on?stroke+grow*t:stroke..color=color);
   start+=sweep;
  }
 }
 /// Which slice a tap at [p] lands on, or null for the centre or outside the ring.
 static int? hit(Offset p,Size size,List<int> values){
  final c=size.center(Offset.zero),v=p-c,r=v.distance;
  final stroke=size.width*ringShare,outer=size.width/2,inner=outer-stroke*1.8;
  final total=values.fold<int>(0,(a,b)=>a+b);
  if(r<inner||r>outer||total<=0)return null;
  var angle=v.direction+1.5708;if(angle<0)angle+=6.2832;
  var acc=0.0;
  for(var i=0;i<values.length;i++){acc+=6.2832*values[i]/total;if(angle<=acc)return i;}
  return values.length-1;
 }
 @override bool shouldRepaint(_DonutPainter old)=>old.values!=values||old.colors!=colors||old.selected!=selected||old.t!=t;
}

extension _ReportsScreen on _FinanceState {
 List<Color> get reportPalette=>isDark?PaydayReport.dark:PaydayReport.light;

 /// Spending per category for one month, largest first.
 List<MapEntry<String,int>> spendingByCategory(Map<String,List<RowData>> d,String key){
  final totals=<String,int>{};
  for(final t in monthTransactionsFor(d,key).where((t)=>st(t,'type')=='Expense')){
   totals[st(t,'category')]=(totals[st(t,'category')]??0)+val(t,'amount');
  }
  return totals.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
 }

 /// Records · Calendar: each day shaded by how much was spent; tap a day to see its entries.
 Widget calendarView(Map<String,List<RowData>> d){
  final first=DateTime(selected.year,selected.month);
  final days=DateTime(selected.year,selected.month+1,0).day;
  final spent=<int,int>{};
  for(final t in monthTransactions(d).where((t)=>st(t,'type')=='Expense')){
   final day=int.tryParse(st(t,'date').substring(8,10))??0;
   spent[day]=(spent[day]??0)+val(t,'amount');
  }
  final top=spent.values.fold<int>(0,(a,b)=>a>b?a:b);
  final now=DateTime.now();
  final paydays=<int>{};
  final cycle=cycleOf(d,first);
  for(final p in [cycle.nextPayday,cycle.start]){
   if(p.year==first.year&&p.month==first.month)paydays.add(p.day);
  }
  final day=calendarDay!=null&&calendarDay!.year==first.year&&calendarDay!.month==first.month?calendarDay!.day:
   (now.year==first.year&&now.month==first.month?now.day:null);
  final blanks=(first.weekday+6)%7; // Monday first
  final letters=localizedWeekdayLetters(language);
  // No spend: no fill, the number sits on the card. Then three steps, each 3:1 on the card.
  int? step(int v){
   if(v<=0||top<=0)return null;
   final level=v/top;
   return level>.66?2:level>.33?1:0;
  }
  final steps=isDark?PaydayCalendar.dark:PaydayCalendar.light,stepInk=isDark?PaydayCalendar.darkOn:PaydayCalendar.lightOn;
  final rows=day==null?<RowData>[]:monthTransactions(d).where((t)=>st(t,'date')==dayKey(DateTime(first.year,first.month,day))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   contentCard(Padding(padding:EdgeInsets.all(PaydaySpace.md),child:Column(children:[
    Row(children:[for(final l in letters)Expanded(child:Center(child:Text(l,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w800,color:muted))))]),
    SizedBox(height:PaydaySpace.sm),
    GridView.count(key:ValueKey('records-calendar'),crossAxisCount:7,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
     mainAxisSpacing:PaydaySpace.xs,crossAxisSpacing:PaydaySpace.xs,children:[
      for(var i=0;i<blanks;i++)const SizedBox.shrink(),
      for(var n=1;n<=days;n++)Builder(builder:(_){
       final s=step(spent[n]??0);
       // Rings sit outside the fill with a 2px gap, so they read on any step:
       // emerald for payday, ink for the picked day.
       final ring=n==day?ink:paydays.contains(n)?jade:null;
       return DecoratedBox(key:ValueKey('calendar-day-$n'),
        decoration:ShapeDecoration(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg),
         side:ring==null?BorderSide.none:BorderSide(color:ring,width:2))),
        child:Padding(padding:const EdgeInsets.all(3),child:Material(color:s==null?Colors.transparent:steps[s],
         borderRadius:BorderRadius.circular(PaydayRadius.sm),clipBehavior:Clip.antiAlias,
         child:InkWell(onTap:()=>setState(()=>calendarDay=DateTime(first.year,first.month,n)),
          child:Center(child:Text('$n',style:TextStyle(fontWeight:FontWeight.w700,fontSize:PaydayType.caption,fontFeatures:PaydayText.tabular,
           color:s==null?ink:stepInk[s])))))));
      }),
     ]),
    SizedBox(height:PaydaySpace.sm),
    LText('Deeper colour = more spent · ring = payday',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
   ]))),
   if(day!=null)...[
    Padding(padding:EdgeInsets.only(top:PaydaySpace.lg,bottom:PaydaySpace.sm),
     child:Text(localizedLongDay(DateTime(first.year,first.month,day),language),key:ValueKey('calendar-day-title'),
      style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink))),
    if(rows.isEmpty)PaydayEmpty(icon:Icons.receipt_long_outlined,message:'Nothing recorded on this day.')
    else ...recordDays(rows,wallets:WalletSetup.decode(Ledger(d).setting(walletSetupKey)),showHeaders:false),
   ],
  ]);
 }

 /// Records · Reports: Month shows the ring and categories against last month; Year shows the months.
 Widget reportsView(Map<String,List<RowData>> d){
  final toggle=Wrap(spacing:8,children:[
   PaydayPill(key:ValueKey('reports-month'),label:'Month',selected:!reportYear,onTap:()=>setState(()=>reportYear=false)),
   PaydayPill(key:ValueKey('reports-year'),label:'Year',selected:reportYear,onTap:()=>setState(()=>reportYear=true)),
  ]);
  if(reportYear)return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[toggle,SizedBox(height:12),moreYear(d)]);
  final key=monthKey(selected),prevKey=monthKey(DateTime(selected.year,selected.month-1));
  final cats=spendingByCategory(d,key);
  final prev={for(final e in spendingByCategory(d,prevKey))e.key:e.value};
  final total=cats.fold<int>(0,(a,e)=>a+e.value);
  final income=sumType(monthTransactionsFor(d,key),'Income');
  final saved=sumType(monthTransactionsFor(d,key),'Savings out')-sumType(monthTransactionsFor(d,key),'Savings in');
  // Five biggest categories get their own colour; the rest share one slice.
  final shown=cats.take(5).toList();
  final rest=cats.skip(5).fold<int>(0,(a,e)=>a+e.value);
  final slices=[...shown.map((e)=>e.value),if(rest>0)rest];
  final palette=reportPalette;
  String change(String cat,int now){
   final before=prev[cat]??0;
   if(before==0)return now>0?'New this month':'';
   final pct=((now-before)*100/before).round();
   if(pct.abs()<3)return 'Same as last month';
   return pct>0?'+{0}% vs last month'.replaceAll('{0}','$pct'):'{0}% vs last month'.replaceAll('{0}','$pct');
  }
  final biggestRise=cats.where((e)=>(prev[e.key]??0)>0).map((e)=>MapEntry(e.key,(e.value-prev[e.key]!)*100~/prev[e.key]!)).where((e)=>e.value>=10).toList()
   ..sort((a,b)=>b.value.compareTo(a.value));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   toggle,SizedBox(height:12),
   // The ring sits on the page: one object, no frame around it.
   Padding(padding:EdgeInsets.symmetric(vertical:PaydaySpace.sm),child:Column(children:[
    Builder(builder:(_){
     final sliceNames=[...shown.map((e)=>e.key),if(rest>0)'Other'];
     final sel=reportSlice!=null&&reportSlice!<slices.length?reportSlice:null;
     return GestureDetector(key:ValueKey('reports-donut-tap'),behavior:HitTestBehavior.opaque,
      onTapUp:(e){final i=_DonutPainter.hit(e.localPosition,const Size(200,200),slices);setState(()=>reportSlice=i==null||i==sel?null:i);},
      child:SizedBox(width:200,height:200,child:TweenAnimationBuilder<double>(key:ValueKey('donut-$sel'),tween:Tween(begin:0,end:1),
       duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:220),curve:Curves.easeOutCubic,
       builder:(_,t,__)=>Stack(alignment:Alignment.center,children:[
        CustomPaint(key:ValueKey('reports-donut'),size:const Size(200,200),
         painter:_DonutPainter(slices,palette,isDark?PaydayColors.darkSurfaceHigh:PaydayColors.surfaceHigh,selected:sel,t:t.clamp(0,1).toDouble())),
        // The centre swaps between the month total and the tapped category.
        AnimatedSwitcher(duration:const Duration(milliseconds:220),
         transitionBuilder:(w,a)=>FadeTransition(opacity:a,child:ScaleTransition(scale:Tween(begin:.85,end:1.0).animate(a),child:w)),
         child:SizedBox(key:ValueKey('centre-$sel'),width:120,child:sel==null?Column(mainAxisSize:MainAxisSize.min,children:[
          FittedBox(child:Text(displayMoney(total,currency,language,style:MoneyStyle.summary,unit:false),style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.title,fontFeatures:PaydayText.tabular,fontWeight:FontWeight.w800,color:ink))),
          LText('{0} spent'.replaceAll('{0}',currencyLabel(currency,language)),textAlign:TextAlign.center,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:muted)),
         ]):Column(key:ValueKey('reports-slice-detail'),mainAxisSize:MainAxisSize.min,children:[
          Container(width:10,height:10,decoration:BoxDecoration(color:palette[sel%palette.length],shape:BoxShape.circle)),SizedBox(height:4),
          LText(sliceNames[sel],category:true,maxLines:2,textAlign:TextAlign.center,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w800,color:ink)),
          FittedBox(child:Text(displayMoney(slices[sel],currency,language,style:MoneyStyle.summary,unit:false),style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.title,fontFeatures:PaydayText.tabular,fontWeight:FontWeight.w800,color:ink))),
          Text('${currencyLabel(currency,language)} · ${total==0?0:slices[sel]*100~/total}%',style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:muted)),
         ]))),
       ]))));
    }),
    SizedBox(height:PaydaySpace.md),
    Row(children:[
     Expanded(child:LText(income>0?'Spent {0} of {1}'.replaceAll('{0}',summaryMoney(total)).replaceAll('{1}',summaryMoney(income)):'Spent {0}'.replaceAll('{0}',summaryMoney(total)),
      style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:muted))),
     if(saved>0)LText('Saved {0}'.replaceAll('{0}',summaryMoney(saved)),style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w800,color:jade)),
    ]),
   ])),
   if(biggestRise.isNotEmpty)Padding(padding:EdgeInsets.only(top:PaydaySpace.md),child:Container(key:ValueKey('reports-insight'),
    padding:EdgeInsets.all(PaydaySpace.md),decoration:BoxDecoration(color:isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint,borderRadius:BorderRadius.circular(PaydayRadius.lg)),
    child:Row(children:[PaydayAppIcon(Icons.trending_up,color:isDark?PaydayColors.darkText:PaydayColors.emerald),SizedBox(width:12),
     Expanded(child:LText('{0} up {1}% on last month'.replaceAll('{0}',categoryLabel(context,biggestRise.first.key)).replaceAll('{1}','${biggestRise.first.value}'),
      style:TextStyle(fontWeight:FontWeight.w800,color:isDark?PaydayColors.darkText:PaydayColors.emerald)))]))),
   SizedBox(height:PaydaySpace.md),
   if(cats.isEmpty)PaydayEmpty(icon:Icons.pie_chart_outline,message:'No spending this month yet.')
   else groupedRows([
    for(var i=0;i<cats.length;i++)listRow(key:ValueKey('report-${cats[i].key}'),
     leading:Container(width:12,height:12,decoration:BoxDecoration(color:i<5?palette[i]:palette[5],borderRadius:BorderRadius.circular(PaydayRadius.sm))),
     title:rowTitle(cats[i].key,category:true),
     subtitle:'${total==0?0:cats[i].value*100~/total}% · ${tr(context,change(cats[i].key,cats[i].value))}',
     amount:listMoney(cats[i].value),onTap:()=>categoryHistory(d,cats[i].key),
     trailing:Padding(padding:EdgeInsetsDirectional.only(start:4),child:PaydayAppIcon(Icons.chevron_right,size:18,color:muted))),
   ]),
  ]);
 }
}
