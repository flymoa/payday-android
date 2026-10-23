import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'backup_notifications.dart';
import 'settings_pages.dart';

const backupNotificationExplanation='Receive a quiet reminder about once a week to save a backup. The first reminder is about seven days after enabling it. A confirmed backup export starts a new seven-day interval. Android may delay reminders to save battery. Notifications contain no balances, transactions, or passwords. Tapping one opens PAYDAY with your usual App lock protection. You can turn reminders off at any time.';

class NotificationSettingsPage extends StatefulWidget {
 const NotificationSettingsPage({super.key,required this.reminders});
 final BackupNotifications reminders;
 @override State<NotificationSettingsPage> createState()=>_NotificationSettingsPageState();
}
class _NotificationSettingsPageState extends State<NotificationSettingsPage> with WidgetsBindingObserver{
 BackupNotificationState? state;
 bool busy=false;
 String? error;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);load();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState value){if(value==AppLifecycleState.resumed&&!busy)load();}
 Future<void> load()async{
  try{final value=await widget.reminders.read();if(mounted)setState((){state=value;error=null;});}
  catch(_){if(mounted)setState(()=>error='Could not read notification settings. Please try again.');}
 }
 Future<void> run(Future<void> Function() action,{String? success})async{
  if(busy)return;
  setState((){busy=true;error=null;});
  try{
   await action();await load();
   if(success!=null&&mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(success)));
  }on FormatException catch(e){if(mounted)setState(()=>error=e.message);}
  catch(_){if(mounted)setState(()=>error='Could not change reminders. Please try again.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Notifications'),leading:IconButton(tooltip:'Back to Settings',onPressed:()=>Navigator.pop(context),icon:const PaydayAppIcon(Icons.arrow_back)),
   actions:[IconButton(tooltip:'About backup reminders',icon:const PaydayAppIcon(Icons.info_outline,size:20),onPressed:()=>showSettingsInfo(context,'Backup reminders',backupNotificationExplanation))]),
  body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
   if(busy||state==null&&error==null)const LinearProgressIndicator(),
   if(state!=null)Card(clipBehavior:Clip.antiAlias,child:SwitchListTile(key:const ValueKey('backup-notifications-toggle'),
    secondary:const PaydayAppIcon(Icons.notifications_none),title:const Text('Backup reminders'),
    subtitle:Text(state!.enabled&&!state!.allowed?'Blocked by Android':'Weekly'),
    value:state!.enabled,onChanged:busy?null:(v)=>run(()=>widget.reminders.setEnabled(v)))),
   if(state?.allowed==false)TextButton(onPressed:busy?null:()=>run(widget.reminders.openSettings),child:const Text('Android notification settings')),
   if(state?.enabled==true&&state?.allowed==true)OutlinedButton.icon(onPressed:busy?null:()=>run(widget.reminders.sendTest,success:'Test notification sent.'),
    icon:const PaydayAppIcon(Icons.notifications_none),label:const Text('Send a test')),
   if(error!=null)...[
    Padding(padding:const EdgeInsets.all(12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    if(state==null)TextButton(onPressed:load,child:const Text('Try again')),
   ],
  ])));
}
