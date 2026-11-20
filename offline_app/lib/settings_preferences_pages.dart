import 'localization.dart';
import 'app_language.dart';
import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'app_preferences.dart';
import 'finance.dart';
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
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:LText('Could not save theme. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Appearance',busy:saving,
  body:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   Card(clipBehavior:Clip.antiAlias,child:RadioGroup<ThemeMode>(groupValue:widget.initial,onChanged:choose,
    child:AbsorbPointer(absorbing:saving,child:const Column(children:[
     RadioListTile<ThemeMode>(value:ThemeMode.light,title:LText('Light')),
     RadioListTile<ThemeMode>(value:ThemeMode.dark,title:LText('Dark')),
     RadioListTile<ThemeMode>(value:ThemeMode.system,title:LText('System'),subtitle:LText('Follow your device appearance')),
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
   title:LText('Use $value?'),scrollable:true,
   content:LText('This changes the currency for all existing and future amounts. '
    'Numbers stay the same: 100,00 ${currencyLabel(widget.initial,languageOf(context))} becomes 100,00 ${currencyLabel(value,languageOf(context))}. '
    'No exchange conversion is performed. Your records, budgets and savings keep their values.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const LText('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:LText('Use $value'))]));
  if(!mounted||confirmed!=true)return;
  setState(()=>saving=true);
  try{final success=await widget.onChanged(value);if(mounted&&success)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:LText('Could not save currency. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Currency',busy:saving,
  actions:[IconButton(tooltip:tr(context,'About currency'),icon:const PaydayAppIcon(Icons.info_outline,size:20),
   onPressed:()=>showSettingsInfo(context,'Currency','One currency for all your records. Changing it does not convert amounts.'))],
  body:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   Card(clipBehavior:Clip.antiAlias,child:Column(children:[
    for(final entry in paydayCurrencies.entries)ListTile(title:LText(entry.value),subtitle:Text(entry.key),
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
 late final buffer=TextEditingController(text:localizedNumber(widget.buffer,languageOf(context)));
 late final savings=TextEditingController(text:localizedNumber(widget.openingSavings,languageOf(context)));
 final form=GlobalKey<FormState>();
 bool saving=false;
 @override void dispose(){buffer.dispose();savings.dispose();super.dispose();}
 int? amount(String? value)=>parseMoneyCents(value??'',allowZero:true);
 Widget field(TextEditingController controller,String label)=>Padding(padding:const EdgeInsets.only(bottom:16),
  child:TextFormField(controller:controller,enabled:!saving,
   keyboardType:const TextInputType.numberWithOptions(decimal:true),
   validator:(s)=>amount(s)==null?tr(context,'Enter a valid amount of zero or more.'):null,
   decoration:InputDecoration(labelText:tr(context,label))));
 Future<void> save()async{
  if(saving||!form.currentState!.validate())return;
  setState(()=>saving=true);
  try{final success=await widget.onSave(amount(buffer.text)!,amount(savings.text)!);if(mounted&&success)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:LText('Could not save money settings. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Money settings',busy:saving,
  actions:[IconButton(tooltip:tr(context,'About money settings'),icon:const PaydayAppIcon(Icons.info_outline,size:20),
   onPressed:()=>showSettingsInfo(context,'Money settings','Your cash buffer stays out of Safe to spend. Opening savings are money saved before using Payday; they are not new income or a new transfer.'))],
  body:Form(key:form,child:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   field(buffer,'Cash buffer (${widget.currency})'),
   field(savings,'Opening savings (${widget.currency})'),
   FilledButton(onPressed:saving?null:save,child:LText(saving?'Saving…':'Save settings')),
  ])));
}


class LanguageSettingsPage extends StatefulWidget{
 const LanguageSettingsPage({super.key,required this.initial,required this.onChanged});
 final String initial;
 final Future<bool> Function(String) onChanged;
 @override State<LanguageSettingsPage> createState()=>_LanguageSettingsPageState();
}
class _LanguageSettingsPageState extends State<LanguageSettingsPage>{
 bool saving=false;
 Future<void> choose(String value)async{
  if(saving)return;
  if(value==widget.initial){Navigator.pop(context);return;}
  setState(()=>saving=true);
  try{final saved=await widget.onChanged(value);if(saved&&mounted)Navigator.pop(context);}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:LText('Could not save language. Please try again.')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Language',busy:saving,
  body:ListView(padding:settingsPagePadding,children:[
   if(saving)const LinearProgressIndicator(),
   Card(clipBehavior:Clip.antiAlias,child:Column(children:[
    for(final entry in paydayLanguages.entries)ListTile(key:ValueKey('language-${entry.key}'),
     title:Text(entry.value),subtitle:LText(switch(entry.key){'fr'=>'French','ar'=>'Arabic',_=>'English'}),
     trailing:entry.key==widget.initial?const PaydayAppIcon(Icons.check_circle_outline):null,
     onTap:saving?null:()=>choose(entry.key)),
   ])),
   const Padding(padding:EdgeInsets.symmetric(horizontal:4,vertical:12),child:LText('Changing language does not change amounts or currency.')),
  ]));
}
