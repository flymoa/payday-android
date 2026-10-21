import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'finance.dart';
import 'offline_store.dart';

void main() {WidgetsFlutterBinding.ensureInitialized();runApp(const PaydayLocal());}
const ink=Color(0xff163A38), jade=Color(0xff087D6B), cream=Color(0xffF5F6F1), amber=Color(0xffC7852E);
typedef RowData=Map<String,Object?>;
String st(RowData row,String key)=>row[key]?.toString()??'';
int val(RowData row,String key)=>(row[key] as num?)?.toInt()??0;
String money(int amount)=>'${mad(amount).toStringAsFixed(2)} MAD';
DateTime parseDay(String text)=>DateTime.tryParse(text)??DateTime.now();
class PaydayLocal extends StatelessWidget {
 const PaydayLocal({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(
  debugShowCheckedModeBanner:false,title:'Payday Local',
  theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:cream,
   colorScheme:ColorScheme.fromSeed(seedColor:jade,primary:jade,surface:Colors.white),
   appBarTheme:const AppBarTheme(backgroundColor:cream,foregroundColor:ink,centerTitle:false),
   cardTheme:CardThemeData(elevation:0,color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
   inputDecorationTheme:InputDecorationTheme(border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
  ),
  home:const FinanceScreen());
}
class FinanceScreen extends StatefulWidget {const FinanceScreen({super.key});@override State<FinanceScreen> createState()=>_FinanceState();}
class _FinanceState extends State<FinanceScreen>{
 final store=OfflineStore();
 late Future<Map<String,List<RowData>>> data=store.snapshot();
 DateTime selected=DateTime(DateTime.now().year,DateTime.now().month);
 int page=0;
 final purchase=TextEditingController(text:'200');
 @override void dispose(){purchase.dispose();store.close();super.dispose();}
 void refresh(){if(mounted)setState(()=>data=store.snapshot());}
 String get month=>monthKey(selected);
 void shift(int n){setState(()=>selected=DateTime(selected.year,selected.month+n));}
 Future<bool> execute(Future<void> Function() fn)async{
  try{await fn();refresh();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved on this phone.')));return true;}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save: $e')));return false;}
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
 int monthlyReserves(Map<String,List<RowData>> d){
  return list(d,'reserves').where((r)=>st(r,'start_month').compareTo(month)<=0&&st(r,'due').substring(0,7).compareTo(month)>=0)
   .fold(0,(n,r)=>n+monthlyReserveTopUp(val(r,'target'),val(r,'funded'),parseDay(st(r,'due')),monthFromKey(st(r,'start_month'))));
 }
 int unpaidBills(Map<String,List<RowData>> d){
  return list(d,'bills').where((b)=>st(b,'due').startsWith(month)).fold(0,(n,b)=>n+billOutstanding(val(b,'amount'),billPaid(d,b)));
 }
 String monthLabel(DateTime d)=>'${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.year}';
 Widget header(String title,{String? subtitle,Widget? action})=>Padding(padding:const EdgeInsets.fromLTRB(4,12,4,10),
  child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:ink)),
   if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:4),child:Text(subtitle,style:TextStyle(color:Colors.grey.shade700)))
  ])),if(action!=null)action]));
 Widget tile(String title,String subtitle,String trailing,{VoidCallback? onTap,IconData icon=Icons.circle_outlined,Color? tone})=>
  Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:5),
   leading:CircleAvatar(backgroundColor:(tone??jade).withValues(alpha:.10),child:Icon(icon,color:tone??jade,size:20)),
   title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),
   subtitle:Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis),
   trailing:Text(trailing,style:TextStyle(fontWeight:FontWeight.w800,color:tone??ink)),onTap:onTap));
 Widget metric(String title,String value,IconData icon,{Color color=jade})=>Expanded(child:Card(child:Padding(
  padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Icon(icon,color:color),const SizedBox(height:12),Text(title,style:const TextStyle(color:Colors.black54,fontSize:12)),
   const SizedBox(height:5),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:ink)))
  ]))));
 Widget navMonth()=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[
  IconButton(onPressed:()=>shift(-1),icon:const Icon(Icons.chevron_left)),
  Text(monthLabel(selected),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
  IconButton(onPressed:()=>shift(1),icon:const Icon(Icons.chevron_right)),
 ]);
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Row(children:[Icon(Icons.wallet_outlined,color:jade),SizedBox(width:10),Text('PAYDAY',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.2)),Text(' LOCAL',style:TextStyle(fontSize:13,color:jade))]),
   actions:[IconButton(tooltip:'Reload local records',onPressed:refresh,icon:const Icon(Icons.refresh))]),
  body:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
   if(snap.hasError)return Center(child:Text('Local database error: ${snap.error}'));
   if(!snap.hasData)return const Center(child:CircularProgressIndicator());
   final d=snap.data!;
   Widget screen;
   switch(page){
    case 0:screen=home(d);break;
    case 1:screen=records(d);break;
    case 2:screen=budgets(d);break;
    case 3:screen=savings(d);break;
    default:screen=more(d);
   }
   return SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,4,16,100),children:[navMonth(),screen]));
  }),
  floatingActionButton:page==0||page==1?FloatingActionButton.extended(backgroundColor:jade,foregroundColor:Colors.white,
   onPressed:()=>transactionForm(null),icon:const Icon(Icons.add),label:const Text('Add entry')):null,
  bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(n)=>setState(()=>page=n),destinations:const [
    NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),
    NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Records'),
    NavigationDestination(icon:Icon(Icons.tune_outlined),selectedIcon:Icon(Icons.tune),label:'Budgets'),
    NavigationDestination(icon:Icon(Icons.savings_outlined),selectedIcon:Icon(Icons.savings),label:'Savings'),
    NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view),label:'More'),
  ]),
 );
 Widget home(Map<String,List<RowData>> d){
  final ts=monthTransactions(d),inc=sumType(ts,'Income'),spent=sumType(ts,'Expense'),out=sumType(ts,'Savings out'),back=sumType(ts,'Savings in');
  final available=inc-spent-out+back;
  final plan=budgetFor(d,month,'Savings goal');
  final gap=(plan-out+back).clamp(0,1000000000).toInt();
  final safe=freeAfterPlan(income:inc,expenses:spent,transferredOut:out,transferredIn:back,unpaidBills:unpaidBills(d),savingsGap:gap,reserves:monthlyReserves(d),buffer:buffer(d));
  final cat=list(d,'categories');
  final leftDays=DateTime(selected.year,selected.month+1,0).day-(DateTime.now().year==selected.year&&DateTime.now().month==selected.month?DateTime.now().day-1:0);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Your money, in focus',subtitle:'Everything stored locally · ${monthLabel(selected)}'),
   Card(color:ink,child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Available this month',style:TextStyle(color:Colors.white70)),
    const SizedBox(height:8),Text(money(available),style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.bold)),
    const Divider(color:Colors.white24,height:25),
    Row(children:[Expanded(child:Text('Safe after bills, goals and buffer',style:TextStyle(color:Colors.white.withValues(alpha:.78)))),
     Text(money(safe),style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))])
   ]))),
   Row(children:[metric('Income',money(inc),Icons.south_west),metric('Spent',money(spent),Icons.north_east,color:amber)]),
   Row(children:[metric('Savings moved',money(out-back),Icons.savings_outlined),metric('Unpaid bills',money(unpaidBills(d)),Icons.event_note_outlined,color:amber)]),
   header('Monthly categories',subtitle:'Budgets follow your selected month and year',action:TextButton(onPressed:()=>setState(()=>page=2),child:const Text('Edit'))),
   ...cat.map((c){final name=st(c,'name'),planned=budgetFor(d,month,name),paid=ts.where((t)=>st(t,'type')=='Expense'&&st(t,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    if(planned==0&&paid==0)return const SizedBox.shrink();
    final fraction=planned<=0?0.0:(paid/planned).clamp(0,1).toDouble();
    return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[
      Row(children:[Expanded(child:Text(name,style:const TextStyle(fontWeight:FontWeight.bold))),Text('${money(paid)} / ${money(planned)}',style:const TextStyle(fontSize:12))]),
      const SizedBox(height:9),LinearProgressIndicator(value:fraction,minHeight:7,borderRadius:BorderRadius.circular(8),color:paid>planned&&planned>0?Colors.deepOrange:jade,backgroundColor:cream),
      const SizedBox(height:6),Align(alignment:Alignment.centerRight,child:Text(planned==0?'Set budget':paid>planned?'Over by ${money(paid-planned)}':'Left ${money(planned-paid)}',style:TextStyle(color:paid>planned&&planned>0?Colors.deepOrange:Colors.black54,fontSize:12))),
    ])));
   }),
   if(cat.every((c)=>budgetFor(d,month,st(c,'name'))==0))const Padding(padding:EdgeInsets.all(10),child:Text('No category budgets yet. Open Budgets to plan this month.')),
   header('Before you buy',subtitle:'Simple cash-based spending check'),
   Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[
    TextField(controller:purchase,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Purchase amount (MAD)',prefixIcon:Icon(Icons.shopping_bag_outlined))),
    const SizedBox(height:12),Builder(builder:(context){final v=double.tryParse(purchase.text.replaceAll(',','.'));final amount=v==null?0:(v*100).round();return Text(amount<=0?'Enter an amount to compare.':amount<=safe?'Within available money · ${money(safe-amount)} remains':'Above safe spending by ${money(amount-safe)}',style:TextStyle(fontWeight:FontWeight.bold,color:amount<=safe?jade:amber));}),
    TextButton(onPressed:()=>setState((){}),child:const Text('Check amount'))
   ]))),
   if(leftDays>0)Padding(padding:const EdgeInsets.all(8),child:Text('Approximate daily safe allowance: ${money((safe.clamp(0,1000000000)/leftDays).floor())} · ${leftDays} days',style:const TextStyle(color:ink))),
   header('Recent transactions'),...ts.take(4).map((r)=>recordTile(r)),
   if(ts.isEmpty)const Text('No transactions yet. Tap Add entry to start.'),
  ]);
 }
 Widget recordTile(RowData t){final type=st(t,'type');return tile(st(t,'description').isEmpty?st(t,'category'):st(t,'description'),'${st(t,'date')} · ${st(t,'category')} · $type',money(val(t,'amount')),icon:type=='Income'?Icons.call_received:type.startsWith('Savings')?Icons.savings_outlined:Icons.call_made,tone:type=='Income'?jade:amber,onTap:()=>transactionForm(t));}
 Widget records(Map<String,List<RowData>> d){
  final ts=monthTransactions(d);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    header('Transactions',subtitle:'${ts.length} entries · only ${monthLabel(selected)}',action:FilledButton.tonalIcon(onPressed:()=>transactionForm(null),icon:const Icon(Icons.add),label:const Text('Add'))),
    ...ts.map(recordTile),
    if(ts.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Nothing recorded for this month. Transactions are never deleted when you change months.'))
  ]);
 }
 Widget budgets(Map<String,List<RowData>> d){
  final categories=list(d,'categories'),ts=monthTransactions(d);
  final planned=categories.fold(0,(n,c)=>n+budgetFor(d,month,st(c,'name')));
  final inc=budgetFor(d,month,'Income plan'),goal=budgetFor(d,month,'Savings goal');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Monthly budget',subtitle:'A separate plan for ${monthLabel(selected)}'),
   Row(children:[metric('Planned income',money(inc),Icons.trending_up),metric('Assigned',money(planned+goal),Icons.pie_chart_outline)]),
   if(inc>0)Card(child:Padding(padding:const EdgeInsets.all(16),child:Text('Unassigned income: ${money(inc-planned-goal)}',style:TextStyle(fontWeight:FontWeight.bold,color:inc-planned-goal>=0?jade:Colors.deepOrange)))),
   tile('Income plan','Expected monthly income',money(inc),icon:Icons.payments_outlined,onTap:()=>budgetForm(d,'Income plan')),
   tile('Savings goal','Monthly savings target',money(goal),icon:Icons.savings_outlined,onTap:()=>budgetForm(d,'Savings goal')),
   header('Spending categories'),
   ...categories.map((c){final name=st(c,'name'),b=budgetFor(d,month,name);
    final spent=ts.where((x)=>st(x,'type')=='Expense'&&st(x,'category')==name).fold(0,(n,x)=>n+val(x,'amount'));
    return tile(name,'${st(c,'group_name')} · Spent ${money(spent)} · Left ${money(b-spent)}',money(b),icon:Icons.tune,onTap:()=>budgetForm(d,name),tone:spent>b&&b>0?Colors.deepOrange:jade);
   }),
   const SizedBox(height:12),FilledButton.tonalIcon(onPressed:()=>categoryForm(),icon:const Icon(Icons.add),label:const Text('Add category'))
  ]);
 }
 Widget savings(Map<String,List<RowData>> d){
  final pool=totalPool(d),used=allocated(d),goals=list(d,'goals'),allocations=list(d,'allocations');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Savings & goals',subtitle:'Allocations divide your savings; they never add new savings'),
   Row(children:[metric('Total saved',money(pool),Icons.account_balance_wallet_outlined),metric('Unassigned',money(pool-used),Icons.savings_outlined)]),
   header('Your goals',action:FilledButton.tonalIcon(onPressed:()=>goalForm(null),icon:const Icon(Icons.add),label:const Text('New'))),
   ...goals.map((g){final sum=allocations.where((x)=>val(x,'goal_id')==val(g,'id')).fold(0,(n,x)=>n+val(x,'amount'));
    final target=val(g,'target');return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text(st(g,'name'),style:const TextStyle(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>goalForm(g),icon:const Icon(Icons.edit_outlined))]),
    Text('${money(sum)} / ${money(target)}',style:const TextStyle(color:Colors.black54)),
    const SizedBox(height:9),LinearProgressIndicator(value:(sum/target).clamp(0,1).toDouble(),minHeight:8,borderRadius:BorderRadius.circular(8)),
    const SizedBox(height:5),Text('Still needed: ${money((target-sum).clamp(0,target).toInt())}'),
    Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>allocationForm(d,g),icon:const Icon(Icons.add),label:const Text('Allocate'))),
   ])));}),
   header('Allocations for ${monthLabel(selected)}'),
   ...allocations.where((x)=>st(x,'month')==month).map((a){final g=goals.where((x)=>val(x,'id')==val(a,'goal_id')).firstOrNull;return tile(g==null?'Goal deleted':st(g,'name'),month,money(val(a,'amount')),onTap:()=>confirmDelete('Delete allocation?',()=>store.deleteAllocation(val(a,'id'))),icon:Icons.check_circle_outline);}),
   if(allocations.where((x)=>st(x,'month')==month).isEmpty)const Padding(padding:EdgeInsets.all(10),child:Text('After closing the month, allocate confirmed savings to your goals.')),
   const SizedBox(height:10),FilledButton.tonalIcon(onPressed:()=>monthCloseForm(d),icon:const Icon(Icons.fact_check_outlined),label:Text('Review and close ${monthLabel(selected)}'))
  ]);
 }
 Widget more(Map<String,List<RowData>> d){
  final bills=list(d,'bills')..sort((a,b)=>st(a,'due').compareTo(st(b,'due')));
  final reserves=list(d,'reserves');
  final tx=list(d,'transactions');
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Bills',subtitle:'Attach the Bill ID when recording an expense',action:FilledButton.tonalIcon(onPressed:()=>billForm(null),icon:const Icon(Icons.add),label:const Text('New'))),
   ...bills.where((b)=>st(b,'due').startsWith(month)).map((b){final remain=billOutstanding(val(b,'amount'),billPaid(d,b));
    return tile(st(b,'name'),'${st(b,'due')} · ID ${st(b,'code')} · Paid ${money(billPaid(d,b))}',remain==0?'Paid':money(remain),icon:remain==0?Icons.check_circle_outline:Icons.event_outlined,tone:remain==0?jade:amber,onTap:()=>billForm(b));
   }),
   if(!bills.any((b)=>st(b,'due').startsWith(month)))const Padding(padding:EdgeInsets.all(8),child:Text('No bills due in this month.')),
   header('Occasional expense reserves',action:FilledButton.tonalIcon(onPressed:()=>reserveForm(null),icon:const Icon(Icons.add),label:const Text('New'))),
   ...reserves.map((r)=>tile(st(r,'name'),'${st(r,'due')} · Funded ${money(val(r,'funded'))} / ${money(val(r,'target'))}','Top up ${money(monthlyReserveTopUp(val(r,'target'),val(r,'funded'),parseDay(st(r,'due')),monthFromKey(st(r,'start_month'))))}',icon:Icons.inventory_2_outlined,onTap:()=>reserveForm(r))),
   header('Year overview',subtitle:'${selected.year} totals from local transactions'),
   ...List.generate(12,(i){final m=monthKey(DateTime(selected.year,i+1));
    final rows=tx.where((r)=>st(r,'date').startsWith(m));
    final inc=sumType(rows,'Income'),exp=sumType(rows,'Expense'),savings=sumType(rows,'Savings out')-sumType(rows,'Savings in');
    return Card(child:ListTile(title:Text(monthLabel(DateTime(selected.year,i+1))),subtitle:Text('Income ${money(inc)} · Spent ${money(exp)}'),trailing:Text('Saved ${money(savings)}')));
   }),
   header('Privacy & local backups',subtitle:'No sign-in, no cloud connection and no financial data upload'),
   const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('All finance entries are stored in a private SQLite database on this device. This version is not app-level encrypted. Export a backup before uninstalling or resetting the phone.'))),
   Row(children:[Expanded(child:OutlinedButton.icon(onPressed:exportBackup,icon:const Icon(Icons.ios_share),label:const Text('Export backup'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:importBackup,icon:const Icon(Icons.file_open),label:const Text('Restore')))]),
   const SizedBox(height:10),FilledButton.tonal(onPressed:()=>settingsForm(d),child:const Text('Settings & cash buffer')),
  ]);
 }
 Future<void> confirmDelete(String title,Future<void> Function() action) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(title),content:const Text('This permanently removes the selected local record.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
  if(ok==true)await execute(action);
 }
 /// Scrollable form with a fixed action area that clears Android's system bar.
 Future<void> sheet(String title,Widget Function(BuildContext,StateSetter) builder,
  {Widget Function(BuildContext,StateSetter)? footer}) async{
  await showModalBottomSheet(
   context:context,isScrollControlled:true,useSafeArea:true,
   showDragHandle:true,backgroundColor:Colors.white,
   constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*0.92),
   builder:(c)=>AnimatedPadding(
    duration:const Duration(milliseconds:180),curve:Curves.easeOut,
    padding:EdgeInsets.only(bottom:MediaQuery.viewInsetsOf(c).bottom),
    child:SafeArea(top:false,bottom:true,child:Padding(
     padding:const EdgeInsets.symmetric(horizontal:18),
     child:StatefulBuilder(builder:(c,rebuild)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
       Padding(padding:const EdgeInsets.only(bottom:12),
        child:Align(alignment:Alignment.centerLeft,
         child:Text(title,style:const TextStyle(fontSize:23,color:ink,fontWeight:FontWeight.bold)))),
       Flexible(child:SingleChildScrollView(
        keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
        padding:EdgeInsets.only(bottom:footer==null?24:12),
        child:builder(c,rebuild))),
       if(footer!=null)Padding(padding:const EdgeInsets.fromLTRB(0,6,0,14),
        child:SizedBox(width:double.infinity,child:footer(c,rebuild))),
      ],
     )),
    )),
   ),
  );
 }
 Widget field(TextEditingController c,String label,{bool number=false,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:12),
  child:TextField(controller:c,maxLines:lines,keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,
   decoration:InputDecoration(labelText:label,isDense:true)));
 int? amount(TextEditingController c,{bool allowZero=false}){
  final d=double.tryParse(c.text.trim().replaceAll(',','.'));
  if(d==null||!d.isFinite||d<0||(!allowZero&&d==0)||d>1000000000)return null;
  return (d*100).round();
 }
 void inputError(String message){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));}
 Future<void> transactionForm(RowData? existing,{String billId=''}) async{
  final d=await store.snapshot();if(!mounted)return;
  final cats=list(d,'categories').map((x)=>st(x,'name')).toList();
  final desc=TextEditingController(text:existing==null?'':st(existing,'description'));
  final note=TextEditingController(text:existing==null?'':st(existing,'note'));
  final bill=TextEditingController(text:existing==null?billId:st(existing,'bill_id'));
  final amt=TextEditingController(text:existing==null?'':mad(val(existing,'amount')).toStringAsFixed(2));
  var type=existing==null?'Expense':st(existing,'type');
  var category=existing==null?'Groceries':st(existing,'category');
  if(!cats.contains(category))category=cats.first;
  var date=existing==null?DateTime.now():parseDay(st(existing,'date'));
  await sheet(existing==null?'New transaction':'Edit transaction',(c,rebuild)=>Column(children:[
   DropdownButtonFormField<String>(initialValue:type,decoration:const InputDecoration(labelText:'Type'),items:['Expense','Income','Savings out','Savings in'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)rebuild(()=>type=v);}),
   const SizedBox(height:12),
   DropdownButtonFormField<String>(key:ValueKey(type),initialValue:cats.contains(category)?category:cats.first,decoration:const InputDecoration(labelText:'Category'),items:[...cats,if(!cats.contains('Salary'))'Salary',if(!cats.contains('Savings'))'Savings'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)category=v;}),
   const SizedBox(height:12),field(amt,'Amount (MAD)',number:true),field(desc,'Description'),field(note,'Note (optional)'),field(bill,'Bill ID (optional)'),
   Row(children:[const Icon(Icons.today,size:18),TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>date=p);},child:Text(dayKey(date)))]),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete this transaction?',()=>store.removeTransaction(val(existing,'id')));},child:const Text('Delete transaction',style:TextStyle(color:Colors.red)))
  ]),footer:(c,rebuild)=>FilledButton.icon(
   icon:const Icon(Icons.check_circle_outline),label:const Text('Save locally'),
   onPressed:()async{
    final cents=amount(amt);
    if(cents==null){inputError('Enter a positive amount.');return;}
    final success=await execute(()=>store.saveTransaction(
      id:existing==null?null:val(existing,'id'),date:dayKey(date),
      type:type,category:category,amount:cents,
      description:desc.text.trim(),note:note.text.trim(),billId:bill.text.trim()));
    if(success&&c.mounted)Navigator.pop(c);
   },
  ));
 }
 Future<void> budgetForm(Map<String,List<RowData>> d,String category)async{
  final a=TextEditingController(text:mad(budgetFor(d,month,category)).toStringAsFixed(2));
  await sheet('$category · $month',(c,rebuild)=>Column(children:[field(a,'Budget amount (MAD)',number:true),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{final n=amount(a,allowZero:true);if(n==null){inputError('Enter a valid amount');return;}await execute(()=>store.setBudget(month,category,n));if(c.mounted)Navigator.pop(c);},child:const Text('Save budget')))]));
 }
 Future<void> categoryForm() async{
  final name=TextEditingController();var group='Essential';
  await sheet('New category',(c,rebuild)=>Column(children:[field(name,'Name'),DropdownButtonFormField<String>(initialValue:group,items:['Essential','Flexible'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)group=v;}),
   const SizedBox(height:12),FilledButton(onPressed:()async{await execute(()=>store.addCategory(name.text,group));if(c.mounted)Navigator.pop(c);},child:const Text('Add category'))]));
 }
 Future<void> goalForm(RowData? existing) async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name')),target=TextEditingController(text:existing==null?'':mad(val(existing,'target')).toStringAsFixed(2));
  await sheet(existing==null?'Add savings goal':'Edit savings goal',(c,rebuild)=>Column(children:[field(name,'Goal name'),field(target,'Target (MAD)',number:true),
   FilledButton(onPressed:()async{final n=amount(target);if(n==null)return inputError('Invalid target');await execute(()=>store.saveGoal(id:existing==null?null:val(existing,'id'),name:name.text,target:n));if(c.mounted)Navigator.pop(c);},child:const Text('Save goal'))]));
 }
 Future<void> allocationForm(Map<String,List<RowData>> d,RowData goal)async{
  final remaining=totalPool(d)-allocated(d),a=TextEditingController();
  await sheet('Allocate to ${st(goal,'name')}',(c,rebuild)=>Column(children:[
   Text('Unassigned savings: ${money(remaining)}\nAllocations are not new savings.'),
   const SizedBox(height:12),field(a,'Amount (MAD)',number:true),
   FilledButton(onPressed:()async{
    final n=amount(a);if(n==null||n>remaining)return inputError('Allocation exceeds available savings.');
    // Month must have been reviewed and closed, as in the spreadsheet.
    final closing=list(d,'month_closes').where((x)=>st(x,'month')==month&&val(x,'entries_ok')==1&&val(x,'balance_ok')==1);
    if(closing.isEmpty)return inputError('Close this month before allocating savings.');
    await execute(()=>store.allocate(month,val(goal,'id'),n));if(c.mounted)Navigator.pop(c);
   },child:const Text('Allocate savings'))]));
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
   FilledButton(onPressed:()async{final n=amount(value);if(n==null)return inputError('Invalid bill amount');await execute(()=>store.saveBill(id:existing==null?null:val(existing,'id'),code:code.text,name:name.text,due:dayKey(date),amount:n,category:category,note:note.text));if(c.mounted)Navigator.pop(c);},child:const Text('Save bill')),
   if(existing!=null)TextButton(onPressed:(){Navigator.pop(c);transactionForm(null,billId:st(existing,'code'));},child:const Text('Record payment using this Bill ID')),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete bill?',()=>store.removeBill(val(existing,'id')));},child:const Text('Delete bill',style:TextStyle(color:Colors.red)))
  ]));
 }
 Future<void> reserveForm(RowData? existing)async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name'));
  final target=TextEditingController(text:existing==null?'':mad(val(existing,'target')).toStringAsFixed(2));
  final funded=TextEditingController(text:existing==null?'0':mad(val(existing,'funded')).toStringAsFixed(2));
  var due=existing==null?DateTime(DateTime.now().year+1,1):parseDay(st(existing,'due'));
  var start=existing==null?DateTime.now():monthFromKey(st(existing,'start_month'));
  await sheet(existing==null?'New expense reserve':'Edit expense reserve',(c,rebuild)=>Column(children:[
   field(name,'Reserve name'),field(target,'Target (MAD)',number:true),field(funded,'Already funded (MAD)',number:true),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:due,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>due=p);},child:Text('Due: ${dayKey(due)}')),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:start,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>start=p);},child:Text('Start month: ${monthKey(start)}')),
   FilledButton(onPressed:()async{final t=amount(target),f=amount(funded,allowZero:true);if(t==null||f==null||due.isBefore(DateTime(start.year,start.month)))return inputError('Check target, funded and dates');
     await execute(()=>store.saveReserve(id:existing==null?null:val(existing,'id'),name:name.text,target:t,funded:f,due:dayKey(due),startMonth:monthKey(start)));if(c.mounted)Navigator.pop(c);},child:const Text('Save reserve')),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete reserve?',()=>store.removeReserve(val(existing,'id')));},child:const Text('Delete reserve',style:TextStyle(color:Colors.red)))
  ]));
 }
 Future<void> monthCloseForm(Map<String,List<RowData>> d)async{
  final current=list(d,'month_closes').firstWhere((r)=>st(r,'month')==month,orElse:()=>{});
  var checked=val(current,'entries_ok')==1,balanced=val(current,'balance_ok')==1;
  final extra=TextEditingController(text:mad(val(current,'extra')).toStringAsFixed(2));
  final opening=TextEditingController(text:mad(val(current,'opening_balance')).toStringAsFixed(2));
  final ts=monthTransactions(d);
  final inc=sumType(ts,'Income'),spent=sumType(ts,'Expense'),saved=sumType(ts,'Savings out')-sumType(ts,'Savings in');
  final currentMonth=DateTime(DateTime.now().year,DateTime.now().month);
  final available=(inc-spent-saved-unpaidBills(d)-monthlyReserves(d)-buffer(d)).clamp(0,100000000000).toInt();
  await sheet('Close ${monthLabel(selected)}',(c,rebuild)=>Column(children:[
   Text('Estimated available extra: ${money(available)}\nOnly extra savings beyond recorded transfers should be entered.'),
   const SizedBox(height:8),CheckboxListTile(value:checked,onChanged:(v)=>rebuild(()=>checked=v??false),title:const Text('All transactions checked')),
   CheckboxListTile(value:balanced,onChanged:(v)=>rebuild(()=>balanced=v??false),title:const Text('Cash balance checked')),
   field(opening,'Opening spendable cash (MAD)',number:true),field(extra,'Extra saved (MAD)',number:true),
   FilledButton(onPressed:()async{
    if(!selected.isBefore(currentMonth))return inputError('The month must end before closing it.');
    final n=amount(extra,allowZero:true),o=amount(opening,allowZero:true);
    if(n==null||o==null||n>available||!checked||!balanced)return inputError('Complete checks; extra must not exceed available cash.');
    await execute(()=>store.saveMonthClose(month,entriesOk:checked,balanceOk:balanced,extra:n,openingBalance:o));if(c.mounted)Navigator.pop(c);
   },child:const Text('Confirm month close'))
  ]));
 }
 Future<void> settingsForm(Map<String,List<RowData>> d)async{
  String find(String k,String fallback)=>st(list(d,'settings').firstWhere((x)=>st(x,'key')==k,orElse:()=>{'value':fallback}),'value');
  final b=TextEditingController(text:mad(int.tryParse(find('buffer','20000'))??20000).toStringAsFixed(2));
  final saved=TextEditingController(text:mad(int.tryParse(find('opening_savings','0'))??0).toStringAsFixed(2));
  await sheet('Local settings',(c,rebuild)=>Column(children:[
   field(b,'Cash buffer (MAD)',number:true),field(saved,'Opening savings (MAD)',number:true),
   const Padding(padding:EdgeInsets.all(8),child:Text('These balances are in centimes in the local database and never sent online.')),
   FilledButton(onPressed:()async{
    final bn=amount(b,allowZero:true),sn=amount(saved,allowZero:true);if(bn==null||sn==null)return inputError('Check amounts');
    await execute(()async{await store.setSetting('buffer',bn.toString());await store.setSetting('opening_savings',sn.toString());});if(c.mounted)Navigator.pop(c);
   },child:const Text('Save settings'))
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
   final raw=file.path!=null?await File(file.path!).readAsString():file.bytes!=null?String.fromCharCodes(file.bytes!):null;
   if(raw==null)return inputError('Could not read the backup.');
   if(!mounted)return;
   final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
    title:const Text('Restore Payday backup?'),content:const Text('This replaces ALL records currently stored in this offline app. Export a backup first.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Replace local data'))]));
   if(yes==true)await execute(()=>store.importJson(raw));
  }catch(e){inputError('Restore failed: $e');}
 }
}
