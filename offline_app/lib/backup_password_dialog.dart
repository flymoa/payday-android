import 'localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'settings_pages.dart';

class BackupPasswordDialog extends StatefulWidget {
 const BackupPasswordDialog({super.key,required this.creating,required this.submit});
 final bool creating;
 final Future<String> Function(String password) submit;
 @override State<BackupPasswordDialog> createState()=>_BackupPasswordDialogState();
}
class _BackupPasswordDialogState extends State<BackupPasswordDialog>{
 final password=TextEditingController(),confirm=TextEditingController();
 bool visible=false,saved=false,busy=false;
 String? error;
 @override void dispose(){password.dispose();confirm.dispose();super.dispose();}
 Future<void> submit()async{
  if(busy)return;
  final p=password.text;
  String? problem;
  if(p.isEmpty||p.trim().isEmpty)problem='Enter a password.';
  else if(utf8.encode(p).length>1024)problem='This password is too long.';
  else if(widget.creating&&p.runes.length<12)problem='Use at least 12 characters.';
  else if(widget.creating&&p!=confirm.text)problem='The passwords do not match.';
  else if(widget.creating&&!saved)problem='Confirm that you have saved this password.';
  if(problem!=null){setState(()=>error=problem);return;}
  setState((){busy=true;error=null;});
  try{
   final result=await widget.submit(p);
   if(mounted)Navigator.pop(context,result);
  }on FormatException catch(e){if(mounted)setState(()=>error=e.message);}
  catch(_){if(mounted)setState(()=>error='Could not prepare the backup. Please try again.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>PopScope(canPop:!busy,child:AlertDialog(
  scrollable:true,
  title:Row(children:[Expanded(child:LText(widget.creating?'Protect your backup':'Unlock backup')),
   IconButton(tooltip:tr(context,'About backup passwords'),icon:const PaydayAppIcon(Icons.info_outline,size:20),onPressed:busy?null:()=>showSettingsInfo(context,'Backup password',
    'New backups are encrypted with the password you choose. Payday does not save it and cannot reset it. Older unprotected JSON backups can still be restored.'))]),
  content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   if(widget.creating)const Padding(padding:EdgeInsets.only(bottom:16),child:LText('Keep this password. Payday cannot recover it.')),
   TextField(key:const ValueKey('backup-password'),controller:password,enabled:!busy,obscureText:!visible,
    autocorrect:false,enableSuggestions:false,keyboardType:TextInputType.visiblePassword,
    decoration:InputDecoration(labelText:tr(context,'Password'),helperText:(widget.creating?'At least 12 characters':null)==null?null:tr(context,(widget.creating?'At least 12 characters':null)!),
     suffixIcon:IconButton(tooltip:tr(context,visible?'Hide password':'Show password'),onPressed:busy?null:()=>setState(()=>visible=!visible),
      icon:PaydayAppIcon(visible?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
   if(widget.creating)...[
    const SizedBox(height:12),TextField(key:const ValueKey('backup-password-confirm'),controller:confirm,enabled:!busy,obscureText:!visible,
     autocorrect:false,enableSuggestions:false,keyboardType:TextInputType.visiblePassword,decoration:InputDecoration(labelText:tr(context,'Confirm password'))),
    CheckboxListTile(key:const ValueKey('backup-password-saved'),contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading,
     title:const LText('I’ve saved this password.'),value:saved,onChanged:busy?null:(v)=>setState(()=>saved=v??false)),
   ],
   if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:LText(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
   if(busy)const Padding(padding:EdgeInsets.only(top:16),child:LinearProgressIndicator()),
  ]),
  actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const LText('Cancel')),
   FilledButton(key:const ValueKey('backup-password-submit'),onPressed:busy?null:submit,child:LText(busy?'Please wait…':widget.creating?'Export':'Unlock'))],
 ));
}

