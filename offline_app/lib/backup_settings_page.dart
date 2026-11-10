import 'localization.dart';
import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'settings_pages.dart';

class BackupSettingsPage extends StatefulWidget{
 const BackupSettingsPage({super.key,required this.initialStatus,required this.refreshStatus,required this.onExport,required this.onRestore,this.loadSnapshotDate,this.onUndoRestore});
 final String initialStatus;
 final Future<String> Function() refreshStatus;
 final Future<void> Function() onExport,onRestore;
 /// Optional: date of the private copy saved before the latest restore, and the action that restores it.
 final Future<DateTime?> Function()? loadSnapshotDate;
 final Future<void> Function()? onUndoRestore;
 @override State<BackupSettingsPage> createState()=>_BackupSettingsPageState();
}
class _BackupSettingsPageState extends State<BackupSettingsPage>{
 late String status=widget.initialStatus;
 bool busy=false;
 String? error;
 DateTime? snapshotDate;
 @override void initState(){super.initState();loadSnapshot();}
 Future<void> loadSnapshot()async{
  final load=widget.loadSnapshotDate;
  if(load==null)return;
  DateTime? value;
  try{value=await load();}catch(_){value=null;}
  if(mounted)setState(()=>snapshotDate=value);
 }
 Future<void> run(Future<void> Function() action)async{
  if(busy)return;
  setState((){busy=true;error=null;});
  try{
   await action();
   final next=await widget.refreshStatus();
   if(mounted)setState(()=>status=next);
   await loadSnapshot();
  }catch(_){if(mounted)setState(()=>error='Could not refresh backup status. Please try again.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Backups & data',busy:busy,
  actions:[IconButton(tooltip:tr(context,'About backups'),icon:const PaydayAppIcon(Icons.info_outline,size:20),
   onPressed:()=>showSettingsInfo(context,'Backups & data','New exports are password protected. Keep the password: Payday cannot recover it. Older JSON backups still work. Restore shows a summary before replacing records and keeps this phone’s App lock and reminder settings. Records on this phone are not encrypted by Payday. An export date confirms the handoff to your chosen app; keep the saved file somewhere safe.'))],
  body:ListView(padding:settingsPagePadding,children:[
   if(busy)const LinearProgressIndicator(),
   Padding(padding:const EdgeInsets.only(bottom:20),child:LText(status,style:const TextStyle(fontWeight:FontWeight.w700))),
   OutlinedButton.icon(key:const ValueKey('export-backup'),onPressed:busy?null:()=>run(widget.onExport),
    icon:const PaydayAppIcon(Icons.ios_share),label:const LText('Export backup')),
   const SizedBox(height:8),
   OutlinedButton.icon(key:const ValueKey('restore-backup'),onPressed:busy?null:()=>run(widget.onRestore),
    icon:const PaydayAppIcon(Icons.file_open),label:const LText('Restore')),
   if(widget.onUndoRestore!=null&&snapshotDate!=null)...[
    const SizedBox(height:24),
    OutlinedButton.icon(key:const ValueKey('undo-restore'),onPressed:busy?null:()=>run(widget.onUndoRestore!),
     icon:const PaydayAppIcon(Icons.undo),label:const LText('Undo last restore')),
    Padding(padding:const EdgeInsets.only(top:8),child:LText('Saved before your last restore: ${localizedDay(snapshotDate!.toLocal(),languageOf(context))}',
     style:Theme.of(context).textTheme.bodySmall)),
   ],
   if(error!=null)Padding(padding:const EdgeInsets.only(top:16),child:LText(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
  ]));
}

