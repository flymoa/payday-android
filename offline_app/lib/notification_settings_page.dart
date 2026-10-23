import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'backup_notifications.dart';
import 'bill_reminders.dart';
import 'settings_pages.dart';

const backupNotificationExplanation='Receive a quiet reminder about once a week to save a backup. The first reminder is about seven days after enabling it. A confirmed backup export starts a new seven-day interval. Android may delay reminders to save battery. Notifications contain no balances, transactions, or passwords. Tapping one opens PAYDAY with your usual App lock protection. You can turn reminders off at any time.';
const billNotificationExplanation='Bill reminders are off by default. Choose the due date, 1 day before, or 3 days before, around 9:00 AM in your phone’s time zone. Only future reminder times for unpaid bills are scheduled, up to a year ahead. Bills sharing a reminder date produce one private notification. Paying or deleting a bill updates the reminders; partial payments keep them active. Open PAYDAY after changing your time zone. Android may delay delivery to save battery.';

class NotificationSettingsPage extends StatefulWidget {
 const NotificationSettingsPage({super.key,required this.reminders,this.bills});
 final BackupNotifications reminders;
 final BillReminders? bills;
 @override State<NotificationSettingsPage> createState()=>_NotificationSettingsPageState();
}
class _NotificationSettingsPageState extends State<NotificationSettingsPage> with WidgetsBindingObserver{
 BackupNotificationState? state;
 BillNotificationState? billState;
 bool busy=false;
 String? error;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);load();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState value){if(value==AppLifecycleState.resumed&&!busy)load();}
 Future<void> load()async{
  try{
   final value=await widget.reminders.read();
   if(mounted)setState(()=>state=value);
   final bills=await widget.bills?.read();
   String? syncError;
   try{if(widget.bills!=null)await widget.bills!.synchronize();}
   catch(_){syncError='Bill reminders could not refresh. Try again, or turn them off.';}
   if(mounted)setState((){state=value;billState=bills;error=syncError;});
  }catch(_){if(mounted)setState(()=>error='Could not read notification settings. Please try again.');}
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
 Future<void> chooseTiming()async{
  final current=billState;
  if(busy||current==null||widget.bills==null)return;
  final selected=await showDialog<int>(context:context,builder:(c)=>SimpleDialog(title:const Text('Remind me'),children:[
   for(final choice in billReminderChoices.entries)SimpleDialogOption(key:ValueKey('bill-timing-${choice.key}'),
    onPressed:()=>Navigator.pop(c,choice.key),child:Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[
     const PaydayAppIcon(Icons.schedule),const SizedBox(width:12),Expanded(child:Text(choice.value)),
     if(choice.key==current.preferences.leadDays)const PaydayAppIcon(Icons.check_circle_outline,size:20),
    ]))),
  ]));
  if(selected!=null&&mounted)await run(()=>widget.bills!.configure(enabled:current.preferences.enabled,leadDays:selected));
 }
 @override Widget build(BuildContext context){
  final backupReady=state?.enabled==true&&state?.allowed==true;
  final billReady=billState?.preferences.enabled==true&&billState?.allowed==true;
  return Scaffold(
   appBar:AppBar(title:const Text('Notifications'),leading:IconButton(tooltip:'Back to Settings',onPressed:()=>Navigator.pop(context),icon:const PaydayAppIcon(Icons.arrow_back)),
    actions:[IconButton(tooltip:'About notifications',icon:const PaydayAppIcon(Icons.info_outline,size:20),onPressed:()=>showSettingsInfo(context,'Notifications',
     widget.bills==null?backupNotificationExplanation:'$backupNotificationExplanation\n\n$billNotificationExplanation'))]),
   body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
    if(busy||state==null&&error==null)const LinearProgressIndicator(),
    if(state!=null)Card(clipBehavior:Clip.antiAlias,child:SwitchListTile(key:const ValueKey('backup-notifications-toggle'),
     secondary:const PaydayAppIcon(Icons.notifications_none),title:const Text('Backup reminders'),
     subtitle:Text(state!.enabled&&!state!.allowed?'Blocked by Android':'Weekly'),
     value:state!.enabled,onChanged:busy?null:(v)=>run(()=>widget.reminders.setEnabled(v)))),
    if(billState!=null)Card(clipBehavior:Clip.antiAlias,child:Column(children:[
     SwitchListTile(key:const ValueKey('bill-notifications-toggle'),secondary:const PaydayAppIcon(Icons.event_note_outlined),title:const Text('Bill reminders'),
      subtitle:Text(billState!.preferences.enabled&&!billState!.allowed?'Blocked by Android':'Unpaid bills only'),
      value:billState!.preferences.enabled,onChanged:busy?null:(v)=>run(()=>widget.bills!.configure(enabled:v,leadDays:billState!.preferences.leadDays))),
     if(billState!.preferences.enabled)ListTile(key:const ValueKey('bill-reminder-timing'),leading:const PaydayAppIcon(Icons.schedule),title:const Text('Remind me'),
      subtitle:Text('${billReminderChoices[billState!.preferences.leadDays]} · 9:00 AM'),trailing:const PaydayAppIcon(Icons.chevron_right),onTap:busy?null:chooseTiming),
    ])),
    if(state?.allowed==false||billState?.allowed==false||error!=null)TextButton(onPressed:busy?null:()=>run(widget.reminders.openSettings),child:const Text('Android notification settings')),
    if(backupReady||billReady)OutlinedButton.icon(onPressed:busy?null:()=>run(backupReady?widget.reminders.sendTest:widget.bills!.sendTest,success:'Test notification sent.'),
     icon:const PaydayAppIcon(Icons.notifications_none),label:const Text('Send a test')),
    if(error!=null)...[
     Padding(padding:const EdgeInsets.all(12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
     TextButton(onPressed:busy?null:load,child:const Text('Try again')),
    ],
   ])));
 }
}
