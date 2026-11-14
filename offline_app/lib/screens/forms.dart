// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _Forms on _FinanceState {
 Future<void> deleteTransactionWithUndo(int id)async{
  final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:LText('Delete this transaction?'),
   content:LText('You can restore it using Undo while the confirmation bar is visible.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:LText('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(c,true),child:LText('Delete'))]));
  if(confirmed!=true||!mounted||writing)return;
  writing=true;
  try{
   final removed=await store.deleteTransactionForUndo(id);
   refresh();
   if(!mounted)return;
   if(removed==null){inputError('This transaction was already removed.');return;}
   showTransactionUndo(removed);
  }catch(e){if(mounted)inputError('Could not delete the transaction: $e');}
  finally{writing=false;}
 }
 void showTransactionUndo(RowData removed,{bool retry=false}){
  var restoring=false;
  final messenger=ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
   persist:false,duration:Duration(seconds:5),
   content:LText(retry?'Could not restore. Tap Undo to retry.':'Transaction deleted.'),
   action:SnackBarAction(label:tr(context,'Undo'),onPressed:()async{
    if(restoring)return;
    restoring=true;
    try{
     await store.restoreDeletedTransaction(removed);
     refresh();
     if(mounted)inputError('Transaction restored.');
    }catch(e){if(mounted)showTransactionUndo(removed,retry:true);}
   })));
 }

 Future<void> confirmDelete(String title,Future<void> Function() action) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:LText(title),content:LText('This permanently removes the selected local record.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:LText('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:LText('Delete'))]));
  if(ok==true)await execute(action);
 }
 /// Scrollable form with a fixed action area that clears Android's system bar.
 Future<void> sheet(String title,Widget Function(BuildContext,StateSetter) builder,
  {Widget Function(BuildContext,StateSetter)? footer,bool fullScreen=false}) async{
  await showModalBottomSheet(
   context:context,isScrollControlled:true,useSafeArea:true,
   showDragHandle:true,backgroundColor:surface,
   constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*(fullScreen ? .98 : .92)),
   builder:(c)=>AnimatedPadding(
    duration:MediaQuery.disableAnimationsOf(c)?Duration.zero:Duration(milliseconds:180),curve:Curves.easeOut,
    padding:EdgeInsets.only(bottom:MediaQuery.viewInsetsOf(c).bottom),
    child:SafeArea(top:false,bottom:true,child:Padding(
     padding:EdgeInsets.symmetric(horizontal:18),
     child:StatefulBuilder(builder:(c,rebuild)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
       Padding(padding:EdgeInsets.only(bottom:12),
        child:Align(alignment:AlignmentDirectional.centerStart,
         child:Row(children:[if(fullScreen)IconButton(tooltip:tr(context,'Close transaction'),onPressed:()=>Navigator.pop(c),icon:PaydayAppIcon(Icons.close)),Expanded(child:LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:23,color:ink,fontWeight:FontWeight.w800)))]))),
       Flexible(child:SingleChildScrollView(
        keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
        padding:EdgeInsets.only(bottom:footer==null?24:12),
        child:builder(c,rebuild))),
       if(footer!=null)Padding(padding:EdgeInsetsDirectional.fromSTEB(0,6,0,14),
        child:SizedBox(width:double.infinity,child:footer(c,rebuild))),
      ],
     )),
    )),
   ),
  );
 }
 Widget field(TextEditingController c,String label,{bool number=false,int lines=1})=>Padding(padding:EdgeInsets.only(bottom:12),
  child:TextField(controller:c,maxLines:lines,keyboardType:number?TextInputType.numberWithOptions(decimal:true):TextInputType.text,
   decoration:InputDecoration(labelText:tr(context,label),isDense:true)));
 int? amount(TextEditingController c,{bool allowZero=false}){
  return parseMoneyCents(c.text,allowZero:allowZero);
 }
 void inputError(String message){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText(message)));}
 Future<void> transactionForm(RowData? existing,{RowData? payBill,String? initialType,RowData? copyFrom}) async{
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
  List<String> categoriesFor(String entry,{bool editing=false})=>categoryChoices(d,entry,
   existing:editing&&existing!=null?st(existing,'category'):null);
  final desc=TextEditingController(text:existing==null?(prefill?.description??''):st(existing,'description'));
  final note=TextEditingController(text:existing==null?'':st(existing,'note'));
  final bill=TextEditingController(text:existing==null?(prefill?.billId??''):st(existing,'bill_id'));
  final amt=TextEditingController(text:existing==null?(prefill==null?'':inputNumber(prefill.amountCents)):inputNumber(val(existing,'amount')));
  var type=existing==null?(prefill?.type??initialType??'Expense'):st(existing,'type');
  var category=existing==null?(prefill?.category??(type=='Income'?'Salary':type.startsWith('Savings')?'Savings':'Groceries')):st(existing,'category');
  // Duplicate: same details as a new entry dated today (bill link not copied).
  if(existing==null&&copyFrom!=null){
   desc.text=st(copyFrom,'description');note.text=st(copyFrom,'note');amt.text=inputNumber(val(copyFrom,'amount'));
   type=st(copyFrom,'type');category=st(copyFrom,'category');
  }
  var cats=categoriesFor(type,editing:existing!=null);
  if(!cats.contains(category)){if(prefill!=null){cats=[category,...cats];}else{category=cats.first;}}
  var date=existing==null?(prefill!=null||copyFrom!=null||month==monthKey(DateTime.now())?DateTime.now():selected):parseDay(st(existing,'date'));
  var submitting=false;
  var allCategories=false;
  await sheet(existing==null?(prefill==null?(copyFrom==null?'New transaction':'Duplicate transaction'):'Record bill payment'):'Edit transaction',(c,rebuild)=>Column(children:[
   if(prefill!=null)Padding(padding:EdgeInsets.only(bottom:12),child:LText(
      'Prefilled from your bill. You can change every field; the payment date defaults to today, not the bill due date.',
      style:TextStyle(color:jade,fontSize:12,fontWeight:FontWeight.w600))),
   Container(padding:EdgeInsets.all(4),decoration:BoxDecoration(
    color:Theme.of(c).colorScheme.surfaceContainerLow,borderRadius:BorderRadius.circular(PaydayRadius.lg)),
    child:Row(children:['Expense','Income','Savings'].map((entry){
     final selected=entry=='Savings'?type.startsWith('Savings'):type==entry;
     return Expanded(child:TextButton(style:TextButton.styleFrom(
      padding:EdgeInsets.symmetric(vertical:13,horizontal:2),backgroundColor:selected?surface:Colors.transparent,
      foregroundColor:selected?jade:muted,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),
      onPressed:submitting?null:()=>rebuild((){
       type=entry=='Savings'?'Savings out':entry;cats=categoriesFor(type);category=cats.contains(entry=='Expense'?'Groceries':entry=='Income'?'Salary':'Savings')?
        (entry=='Expense'?'Groceries':entry=='Income'?'Salary':'Savings'):cats.first;allCategories=false;
      }),child:LText(entry,style:TextStyle(fontSize:13,fontWeight:selected?FontWeight.w800:FontWeight.w500))));
    }).toList())),
   if(type.startsWith('Savings'))...[
    SizedBox(height:14),
    Row(children:[
     Expanded(child:OutlinedButton(style:OutlinedButton.styleFrom(backgroundColor:type=='Savings out'?jade.withValues(alpha:.12):Colors.transparent,
      side:BorderSide(color:type=='Savings out'?jade:line),padding:EdgeInsets.symmetric(horizontal:5,vertical:12)),
      onPressed:submitting?null:()=>rebuild(()=>type='Savings out'),child:LText('Add to savings',style:TextStyle(fontSize:12)))),
     SizedBox(width:8),
     Expanded(child:OutlinedButton(style:OutlinedButton.styleFrom(backgroundColor:type=='Savings in'?jade.withValues(alpha:.12):Colors.transparent,
      side:BorderSide(color:type=='Savings in'?jade:line),padding:EdgeInsets.symmetric(horizontal:5,vertical:12)),
      onPressed:submitting?null:()=>rebuild(()=>type='Savings in'),child:LText('Take from savings',style:TextStyle(fontSize:12)))),
    ]),SizedBox(height:6),LText(type=='Savings out'?'Moves available money into savings.':'Returns saved money to your available balance.',
     style:TextStyle(fontSize:12,color:muted),textAlign:TextAlign.center),
   ],
   SizedBox(height:22),
   TextField(controller:amt,textAlign:TextAlign.center,keyboardType:TextInputType.numberWithOptions(decimal:true),
    style:TextStyle(fontFamily:'Bricolage',fontSize:44,fontWeight:FontWeight.w800,color:jade),
    decoration:InputDecoration(labelText:tr(context,'Amount ($currency)'),floatingLabelAlignment:FloatingLabelAlignment.center,
     filled:false,border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none)),
   if(type=='Expense')Padding(padding:EdgeInsets.symmetric(vertical:10),child:LText(
    budgetFor(d,monthKey(date),category)<=0?'No budget set for $category':
     '${money(budgetFor(d,monthKey(date),category)-monthTransactionsFor(d,monthKey(date)).where((t)=>st(t,'type')=='Expense'&&st(t,'category')==category&&val(t,'id')!=(existing==null?-1:val(existing,'id'))).fold(0,(n,t)=>n+val(t,'amount')))} left in $category',
    textAlign:TextAlign.center,style:TextStyle(color:jade,fontWeight:FontWeight.w700))),
   Align(alignment:AlignmentDirectional.centerStart,child:LText('Category',style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:18))),
   SizedBox(height:12),
   LayoutBuilder(builder:(context,limits){
    final ordered={category,...cats}.toList();
    final choices=allCategories?ordered:ordered.take(7).toList();
    // Grows with the phone's text size so two-line names always fit (82 at normal size).
    final tileHeight=max(82.0,46+MediaQuery.textScalerOf(c).scale(11)*2.9);
    return Wrap(key:ValueKey('transaction-category-grid'),spacing:8,runSpacing:8,children:[
     ...choices.map((name)=>SizedBox(width:(limits.maxWidth-24)/4,height:tileHeight,child:OutlinedButton(
      style:OutlinedButton.styleFrom(padding:EdgeInsets.all(3),backgroundColor:name==category?jade.withValues(alpha:.10):surface,
       side:BorderSide(color:name==category?jade:line,width:name==category?2:1),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg))),
      onPressed:()=>rebuild(()=>category=name),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
       PaydayCategoryIcon(name,size:32),SizedBox(height:5),LText(name,category:true,textAlign:TextAlign.center,maxLines:2,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w600)),
      ])))),
     if(!allCategories&&ordered.length>7)SizedBox(width:(limits.maxWidth-24)/4,height:tileHeight,child:OutlinedButton(
      style:OutlinedButton.styleFrom(padding:EdgeInsets.all(3),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg))),
      onPressed:()=>rebuild(()=>allCategories=true),child:LText('More',style:TextStyle(fontSize:PaydayType.caption)))),
    ]);
   }),
   if(type=='Income')Align(alignment:AlignmentDirectional.centerStart,child:TextButton.icon(
    icon:PaydayAppIcon(Icons.tune_outlined),label:LText('Manage income categories'),
    onPressed:submitting?null:()async{
     await incomeCategoriesForm();
     final fresh=await store.snapshot();
     if(c.mounted)rebuild((){d.clear();d.addAll(fresh);cats=categoriesFor(type,editing:existing!=null);
      if(!cats.contains(category))category=cats.first;});
    })),
   SizedBox(height:20),field(desc,'Description'),field(note,'Note (optional)'),field(bill,'Bill ID (optional)'),
   Row(children:[PaydayAppIcon(Icons.today,size:18),Expanded(child:TextButton.icon(icon:PaydayAppIcon(Icons.edit_calendar_outlined),onPressed:()async{final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>date=p);},label:LText('Payment date: ${uiDay(date)}')))]),
   if(existing!=null)TextButton.icon(key:ValueKey('duplicate-transaction'),onPressed:()async{Navigator.pop(c);await transactionForm(null,copyFrom:existing);},
    icon:PaydayAppIcon(Icons.copy_outlined),label:LText('Duplicate as new (today)')),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await deleteTransactionWithUndo(val(existing,'id'));},child:LText('Delete transaction',style:TextStyle(color:Colors.red)))
  ]),footer:(c,rebuild)=>FilledButton.icon(
   icon:PaydayAppIcon(Icons.check_circle_outline),label:LText(submitting?'Saving…':'Save locally'),
   onPressed:submitting?null:()async{
    final cents=amount(amt);
    if(cents==null){inputError('Enter a positive amount.');return;}
    rebuild(()=>submitting=true);
    final success=await execute(()=>store.saveTransaction(
      id:existing==null?null:val(existing,'id'),date:dayKey(date),
      type:type,category:category,amount:cents,
      description:desc.text.trim(),note:note.text.trim(),billId:bill.text.trim()));
    if(c.mounted){if(success){Navigator.pop(c);}else{rebuild(()=>submitting=false);}}
    if(success&&type=='Expense')await warnIfBudgetCrossed(category,monthKey(date),cents,
     existing!=null&&st(existing,'type')=='Expense'&&st(existing,'category')==category&&st(existing,'date').startsWith(monthKey(date))?val(existing,'amount'):0);
   },
  ),fullScreen:true);
 }
 /// After saving an expense, says once when its category reaches 85% or goes over.
 Future<void> warnIfBudgetCrossed(String category,String key,int cents,int replacedAmount)async{
  try{
   final d=await store.snapshot();
   final budget=budgetFor(d,key,category);
   final after=categoryMonthTotal(list(d,'transactions'),category,key);
   final crossing=budgetCrossing(before:after-cents+replacedAmount,after:after,budget:budget);
   if(crossing==null||!mounted)return;
   final name=categoryLabel(context,category);
   inputError(crossing==BudgetCrossing.overBudget?'$name is over its budget by ${money(after-budget)}.':
    '$name has used ${(after*100/budget).round()}% of its budget.');
  }catch(_){}
 }
 Future<void> copyBudgetForm(Map<String,List<RowData>> d)async{
  final targetMonth=month;
  final rows=list(d,'budgets');
  final plan=BudgetCopyPlan(rows,targetMonth);
  final expected=budgetCopyState(rows,targetMonth);
  var saving=false;
  String? error;
  await sheet('Copy last month’s budget',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    LText('${monthLabel(monthFromKey(plan.sourceMonth))} → ${monthLabel(monthFromKey(targetMonth))}',
     style:TextStyle(fontWeight:FontWeight.bold)),
    SizedBox(height:12),
    LText('Existing entries stay unchanged, including amounts set to zero. Only missing entries below will be added. This copies your plan, not transactions or bill payments.'),
    SizedBox(height:12),
    if(plan.additions.isEmpty)LText('Nothing to copy. The previous month has no missing entries to add.'),
    ...plan.additions.map((r)=>Padding(padding:EdgeInsets.symmetric(vertical:8),
     child:Row(children:[Expanded(child:LText(st(r,'category'),category:true)),SizedBox(width:8),LText(money(val(r,'amount')))]))),
    Divider(),LText('Planned income after copy: ${money(plan.income)}'),
    LText('Assigned after copy: ${money(plan.assigned)}'),
    SizedBox(height:8),
    if(!plan.allowed)LText('Cannot copy: allocations exceed planned income by ${money(plan.exceededBy)}. Update this month’s income plan or reduce existing allocations, then try again.',
     style:TextStyle(color:Colors.deepOrange)),
    if(error!=null)Padding(padding:EdgeInsets.only(top:12),child:LText(error!,style:TextStyle(color:Colors.deepOrange))),
   ]),footer:(c,rebuild)=>FilledButton(
    onPressed:saving||!plan.allowed||plan.additions.isEmpty?null:()async{
     rebuild(()=>saving=true);
     try{
      await store.copyBudget(targetMonth,expectedState:expected);
      refresh();
      if(c.mounted)Navigator.pop(c);
      if(mounted)inputError('Budget copied to $targetMonth. Existing entries were kept.');
     }catch(e){if(c.mounted)rebuild(()=>error=currencyMessage(e.toString()).replaceFirst('Bad state: ',''));}
     finally{if(c.mounted)rebuild(()=>saving=false);}
    },child:LText(saving?'Copying…':'Copy budget')));
 }

 Future<void> budgetForm(Map<String,List<RowData>> d,String category)async{
  final budgetMonth=month;
  final original=Ledger(d).plannedBudget(budgetMonth,category);
  final a=TextEditingController(text:inputNumber(original));
  final initial=checkBudgetAssignment(rows:list(d,'budgets'),month:budgetMonth,
   category:category,proposed:original);
  var saving=false;
  Future<void> notice(BuildContext c,String title,String message)async{
   await showDialog<void>(context:c,builder:(dialog)=>AlertDialog(title:LText(title),content:LText(message),
    actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:LText('OK'))]));
  }
  await sheet('${categoryLabel(context,category)} · $budgetMonth',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(category!='Income plan')Padding(padding:EdgeInsets.only(bottom:12),
     child:LText('Maximum total for this category: ${money(initial.maximum)}',
      style:TextStyle(color:muted,fontWeight:FontWeight.w600))),
    field(a,'Budget amount ($currency)',number:true),
    if(category=='Income plan')TextButton.icon(onPressed:()=>incomeCategoriesForm(),
     icon:PaydayAppIcon(Icons.tune_outlined),label:LText('Manage income categories')),
    if(!['Income plan','Savings goal'].contains(category))TextButton.icon(
     icon:PaydayAppIcon(Icons.delete_outline),label:LText('Delete category'),
     onPressed:saving?null:()async{
      if(await deleteCategoryPrompt(category,budgetMonth)&&c.mounted)Navigator.pop(c);
     }),
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
      if(c.mounted)await notice(c,'Budget limit reached',currencyMessage(e.check.message));
     }catch(e){
      if(c.mounted)await notice(c,'Could not save budget','$e');
     }finally{
      if(c.mounted)rebuild(()=>saving=false);
     }
    },child:LText(saving?'Saving…':'Save budget')));
 }
 Future<bool> deleteCategoryPrompt(String name,String categoryMonth)async{
  final confirmed=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
   title:LText('Delete $name?'),
   content:LText('Remove this category from new entries and clear its budget for $categoryMonth. Existing records and other months’ budgets stay unchanged.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:LText('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:LText('Delete category'))]));
  if(confirmed!=true)return false;
  return execute(()=>store.deleteCategory(name,month:categoryMonth));
 }
 Future<void> incomeCategoriesForm()async{
  var data=await store.snapshot();if(!mounted)return;
  await sheet('Income categories',(c,rebuild)=>Column(children:[
   LText('Add income sources or remove categories you no longer use. Existing records keep their category.'),
   ...categoryChoices(data,'Income').where((name)=>name!='Uncategorized').map((name)=>ListTile(
    leading:PaydayCategoryIcon(name),title:LText(name,category:true),trailing:IconButton(
     tooltip:tr(context,'Delete $name'),icon:PaydayAppIcon(Icons.delete_outline),onPressed:()async{
      if(await deleteCategoryPrompt(name,month)){
       final fresh=await store.snapshot();if(c.mounted)rebuild(()=>data=fresh);
      }
     }))),
  ]),footer:(c,rebuild)=>FilledButton.icon(icon:PaydayAppIcon(Icons.add),label:LText('Add income category'),
   onPressed:()async{
    await categoryForm(income:true);
    final fresh=await store.snapshot();if(c.mounted)rebuild(()=>data=fresh);
   }));
 }
 Future<void> categoryForm({bool income=false}) async{
  final name=TextEditingController();var group=income?'Income':'Essential';var saving=false;
  await sheet(income?'New income category':'New category',(c,rebuild)=>Column(children:[field(name,'Name'),
   if(!income)DropdownButtonFormField<String>(initialValue:group,items:['Essential','Flexible'].map((x)=>DropdownMenuItem(value:x,child:LText(x))).toList(),onChanged:(v){if(v!=null)group=v;}),
   SizedBox(height:12),FilledButton(onPressed:saving?null:()async{
    rebuild(()=>saving=true);
    final success=await execute(()=>store.addCategory(name.text,group));
    if(c.mounted){if(success){Navigator.pop(c);}else{rebuild(()=>saving=false);}}
   },child:LText(saving?'Saving…':'Add category'))]));
 }
 Future<void> goalForm(RowData? existing) async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name')),target=TextEditingController(text:existing==null?'':inputNumber(val(existing,'target')));
  await sheet(existing==null?'Add savings goal':'Edit savings goal',(c,rebuild)=>Column(children:[field(name,'Goal name'),field(target,'Target ($currency)',number:true),
   FilledButton(onPressed:()async{final n=amount(target);if(n==null)return inputError('Invalid target');final saveSucceeded=await execute(()=>store.saveGoal(id:existing==null?null:val(existing,'id'),name:name.text,target:n));if(saveSucceeded&&c.mounted)Navigator.pop(c);},child:LText('Save goal')),
   if(existing!=null)Padding(padding:EdgeInsets.only(top:8),child:TextButton(onPressed:()async{
    final ok=await showDialog<bool>(context:c,builder:(dialog)=>AlertDialog(
     title:LText('Delete this goal and its allocations?'),
     content:LText('Money allocated to this goal returns to unassigned savings.'),
     actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:LText('Cancel')),
      FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:LText('Delete'))]));
    if(ok!=true||!c.mounted)return;
    final deleted=await execute(()=>store.deleteGoal(val(existing,'id')));if(deleted&&c.mounted)Navigator.pop(c);
   },child:LText('Delete goal')))]));
 }
 Future<void> allocationForm(Map<String,List<RowData>> d,RowData goal)async{
  final remaining=totalPool(d)-allocated(d),a=TextEditingController();
  await sheet('Allocate to ${st(goal,'name')}',(c,rebuild)=>Column(children:[
   LText('Unassigned savings: ${money(remaining)}\nAllocations are not new savings.'),
   SizedBox(height:12),field(a,'Amount ($currency)',number:true),
   FilledButton(onPressed:()async{
    final n=amount(a);if(n==null||n>remaining)return inputError('Allocation exceeds available savings.');
    // Month must have been reviewed and closed, as in the spreadsheet.
    final closing=list(d,'month_closes').where((x)=>st(x,'month')==month&&val(x,'entries_ok')==1&&val(x,'balance_ok')==1);
    if(closing.isEmpty)return inputError('Close this month before allocating savings.');
    final saveSucceeded=await execute(()=>store.allocate(month,val(goal,'id'),n));if(saveSucceeded&&c.mounted)Navigator.pop(c);
   },child:LText('Allocate savings'))]));
 }
 Future<void> repeatBillForm(RowData bill)async{
  final due=nextBillDue(parseDay(st(bill,'due')));
  var saving=false;
  String? error;
  await sheet('Repeat next month',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(st(bill,'name'),style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
    SizedBox(height:12),LText('Due: ${uiDay(due)}'),
    LText('Amount: ${money(val(bill,'amount'))}'),LText('Category: ${categoryLabel(context,st(bill,'category'))}'),
    SizedBox(height:12),LText('Creates one unpaid bill using the saved details above. Payments stay with the original bill. You can edit the new bill afterward. Repeat it again next month when needed; this does not schedule automatic payments.'),
    if(error!=null)Padding(padding:EdgeInsets.only(top:12),child:LText(error!,style:TextStyle(color:Colors.deepOrange))),
   ]),footer:(c,rebuild)=>FilledButton(
    onPressed:saving?null:()async{
     rebuild(()=>saving=true);
     try{
      final created=await store.repeatBill(val(bill,'id'),expected:bill);
      refresh();
      if(c.mounted)Navigator.pop(c);
      if(mounted)inputError(created?'Unpaid bill created for ${uiDay(due)}.':'This bill was already repeated. No duplicate was created.');
     }catch(e){if(c.mounted)rebuild(()=>error=currencyMessage(e.toString()).replaceFirst('Bad state: ',''));}
     finally{if(c.mounted)rebuild(()=>saving=false);}
    },child:LText(saving?'Creating…':'Create next month’s bill')));
 }

 Future<void> billForm(RowData? existing) async {
  final code=TextEditingController(text:existing==null?'B${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}':st(existing,'code'));
  final name=TextEditingController(text:existing==null?'':st(existing,'name'));
  final note=TextEditingController(text:existing==null?'':st(existing,'note'));
  final value=TextEditingController(text:existing==null?'':inputNumber(val(existing,'amount')));
  var date=existing==null?DateTime.now():parseDay(st(existing,'due'));
  var category=existing==null?'Housing':st(existing,'category');
  final d=await store.snapshot();if(!mounted)return;
  final billCategories=categoryChoices(d,'Expense',existing:existing==null?null:category);
  if(!billCategories.contains(category))category=billCategories.first;
  await sheet(existing==null?'Add a bill':'Edit bill',(c,rebuild)=>Column(children:[
   field(name,'Bill name'),field(code,'Unique Bill ID'),field(value,'Due amount ($currency)',number:true),field(note,'Note'),
   DropdownButtonFormField<String>(initialValue:category,items:billCategories.map((name)=>DropdownMenuItem(value:name,child:LText(name,category:true))).toList(),onChanged:(v){if(v!=null)category=v;}),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>date=p);},child:LText('Due: ${uiDay(date)}')),
   FilledButton(onPressed:()async{final n=amount(value);if(n==null)return inputError('Invalid bill amount');final saveSucceeded=await execute(()=>store.saveBill(id:existing==null?null:val(existing,'id'),code:code.text,name:name.text,due:dayKey(date),amount:n,category:category,note:note.text));if(saveSucceeded&&c.mounted)Navigator.pop(c);},child:LText('Save bill')),
   if(existing!=null)Column(children:[
    OutlinedButton.icon(onPressed:()async{Navigator.pop(c);if(mounted)await repeatBillForm(existing);},
     icon:PaydayAppIcon(Icons.repeat),label:LText('Repeat next month')),
    LText('Outstanding: ${money(billOutstanding(val(existing,'amount'),billPaid(d,existing)))}',
      style:TextStyle(color:ink,fontWeight:FontWeight.w700)),
    SizedBox(height:8),
    SizedBox(width:double.infinity,child:FilledButton.tonalIcon(
     onPressed:billOutstanding(val(existing,'amount'),billPaid(d,existing))==0
      ?null:()async{
       Navigator.pop(c);
       if(mounted)await transactionForm(null,payBill:existing);
      },
     icon:PaydayAppIcon(Icons.payments_outlined),
     label:LText(billOutstanding(val(existing,'amount'),billPaid(d,existing))==0
      ?'Bill fully paid':'Record payment'),
    )),
   ]),
   if(existing!=null)TextButton(onPressed:()async{Navigator.pop(c);await confirmDelete('Delete bill?',()=>store.removeBill(val(existing,'id')));},child:LText('Delete bill',style:TextStyle(color:Colors.red)))
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
    LText('Currently set aside: ${money(balance)}',
      style:TextStyle(color:jade,fontWeight:FontWeight.bold)),
    LText(adding?'Still needed: ${money(needed)}':
      'Money returned to spendable cash when you take it out.',
      style:TextStyle(color:muted,fontSize:12)),
    SizedBox(height:16),
    field(amountController,'Amount ($currency)',number:true),
    field(noteController,'Note (optional)'),
    Row(children:[PaydayAppIcon(Icons.calendar_today_outlined,size:18),
     TextButton.icon(icon:PaydayAppIcon(Icons.edit_calendar_outlined),
      onPressed:()async{
       final picked=await showDatePicker(context:c,initialDate:date,
        firstDate:DateTime(2000),lastDate:DateTime.now());
       if(picked!=null)rebuild(()=>date=picked);
      },
      label:LText('Transfer date: ${uiDay(date)}'),
     ),
    ]),
    Padding(padding:EdgeInsets.only(top:8),
     child:LText('This is a transfer between spendable cash and your reserve, '
       'not an ordinary expense. Record the actual purchase separately when it occurs.',
       style:TextStyle(color:muted,fontSize:12))),
   ]),footer:(c,rebuild)=>FilledButton.icon(
    icon:PaydayAppIcon(adding?Icons.savings_outlined:Icons.undo),
    label:LText(adding?'Record money set aside':'Record withdrawal'),
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
    LText('Opening funds: ${money(val(reserve,'funded'))}',
      style:TextStyle(color:muted)),
    SizedBox(height:10),
    if(history.isEmpty)LText('No deposits or withdrawals recorded yet.'),
    ...history.map((m)=>ListTile(
     contentPadding:EdgeInsets.zero,
     leading:PaydayAppIcon(st(m,'kind')=='add'?Icons.arrow_downward:Icons.arrow_upward,
       color:st(m,'kind')=='add'?jade:amber),
     title:LText(st(m,'kind')=='add'?'Added to reserve':'Taken out of reserve'),
     subtitle:Text('${displayDay(context,st(m,'date'))}${st(m,'note').isEmpty?'':' · '+st(m,'note')}'),
     trailing:LText('${st(m,'kind')=='add'?'+':'−'}${money(val(m,'amount'))}',
       style:TextStyle(fontWeight:FontWeight.w800,
         color:st(m,'kind')=='add'?jade:amber)),
    )),
    SizedBox(height:10),
    LText('To correct a previous transfer, record an opposite transfer. '
      'This keeps a dated history of money moving in and out.',
      style:TextStyle(color:muted,fontSize:12)),
   ]));
 }
 Future<void> reserveForm(RowData? existing)async{
  final name=TextEditingController(text:existing==null?'':st(existing,'name'));
  final target=TextEditingController(text:existing==null?'':inputNumber(val(existing,'target')));
  final funded=TextEditingController(text:existing==null?'0':inputNumber(val(existing,'funded')));
  var due=existing==null?DateTime(DateTime.now().year+1,1):parseDay(st(existing,'due'));
  var start=existing==null?DateTime.now():monthFromKey(st(existing,'start_month'));
  await sheet(existing==null?'Create a reserve':'Edit reserve target',(c,rebuild)=>Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
   field(name,'Reserve name (e.g. Vacation)'),
   field(target,'Total target ($currency)',number:true),
   if(existing==null)field(funded,'Already put aside before using Payday ($currency)',number:true),
   if(existing!=null)Padding(padding:EdgeInsets.only(bottom:10),
     child:LText('Original opening funds: ${money(val(existing,'funded'))}. '
      'Use Add money / Take out to record changes.',
      style:TextStyle(color:muted,fontSize:12))),
   if(existing==null)Padding(padding:EdgeInsets.only(bottom:10),child:LText(
     'Opening funds are money already saved before this app. '
     'They are not deducted again from cash. New deposits must use Add money.',
     style:TextStyle(color:muted,fontSize:12))),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:due,
    firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>due=p);},
    child:LText('Due: ${uiDay(due)}')),
   TextButton(onPressed:()async{final p=await showDatePicker(context:c,initialDate:start,
    firstDate:DateTime(2000),lastDate:DateTime(2100));if(p!=null)rebuild(()=>start=p);},
    child:LText('Start month: ${monthLabel(start)}')),
   if(existing!=null)TextButton(onPressed:()async{
     Navigator.pop(c);await confirmDelete('Delete reserve?',()=>store.removeReserve(val(existing,'id')));
    },child:LText('Delete reserve',style:TextStyle(color:Colors.red))),
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
   },child:LText('Save reserve')),
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
  final closedNow=val(current,'entries_ok')==1&&val(current,'balance_ok')==1;
  final unspent=Ledger(d).unspentBudgets(month);
  final unspentTotal=unspent.values.fold<int>(0,(a,b)=>a+b);
  final nextMonth=DateTime(selected.year,selected.month+1);
  // Previous choice: carried if the next month has a carry-over saved.
  var leftover=Ledger(d).carriedIntoMonth(monthKey(nextMonth)).isNotEmpty?'carry':'none';
  await sheet('Close ${monthLabel(selected)}',(c,rebuild)=>Column(children:[
   LText('Estimated available extra: ${money(available)}\nOnly extra savings beyond recorded transfers should be entered.'),
   SizedBox(height:8),CheckboxListTile(value:checked,onChanged:(v)=>rebuild(()=>checked=v??false),title:LText('All transactions checked')),
   CheckboxListTile(value:balanced,onChanged:(v)=>rebuild(()=>balanced=v??false),title:LText('Cash balance checked')),
   if(unspentTotal>0)...[
    SizedBox(height:8),
    LText('Unspent budget this month: ${money(unspentTotal)}',style:TextStyle(fontWeight:FontWeight.w700)),
    RadioGroup<String>(groupValue:leftover,onChanged:(v){if(v==null)return;rebuild((){
      leftover=v;
      if(v=='save')extra.text=inputNumber(unspentTotal<available?unspentTotal:available);
     });},
     child:Column(children:[
      RadioListTile<String>(value:'carry',title:LText('Carry to ${monthLabel(nextMonth)}'),
       subtitle:LText('Each category gets its unspent amount added to next month\'s budget.')),
      RadioListTile<String>(value:'save',title:LText('Add to savings'),
       subtitle:LText('Fills Extra saved below with the unspent amount (up to available cash).')),
      RadioListTile<String>(value:'none',title:LText('Do nothing')),
     ])),
   ],
   field(opening,'Opening spendable cash ($currency)',number:true),field(extra,'Extra saved ($currency)',number:true),
   FilledButton(onPressed:()async{
    if(!selected.isBefore(currentMonth))return inputError('Wait until the month ends before closing it.');
    final n=amount(extra,allowZero:true),o=amount(opening,allowZero:true);
    if(n==null||o==null||n>available||!checked||!balanced)return inputError('Complete the checks. Extra savings cannot exceed available cash.');
    final saveSucceeded=await execute(()=>store.saveMonthClose(month,entriesOk:checked,balanceOk:balanced,extra:n,openingBalance:o,carryToNext:leftover=='carry'?unspent:const {}));if(saveSucceeded&&c.mounted)Navigator.pop(c);
   },child:LText('Confirm month close')),
   if(closedNow)Padding(padding:EdgeInsets.only(top:8),child:TextButton(onPressed:()async{
    final reopened=await execute(()=>store.reopenMonth(month));if(reopened&&c.mounted)Navigator.pop(c);
   },child:LText('Reopen month')))
  ]));
 }
 Future<void> settingsForm(Map<String,List<RowData>> d)async{
  int setting(String key,int fallback)=>int.tryParse(st(list(d,'settings').firstWhere((x)=>st(x,'key')==key,orElse:()=>{}),'value'))??fallback;
  await openSettingsPage((_)=>MoneySettingsPage(currency:currency,buffer:setting('buffer',20000),openingSavings:setting('opening_savings',0),
   onSave:(buffer,savings)=>execute(()=>store.saveMoneySettings(buffer:buffer,openingSavings:savings))));
 }
}
