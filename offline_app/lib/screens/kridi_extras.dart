// Part of the main finance screen. Kridi pay-back dates, carnet limits and the
// "instalments soon" pop-up.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _KridiExtras on _FinanceState {
 static const instalmentPopupKey='kridi_popup_shown';
 Color get softSurface=>isDark?PaydayColors.darkSurfaceLow:PaydayColors.surfaceLow;
 Color get saffronTint=>paydaySaffron.withValues(alpha:isDark?0.16:0.22);

 /// "In 2 days · Thursday 27 November", in the app language.
 String dueChip(DateTime date){
  final now=DateTime.now(),days=DateTime(date.year,date.month,date.day).difference(DateTime(now.year,now.month,now.day)).inDays;
  final day=uiDay(date);
  if(language=='ar')return days==0?'اليوم · $day':days==1?'غدًا · $day':'بعد ${arabicDays(days,after:true)} · $day';
  final t=days==0?'Today · {0}':days==1?'Tomorrow · {0}':'In {0} days · {1}';
  return translateMessage(t,language).replaceAll('{0}',days>1?'$days':day).replaceAll('{1}',day);
 }

 /// Shown once a day, when the app opens, if a bank instalment is taken within 3 days.
 Future<void> maybeShowInstalmentPopup()async{
  try{
   final d=await store.snapshot();if(!mounted)return;
   final today=dayKey(DateTime.now());
   if(Ledger(d).setting(instalmentPopupKey)==today)return;
   final soon=instalmentsDueSoon(kridiOf(d),DateTime.now());
   if(soon.isEmpty)return;
   await store.setSetting(instalmentPopupKey,today);
   if(!mounted)return;
   await instalmentSheet(soon);
  }catch(_){}
 }

 Future<void> instalmentSheet(List<(Kridi,DateTime)> soon)async{
  final total=soon.fold<int>(0,(n,x)=>n+x.$1.monthly);
  final first=soon.first.$2;
  final title=soon.length==1?'An instalment leaves your account soon':soon.length==2?'Two instalments leave your account soon':
   '{0} instalments leave your account soon'.replaceAll('{0}','${soon.length}');
  await showModalBottomSheet<void>(context:context,showDragHandle:true,useSafeArea:true,isScrollControlled:true,
   backgroundColor:Theme.of(context).scaffoldBackgroundColor,
   builder:(c)=>SafeArea(top:false,child:Padding(key:ValueKey('instalment-popup'),padding:EdgeInsets.fromLTRB(20,0,20,16),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(padding:EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:saffronTint,borderRadius:BorderRadius.circular(999)),
     child:Row(mainAxisSize:MainAxisSize.min,children:[PaydayAppIcon(Icons.event_outlined,size:14,color:saffronText),SizedBox(width:6),
      Text(dueChip(first),style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:saffronText))])),
    SizedBox(height:10),
    LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:21,fontWeight:FontWeight.w800,color:ink,height:1.2)),
    SizedBox(height:4),
    LText('Keep this money in your account until then.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    SizedBox(height:12),Divider(height:1,color:line),
    for(final x in soon)...[
     Padding(padding:EdgeInsets.symmetric(vertical:12),child:Row(children:[
      iconTile(kridiIcon(x.$1),size:38),SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(x.$1.name,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,fontSize:15,color:ink)),
       LText(x.$1.months>0?'Instalment {0} of {1}'.replaceAll('{0}','${(x.$1.paidCount+1).clamp(1,x.$1.months)}').replaceAll('{1}','${x.$1.months}'):shortDay(dayKey(x.$2)),
        style:TextStyle(fontSize:12,color:muted)),
      ])),
      Text(money(x.$1.monthly),style:TextStyle(fontWeight:FontWeight.w700,color:ink)),
     ])),
     Divider(height:1,color:line),
    ],
    Container(margin:EdgeInsets.only(top:10,bottom:16),padding:EdgeInsets.symmetric(horizontal:14,vertical:12),
     decoration:BoxDecoration(color:softSurface,borderRadius:BorderRadius.circular(14)),
     child:Row(children:[Expanded(child:LText('Total to keep ready',style:TextStyle(fontSize:PaydayType.caption,color:muted))),
      Text(money(total),style:TextStyle(fontFamily:'Bricolage',fontSize:20,fontWeight:FontWeight.w800,color:jade))])),
    SizedBox(width:double.infinity,height:48,child:FilledButton(key:ValueKey('instalment-popup-ok'),onPressed:()=>Navigator.pop(c),child:LText('Got it'))),
    SizedBox(width:double.infinity,child:TextButton(onPressed:(){Navigator.pop(c);openTool(7);},child:LText('Open Kridi'))),
   ]))));
 }

 /// Centred, calm message after a carnet purchase goes past the shop's limit.
 Future<void> carnetLimitDialog(Kridi k)async{
  final over=k.balance-k.limit;
  await showDialog<void>(context:context,builder:(c)=>Dialog(key:ValueKey('carnet-limit-dialog'),
   backgroundColor:Theme.of(context).scaffoldBackgroundColor,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
   child:Padding(padding:EdgeInsets.fromLTRB(20,22,20,12),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Container(width:52,height:52,decoration:BoxDecoration(color:saffronTint,borderRadius:BorderRadius.circular(16)),
     child:Center(child:PaydayAppIcon(Icons.storefront_outlined,size:26,color:saffronText))),
    SizedBox(height:12),
    LText('You went past your carnet limit',textAlign:TextAlign.center,style:TextStyle(fontFamily:'Bricolage',fontSize:19,fontWeight:FontWeight.w800,color:ink,height:1.25)),
    SizedBox(height:6),
    Text(k.name,textAlign:TextAlign.center,style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    SizedBox(height:12),
    ClipRRect(borderRadius:BorderRadius.circular(4),child:SizedBox(height:8,child:Row(children:[
     Expanded(flex:k.limit,child:ColoredBox(color:jade)),Expanded(flex:over,child:ColoredBox(color:paydaySaffron))]))),
    SizedBox(height:6),
    Row(children:[Expanded(child:LText('{0} owed'.replaceAll('{0}',money(k.balance)),style:TextStyle(fontSize:12,color:muted))),
     LText('Limit {0}'.replaceAll('{0}',money(k.limit)),style:TextStyle(fontSize:12,color:muted))]),
    Container(width:double.infinity,margin:EdgeInsets.only(top:12,bottom:14),padding:EdgeInsets.symmetric(horizontal:12,vertical:10),
     decoration:BoxDecoration(color:softSurface,borderRadius:BorderRadius.circular(12)),
     child:LText('Your purchase is saved. You are {0} over, so pay a little back soon.'.replaceAll('{0}',money(over)),
      textAlign:TextAlign.center,style:TextStyle(fontSize:PaydayType.caption,color:ink,height:1.45))),
    SizedBox(width:double.infinity,height:46,child:FilledButton(key:ValueKey('carnet-limit-ok'),onPressed:()=>Navigator.pop(c),child:LText('OK'))),
    TextButton(onPressed:(){Navigator.pop(c);kridiEdit(k.id);},child:LText('Change limit')),
   ]))));
 }

 /// The one extra setting each kind has: pay-back date, carnet limit or instalment day.
 Future<void> kridiEdit(int id)async{
  final d=await store.snapshot();if(!mounted)return;
  final list_=kridiOf(d);final k=list_.firstWhere((x)=>x.id==id);
  DateTime? due=DateTime.tryParse(k.dueDate??'');
  final limit=TextEditingController(text:k.limit>0?inputNumber(k.limit):'');
  final day=TextEditingController(text:k.payDay>0?'${k.payDay}':'');
  await sheet(k.name,(c,rebuild)=>kridiExtraFields(c,rebuild,k.kind,due:due,setDue:(v)=>due=v,limit:limit,day:day),
   footer:(c,rebuild)=>FilledButton(key:ValueKey('kridi-edit-save'),onPressed:()async{
    final r=readKridiExtras(k.kind,limit,day);if(r==null)return;
    k.dueDate=due==null?null:dayKey(due!);k.limit=r.$1;k.payDay=r.$2;
    if(await saveKridi(list_,saved:'Kridi saved.')&&c.mounted)Navigator.pop(c);
   },child:LText('Save changes')));
 }

 Widget kridiExtraFields(BuildContext c,StateSetter rebuild,String kind,{required DateTime? due,required void Function(DateTime?) setDue,
  required TextEditingController limit,required TextEditingController day}){
  if(kind=='borrowed'||kind=='lent'){
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
     Expanded(child:OutlinedButton.icon(key:ValueKey('kridi-due'),icon:PaydayAppIcon(Icons.event_outlined,size:18),
      onPressed:()async{final now=DateTime.now();final p=await showDatePicker(context:c,initialDate:due??DateTime(now.year,now.month+1,now.day),
       firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>setDue(p));},
      label:LText(due==null?'Add a pay-back date':'Pay back by {0}'.replaceAll('{0}',uiDay(due))))),
     if(due!=null)IconButton(tooltip:tr(context,'Remove date'),onPressed:()=>rebuild(()=>setDue(null)),icon:PaydayAppIcon(Icons.close,size:18)),
    ]),
    SizedBox(height:6),
    LText(kind=='lent'?'Optional. The bell reminds you 3 days before to ask for it back.':'Optional. The bell reminds you 3 days before.',
     style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    SizedBox(height:12),
   ]);
  }
  if(kind=='shop'){
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    field(limit,'Carnet limit ({0}), optional'.replaceAll('{0}',currencyLabel(currency,language)),number:true),
    LText('You get a message when a purchase takes you past it.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
    SizedBox(height:12),
   ]);
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   field(day,'Instalment day (1–31)',number:true),
   LText('The day of the month your bank takes it. You get a reminder 3 days before.',style:TextStyle(fontSize:PaydayType.caption,color:muted)),
   SizedBox(height:12),
  ]);
 }

 /// (limit cents, instalment day), or null after showing an input error.
 (int,int)? readKridiExtras(String kind,TextEditingController limit,TextEditingController day){
  var l=0,p=0;
  if(kind=='shop'&&limit.text.trim().isNotEmpty){final n=amount(limit);if(n==null){inputError('Enter a positive amount.');return null;}l=n;}
  if(kind=='loan'&&day.text.trim().isNotEmpty){
   p=int.tryParse(day.text.trim())??0;
   if(p<1||p>31){inputError('Enter a day between 1 and 31.');return null;}
  }
  return (l,p);
 }
}
