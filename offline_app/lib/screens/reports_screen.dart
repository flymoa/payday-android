// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

/// Ring chart of spending by category. Each slice keeps a 2° gap so small slices stay readable.
class _DonutPainter extends CustomPainter{
 _DonutPainter(this.values,this.colors,this.track);
 final List<int> values;final List<Color> colors;final Color track;
 @override void paint(Canvas canvas,Size size){
  final stroke=size.width*.13;
  final rect=Rect.fromLTWH(stroke/2,stroke/2,size.width-stroke,size.height-stroke);
  final total=values.fold<int>(0,(a,b)=>a+b);
  final base=Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..color=track;
  canvas.drawArc(rect,0,6.2832,false,base);
  if(total<=0)return;
  var start=-1.5708;
  for(var i=0;i<values.length;i++){
   final sweep=6.2832*values[i]/total;
   final gap=values.length>1?0.035:0.0;
   if(sweep>gap)canvas.drawArc(rect,start+gap/2,sweep-gap,false,Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..color=colors[i%colors.length]);
   start+=sweep;
  }
 }
 @override bool shouldRepaint(_DonutPainter old)=>old.values!=values||old.colors!=colors;
}

extension _ReportsScreen on _FinanceState {
 List<Color> get reportPalette=>isDark
  ?const [Color(0xFF5FD3A9),Color(0xFF2C8979),Color(0xFFE5B56E),Color(0xFFF4A62A),Color(0xFF7FA99B),Color(0xFF6B7377)]
  :const [Color(0xFF0E5A47),Color(0xFF2C8979),Color(0xFFD2A15A),Color(0xFFF4A62A),Color(0xFF7FA99B),Color(0xFFA9B0B3)];

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
  Color shade(int v){
   if(v<=0||top<=0)return surface;
   final level=v/top;
   if(level>.66)return jade;
   if(level>.33)return isDark?const Color(0xFF2D5446):const Color(0xFFB7D6C6);
   return isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint;
  }
  final rows=day==null?<RowData>[]:monthTransactions(d).where((t)=>st(t,'date')==dayKey(DateTime(first.year,first.month,day))).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   contentCard(Padding(padding:EdgeInsets.all(PaydaySpace.md),child:Column(children:[
    Row(children:[for(final l in letters)Expanded(child:Center(child:Text(l,style:TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:muted))))]),
    SizedBox(height:PaydaySpace.sm),
    GridView.count(key:ValueKey('records-calendar'),crossAxisCount:7,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
     mainAxisSpacing:5,crossAxisSpacing:5,children:[
      for(var i=0;i<blanks;i++)const SizedBox.shrink(),
      for(var n=1;n<=days;n++)Builder(builder:(_){
       final v=spent[n]??0,bg=shade(v),strong=bg==jade;
       return Material(key:ValueKey('calendar-day-$n'),color:bg,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),
         side:BorderSide(color:paydays.contains(n)?paydaySaffron:(n==day?ink:line),width:paydays.contains(n)||n==day?2:1)),
        child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>setState(()=>calendarDay=DateTime(first.year,first.month,n)),
         child:Center(child:Text('$n',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13,color:strong?(isDark?PaydayColors.ink:paydaySand):ink)))));
      }),
     ]),
    SizedBox(height:PaydaySpace.sm),
    LText('Darker day = more spent · ring = payday',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
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
   contentCard(Padding(padding:EdgeInsets.all(PaydaySpace.lg),child:Column(children:[
    SizedBox(width:180,height:180,child:Stack(alignment:Alignment.center,children:[
     CustomPaint(key:ValueKey('reports-donut'),size:const Size(180,180),painter:_DonutPainter(slices,palette,isDark?PaydayColors.darkSurfaceHigh:PaydayColors.surfaceHigh)),
     Column(mainAxisSize:MainAxisSize.min,children:[
      FittedBox(child:Text(localizedWhole(total,language),style:TextStyle(fontFamily:'Bricolage',fontSize:26,fontWeight:FontWeight.w800,color:ink))),
      LText('{0} spent'.replaceAll('{0}',currencyLabel(currency,language)),style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:muted)),
     ]),
    ])),
    SizedBox(height:PaydaySpace.md),
    Row(children:[
     Expanded(child:LText(income>0?'Spent {0} of {1}'.replaceAll('{0}',money(total)).replaceAll('{1}',money(income)):'Spent {0}'.replaceAll('{0}',money(total)),
      style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:muted))),
     if(saved>0)LText('Saved {0}'.replaceAll('{0}',money(saved)),style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w800,color:jade)),
    ]),
   ]))),
   if(biggestRise.isNotEmpty)Padding(padding:EdgeInsets.only(top:PaydaySpace.md),child:Container(key:ValueKey('reports-insight'),
    padding:EdgeInsets.all(PaydaySpace.md),decoration:BoxDecoration(color:isDark?const Color(0xFF3A2E1C):const Color(0xFFFCEBD0),borderRadius:BorderRadius.circular(18)),
    child:Row(children:[PaydayAppIcon(Icons.trending_up,color:saffronText),SizedBox(width:12),
     Expanded(child:LText('{0} up {1}% on last month'.replaceAll('{0}',categoryLabel(context,biggestRise.first.key)).replaceAll('{1}','${biggestRise.first.value}'),
      style:TextStyle(fontWeight:FontWeight.w800,color:saffronText)))]))),
   SizedBox(height:PaydaySpace.md),
   if(cats.isEmpty)PaydayEmpty(icon:Icons.donut_large,message:'No spending this month yet.')
   else groupedRows([
    for(var i=0;i<cats.length;i++)listRow(key:ValueKey('report-${cats[i].key}'),
     leading:Container(width:12,height:12,decoration:BoxDecoration(color:i<5?palette[i]:palette[5],borderRadius:BorderRadius.circular(4))),
     title:rowTitle(cats[i].key,category:true),
     subtitle:'${total==0?0:cats[i].value*100~/total}% · ${tr(context,change(cats[i].key,cats[i].value))}',
     amount:money(cats[i].value),onTap:()=>categoryHistory(d,cats[i].key),
     trailing:Padding(padding:EdgeInsetsDirectional.only(start:4),child:PaydayAppIcon(Icons.chevron_right,size:18,color:muted))),
   ]),
  ]);
 }
}
