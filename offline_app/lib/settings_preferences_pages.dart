import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'app_preferences.dart';
import 'settings_pages.dart';

class ThemeSettingsPage extends StatefulWidget {
 const ThemeSettingsPage({super.key,required this.initial,required this.onChanged});
 final ThemeMode initial;
 final Future<bool> Function(ThemeMode) onChanged;
 @override State<ThemeSettingsPage> createState()=>_ThemeSettingsPageState();
}
class _ThemeSettingsPageState extends State<ThemeSettingsPage>{
 bool saving=false;
 Future<void> choose(ThemeMode? value)async{
  if(value==null||saving)return;
  if(value==widget.initial){Navigator.pop(context);return;}
  setState(()=>saving=true);
  try{final success=await widget.onChanged(value);if(mounted&&success)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save theme. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Theme',busy:saving,
  body:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   Card(clipBehavior:Clip.antiAlias,child:RadioGroup<ThemeMode>(groupValue:widget.initial,onChanged:choose,
    child:AbsorbPointer(absorbing:saving,child:const Column(children:[
     RadioListTile<ThemeMode>(value:ThemeMode.light,title:Text('Light')),
     RadioListTile<ThemeMode>(value:ThemeMode.dark,title:Text('Dark')),
     RadioListTile<ThemeMode>(value:ThemeMode.system,title:Text('System'),subtitle:Text('Follow your device appearance')),
    ])))),
  ]));
}

class CurrencySettingsPage extends StatefulWidget {
 const CurrencySettingsPage({super.key,required this.initial,required this.onChanged});
 final String initial;
 final Future<bool> Function(String) onChanged;
 @override State<CurrencySettingsPage> createState()=>_CurrencySettingsPageState();
}
class _CurrencySettingsPageState extends State<CurrencySettingsPage>{
 bool saving=false;
 Future<void> choose(String value)async{
  if(saving)return;
  if(value==widget.initial){Navigator.pop(context);return;}
  final confirmed=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
   title:Text('Use $value?'),scrollable:true,
   content:Text('This changes the currency for all existing and future amounts. '
    'Numbers stay the same: 100.00 ${widget.initial} becomes 100.00 $value. '
    'No exchange conversion is performed. Your records, budgets and savings keep their values.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:Text('Use $value'))]));
  if(!mounted||confirmed!=true)return;
  setState(()=>saving=true);
  try{final success=await widget.onChanged(value);if(mounted&&success)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save currency. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Currency',busy:saving,
  actions:[IconButton(tooltip:'About currency',icon:const PaydayAppIcon(Icons.info_outline,size:20),
   onPressed:()=>showSettingsInfo(context,'Currency','One currency for all your records. Changing it does not convert amounts.'))],
  body:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   Card(clipBehavior:Clip.antiAlias,child:Column(children:[
    for(final entry in paydayCurrencies.entries)ListTile(title:Text(entry.value),subtitle:Text(entry.key),
     trailing:entry.key==widget.initial?const PaydayAppIcon(Icons.check_circle_outline):null,
     onTap:saving?null:()=>choose(entry.key)),
   ])),
  ]));
}

class MoneySettingsPage extends StatefulWidget {
 const MoneySettingsPage({super.key,required this.currency,required this.buffer,required this.openingSavings,required this.onSave});
 final String currency;
 final int buffer,openingSavings;
 final Future<bool> Function(int,int) onSave;
 @override State<MoneySettingsPage> createState()=>_MoneySettingsPageState();
}
class _MoneySettingsPageState extends State<MoneySettingsPage>{
 late final buffer=TextEditingController(text:(widget.buffer/100).toStringAsFixed(2));
 late final savings=TextEditingController(text:(widget.openingSavings/100).toStringAsFixed(2));
 final form=GlobalKey<FormState>();
 bool saving=false;
 @override void dispose(){buffer.dispose();savings.dispose();super.dispose();}
 int? amount(String? value){
  final n=double.tryParse((value??'').trim().replaceAll(',','.'));
  if(n==null||!n.isFinite||n<0||n>1000000000)return null;
  return (n*100).round();
 }
 Widget field(TextEditingController controller,String label)=>Padding(padding:const EdgeInsets.only(bottom:16),
  child:TextFormField(controller:controller,enabled:!saving,
   keyboardType:const TextInputType.numberWithOptions(decimal:true),
   validator:(s)=>amount(s)==null?'Enter a valid amount of zero or more.':null,
   decoration:InputDecoration(labelText:label)));
 Future<void> save()async{
  if(saving||!form.currentState!.validate())return;
  setState(()=>saving=true);
  try{final success=await widget.onSave(amount(buffer.text)!,amount(savings.text)!);if(mounted&&success)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save money settings. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Money settings',busy:saving,
  actions:[IconButton(tooltip:'About money settings',icon:const PaydayAppIcon(Icons.info_outline,size:20),
   onPressed:()=>showSettingsInfo(context,'Money settings','Your cash buffer stays out of Safe to spend. Opening savings are money saved before using Payday; they are not new income or a new transfer.'))],
  body:Form(key:form,child:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   field(buffer,'Cash buffer (${widget.currency})'),
   field(savings,'Opening savings (${widget.currency})'),
   FilledButton(onPressed:saving?null:save,child:Text(saving?'Saving…':'Save settings')),
  ])));
}
