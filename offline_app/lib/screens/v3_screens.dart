// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _V3Screens on _FinanceState {
 // ------------------------------------------------------------------ quick adds
 List<QuickAdd> quickAddsOf(Map<String,List<RowData>> d)=>decodeQuickAdds(Ledger(d).setting(quickAddKey));

 /// Home: one tap records a usual expense today.
 Widget quickAddRow(Map<String,List<RowData>> d){
  final qs=quickAddsOf(d);
  if(qs.isEmpty)return const SizedBox.shrink();
  return Padding(key:ValueKey('home-quick-adds'),padding:EdgeInsets.only(top:PaydaySpace.lg),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Expanded(child:Text(tr(context,'Quick add').toUpperCase(),style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w800,color:muted,letterSpacing:language=='ar'?0:.4))),
    TextButton(key:ValueKey('quick-adds-edit'),onPressed:()=>quickAddsManager(),child:LText('Edit',style:TextStyle(fontWeight:FontWeight.w700)))]),
   SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
    for(var i=0;i<qs.length;i++)Padding(padding:EdgeInsetsDirectional.only(end:8),child:Material(key:ValueKey('quick-add-$i'),color:surface,
     shape:StadiumBorder(side:BorderSide(color:line)),child:InkWell(customBorder:const StadiumBorder(),onTap:()=>useQuickAdd(qs[i]),
      child:Padding(padding:EdgeInsetsDirectional.fromSTEB(6,6,14,6),child:Row(mainAxisSize:MainAxisSize.min,children:[
       PaydayCategoryIcon(qs[i].category,size:30),SizedBox(width:8),
       Text(qs[i].name,style:TextStyle(fontWeight:FontWeight.w700,color:ink)),SizedBox(width:6),
       Text(localizedWhole(qs[i].amount,language),style:TextStyle(fontWeight:FontWeight.w600,color:muted,fontFeatures:PaydayText.tabular)),
      ]))))),
   ])),
  ]));
 }

 Future<void> useQuickAdd(QuickAdd q)async{
  final before=await store.snapshot();
  final known=list(before,'transactions').map((t)=>val(t,'id')).toSet();
  final wallets=walletSetupOf(before);
  final ok=await execute(()=>store.saveTransaction(date:dayKey(DateTime.now()),type:'Expense',category:q.category,amount:q.amount,
   description:q.name,note:'',billId:'',account:wallets==null?null:(q.wallet??'Cash')),saved:'Saved · {0} {1}.'.replaceAll('{0}',money(q.amount)).replaceAll('{1}',q.name));
  if(!ok||!mounted)return;
  final after=await store.snapshot();
  final added=list(after,'transactions').where((t)=>!known.contains(val(t,'id'))).map((t)=>val(t,'id')).toList();
  if(added.isEmpty||!mounted)return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText('Saved · {0} {1}.'.replaceAll('{0}',money(q.amount)).replaceAll('{1}',q.name)),
   action:SnackBarAction(label:tr(context,'Undo'),onPressed:()async{await store.deleteTransactionForUndo(added.first);refresh();})));
  await warnIfBudgetCrossed(q.category,monthKey(DateTime.now()),q.amount,0);
 }

 Future<void> saveQuickAdds(List<QuickAdd> qs)=>execute(()=>store.setSetting(quickAddKey,encodeQuickAdds(qs)),saved:'Quick adds saved.');

 Future<void> quickAddsManager()async{
  final d=await store.snapshot();if(!mounted)return;
  var qs=quickAddsOf(d);
  await sheet('Quick adds',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText('Quick adds appear on Home. One tap records the expense today.',style:TextStyle(color:muted)),
   SizedBox(height:12),
   if(qs.isEmpty)PaydayEmpty(icon:Icons.bolt_outlined,message:'No quick adds yet. Save an expense as a quick add from its More details.')
   else groupedRows([for(var i=0;i<qs.length;i++)listRow(key:ValueKey('quick-add-row-$i'),leading:PaydayCategoryIcon(qs[i].category,size:38),
    title:rowTitle(qs[i].name,raw:true),subtitle:categoryLabel(context,qs[i].category),amount:listMoney(qs[i].amount),
    trailing:IconButton(tooltip:tr(context,'Delete'),icon:PaydayAppIcon(Icons.delete_outline,size:20,color:danger),onPressed:()async{
     qs=[...qs]..removeAt(i);await saveQuickAdds(qs);rebuild((){});}))]),
  ]),footer:(c,rebuild)=>FilledButton(onPressed:()=>Navigator.pop(c),child:LText('Done')));
 }

 // ------------------------------------------------------------------ split
 /// Splits one receipt across categories. Returns the parts, or null when cancelled.
 Future<List<(String,int)>?> splitForm(List<String> cats,int total,String first)async{
  final parts=<(String,TextEditingController)>[(first.isEmpty?cats.first:first,TextEditingController(text:inputNumber(total))),
   (cats.firstWhere((x)=>x!=first,orElse:()=>cats.first),TextEditingController())];
  List<(String,int)>? result;
  await sheet('Split expense',(c,rebuild){
   final sum=parts.fold<int>(0,(n,p)=>n+(evalAmountCents(p.$2.text)??0));
   final left=total-sum;
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText('One receipt, several categories. The parts must add up to the total.',style:TextStyle(color:muted)),
    SizedBox(height:12),
    Row(children:[
     Expanded(child:LText('Total {0}'.replaceAll('{0}',money(total)),style:TextStyle(fontWeight:FontWeight.w700))),
     LText('Left {0}'.replaceAll('{0}',money(left)),key:ValueKey('split-left'),style:TextStyle(fontWeight:FontWeight.w800,color:left==0?jade:danger)),
    ]),
    SizedBox(height:12),
    for(var i=0;i<parts.length;i++)Padding(padding:EdgeInsets.only(bottom:10),child:Row(children:[
     Expanded(flex:3,child:DropdownButtonFormField<String>(key:ValueKey('split-category-$i'),initialValue:parts[i].$1,isExpanded:true,
      items:[for(final x in cats)DropdownMenuItem(value:x,child:LText(x,category:true,maxLines:1,overflow:TextOverflow.ellipsis))],
      onChanged:(v){if(v!=null)rebuild(()=>parts[i]=(v,parts[i].$2));},decoration:const InputDecoration(isDense:true))),
     SizedBox(width:10),
     Expanded(flex:2,child:TextField(key:ValueKey('split-amount-$i'),controller:parts[i].$2,keyboardType:const TextInputType.numberWithOptions(decimal:true),
      textAlign:TextAlign.end,onChanged:(_)=>rebuild((){}),decoration:const InputDecoration(isDense:true))),
     if(parts.length>2)IconButton(tooltip:tr(context,'Delete'),icon:PaydayAppIcon(Icons.close,size:18),onPressed:()=>rebuild(()=>parts.removeAt(i))),
    ])),
    TextButton.icon(key:ValueKey('split-add-part'),onPressed:()=>rebuild(()=>parts.add((cats.first,TextEditingController(text:left>0?inputNumber(left):''))))
     ,icon:PaydayAppIcon(Icons.add),label:LText('Add a part')),
   ]);
  },footer:(c,rebuild)=>FilledButton(key:ValueKey('split-done'),onPressed:(){
   final values=[for(final p in parts)(p.$1,evalAmountCents(p.$2.text)??0)].where((p)=>p.$2>0).toList();
   if(values.fold<int>(0,(n,p)=>n+p.$2)!=total){inputError('The parts must add up to the total.');return;}
   if(values.length<2){inputError('Add at least two parts.');return;}
   result=values;Navigator.pop(c);
  },child:LText('Done')));
  return result;
 }

 // ------------------------------------------------------------------ paste a bank message
 /// Reads the clipboard; returns what a bank SMS says, or tells the user nothing was found.
 Future<BankMessage?> pasteBankMessage()async{
  final data=await Clipboard.getData(Clipboard.kTextPlain);
  final text=data?.text??'';
  final parsed=text.isEmpty?null:parseBankMessage(text);
  if(parsed==null){inputError('Copy a bank or wallet message first, then tap Paste.');return null;}
  return parsed;
 }

 // ------------------------------------------------------------------ kridi
 List<Kridi> kridiOf(Map<String,List<RowData>> d)=>decodeKridi(Ledger(d).setting(kridiKey));
 Future<bool> saveKridi(List<Kridi> list,{String saved='Saved on this phone.'})=>execute(()=>store.setSetting(kridiKey,encodeKridi(list)),saved:saved);
 IconData kridiIcon(Kridi k)=>k.kind=='shop'?Icons.storefront_outlined:k.kind=='loan'?Icons.directions_car_outlined:Icons.people_outline;

 Widget moreKridi(Map<String,List<RowData>> d){
  final all=kridiOf(d);
  final open=all.where((k)=>k.balance!=0).toList();
  final owe=open.where((k)=>k.iOwe).fold<int>(0,(n,k)=>n+k.balance);
  final owed=open.where((k)=>!k.iOwe).fold<int>(0,(n,k)=>n+k.balance);
  final income=budgetFor(d,month,'Income plan')>0?budgetFor(d,month,'Income plan'):sumType(monthTransactions(d),'Income');
  final share=repaymentShare(all,income);
  Widget total(String label,int v,Color color,String sub)=>Expanded(child:(Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.sm,0,PaydaySpace.sm),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(label,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:muted)),SizedBox(height:4),
   FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText(summaryMoney(v),style:PaydayText.figure.copyWith(color:color))),
   SizedBox(height:2),LText(sub,style:TextStyle(fontSize:PaydayType.caption,color:muted)),
  ]))));
  final people=open.where((k)=>k.kind!='loan').toList(),loans=open.where((k)=>k.kind=='loan').toList();
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[
    total('I owe',owe,danger,'{0} open'.replaceAll('{0}','${open.where((k)=>k.iOwe).length}')),SizedBox(width:10),
    total('Owed to me',owed,jade,'{0} open'.replaceAll('{0}','${open.where((k)=>!k.iOwe).length}')),
   ]),
   if(loans.isNotEmpty)Padding(padding:EdgeInsets.only(top:PaydaySpace.md),child:(Padding(key:ValueKey('kridi-gauge'),padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.sm,PaydaySpace.xs,PaydaySpace.sm),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:LText('Repayments vs income',style:TextStyle(fontWeight:FontWeight.w700))),
     Text('$share%',style:PaydayText.figure.copyWith(color:share>=40?danger:share>=30?saffronText:jade))]),
    SizedBox(height:8),
    LayoutBuilder(builder:(_,b)=>Stack(clipBehavior:Clip.none,children:[
     PaydayProgress(value:(share/60).clamp(0,1).toDouble(),color:share>=40?danger:share>=30?warn:jade),
     PositionedDirectional(start:b.maxWidth*40/60-1,top:-4,child:Container(width:2,height:16,color:danger)),
    ])),
    SizedBox(height:6),
    LText(income<=0?'Add your planned income in Budgets to see this.':'Red line at 40%: above it, repayments start to squeeze the month.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
   ])))),
   Padding(padding:EdgeInsets.only(top:PaydaySpace.lg,bottom:PaydaySpace.sm),child:LText('People & shops',style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink))),
   if(people.isEmpty)PaydayEmpty(icon:Icons.people_outline,message:'No kridi yet. Note money you borrowed, lent, or bought on carnet at the hanout.')
   else groupedRows([for(final k in people)listRow(key:ValueKey('kridi-${k.id}'),leading:iconTile(kridiIcon(k)),title:rowTitle(k.name,raw:true),
    subtitle:k.kind=='shop'?'Carnet':k.kind=='lent'?'I lent':'I borrowed',amount:'${k.iOwe?'−':'+'}${listMoney(k.balance)}',amountColor:k.iOwe?danger:jade,
    onTap:()=>kridiDetails(k.id))]),
   if(loans.isNotEmpty)...[
    Padding(padding:EdgeInsets.only(top:PaydaySpace.lg,bottom:PaydaySpace.sm),child:LText('Instalments',style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink))),
    groupedRows([for(final k in loans)listRow(key:ValueKey('kridi-${k.id}'),leading:iconTile(kridiIcon(k)),title:rowTitle(k.name,raw:true),
     subtitle:'{0} of {1} paid · {2} a month'.replaceAll('{0}','${k.paidCount}').replaceAll('{1}','${k.months}').replaceAll('{2}',money(k.monthly)),
     amount:'−${listMoney(k.balance)}',amountColor:danger,onTap:()=>kridiDetails(k.id))]),
   ],
   listAction('Add kridi',Icons.add,()=>kridiForm(),key:ValueKey('kridi-add')),
   Padding(padding:EdgeInsets.only(top:10),child:LText('Kridi keeps track of who owes what. Record the spending itself as a normal expense.',style:TextStyle(fontSize:PaydayType.caption,color:muted))),
  ]);
 }

 Future<void> kridiForm()async{
  final d=await store.snapshot();if(!mounted)return;
  var kind='borrowed';final name=TextEditingController(),value=TextEditingController(),months=TextEditingController(text:'12');
  await sheet('Add kridi',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Wrap(spacing:8,runSpacing:8,children:[
    for(final k in const [('borrowed','I borrowed'),('lent','I lent'),('shop','Carnet'),('loan','Instalments')])
     PaydayPill(key:ValueKey('kridi-kind-${k.$1}'),label:k.$2,selected:kind==k.$1,onTap:()=>rebuild(()=>kind=k.$1)),
   ]),
   SizedBox(height:14),
   field(name,kind=='shop'?'Shop':kind=='loan'?'Loan':'Who'),
   field(value,kind=='loan'?'Monthly instalment ({0})'.replaceAll('{0}',currencyLabel(currency,language)):'Amount ({0})'.replaceAll('{0}',currencyLabel(currency,language)),number:true),
   if(kind=='loan')field(months,'Instalments left',number:true),
   LText(kind=='shop'?'Each time you buy on carnet, add it here. Pay back when you settle with the shop.':
    kind=='loan'?'Each instalment you pay lowers what is left.':
    'Borrowed money is not income: it only shows here until you pay it back.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
  ]),footer:(c,rebuild)=>FilledButton(key:ValueKey('kridi-save'),onPressed:()async{
   final n=amount(value);if(name.text.trim().isEmpty){inputError('Enter a name.');return;}
   if(n==null){inputError('Enter a positive amount.');return;}
   final list_=kridiOf(d);final id=list_.fold<int>(0,(a,k)=>k.id>a?k.id:a)+1;
   final m=int.tryParse(months.text.trim())??0;
   if(kind=='loan'&&m<=0){inputError('Enter how many instalments are left.');return;}
   list_.add(Kridi(id:id,name:name.text.trim(),kind:kind,monthly:kind=='loan'?n:0,months:kind=='loan'?m:0,
    moves:[{'date':dayKey(DateTime.now()),'amount':kind=='loan'?n*m:n,'note':''}]));
   if(await saveKridi(list_,saved:'Kridi saved.')&&c.mounted)Navigator.pop(c);
  },child:LText('Save')));
 }

 Future<void> kridiDetails(int id)async{
  final d=await store.snapshot();if(!mounted)return;
  final list_=kridiOf(d);final k=list_.firstWhere((x)=>x.id==id);
  final value=TextEditingController(text:k.kind=='loan'?inputNumber(k.monthly):'');
  await sheet(k.name,(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Center(child:Column(children:[
    iconTile(kridiIcon(k),size:52),SizedBox(height:8),
    LText(k.iOwe?'You owe':'Owed to you',style:TextStyle(color:muted,fontWeight:FontWeight.w700)),
    Text(money(k.balance),key:ValueKey('kridi-balance'),style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.figure,fontWeight:FontWeight.w800,fontFeatures:PaydayText.tabular,color:k.iOwe?danger:jade)),
   ])),
   SizedBox(height:14),
   field(value,'Amount ({0})'.replaceAll('{0}',currencyLabel(currency,language)),number:true),
   Row(children:[
    Expanded(child:FilledButton.icon(key:ValueKey('kridi-pay'),onPressed:()async{
     final n=amount(value);if(n==null){inputError('Enter a positive amount.');return;}
     if(n>k.balance){inputError('That is more than what is left.');return;}
     k.moves.add({'date':dayKey(DateTime.now()),'amount':-n,'note':''});
     if(await saveKridi(list_,saved:k.iOwe?'Paid back.':'Received.')&&c.mounted)Navigator.pop(c);
    },icon:PaydayAppIcon(Icons.check),label:LText(k.iOwe?'Pay back':'Received'))),
    if(k.kind!='loan')...[SizedBox(width:10),Expanded(child:OutlinedButton.icon(key:ValueKey('kridi-more'),onPressed:()async{
     final n=amount(value);if(n==null){inputError('Enter a positive amount.');return;}
     k.moves.add({'date':dayKey(DateTime.now()),'amount':n,'note':''});
     if(await saveKridi(list_)&&c.mounted)Navigator.pop(c);
    },icon:PaydayAppIcon(Icons.add),label:LText(k.kind=='shop'?'New buy':'Add more')))],
   ]),
   SizedBox(height:14),
   LText('History',style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink)),
   SizedBox(height:8),
   groupedRows([for(final m in k.moves.reversed)listRow(leading:iconTile((m['amount'] as int)<0?Icons.check:Icons.add,size:36),
    title:rowTitle((m['amount'] as int)<0?(k.iOwe?'Paid back':'Received'):(k.kind=='shop'?'Bought on carnet':'Added')),
    subtitle:shortDay(m['date'] as String),amount:'${(m['amount'] as int)<0?'−':'+'}${listMoney((m['amount'] as int).abs())}')]),
   TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete this kridi?',()async{
    final rest=list_.where((x)=>x.id!=id).toList();await store.setSetting(kridiKey,encodeKridi(rest));});},
    child:LText('Delete',style:TextStyle(color:danger))),
  ]));
 }

 // ------------------------------------------------------------------ daret
 List<Daret> daretsOf(Map<String,List<RowData>> d)=>decodeDarets(Ledger(d).setting(daretKey));

 /// Money · Owed & Daret: what people owe (kridi), then the rotating savings circles.
 /// One tab because both are money moving between you and people you know.
 Widget owedAndDaret(Map<String,List<RowData>> d)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  moreKridi(d),
  Padding(padding:EdgeInsetsDirectional.fromSTEB(0,PaydaySpace.xl,0,PaydaySpace.sm),   child:LText('Daret',key:ValueKey('daret-section'),style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.section,fontWeight:FontWeight.w800,color:ink))),
  moreDaret(d),
 ]);

 Widget moreDaret(Map<String,List<RowData>> d){
  final all=daretsOf(d);
  final now=monthKey(DateTime.now());
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   if(all.isEmpty)PaydayEmpty(icon:Icons.autorenew,message:'No daret yet. Add one to track your payments and your turn.'),
   // Each daret sits on the page between hairlines; the round of turns is its own visual.
   for(final r in all)DecoratedBox(decoration:BoxDecoration(border:Border(bottom:BorderSide(color:line))),child:Padding(key:ValueKey('daret-${r.id}'),padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.md,0,PaydaySpace.lg),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[iconTile(Icons.autorenew,size:40),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(r.name,style:PaydayText.rowTitle.copyWith(color:ink)),
     LText('{0} people · {1} each month'.replaceAll('{0}','${r.members}').replaceAll('{1}',money(r.amount)),style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    ])),IconButton(tooltip:tr(context,'Delete'),icon:PaydayAppIcon(Icons.delete_outline,size:20,color:muted),onPressed:()=>confirmDelete('Delete this daret?',
     ()async{await store.setSetting(daretKey,encodeDarets(all.where((x)=>x.id!=r.id).toList()));}))]),
    SizedBox(height:12),
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(var i=1;i<=r.members;i++)Padding(padding:EdgeInsetsDirectional.only(end:6),child:Column(children:[
     // Paid turns: solid emerald. Your turn: a 2px emerald ring on mint. Saffron stays on the add button.
     Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,
      color:r.paid.contains(r.monthOf(i))?jade:i==r.myTurn?(isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint):surface,
      border:Border.all(color:i==r.myTurn?jade:line,width:i==r.myTurn?2:1)),
      child:Text('$i',style:TextStyle(fontWeight:FontWeight.w800,fontSize:PaydayType.caption,fontFeatures:PaydayText.tabular,
       color:r.paid.contains(r.monthOf(i))?Theme.of(context).colorScheme.onPrimary:i==r.myTurn?jade:ink))),
     SizedBox(height:3),Text(localizedShortMonth(r.monthOf(i),language),style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600,color:muted)),
    ]))])),
    SizedBox(height:12),
    Container(padding:EdgeInsets.all(PaydaySpace.md),decoration:BoxDecoration(color:isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint,borderRadius:BorderRadius.circular(PaydayRadius.lg)),
     child:Row(children:[PaydayAppIcon(Icons.star_outline,color:jade),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      LText('Your turn: {0}'.replaceAll('{0}',localizedMonth(DateTime.parse('${r.monthOf(r.myTurn)}-01'),language)),style:TextStyle(fontWeight:FontWeight.w800,color:jade)),
      LText('You receive {0}. Paid in so far: {1}.'.replaceAll('{0}',money(r.pot)).replaceAll('{1}',money(r.paidIn)),style:TextStyle(fontSize:PaydayType.caption,color:ink)),
     ]))])),
    SizedBox(height:12),
    if(!r.finished&&!r.paid.contains(now)&&now.compareTo(r.start)>=0)SizedBox(width:double.infinity,child:FilledButton.icon(key:ValueKey('daret-pay-${r.id}'),
     onPressed:()=>daretPay(r.id),icon:PaydayAppIcon(Icons.check),label:LText('Pay {0} for {1}'.replaceAll('{0}',money(r.amount)).replaceAll('{1}',localizedMonth(DateTime.now(),language))))),
    if(!r.received&&now.compareTo(r.monthOf(r.myTurn))>=0)Padding(padding:EdgeInsets.only(top:8),child:SizedBox(width:double.infinity,child:OutlinedButton.icon(key:ValueKey('daret-receive-${r.id}'),
     onPressed:()=>daretReceive(r.id),icon:PaydayAppIcon(Icons.download_outlined),label:LText('Receive {0}'.replaceAll('{0}',money(r.pot)))))),
   ]))),
   listAction('New daret',Icons.add,()=>daretForm(),key:ValueKey('daret-add')),
   Padding(padding:EdgeInsets.only(top:10),child:LText('Payments and the pot are recorded under Daret, so over a full round they balance out.',style:TextStyle(fontSize:PaydayType.caption,color:muted))),
  ]);
 }

 Future<void> daretPay(int id)async{
  final d=await store.snapshot();final all=daretsOf(d);final r=all.firstWhere((x)=>x.id==id);
  final wallets=walletSetupOf(d);final now=monthKey(DateTime.now());
  final ok=await execute(()async{
   await store.saveTransaction(date:dayKey(DateTime.now()),type:'Expense',category:'Daret',amount:r.amount,description:r.name,note:'Daret',billId:'',account:wallets==null?null:'Cash');
   r.paid.add(now);await store.setSetting(daretKey,encodeDarets(all));
  },saved:'Daret payment saved.');
  if(!ok)return;
 }
 Future<void> daretReceive(int id)async{
  final d=await store.snapshot();final all=daretsOf(d);final r=all.firstWhere((x)=>x.id==id);
  final wallets=walletSetupOf(d);
  await execute(()async{
   await store.saveTransaction(date:dayKey(DateTime.now()),type:'Income',category:'Daret',amount:r.pot,description:r.name,note:'Daret',billId:'',account:wallets==null?null:'Cash');
   r.received=true;await store.setSetting(daretKey,encodeDarets(all));
  },saved:'Pot received.');
 }

 Future<void> daretForm()async{
  final d=await store.snapshot();if(!mounted)return;
  final name=TextEditingController(),members=TextEditingController(text:'10'),value=TextEditingController(),turn=TextEditingController(text:'1');
  var start=DateTime(DateTime.now().year,DateTime.now().month);
  await sheet('New daret',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   field(name,'Name'),field(members,'People',number:true),
   field(value,'Each month ({0})'.replaceAll('{0}',currencyLabel(currency,language)),number:true),
   field(turn,'Your turn (number)',number:true),
   TextButton.icon(icon:PaydayAppIcon(Icons.calendar_today_outlined),onPressed:()async{
    final p=await showDatePicker(context:c,initialDate:start,firstDate:DateTime(2020),lastDate:DateTime(2100));if(p!=null)rebuild(()=>start=DateTime(p.year,p.month));},
    label:LText('First month: {0}'.replaceAll('{0}',localizedMonth(start,language)))),
  ]),footer:(c,rebuild)=>FilledButton(key:ValueKey('daret-save'),onPressed:()async{
   final n=amount(value),m=int.tryParse(members.text.trim())??0,t=int.tryParse(turn.text.trim())??0;
   if(name.text.trim().isEmpty){inputError('Enter a name.');return;}
   if(n==null||m<2||t<1||t>m){inputError('Check the amount, the number of people and your turn.');return;}
   final all=daretsOf(d);final id=all.fold<int>(0,(a,x)=>x.id>a?x.id:a)+1;
   all.add(Daret(id:id,name:name.text.trim(),members:m,amount:n,start:monthKey(start),myTurn:t,paid:[]));
   if(await execute(()=>store.setSetting(daretKey,encodeDarets(all)),saved:'Daret saved.')&&c.mounted)Navigator.pop(c);
  },child:LText('Save')));
 }

 // ------------------------------------------------------------------ cash count
 Future<void> cashCount(int appBalance)async{
  final counts=<int,int>{for(final v in cashDenominations)v:0};
  await sheet('Count your cash',(c,rebuild){
   final counted=counts.entries.fold<int>(0,(n,e)=>n+e.key*e.value);
   final diff=counted-appBalance;
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[LText('Counted',style:TextStyle(fontSize:PaydayType.caption,color:muted,fontWeight:FontWeight.w700)),Text(money(counted),key:ValueKey('cash-counted'),style:PaydayText.figure.copyWith(color:ink))])),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[LText('App says',style:TextStyle(fontSize:PaydayType.caption,color:muted,fontWeight:FontWeight.w700)),Text(money(appBalance),style:PaydayText.figure.copyWith(color:ink))])),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[LText('Difference',style:TextStyle(fontSize:PaydayType.caption,color:muted,fontWeight:FontWeight.w700)),Text(money(diff),style:PaydayText.figure.copyWith(color:diff==0?jade:saffronText))])),
    ]),
    SizedBox(height:12),
    groupedRows([for(final v in cashDenominations)Padding(padding:EdgeInsets.symmetric(horizontal:12,vertical:4),child:Row(children:[
     Container(width:64,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:v>=2000?(isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint):(isDark?PaydayColors.darkSurfaceHigh:PaydayColors.surfaceHigh),borderRadius:BorderRadius.circular(PaydayRadius.sm)),
      child:Text(v%100==0?'${v~/100}':'0,${(v%100).toString().padLeft(2,'0')}',style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,color:ink))),
     SizedBox(width:10),Expanded(child:LText(v>=2000?'note':'coin',style:TextStyle(color:muted,fontSize:PaydayType.caption))),
     IconButton(key:ValueKey('cash-less-$v'),tooltip:tr(context,'Less'),onPressed:counts[v]!>0?()=>rebuild(()=>counts[v]=counts[v]!-1):null,icon:PaydayAppIcon(Icons.remove,size:18)),
     SizedBox(width:26,child:Text('${counts[v]}',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w800,color:ink))),
     IconButton(key:ValueKey('cash-more-$v'),tooltip:tr(context,'More'),onPressed:()=>rebuild(()=>counts[v]=counts[v]!+1),icon:PaydayAppIcon(Icons.add,size:18)),
    ]))]),
   ]);
  },footer:(c,rebuild){
   final counted=counts.entries.fold<int>(0,(n,e)=>n+e.key*e.value),diff=counted-appBalance;
   return FilledButton(key:ValueKey('cash-fix'),onPressed:diff==0?()=>Navigator.pop(c):()async{
    final ok=await execute(()=>store.saveTransaction(date:dayKey(DateTime.now()),type:diff<0?'Expense':'Income',category:'Other',amount:diff.abs(),
     description:tr(context,'Cash count'),note:'',billId:'',account:'Cash'),saved:'Cash balance corrected.');
    if(ok&&c.mounted)Navigator.pop(c);
   },child:LText(diff==0?'Matches · Done':diff<0?'Fix: {0} as small spending'.replaceAll('{0}',money(-diff)):'Fix: {0} found'.replaceAll('{0}',money(diff))));
  });
 }

 // ------------------------------------------------------------------ budgets: 80% and move money
 /// Categories at 80% or more of their budget this month (not yet over).
 List<(String,int,int)> nearLimit(Map<String,List<RowData>> d,String key){
  final out=<(String,int,int)>[];
  for(final c in spendingCategories(d)){
   final name=st(c,'name'),budget=budgetFor(d,key,name);
   if(budget<=0)continue;
   final spent=categoryMonthTotal(list(d,'transactions'),name,key);
   if(spent*100>=budget*80&&spent<budget)out.add((name,spent,budget));
  }
  return out;
 }

 Widget budgetAlertBanner(Map<String,List<RowData>> d){
  final near=nearLimit(d,month);
  if(near.isEmpty)return const SizedBox.shrink();
  final n=near.first,left=n.$3-n.$2;
  return Padding(padding:EdgeInsets.only(bottom:PaydaySpace.md),child:Container(key:ValueKey('budget-80-banner'),
   padding:EdgeInsetsDirectional.fromSTEB(14,10,6,10),decoration:BoxDecoration(color:isDark?PaydayColors.nearTintDark:PaydayColors.nearTintLight,borderRadius:BorderRadius.circular(PaydayRadius.lg)),
   child:Row(children:[PaydayAppIcon(Icons.notifications_none,color:saffronText),SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText('{0} reached 80%'.replaceAll('{0}',categoryLabel(context,n.$1)),style:TextStyle(fontWeight:FontWeight.w800,color:saffronText)),
     LText('{0} left'.replaceAll('{0}',money(left)),style:TextStyle(fontSize:PaydayType.caption,color:ink)),
    ])),
    TextButton(key:ValueKey('budget-move-money'),onPressed:()=>moveMoneyForm(d,n.$1),child:LText('Move money',style:TextStyle(fontWeight:FontWeight.w800,color:saffronText))),
   ])));
 }

 Future<void> moveMoneyForm(Map<String,List<RowData>> d,String to)async{
  final sources=[for(final c in spendingCategories(d))st(c,'name')].where((n)=>n!=to&&budgetFor(d,month,n)-categoryMonthTotal(list(d,'transactions'),n,month)>0).toList();
  if(sources.isEmpty){inputError('No other category has money left to move.');return;}
  var from=sources.first;final value=TextEditingController();
  await sheet('Move money to {0}'.replaceAll('{0}',categoryLabel(context,to)),(c,rebuild){
   final room=budgetFor(d,month,from)-categoryMonthTotal(list(d,'transactions'),from,month);
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText('Take from a category that has room. Nothing is spent; only the plan changes.',style:TextStyle(color:muted)),
    SizedBox(height:12),
    field(value,'Amount ({0})'.replaceAll('{0}',currencyLabel(currency,language)),number:true),
    LText('From',style:TextStyle(fontWeight:FontWeight.w700,color:muted)),SizedBox(height:6),
    groupedRows([for(final s in sources)listRow(key:ValueKey('move-from-$s'),leading:PaydayCategoryIcon(s,size:36),title:rowTitle(s,category:true),
     subtitle:'{0} left'.replaceAll('{0}',money(budgetFor(d,month,s)-categoryMonthTotal(list(d,'transactions'),s,month))),
     trailing:PaydayAppIcon(from==s?Icons.check_circle_outline:Icons.add,size:20,color:from==s?jade:muted),onTap:()=>rebuild(()=>from=s))]),
    SizedBox(height:6),LText('Up to {0} from {1}.'.replaceAll('{0}',money(room)).replaceAll('{1}',categoryLabel(context,from)),style:TextStyle(fontSize:PaydayType.caption,color:muted)),
   ]);
  },footer:(c,rebuild)=>FilledButton(key:ValueKey('move-money-save'),onPressed:()async{
   final n=amount(value);if(n==null){inputError('Enter a positive amount.');return;}
   final room=budgetFor(d,month,from)-categoryMonthTotal(list(d,'transactions'),from,month);
   if(n>room){inputError('That is more than {0} has left.'.replaceAll('{0}',categoryLabel(context,from)));return;}
   final ok=await execute(()async{
    await store.setBudget(month,from,budgetFor(d,month,from)-n);
    await store.setBudget(month,to,budgetFor(d,month,to)+n);
   },saved:'Moved {0}.'.replaceAll('{0}',money(n)));
   if(ok&&c.mounted)Navigator.pop(c);
  },child:LText('Move')));
 }

 // ------------------------------------------------------------------ CSV import
 Future<void> importCsv()async{
  final picker=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['csv','txt'],withData:true);
  final file=picker?.files.firstOrNull;
  if(file==null||!mounted)return;
  final bytes=file.bytes;
  if(bytes==null){inputError('Could not read this file.');return;}
  String text;
  try{text=utf8.decode(bytes);}catch(_){text=latin1.decode(bytes);}
  final rows=parseBankCsv(text);
  if(rows.isEmpty){inputError('No dated amounts found. The file needs a Date column and an amount, or Debit and Credit columns.');return;}
  final d=await store.snapshot();if(!mounted)return;
  final today=dayKey(DateTime.now());
  final existing=list(d,'transactions').map((t)=>'${st(t,'date')}|${val(t,'amount')}|${st(t,'type')}').toSet();
  final fresh=rows.where((r)=>r.date.compareTo(today)<=0&&!existing.contains('${r.date}|${r.amountCents}|${r.income?'Income':'Expense'}')).toList();
  final skipped=rows.length-fresh.length;
  var wallet='Bank';
  final wallets=walletSetupOf(d);
  await sheet('Import',(c,rebuild)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   contentCard(listRow(leading:iconTile(Icons.description_outlined),title:rowTitle(file.name,raw:true),
    subtitle:'{0} rows found'.replaceAll('{0}','${rows.length}'))),
   SizedBox(height:12),
   if(skipped>0)LText('{0} rows look like duplicates or future dates. They will be skipped.'.replaceAll('{0}','$skipped'),style:TextStyle(color:saffronText,fontWeight:FontWeight.w700)),
   SizedBox(height:8),
   LText('Expenses go to Other and income to Other income. You can change categories later in Records.',style:TextStyle(color:muted,fontSize:PaydayType.caption)),
   if(wallets!=null)...[SizedBox(height:12),Wrap(spacing:8,children:[for(final w in walletNames)PaydayPill(label:w,selected:wallet==w,onTap:()=>rebuild(()=>wallet=w))])],
  ]),footer:(c,rebuild)=>FilledButton.icon(key:ValueKey('csv-import'),onPressed:fresh.isEmpty?null:()async{
   final ok=await execute(()async{
    for(final r in fresh){
     await store.saveTransaction(date:r.date,type:r.income?'Income':'Expense',category:r.income?'Other income':'Other',amount:r.amountCents,
      description:r.description,note:'Imported',billId:'',account:wallets==null?null:wallet);
    }
   },saved:'{0} records imported.'.replaceAll('{0}','${fresh.length}'));
   if(ok&&c.mounted)Navigator.pop(c);
  },icon:PaydayAppIcon(Icons.download_outlined),label:LText('Import {0} records'.replaceAll('{0}','${fresh.length}'))));
 }
}
