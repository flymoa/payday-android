import 'dart:io';
import 'dart:convert';
import 'brand.dart';
import 'opening.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'finance.dart';
import 'offline_store.dart';

void main() {WidgetsFlutterBinding.ensureInitialized();runApp(const PaydayLocal());}
const ink=Color(0xff0B2545), jade=Color(0xff087F7C), cream=Color(0xffF8F9F6), amber=Color(0xffA36B2E);
const homeNavy=Color(0xff0B2545), homeCopper=Color(0xffF0CA94);
const homeText=Color(0xff344B45), homeGreen=Color(0xff2C8979);
const homeNear=Color(0xffD2A15A), homeOver=Color(0xffCA554A);
typedef RowData=Map<String,Object?>;
String st(RowData row,String key)=>row[key]?.toString()??'';
int val(RowData row,String key)=>(row[key] as num?)?.toInt()??0;
String money(int amount)=>'${mad(amount).toStringAsFixed(2)} MAD';
DateTime parseDay(String text)=>DateTime.tryParse(text)??DateTime.now();
class PaydayLocal extends StatefulWidget {
 const PaydayLocal({super.key,this.initialData});
 final Future<Map<String,List<RowData>>>? initialData;
 @override State<PaydayLocal> createState()=>_PaydayLocalState();
}
class _PaydayLocalState extends State<PaydayLocal> {
 ThemeMode mode=ThemeMode.light;
 ThemeData palette(Brightness brightness){
  final dark=brightness==Brightness.dark;
  final scheme=ColorScheme.fromSeed(seedColor:jade,brightness:brightness,
   primary:dark?const Color(0xff62D5C9):jade,
   surface:dark?const Color(0xff142D43):Colors.white);
  return ThemeData(useMaterial3:true,colorScheme:scheme,
   scaffoldBackgroundColor:dark?const Color(0xff091D2D):cream,
   appBarTheme:AppBarTheme(backgroundColor:dark?const Color(0xff091D2D):cream,
    foregroundColor:scheme.onSurface,centerTitle:true,surfaceTintColor:Colors.transparent),
   cardTheme:CardThemeData(elevation:0,color:scheme.surface,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
   inputDecorationTheme:InputDecorationTheme(filled:true,
    fillColor:scheme.surfaceContainerLow,
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
    minimumSize:const Size(48,48))),
   navigationBarTheme:NavigationBarThemeData(backgroundColor:scheme.surface),
  );
 }
 @override Widget build(BuildContext context)=>MaterialApp(
  debugShowCheckedModeBanner:false,title:'PAYDAY',theme:palette(Brightness.light),
  darkTheme:palette(Brightness.dark),themeMode:mode,
  builder:(context,child)=>PaydayOpening(child:child??const SizedBox.shrink()),
  home:FinanceScreen(initialData:widget.initialData,onToggleTheme:(dark)=>setState(()=>mode=dark?ThemeMode.dark:ThemeMode.light)));
}
class FinanceScreen extends StatefulWidget {const FinanceScreen({super.key,this.onToggleTheme,this.initialData,this.store});final ValueChanged<bool>? onToggleTheme;
 final OfflineStore? store;
 final Future<Map<String,List<RowData>>>? initialData;@override State<FinanceScreen> createState()=>_FinanceState();}
class _FinanceState extends State<FinanceScreen>{
 bool get isDark=>Theme.of(context).brightness==Brightness.dark;
 Color get ink=>Theme.of(context).colorScheme.onSurface;
 Color get jade=>Theme.of(context).colorScheme.primary;
 Color get cream=>Theme.of(context).scaffoldBackgroundColor;
 Color get surface=>Theme.of(context).colorScheme.surface;
 Color get muted=>Theme.of(context).colorScheme.onSurfaceVariant;
 Color get homeNavy=>ink;
 Color get homeText=>muted;
 Color get homeGreen=>jade;
 Color get line=>Theme.of(context).colorScheme.outlineVariant;
 bool writing=false;
 String recordQuery='';
 String recordType='All';
 final search=TextEditingController();
 late final store=widget.store??OfflineStore();
 late Future<Map<String,List<RowData>>> data=widget.initialData??store.snapshot();
 DateTime selected=DateTime(DateTime.now().year,DateTime.now().month);
 int page=0;
 int? moreSection; // null means More menu; index selects the opened section.
 final purchase=TextEditingController(text:'200');
 @override void dispose(){purchase.dispose();search.dispose();store.close();super.dispose();}
 void refresh(){if(mounted)setState(()=>data=store.snapshot());}
 String get month=>monthKey(selected);
 void shift(int n){setState(()=>selected=DateTime(selected.year,selected.month+n));}
 Future<bool> execute(Future<void> Function() fn)async{
  if(writing)return false;
  writing=true;
  try{await fn();refresh();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Saved on this phone.')));return true;}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save: $e')));return false;}
  finally{writing=false;}
 }
 List<RowData> list(Map<String,List<RowData>> d,String table)=>d[table]??[];
 List<RowData> monthTransactions(Map<String,List<RowData>> d)=>list(d,'transactions').where((t)=>st(t,'date').startsWith(month)).toList()..sort((a,b)=>st(b,'date').compareTo(st(a,'date')));
 int sumType(Iterable<RowData> tx,String type)=>tx.where((t)=>st(t,'type')==type).fold(0,(n,t)=>n+val(t,'amount'));
 int budgetFor(Map<String,List<RowData>> d,String key,String category)=>list(d,'budgets').where((x)=>st(x,'month')==key&&st(x,'category')==category).fold(0,(n,x)=>n+val(x,'amount'));
 int billPaid(Map<String,List<RowData>> d,RowData bill)=>list(d,'transactions').where((x)=>st(x,'type')=='Expense'&&st(x,'bill_id')==st(bill,'code')).fold(0,(n,x)=>n+val(x,'amount'));
 int totalPool(Map<String,List<RowData>> d){
  final ts=list(d,'transactions');
  final closes=list(d,'month_closes').where((x)=>val(x,'entries_ok')==1&&val(x,'balance_ok')==1);
  final op=int.tryParse(st(list(d,'settings').firstWhere((x)=>st(x,'key')=='opening_savings',orElse:()=>{}),'value'))??0;
  return savingsPool(opening:op,transferredOut:sumType(ts,'Savings out'),transferredIn:sumType(ts,'Savings in'),confirmedExtra:closes.fold(0,(n,x)=>n+val(x,'extra')));
 }
 int allocated(Map<String,List<RowData>> d)=>list(d,'allocations').fold(0,(n,x)=>n+val(x,'amount'));
 int buffer(Map<String,List<RowData>> d)=>int.tryParse(st(list(d,'settings').firstWhere((x)=>st(x,'key')=='buffer',orElse:()=>{}),'value'))??20000;
 /// Reserve history is independent from expenses and savings goals.
 List<RowData> reserveHistory(Map<String,List<RowData>> d,int reserveId){
  final rows=list(d,'reserve_movements').where((r)=>val(r,'reserve_id')==reserveId).toList();
  rows.sort((a,b){final date=st(b,'date').compareTo(st(a,'date'));return date!=0?date:val(b,'id').compareTo(val(a,'id'));});
  return rows;
 }
 int reserveNetForMonth(Map<String,List<RowData>> d,String key,{int? reserveId}){
  return list(d,'reserve_movements').where((r)=>st(r,'date').startsWith(key) &&
   (reserveId==null || val(r,'reserve_id')==reserveId)).fold(0,(sum,r)=>
     sum+(st(r,'kind')=='add'?val(r,'amount'):-val(r,'amount')));
 }
 int reserveFundedAt(Map<String,List<RowData>> d,RowData reserve,String thruMonth){
  final id=val(reserve,'id');
  final lastDay=dayKey(DateTime(monthFromKey(thruMonth).year,monthFromKey(thruMonth).month+1,0));
  return val(reserve,'funded')+list(d,'reserve_movements')
   .where((r)=>val(r,'reserve_id')==id && st(r,'date').compareTo(lastDay)<=0)
   .fold(0,(sum,r)=>sum+(st(r,'kind')=='add'?val(r,'amount'):-val(r,'amount')));
 }
 int monthlyReserves(Map<String,List<RowData>> d){
  final chosen=monthFromKey(month);
  final preceding=monthKey(DateTime(chosen.year,chosen.month-1));
  return list(d,'reserves').where((r)=>st(r,'start_month').compareTo(month)<=0 &&
    st(r,'due').substring(0,7).compareTo(month)>=0)
   .fold(0,(sum,r)=>sum+reserveAdditionalHold(
    target:val(r,'target'),fundedBeforeMonth:reserveFundedAt(d,r,preceding),
    netContributedThisMonth:reserveNetForMonth(d,month,reserveId:val(r,'id')),
    due:parseDay(st(r,'due')),month:chosen));
 }
 int unpaidBills(Map<String,List<RowData>> d){
  return list(d,'bills').where((b)=>st(b,'due').startsWith(month)).fold(0,(n,b)=>n+billOutstanding(val(b,'amount'),billPaid(d,b)));
 }
 String monthLabel(DateTime d)=>'${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.year}';
 Widget header(String title,{String? subtitle,Widget? action})=>Padding(padding:EdgeInsets.fromLTRB(4,12,4,10),
  child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(title,style:TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:ink)),
   if(subtitle!=null)Padding(padding:EdgeInsets.only(top:4),child:Text(subtitle,style:TextStyle(color:muted)))
  ])),if(action!=null)action]));
 Widget tile(String title,String subtitle,String trailing,{VoidCallback? onTap,IconData icon=Icons.circle_outlined,Color? tone})=>
  Card(child:ListTile(contentPadding:EdgeInsets.symmetric(horizontal:16,vertical:5),
   leading:CircleAvatar(backgroundColor:(tone??jade).withValues(alpha:.10),child:Icon(icon,color:tone??jade,size:20)),
   title:Text(title,style:TextStyle(fontWeight:FontWeight.w700)),
   subtitle:Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis),
   trailing:Text(trailing,style:TextStyle(fontWeight:FontWeight.w800,color:tone??ink)),onTap:onTap));
 Widget metric(String title,String value,IconData icon,{Color? color})=>Expanded(child:Card(child:Padding(
  padding:EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Icon(icon,color:color??jade),SizedBox(height:12),Text(title,style:TextStyle(color:muted,fontSize:12)),
   SizedBox(height:5),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(value,style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:ink)))
  ]))));

 // Home V2.2 presentation helpers — finance data remains sourced from SQLite.
 String homeDigits(int cents){
  final value=mad(cents.abs()).toStringAsFixed(2).split('.');
  final whole=value[0],parts=<String>[];
  for(var end=whole.length;end>0;end-=3){
   final begin=end-3>0?end-3:0;
   parts.insert(0,whole.substring(begin,end));
  }
  return '${cents<0?'−':''}${parts.join(',')}.${value[1]}';
 }
 String homeMonthName(){
  const names=['January','February','March','April','May','June',
   'July','August','September','October','November','December'];
  return '${names[selected.month-1]} ${selected.year}';
 }
 Widget homeSummary(String label,int value,IconData icon,Color tint,Color iconBg){
  return Expanded(child:Container(
   padding:EdgeInsets.all(13),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(19),
    border:Border.all(color:line)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:38,height:38,decoration:BoxDecoration(color:iconBg,
     borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:tint,size:20)),
    SizedBox(height:11),
    Text(label,maxLines:2,style:TextStyle(color:muted,fontSize:12,height:1.2)),
    SizedBox(height:8),
    FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
     child:Row(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.baseline,
      textBaseline:TextBaseline.alphabetic,children:[
      Text(homeDigits(value),style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:homeNavy)),
      SizedBox(width:5),
      Text('MAD',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:homeText)),
     ])),
   ]),
  ));
 }
 Widget homeQuickAction(String label,IconData icon,Color bg,Color tint,VoidCallback onPressed){
  return Expanded(child:InkWell(
   borderRadius:BorderRadius.circular(15),onTap:onPressed,
   child:Padding(padding:EdgeInsets.symmetric(vertical:4),child:Column(children:[
    Container(width:52,height:52,decoration:BoxDecoration(color:bg,
     borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:tint,size:24)),
    SizedBox(height:7),
    Text(label,maxLines:2,textAlign:TextAlign.center,
     style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:homeText)),
   ])),
  ));
 }
 Widget homeCategory(String category,int spent,int limit){
  final status=categoryBudgetStatus(spent,limit);
  final isOver=status==CategoryBudgetStatus.overBudget;
  final isNear=status==CategoryBudgetStatus.nearLimit;
  final isUnbudgeted=status==CategoryBudgetStatus.unbudgeted;
  final statusColor=isOver?homeOver:(isNear||isUnbudgeted)?homeNear:homeGreen;
  final progress=limit<=0?(spent>0?1.0:0.0):(spent/limit).clamp(0,1).toDouble();
  final description=isOver?'Over budget':
    isUnbudgeted?'No budget set':isNear?'Near limit':'${(spent*100/limit).round()}% used';
  return Container(
   margin:EdgeInsets.only(bottom:10),padding:EdgeInsets.all(15),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(19),
    border:Border.all(color:isOver?Color(0xffE9BEB8):line)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
     Expanded(child:Text(category,style:TextStyle(color:ink,
      fontWeight:FontWeight.w700,fontSize:14))),
     if(isOver)Padding(padding:EdgeInsets.only(right:4),
      child:Icon(Icons.error_outline,color:homeOver,size:17)),
     Text(description,style:TextStyle(color:isOver?homeOver:
      (isNear||isUnbudgeted)?(isDark?homeNear:Color(0xff996522)):homeText,
      fontWeight:FontWeight.w700,fontSize:12)),
    ]),
    SizedBox(height:9),
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Expanded(flex:6,child:Text('${homeDigits(spent)} / ${homeDigits(limit)} MAD',
      maxLines:2,style:TextStyle(color:homeText,fontSize:12))),
     SizedBox(width:5),
     Flexible(flex:5,child:Text(isOver?'Over by ${homeDigits(spent-limit)} MAD':
      isUnbudgeted?'Set a budget':'${homeDigits(limit-spent)} MAD left',
      textAlign:TextAlign.end,softWrap:true,
      style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,
       color:isOver?homeOver:homeText))),
    ]),
    SizedBox(height:11),
    ClipRRect(borderRadius:BorderRadius.circular(12),
     child:LinearProgressIndicator(value:progress,minHeight:9,
      color:statusColor,
      backgroundColor:isOver?Color(0xffF4D9D4):Color(0xffE9F0EB))),
    if(isOver)Padding(padding:EdgeInsets.only(top:10),
      child:Text('Exceeded your budget by ${homeDigits(spent-limit)} MAD '
       '(${((spent/limit-1)*100).round()}% over).',
       style:TextStyle(color:homeOver,fontSize:12))),
   ]),
  );
 }
 Widget navMonth()=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[
  IconButton(onPressed:()=>shift(-1),icon:Icon(Icons.chevron_left)),
  Text(monthLabel(selected),style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
  IconButton(onPressed:()=>shift(1),icon:Icon(Icons.chevron_right)),
 ]);
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(toolbarHeight:page==0?82:72,titleSpacing:8,
   title:PaydayBrand(compact:page!=0),centerTitle:true,
   actions:[IconButton(tooltip:isDark?'Use light appearance':'Use dark appearance',
    onPressed:widget.onToggleTheme==null?null:()=>widget.onToggleTheme!(!isDark),
    icon:Icon(isDark?Icons.light_mode_outlined:Icons.dark_mode_outlined))]),
  body:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
   if(snap.hasError)return Center(child:Text('Local database error: ${snap.error}'));
   if(!snap.hasData)return Center(child:CircularProgressIndicator());
   final d=snap.data!;
   Widget screen;
   switch(page){
    case 0:screen=home(d);break;
    case 1:screen=records(d);break;
    case 2:screen=budgets(d);break;
    case 3:screen=savings(d);break;
    default:screen=more(d);
   }
   return SafeArea(child:ListView(padding:EdgeInsets.fromLTRB(16,4,16,100),children:[if(page!=0 && (page!=4 || moreSection==0 || moreSection==2)) navMonth(),screen]));
  }),
  floatingActionButton:page==1?FloatingActionButton.extended(backgroundColor:jade,foregroundColor:Colors.white,
   onPressed:()=>transactionForm(null),icon:Icon(Icons.add),label:Text('Add entry')):null,
  bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(n)=>setState(() {page=n;moreSection=null;}),destinations:[
    NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),
    NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Records'),
    NavigationDestination(icon:Icon(Icons.tune_outlined),selectedIcon:Icon(Icons.tune),label:'Budgets'),
    NavigationDestination(icon:Icon(Icons.savings_outlined),selectedIcon:Icon(Icons.savings),label:'Savings'),
    NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view),label:'More'),
  ]),
 );

 Widget home(Map<String,List<RowData>> d){
  final ts=monthTransactions(d);
  final income=sumType(ts,'Income');
  final expenses=sumType(ts,'Expense');
  final saved=sumType(ts,'Savings out')-sumType(ts,'Savings in');
  final reserveNet=reserveNetForMonth(d,month);
  final available=income-expenses-saved-reserveNet;
  final savingsGap=(budgetFor(d,month,'Savings goal')-saved).clamp(0,1000000000).toInt();
  final safe=freeAfterPlan(income:income,expenses:expenses+reserveNet,
   transferredOut:sumType(ts,'Savings out'),transferredIn:sumType(ts,'Savings in'),
   unpaidBills:unpaidBills(d),savingsGap:savingsGap,
   reserves:monthlyReserves(d),buffer:buffer(d));
  final categories=list(d,'categories');
  final visibleCategories=categories.where((c){
   final name=st(c,'name');
   return budgetFor(d,month,name)>0 ||
    ts.any((t)=>st(t,'type')=='Expense'&&st(t,'category')==name);
  }).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   SizedBox(height:8),
   Container(padding:EdgeInsets.symmetric(horizontal:8,vertical:6),
    decoration:BoxDecoration(color:surface,
     border:Border.all(color:line),
     borderRadius:BorderRadius.circular(20)),
    child:Row(children:[
     IconButton(tooltip:'Previous month',onPressed:()=>shift(-1),
      icon:Icon(Icons.chevron_left,color:homeNavy)),
     Expanded(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.calendar_today_outlined,color:homeText,size:17),
      SizedBox(width:8),
      Flexible(child:FittedBox(fit:BoxFit.scaleDown,
       child:Text(homeMonthName(),style:TextStyle(color:homeNavy,
        fontWeight:FontWeight.w700,fontSize:16)))),
     ])),
     IconButton(tooltip:'Next month',onPressed:()=>shift(1),
      icon:Icon(Icons.chevron_right,color:homeNavy)),
    ])),
   SizedBox(height:16),
   Container(width:double.infinity,padding:EdgeInsets.all(21),
    decoration:BoxDecoration(color:Color(0xff0B2545),
     borderRadius:BorderRadius.circular(24)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Row(children:[
      Icon(Icons.account_balance_wallet_outlined,color:Color(0xffD7E2E6),size:20),
      SizedBox(width:8),
      Expanded(child:Text('Available this month',style:TextStyle(color:Color(0xffE2EAF0),fontSize:14))),
      SizedBox(width:8),
      Icon(Icons.verified_user_outlined,color:homeCopper,size:21),
     ]),
     SizedBox(height:12),
     FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
      child:Row(mainAxisSize:MainAxisSize.min,
       crossAxisAlignment:CrossAxisAlignment.baseline,
       textBaseline:TextBaseline.alphabetic,children:[
        Text(homeDigits(available),
         style:TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w900)),
        SizedBox(width:9),
        Text('MAD',style:TextStyle(color:homeCopper,fontSize:16,fontWeight:FontWeight.w800)),
       ])),
     SizedBox(height:8),
     Text('After spending, savings and reserves',
      style:TextStyle(color:Color(0xffCDD9DE),fontSize:12)),
     Divider(color:Color(0xff475A6C),height:30),
     Text('Safe after bills and planned savings',
      style:TextStyle(color:Color(0xffD0DCE1),fontSize:12)),
     SizedBox(height:5),
     FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
      child:Row(mainAxisSize:MainAxisSize.min,children:[
       Text(homeDigits(safe),style:TextStyle(color:Colors.white,
        fontSize:21,fontWeight:FontWeight.w800)),
       SizedBox(width:7),
       Text('MAD',style:TextStyle(color:homeCopper,fontSize:12,fontWeight:FontWeight.w700)),
      ])),
    ])),
   SizedBox(height:22),
   Text('Monthly overview',style:TextStyle(color:homeNavy,fontSize:19,
    fontWeight:FontWeight.w800)),
   SizedBox(height:12),
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    homeSummary('Income this month',income,Icons.south_west,
     Color(0xff278777),Color(0xffEAF4EF)),
    SizedBox(width:10),
    homeSummary('Spent this month',expenses,Icons.north_east,
     Color(0xffC28250),Color(0xffFBF0E8)),
   ]),
   SizedBox(height:10),
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    homeSummary('Saved this month',saved,Icons.savings_outlined,
     Color(0xff5D77AA),Color(0xffEDF1FA)),
    SizedBox(width:10),
    homeSummary('Reserved this month',reserveNet,Icons.event_repeat_outlined,
     Color(0xff9170AE),Color(0xffF3EDFA)),
   ]),
   SizedBox(height:22),
   Text('Quick actions',style:TextStyle(color:homeNavy,fontSize:19,
    fontWeight:FontWeight.w800)),
   SizedBox(height:11),
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    homeQuickAction('Expense',Icons.north_east,
     Color(0xffFBF0E8),Color(0xffC28250),()=>transactionForm(null)),
    homeQuickAction('Income',Icons.south_west,
     Color(0xffEAF4EF),Color(0xff278777),
     ()=>transactionForm(null,initialType:'Income')),
    homeQuickAction('Save',Icons.savings_outlined,
     Color(0xffEDF1FA),Color(0xff5D77AA),
     ()=>setState(()=>page=3)),
    homeQuickAction('Reserve',Icons.event_repeat_outlined,
     Color(0xffF3EDFA),Color(0xff9170AE),
     ()=>setState((){page=4;moreSection=1;})),
   ]),
   SizedBox(height:24),
   Divider(color:line),
   SizedBox(height:12),
   Text('Spending by category',style:TextStyle(color:homeNavy,
    fontSize:19,fontWeight:FontWeight.w800)),
   SizedBox(height:5),
   Text('Your monthly budget progress',
    style:TextStyle(color:homeText,fontSize:12)),
   SizedBox(height:13),
   ...visibleCategories.map((c){
    final name=st(c,'name');
    final planned=budgetFor(d,month,name);
    final paid=ts.where((t)=>st(t,'type')=='Expense'&&st(t,'category')==name)
     .fold(0,(n,t)=>n+val(t,'amount'));
    return homeCategory(name,paid,planned);
   }),
   if(visibleCategories.isEmpty)Container(width:double.infinity,
    padding:EdgeInsets.all(15),
    decoration:BoxDecoration(color:surface,
     borderRadius:BorderRadius.circular(18)),
    child:Text('No spending or category budgets for this month.',
     style:TextStyle(color:homeText))),
  ]);
 }
 Widget recordTile(RowData t){final type=st(t,'type');return tile(st(t,'description').isEmpty?st(t,'category'):st(t,'description'),'${st(t,'date')} · ${st(t,'category')} · $type',money(val(t,'amount')),icon:type=='Income'?Icons.call_received:type.startsWith('Savings')?Icons.savings_outlined:Icons.call_made,tone:type=='Income'?jade:amber,onTap:()=>transactionForm(t));}
 Widget records(Map<String,List<RowData>> d){
  final all=monthTransactions(d);
  final ts=all.where((t)=>matchesRecord(t,recordQuery,recordType)).toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Transactions',subtitle:'${ts.length} of ${all.length} entries · ${monthLabel(selected)}'),
   TextField(controller:search,onChanged:(v)=>setState(()=>recordQuery=v),
    decoration:InputDecoration(hintText:'Search description, category or note',
     prefixIcon:Icon(Icons.search),suffixIcon:recordQuery.isEmpty?null:IconButton(
      tooltip:'Clear search',icon:Icon(Icons.close),onPressed:(){search.clear();setState(()=>recordQuery='');}))),
   SizedBox(height:10),
   SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:
    ['All','Expense','Income','Savings out','Savings in'].map((type)=>Padding(
     padding:EdgeInsets.only(right:8),child:ChoiceChip(label:Text(type),
      selected:recordType==type,onSelected:(_)=>setState(()=>recordType=type)))).toList())),
   SizedBox(height:10),
   ...ts.map(recordTile),
   if(ts.isEmpty)Padding(padding:EdgeInsets.all(24),child:Text(all.isEmpty?
    'No entries for this month. Tap Add entry to record your first transaction.':
    'No matching entries. Change the search or type filter.')),
  ]);
 }
 Widget budgets(Map<String,List<RowData>> d){
  final categories=list(d,'categories'),ts=monthTransactions(d);
  final assigned=assignedBudgetCents(list(d,'budgets'),month);
  final inc=budgetFor(d,month,'Income plan'),goal=budgetFor(d,month,'Savings goal');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Monthly budget',subtitle:'A separate plan for ${monthLabel(selected)}'),
   Row(children:[metric('Planned income',money(inc),Icons.trending_up),metric('Assigned',money(assigned),Icons.pie_chart_outline)]),
   Card(child:Padding(padding:EdgeInsets.all(16),child:Text(
    inc==0&&assigned==0?'Set planned income to start assigning your budget.':
    inc==assigned?'No more money to assign. Your income is fully assigned.':
    assigned>inc?'Over assigned by ${money(assigned-inc)}. Reduce budgets or increase planned income.':
    'Available to assign: ${money(inc-assigned)}',
    style:TextStyle(fontWeight:FontWeight.bold,color:inc-assigned>=0?jade:Colors.deepOrange)))),
   tile('Income plan','Expected monthly income',money(inc),icon:Icons.payments_outlined,onTap:()=>budgetForm(d,'Income plan')),
   tile('Savings goal','Monthly savings target',money(goal),icon:Icons.savings_outlined,onTap:()=>budgetForm(d,'Savings goal')),
   header('Spending categories'),
   ...categories.map((c){final name=st(c,'name'),b=budgetFor(d,month,name);
    final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    return tile(name,'${st(c,'group_name')} · Spent ${money(spent)} · Left ${money(b-spent)}',money(b),icon:Icons.tune,onTap:()=>budgetForm(d,name),tone:spent>b&&b>0?Colors.deepOrange:jade);
   }),
   SizedBox(height:12),FilledButton.tonalIcon(onPressed:()=>categoryForm(),icon:Icon(Icons.add),label:Text('Add category'))
  ]);
 }
 Widget savings(Map<String,List<RowData>> d){
  final pool=totalPool(d),used=allocated(d),goals=list(d,'goals'),allocations=list(d,'allocations');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Savings & goals',subtitle:'Allocations divide your savings; they never add new savings'),
   Row(children:[metric('Total saved',money(pool),Icons.account_balance_wallet_outlined),metric('Unassigned',money(pool-used),Icons.savings_outlined)]),
   header('Your goals',action:FilledButton.tonalIcon(onPressed:()=>goalForm(null),icon:Icon(Icons.add),label:Text('New'))),
   ...goals.map((g){final sum=allocations.where((x)=>val(x,'goal_id')==val(g,'id')).fold(0,(n,x)=>n+val(x,'amount'));
    final target=val(g,'target');return Card(child:Padding(padding:EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(st(g,'name'),style:TextStyle(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>goalForm(g),icon:Icon(Icons.edit_outlined))]),
    Text('${money(sum)} / ${money(target)}',style:TextStyle(color:muted)),
    SizedBox(height:9),LinearProgressIndicator(value:(sum/target).clamp(0,1).toDouble(),minHeight:8,borderRadius:BorderRadius.circular(8)),
    SizedBox(height:5),Text('Still needed: ${money((target-sum).clamp(0,target).toInt())}'),
    Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>allocationForm(d,g),icon:Icon(Icons.add),label:Text('Allocate'))),
   ])));}),
   header('Allocations for ${monthLabel(selected)}'),
   ...allocations.where((x)=>st(x,'month')==month).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;return tile(g==null?'Goal deleted':st(g,'name'),month,money(val(a,'amount')),onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))),icon:Icons.check_circle_outline);}),
   if(allocations.where((x)=>st(x,'month')==month).isEmpty)Padding(padding:EdgeInsets.all(10),child:Text('After closing the month, allocate confirmed savings to your goals.')),
   SizedBox(height:10),FilledButton.tonalIcon(onPressed:()=>monthCloseForm(d),icon:Icon(Icons.fact_check_outlined),label:Text('Review and close ${monthLabel(selected)}'))
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
    moreLink('Year overview','Income, spending and savings across the year',
      Icons.bar_chart_rounded,2,selected.year.toString()),
    moreLink('Backups & settings','Export, restore and adjust your local data',
      Icons.settings_outlined,3,'Stored only on this phone'),
    SizedBox(height:15),
    Padding(padding:EdgeInsets.all(8),child:Text(
      'All your financial records stay on this device, with no Google account or internet required.',
      style:TextStyle(color:muted,fontSize:12))),
   ]);
  }
  Widget section;
  switch(moreSection) {
   case 0:section=moreBills(d);break;
   case 1:section=moreReserves(d);break;
   case 2:section=moreYear(d);break;
   default:section=moreBackups(d);
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   TextButton.icon(onPressed:()=>setState(()=>moreSection=null),
    icon:Icon(Icons.arrow_back),label:Text('Back to More')),
   section,
  ]);
 }
 Widget moreLink(String name,String description,IconData symbol,int section,String summary)=>
  Card(clipBehavior:Clip.antiAlias,child:InkWell(
   onTap:()=>setState(()=>moreSection=section),
   child:Padding(padding:EdgeInsets.all(16),child:Row(children:[
    Container(width:48,height:48,
     decoration:BoxDecoration(color:jade.withValues(alpha:.10),borderRadius:BorderRadius.circular(14)),
     child:Icon(symbol,color:jade)),
    SizedBox(width:14),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(name,style:TextStyle(fontWeight:FontWeight.w800,color:ink,fontSize:16)),
     SizedBox(height:4),Text(description,style:TextStyle(color:muted,fontSize:12)),
     SizedBox(height:7),Text(summary,style:TextStyle(color:jade,fontSize:12,fontWeight:FontWeight.w700)),
    ])),
    Icon(Icons.chevron_right,color:Colors.black45)
   ])),
  ));
 Widget moreBills(Map<String,List<RowData>> d){
  final bills=list(d,'bills')..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Bills',subtitle:'Attach the Bill ID when recording an expense',action:FilledButton.tonalIcon(onPressed:()=>billForm(null),icon:Icon(Icons.add),label:Text('New'))),
   ...bills.where((b)=>st(b,'due').startsWith(month)).map((b){final remain=billOutstanding(val(b,'amount'),billPaid(d,b));
    return tile(st(b,'name'),'${st(b,'due')} · ID ${st(b,'code')} · Paid ${money(billPaid(d,b))}',remain==0?'Paid':money(remain),icon:remain==0?Icons.check_circle_outline:Icons.event_outlined,tone:remain==0?jade:amber,onTap:()=>billForm(b));
   }),
   if(!bills.any((b)=>st(b,'due').startsWith(month)))Padding(padding:EdgeInsets.all(8),child:Text('No bills due in this month.'))
  ]);
 }
 Widget moreReserves(Map<String,List<RowData>> d){
  final reserves=list(d,'reserves');
  final now=DateTime.now();
  final todayMonth=monthKey(now);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Occasional expenses',subtitle:'Real money set aside, tracked separately from spending.',
    action:IconButton.filledTonal(onPressed:()=>reserveForm(null),
     icon:Icon(Icons.add),tooltip:'Create a reserve')),
   if(reserves.isEmpty)Card(child:Padding(padding:EdgeInsets.all(18),
    child:Text('Create a reserve for a vacation, annual bill or future purchase. '
      'Record each deposit to see progress and reduce your spendable cash.'))),
   ...reserves.map((r){
    final held=reserveFundedAt(d,r,todayMonth);
    final needed=(val(r,'target')-held).clamp(0,val(r,'target')).toInt();
    final contributed=reserveNetForMonth(d,todayMonth,reserveId:val(r,'id'));
    final next=reserveNextMonthTopUp(
      target:val(r,'target'),currentlyFunded:held,
      due:parseDay(st(r,'due')),selectedMonth:now);
    final goal=val(r,'target');
    return Card(child:Padding(padding:EdgeInsets.all(16),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(st(r,'name'),
       style:TextStyle(color:ink,fontSize:17,fontWeight:FontWeight.w800))),
       IconButton(onPressed:()=>reserveForm(r),tooltip:'Edit reserve goal',
         icon:Icon(Icons.edit_outlined)),
      ]),
      Text('Due ${st(r,'due')}',style:TextStyle(color:muted,fontSize:12)),
      SizedBox(height:12),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
       Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Put aside',style:TextStyle(color:muted,fontSize:12)),
        Text(money(held),style:TextStyle(color:jade,fontWeight:FontWeight.w900,fontSize:20)),
       ]),
       Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text('Still needed',style:TextStyle(color:muted,fontSize:12)),
        Text(money(needed),style:TextStyle(color:ink,fontWeight:FontWeight.w800,fontSize:16)),
       ]),
      ]),
      SizedBox(height:10),
      LinearProgressIndicator(value:goal==0?0:(held/goal).clamp(0,1).toDouble(),
       minHeight:9,borderRadius:BorderRadius.circular(10),backgroundColor:cream,color:jade),
      SizedBox(height:10),
      Text('Set aside this month: ${money(contributed)}',style:TextStyle(fontSize:12)),
      Text(next>0?'Suggested next month: ${money(next)}':
       needed==0?'Target fully funded':'Next month: target due or overdue',
       style:TextStyle(fontSize:12,color:muted)),
      SizedBox(height:15),
      Row(children:[
       Expanded(child:FilledButton.icon(onPressed:needed<=0?null:()=>reserveMovementForm(r,'add'),
        icon:Icon(Icons.add),label:Text('Add money'))),
       SizedBox(width:9),
       Expanded(child:OutlinedButton.icon(onPressed:held<=0?null:()=>reserveMovementForm(r,'release'),
        icon:Icon(Icons.remove),label:Text('Take out'))),
      ]),
      Align(alignment:Alignment.centerRight,child:TextButton.icon(
       onPressed:()=>reserveHistoryForm(r),
       icon:Icon(Icons.history),label:Text('View transfer history'))),
     ])));
   }),
  ]);
 }
 Widget moreYear(Map<String,List<RowData>> d){
  final tx=list(d,'transactions');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Year overview',subtitle:'${selected.year} totals from local transactions'),
   ...List.generate(12,(i){final m=monthKey(DateTime(selected.year,i+1));
    final rows=tx.where((r)=>st(r,'date').startsWith(m));
    final inc=sumType(rows,'Income'),exp=sumType(rows,'Expense'),savings=sumType(rows,'Savings out')-sumType(rows,'Savings in');
    return Card(child:ListTile(title:Text(monthLabel(DateTime(selected.year,i+1))),subtitle:Text('Income ${money(inc)} · Spent ${money(exp)}'),trailing:Text('Saved ${money(savings)}')));
   })
  ]);
 }
 Widget moreBackups(Map<String,List<RowData>> d){
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Privacy & local backups',subtitle:'No sign-in, no cloud connection and no financial data upload'),
   Card(child:Padding(padding:EdgeInsets.all(14),child:Text('All finance entries are stored in a private SQLite database on this device. This version is not app-level encrypted. Export a backup before uninstalling or resetting the phone.'))),
   Row(children:[Expanded(child:OutlinedButton.icon(onPressed:exportBackup,icon:Icon(Icons.ios_share),label:Text('Export backup'))),SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:importBackup,icon:Icon(Icons.file_open),label:Text('Restore')))]),
   SizedBox(height:10),FilledButton.tonal(onPressed:()=>settingsForm(d),child:Text('Settings & cash buffer'))
  ]);
 }
 Future<void> confirmDelete(String title,Future<void> Function() action) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(title),content:Text('This permanently removes the selected local record.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text('Delete'))]));
  if(ok==true)await execute(action);
 }
 /// Scrollable form with a fixed action area that clears Android's system bar.
 Future<void> sheet(String title,Widget Function(BuildContext,StateSetter) builder,
  {Widget Function(BuildContext,StateSetter)? footer}) async{
  await showModalBottomSheet(
   context:context,isScrollControlled:true,useSafeArea:true,
   showDragHandle:true,backgroundColor:surface,
   constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*0.92),
   builder:(c)=>AnimatedPadding(
    duration:Duration(milliseconds:180),curve:Curves.easeOut,
    padding:EdgeInsets.only(bottom:MediaQuery.viewInsetsOf(c).bottom),
    child:SafeArea(top:false,bottom:true,child:Padding(
     padding:EdgeInsets.symmetric(horizontal:18),
     child:StatefulBuilder(builder:(c,rebuild)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
       Padding(padding:EdgeInsets.only(bottom:12),
        child:Align(alignment:Alignment.centerLeft,
         child:Text(title,style:TextStyle(fontSize:23,color:ink,fontWeight:FontWeight.bold)))),
       Flexible(child:SingleChildScrollView(
        keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
        padding:EdgeInsets.only(bottom:footer==null?24:12),
        child:builder(c,rebuild))),
       if(footer!=null)Padding(padding:EdgeInsets.fromLTRB(0,6,0,14),
        child:SizedBox(width:double.infinity,child:footer(c,rebuild))),
      ],
     )),
    )),
   ),
  );
 }
 Widget field(TextEditingController c,String label,{bool number=false,int lines=1})=>Padding(padding:EdgeInsets.only(bottom:12),
  child:TextField(controller:c,maxLines:lines,keyboardType:number?TextInputType.numberWithOptions(decimal:true):TextInputType.text,
   decoration:InputDecoration(labelText:label,isDense:true)));
 int? amount(TextEditingController c,{bool allowZero=false}){
  return parseMoneyCents(c.text,allowZero:allowZero);
 }
 void inputError(String message){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));}
 Future<void> transactionForm(RowData? existing,{RowData? payBill,String? initialType}) async{
  final d=await store.snapshot();if(!mounted)return;
  final prefill=payBill==null?null:prepareBillPayment(
    name:st(payBill,'name'),
    category:st(payBill,'category'),
    code:st(payBill,'code'),
    billAmountCents:val(payBill,'amount'),
    alreadyPaidCents:billPaid(d,payBill),
  );
  if(prefill!=null && prefill.amountCents<=0){
    inputError('This bill is fully paid. No remaining payment is due.');
    return;
  }
  final cats={...list(d,'categories').map((x)=>st(x,'name')),'Salary','Savings'}.toList();
  final desc=TextEditingController(text:existing==null?(prefill?.description??''):st(existing,'description'));
  final note=TextEditingController(text:existing==null?'':st(existing,'note'));
  final bill=TextEditingController(text:existing==null?(prefill?.billId??''):st(existing,'bill_id'));
  final amt=TextEditingController(text:existing==null?(prefill==null?'':mad(prefill.amountCents).toStringAsFixed(2)):mad(val(existing,'amount')).toStringAsFixed(2));
  var type=existing==null?(prefill?.type??initialType??'Expense'):st(existing,'type');
  var category=existing==null?(prefill?.category??(type=='Income'?'Salary':type.startsWith('Savings')?'Savings':'Groceries')):st(existing,'category');
  if(!cats.contains(category))category=cats.first;
  var date=existing==null?(prefill!=null||month==monthKey(DateTime.now())?DateTime.now():selected):parseDay(st(existing,'date'));
  var submitting=false;
  await sheet(existing==null?(prefill==null?'New transaction':'Record bill payment'):'Edit transaction',(c,rebuild)=>Column(children:[
   if(prefill!=null)Padding(padding:EdgeInsets.only(bottom:12),child:Text(
      'Prefilled from your bill. You can change every field; the payment date defaults to today, not the bill due date.',
      style:TextStyle(color:jade,fontSize:12,fontWeight:FontWeight.w600))),
   DropdownButtonFormField<String>(initialValue:type,decoration:InputDecoration(labelText:'Type'),items:['Expense','Income','Savings out','Savings in'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)rebuild((){type=v;category=v=='Income'?'Salary':v.startsWith('Savings')?'Savings':cats.contains('Groceries')?'Groceries':cats.first;});}),
   SizedBox(height:12),
   DropdownButtonFormField<String>(key:ValueKey(type),initialValue:category,decoration:InputDecoration(labelText:'Category'),items:[...cats,if(!cats.contains('Salary'))'Salary',if(!cats.contains('Savings'))'Savings'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)category=v;}),
   SizedBox(height:12),field(amt,'Amount (MAD)',number:true),field(desc,'Description'),field(note,'Note (optional)'),field(bill,'Bill ID (optional)'),
   Row(children:[Icon(Icons.today,size:18),TextButton.icon(icon:Icon(Icons.edit_calendar_outlined),onPressed:()async{final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>date=p);},label:Text('Payment date: ${dayKey(date)}'))]),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete this transaction?',()=>store.removeTransaction(val(existing,'id')));},child:Text('Delete transaction',style:TextStyle(color:Colors.red)))
  ]),footer:(c,rebuild)=>FilledButton.icon(
   icon:Icon(Icons.check_circle_outline),label:Text(submitting?'Saving…':'Save locally'),
   onPressed:submitting?null:()async{
    final cents=amount(amt);
    if(cents==null){inputError('Enter a positive amount.');return;}
    rebuild(()=>submitting=true);
    final success=await execute(()=>store.saveTransaction(
      id:existing==null?null:val(existing,'id'),date:dayKey(date),
      type:type,category:category,amount:cents,
      description:desc.text.trim(),note:note.text.trim(),billId:bill.text.trim()));
    if(c.mounted){if(success){Navigator.pop(c);}else{rebuild(()=>submitting=false);}}
   },
  ));
 }
 Future<void> budgetForm(Map<String,List<RowData>> d,String category)async{
  final budgetMonth=month;
  final original=budgetFor(d,budgetMonth,category);
  final a=TextEditingController(text:mad(original).toStringAsFixed(2));
  final initial=checkBudgetAssignment(rows:list(d,'budgets'),month:budgetMonth,
   category:category,proposed:original);
  var saving=false;
  Future<void> notice(BuildContext c,String title,String message)async{
   await showDialog<void>(context:c,builder:(dialog)=>AlertDialog(title:Text(title),content:Text(message),
    actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:Text('OK'))]));
  }
  await sheet('$category · $budgetMonth',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(category!='Income plan')Padding(padding:EdgeInsets.only(bottom:12),
     child:Text('Maximum total for this category: ${money(initial.maximum)}',
      style:TextStyle(color:muted,fontWeight:FontWeight.w600))),
    field(a,'Budget amount (MAD)',number:true),
   ]),footer:(c,rebuild)=>FilledButton(
    onPressed:saving?null:()async{
     final n=amount(a,allowZero:true);
     if(n==null){await notice(c,'Check the amount','Enter a valid amount with at most two decimal places.');return;}
     rebuild(()=>saving=true);
     try{
      final result=await store.setBudget(budgetMonth,category,n);
      refresh();
      if(!c.mounted)return;
      if(result.fullyAssigned){
       await notice(c,'No more money to assign',
        'Your planned income for $budgetMonth is fully assigned. '
        'Reduce another category or increase planned income to assign more.');
      }
      if(c.mounted)Navigator.pop(c);
     }on BudgetAssignmentException catch(e){
      if(c.mounted)await notice(c,'Budget limit reached',e.check.message);
     }catch(e){
      if(c.mounted)await notice(c,'Could not save budget','$e');
     }finally{
      if(c.mounted)rebuild(()=>saving=false);
     }
    },child:Text(saving?'Saving…':'Save budget')));
 }
 Future<void> categoryForm() async{
  final name=TextEditingController();var group='Essential';
  await sheet('New category',(c,rebuild)=>Column(children:[field(name,'Name'),DropdownButtonFormField<String>(initialValue:group,items:['Essential','Flexible'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)group=v;}),
   SizedBox(height:12),FilledButton(onPressed:()async{await execute(()=>store.addCategory(name.text,group));if(c.mounted)Navigator.pop(c);},child:Text('Add category'))]));
 }
 Future<void> goalForm(RowData? existing) async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name')),target=TextEditingController(text:existing==null?'':mad(val(existing,'target')).toStringAsFixed(2));
  await sheet(existing==null?'Add savings goal':'Edit savings goal',(c,rebuild)=>Column(children:[field(name,'Goal name'),field(target,'Target (MAD)',number:true),
   FilledButton(onPressed:()async{final n=amount(target);if(n==null)return inputError('Invalid target');await execute(()=>store.saveGoal(id:existing==null?null:val(existing,'id'),name:name.text,target:n));if(c.mounted)Navigator.pop(c);},child:Text('Save goal'))]));
 }
 Future<void> allocationForm(Map<String,List<RowData>> d,RowData goal)async{
  final remaining=totalPool(d)-allocated(d),a=TextEditingController();
  await sheet('Allocate to ${st(goal,'name')}',(c,rebuild)=>Column(children:[
   Text('Unassigned savings: ${money(remaining)}\nAllocations are not new savings.'),
   SizedBox(height:12),field(a,'Amount (MAD)',number:true),
   FilledButton(onPressed:()async{
    final n=amount(a);if(n==null||n>remaining)return inputError('Allocation exceeds available savings.');
    // Month must have been reviewed and closed, as in the spreadsheet.
    final closing=list(d,'month_closes').where((x)=>st(x,'month')==month&&val(x,'entries_ok')==1&&val(x,'balance_ok')==1);
    if(closing.isEmpty)return inputError('Close this month before allocating savings.');
    await execute(()=>store.allocate(month,val(goal,'id'),n));if(c.mounted)Navigator.pop(c);
   },child:Text('Allocate savings'))]));
 }
 Future<void> billForm(RowData? existing) async {
  final code=TextEditingController(text:existing==null?'B${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}':st(existing,'code'));
  final name=TextEditingController(text:existing==null?'':st(existing,'name'));
  final note=TextEditingController(text:existing==null?'':st(existing,'note'));
  final value=TextEditingController(text:existing==null?'':mad(val(existing,'amount')).toStringAsFixed(2));
  var date=existing==null?DateTime.now():parseDay(st(existing,'due'));
  var category=existing==null?'Housing':st(existing,'category');
  final d=await store.snapshot();if(!mounted)return;
  await sheet(existing==null?'Add bill':'Edit bill',(c,rebuild)=>Column(children:[
   field(name,'Bill name'),field(code,'Unique Bill ID'),field(value,'Due amount (MAD)',number:true),field(note,'Note'),
   DropdownButtonFormField<String>(initialValue:category,items:list(d,'categories').map((x)=>DropdownMenuItem(value:st(x,'name'),child:Text(st(x,'name')))).toList(),onChanged:(v){if(v!=null)category=v;}),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>date=p);},child:Text('Due: ${dayKey(date)}')),
   FilledButton(onPressed:()async{final n=amount(value);if(n==null)return inputError('Invalid bill amount');await execute(()=>store.saveBill(id:existing==null?null:val(existing,'id'),code:code.text,name:name.text,due:dayKey(date),amount:n,category:category,note:note.text));if(c.mounted)Navigator.pop(c);},child:Text('Save bill')),
   if(existing!=null)Column(children:[
    Text('Outstanding: ${money(billOutstanding(val(existing,'amount'),billPaid(d,existing)))}',
      style:TextStyle(color:ink,fontWeight:FontWeight.w700)),
    SizedBox(height:8),
    SizedBox(width:double.infinity,child:FilledButton.tonalIcon(
     onPressed:billOutstanding(val(existing,'amount'),billPaid(d,existing))==0
      ?null:()async{
       Navigator.pop(c);
       if(mounted)await transactionForm(null,payBill:existing);
      },
     icon:Icon(Icons.payments_outlined),
     label:Text(billOutstanding(val(existing,'amount'),billPaid(d,existing))==0
      ?'Bill fully paid':'Record payment'),
    )),
   ]),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete bill?',()=>store.removeBill(val(existing,'id')));},child:Text('Delete bill',style:TextStyle(color:Colors.red)))
  ]));
 }
 Future<void> reserveMovementForm(RowData reserve,String kind) async {
  final adding=kind=='add';
  final d=await store.snapshot();if(!mounted)return;
  final balance=reserveFundedAt(d,reserve,monthKey(DateTime.now()));
  final needed=(val(reserve,'target')-balance).clamp(0,val(reserve,'target')).toInt();
  final amountController=TextEditingController();
  final noteController=TextEditingController();
  var date=DateTime.now();
  await sheet(adding?'Put money aside':'Take money out',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(st(reserve,'name'),style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:ink)),
    SizedBox(height:7),
    Text('Currently set aside: ${money(balance)}',
      style:TextStyle(color:jade,fontWeight:FontWeight.bold)),
    Text(adding?'Still needed: ${money(needed)}':
      'Money returned to spendable cash when you take it out.',
      style:TextStyle(color:muted,fontSize:12)),
    SizedBox(height:16),
    field(amountController,'Amount (MAD)',number:true),
    field(noteController,'Note (optional)'),
    Row(children:[Icon(Icons.calendar_today_outlined,size:18),
     TextButton.icon(icon:Icon(Icons.edit_calendar_outlined),
      onPressed:()async{
       final picked=await showDatePicker(context:c,initialDate:date,
        firstDate:DateTime(2000),lastDate:DateTime.now());
       if(picked!=null)rebuild(()=>date=picked);
      },
      label:Text('Transfer date: ${dayKey(date)}'),
     ),
    ]),
    Padding(padding:EdgeInsets.only(top:8),
     child:Text('This is a transfer between spendable cash and your reserve, '
       'not an ordinary expense. Record the actual purchase separately when it occurs.',
       style:TextStyle(color:muted,fontSize:12))),
   ]),footer:(c,rebuild)=>FilledButton.icon(
    icon:Icon(adding?Icons.savings_outlined:Icons.undo),
    label:Text(adding?'Record money set aside':'Record withdrawal'),
    onPressed:()async{
     final cents=amount(amountController);
     if(cents==null)return inputError('Enter a valid positive amount.');
     if(adding&&cents>needed)return inputError('Amount exceeds the remaining target.');
     if(!adding&&cents>balance)return inputError('Amount exceeds the saved balance.');
     final success=await execute(()=>store.recordReserveMovement(
      reserveId:val(reserve,'id'),date:dayKey(date),kind:kind,
      amount:cents,note:noteController.text));
     if(success&&c.mounted)Navigator.pop(c);
    },
   ));
 }
 Future<void> reserveHistoryForm(RowData reserve) async {
  final d=await store.snapshot();if(!mounted)return;
  final history=reserveHistory(d,val(reserve,'id'));
  await sheet('Reserve transfer history',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(st(reserve,'name'),style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:ink)),
    SizedBox(height:7),
    Text('Opening funds: ${money(val(reserve,'funded'))}',
      style:TextStyle(color:muted)),
    SizedBox(height:10),
    if(history.isEmpty)Text('No deposits or withdrawals recorded yet.'),
    ...history.map((m)=>ListTile(
     contentPadding:EdgeInsets.zero,
     leading:Icon(st(m,'kind')=='add'?Icons.arrow_downward:Icons.arrow_upward,
       color:st(m,'kind')=='add'?jade:amber),
     title:Text(st(m,'kind')=='add'?'Added to reserve':'Taken out of reserve'),
     subtitle:Text('${st(m,'date')}${st(m,'note').isEmpty?'':' · '+st(m,'note')}'),
     trailing:Text('${st(m,'kind')=='add'?'+':'−'}${money(val(m,'amount'))}',
       style:TextStyle(fontWeight:FontWeight.w800,
         color:st(m,'kind')=='add'?jade:amber)),
    )),
    SizedBox(height:10),
    Text('To correct a previous transfer, record an opposite transfer. '
      'This keeps a dated history of money moving in and out.',
      style:TextStyle(color:muted,fontSize:12)),
   ]));
 }
 Future<void> reserveForm(RowData? existing)async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name'));
  final target=TextEditingController(text:existing==null?'':mad(val(existing,'target')).toStringAsFixed(2));
  final funded=TextEditingController(text:existing==null?'0':mad(val(existing,'funded')).toStringAsFixed(2));
  var due=existing==null?DateTime(DateTime.now().year+1,1):parseDay(st(existing,'due'));
  var start=existing==null?DateTime.now():monthFromKey(st(existing,'start_month'));
  await sheet(existing==null?'Create a reserve':'Edit reserve target',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
   field(name,'Reserve name (e.g. Vacation)'),
   field(target,'Total target (MAD)',number:true),
   if(existing==null)field(funded,'Already put aside before using Payday (MAD)',number:true),
   if(existing!=null)Padding(padding:EdgeInsets.only(bottom:10),
     child:Text('Original opening funds: ${money(val(existing,'funded'))}. '
      'Use Add money / Take out to record changes.',
      style:TextStyle(color:muted,fontSize:12))),
   if(existing==null)Padding(padding:EdgeInsets.only(bottom:10),child:Text(
     'Opening funds are money already saved before this app. '
     'They are not deducted again from cash. New deposits must use Add money.',
     style:TextStyle(color:muted,fontSize:12))),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:due,
    firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>due=p);},
    child:Text('Due: ${dayKey(due)}')),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:start,
    firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>start=p);},
    child:Text('Start month: ${monthKey(start)}')),
   if(existing!=null)TextButton(onPressed:()async{
     Navigator.pop(c);await confirmDelete('Delete reserve?',()=>store.removeReserve(val(existing,'id')));
    },child:Text('Delete reserve',style:TextStyle(color:Colors.red))),
  ]),footer:(c,rebuild)=>FilledButton(
   onPressed:()async{
    final t=amount(target),f=amount(funded,allowZero:true);
    if(t==null||f==null||f>t || due.isBefore(DateTime(start.year,start.month))){
     return inputError('Check the target, opening funds and dates.');
    }
    final success=await execute(()=>store.saveReserve(
     id:existing==null?null:val(existing,'id'),
     name:name.text,target:t,funded:f,due:dayKey(due),startMonth:monthKey(start)));
    if(success&&c.mounted)Navigator.pop(c);
   },child:Text('Save reserve')),
  );
 }
 Future<void> monthCloseForm(Map<String,List<RowData>> d)async{
  final current=list(d,'month_closes').firstWhere((r)=>st(r,'month')==month,orElse:()=>{});
  var checked=val(current,'entries_ok')==1,balanced=val(current,'balance_ok')==1;
  final extra=TextEditingController(text:mad(val(current,'extra')).toStringAsFixed(2));
  final opening=TextEditingController(text:mad(val(current,'opening_balance')).toStringAsFixed(2));
  final ts=monthTransactions(d);
  final inc=sumType(ts,'Income'),spent=sumType(ts,'Expense'),saved=sumType(ts,'Savings out')-sumType(ts,'Savings in');
  final currentMonth=DateTime(DateTime.now().year,DateTime.now().month);
  final available=(inc-spent-saved-reserveNetForMonth(d,month)-unpaidBills(d)-monthlyReserves(d)-buffer(d)).clamp(0,100000000000).toInt();
  await sheet('Close ${monthLabel(selected)}',(c,rebuild)=>Column(children:[
   Text('Estimated available extra: ${money(available)}\nOnly extra savings beyond recorded transfers should be entered.'),
   SizedBox(height:8),CheckboxListTile(value:checked,onChanged:(v)=>rebuild(()=>checked=v??false),title:Text('All transactions checked')),
   CheckboxListTile(value:balanced,onChanged:(v)=>rebuild(()=>balanced=v??false),title:Text('Cash balance checked')),
   field(opening,'Opening spendable cash (MAD)',number:true),field(extra,'Extra saved (MAD)',number:true),
   FilledButton(onPressed:()async{
    if(!selected.isBefore(currentMonth))return inputError('The month must end before closing it.');
    final n=amount(extra,allowZero:true),o=amount(opening,allowZero:true);
    if(n==null||o==null||n>available||!checked||!balanced)return inputError('Complete checks; extra must not exceed available cash.');
    await execute(()=>store.saveMonthClose(month,entriesOk:checked,balanceOk:balanced,extra:n,openingBalance:o));if(c.mounted)Navigator.pop(c);
   },child:Text('Confirm month close'))
  ]));
 }
 Future<void> settingsForm(Map<String,List<RowData>> d)async{
  String find(String k,String fallback)=>st(list(d,'settings').firstWhere((x)=>st(x,'key')==k,orElse:()=>{'value':fallback}),'value');
  final b=TextEditingController(text:mad(int.tryParse(find('buffer','20000'))??20000).toStringAsFixed(2));
  final saved=TextEditingController(text:mad(int.tryParse(find('opening_savings','0'))??0).toStringAsFixed(2));
  await sheet('Local settings',(c,rebuild)=>Column(children:[
   field(b,'Cash buffer (MAD)',number:true),field(saved,'Opening savings (MAD)',number:true),
   Padding(padding:EdgeInsets.all(8),child:Text('These balances are in centimes in the local database and never sent online.')),
   FilledButton(onPressed:()async{
    final bn=amount(b,allowZero:true),sn=amount(saved,allowZero:true);if(bn==null||sn==null)return inputError('Check amounts');
    await execute(()async{await store.setSetting('buffer',bn.toString());await store.setSetting('opening_savings',sn.toString());});if(c.mounted)Navigator.pop(c);
   },child:Text('Save settings'))
  ]));
 }
 Future<void> exportBackup() async{
  try{
   final json=await store.exportJson();
   final dir=await getTemporaryDirectory();
   final f=File('${dir.path}/payday-local-backup-${dayKey(DateTime.now())}.json');
   await f.writeAsString(json,flush:true);
   await Share.shareXFiles([XFile(f.path)],text:'Payday Local backup — store this file privately');
  }catch(e){inputError('Backup export failed: $e');}
 }
 Future<void> importBackup() async{
  try{
   final picker=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json']);
   if(picker==null)return;
   final file=picker.files.single;
   final raw=file.path!=null?await File(file.path!).readAsString():file.bytes!=null?utf8.decode(file.bytes!):null;
   if(raw==null)return inputError('Could not read the backup.');
   if(!mounted)return;
   final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
    title:Text('Restore Payday backup?'),content:Text('This replaces ALL records currently stored in this offline app. Export a backup first.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text('Replace local data'))]));
   if(yes==true)await execute(()=>store.importJson(raw));
  }catch(e){inputError('Restore failed: $e');}
 }
}


