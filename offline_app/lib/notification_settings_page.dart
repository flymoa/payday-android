import 'localization.dart';
import 'package:flutter/material.dart';
import 'app_icon.dart';
import 'backup_notifications.dart';
import 'bill_reminders.dart';
import 'reserve_reminders.dart';
import 'settings_pages.dart';

const backupNotificationExplanation='Receive a quiet reminder about once a week to save a backup. The first reminder is about seven days after enabling it. A confirmed backup export starts a new seven-day interval. Android may delay reminders to save battery. Notifications contain no balances, transactions, or passwords. Tapping one opens Payday with your usual App lock protection. You can turn reminders off at any time.';
const reserveNotificationExplanation='Reserve reminders are off by default. Choose the 1st, 15th or 25th of each month, around 9:00 AM in your phone’s time zone. Only reserves that have started, have not expired, and still need their monthly contribution are included. Recording a deposit, withdrawal or target change refreshes reminders. No money is moved automatically. One private reminder groups all contributions; no reserve names or amounts are shown. The next year is queued using recorded transfers; open Payday after changing your time zone. Android may delay delivery.';
const billNotificationExplanation='Bill reminders are off by default. Choose the due date, 1 day before, or 3 days before, around 9:00 AM in your phone’s time zone. Only future reminder times for unpaid bills are scheduled, up to a year ahead. Bills sharing a reminder date produce one private notification. Paying or deleting a bill updates the reminders; partial payments keep them active. Open Payday after changing your time zone. Android may delay delivery to save battery.';

class NotificationSettingsPage extends StatefulWidget {
 const NotificationSettingsPage({super.key,required this.reminders,this.bills,this.reserves});
 final BackupNotifications reminders;
 final BillReminders? bills;
 final ReserveReminders? reserves;
 @override State<NotificationSettingsPage> createState()=>_NotificationSettingsPageState();
}
class _NotificationSettingsPageState extends State<NotificationSettingsPage> with WidgetsBindingObserver{
 BackupNotificationState? state;
 BillNotificationState? billState;
 ReserveNotificationState? reserveState;
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
   final reserves=await widget.reserves?.read();
   try{if(widget.reserves!=null)await widget.reserves!.synchronize();}
   catch(_){syncError=[if(syncError!=null)syncError,'Reserve reminders could not refresh. Try again, or turn them off.'].join('\n');}
   if(mounted)setState((){state=value;billState=bills;reserveState=reserves;error=syncError;});
  }catch(_){if(mounted)setState(()=>error='Could not read notification settings. Please try again.');}
 }
 Future<void> run(Future<void> Function() action,{String? success})async{
  if(busy)return;
  setState((){busy=true;error=null;});
  try{
   await action();await load();
   if(success!=null&&mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText(success)));
  }on FormatException catch(e){if(mounted)setState(()=>error=e.message);}
  catch(_){if(mounted)setState(()=>error='Could not change reminders. Please try again.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> chooseTiming()async{
  final current=billState;
  if(busy||current==null||widget.bills==null)return;
  final selected=await showDialog<int>(context:context,builder:(c)=>SimpleDialog(title:const LText('Remind me'),children:[
   for(final choice in billReminderChoices.entries)SimpleDialogOption(key:ValueKey('bill-timing-${choice.key}'),
    onPressed:()=>Navigator.pop(c,choice.key),child:Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[
     const PaydayAppIcon(Icons.schedule),const SizedBox(width:12),Expanded(child:LText(choice.value)),
     if(choice.key==current.preferences.leadDays)const PaydayAppIcon(Icons.check_circle_outline,size:20),
    ]))),
  ]));
  if(selected!=null&&mounted)await run(()=>widget.bills!.configure(enabled:current.preferences.enabled,leadDays:selected));
 }
 Future<void> chooseReserveDay()async{
  final current=reserveState;
  if(busy||current==null||widget.reserves==null)return;
  final selected=await showDialog<int>(context:context,builder:(c)=>SimpleDialog(title:const LText('Monthly reminder'),children:[
   for(final choice in reserveReminderChoices.entries)SimpleDialogOption(key:ValueKey('reserve-day-${choice.key}'),
    onPressed:()=>Navigator.pop(c,choice.key),child:Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[
     const PaydayAppIcon(Icons.schedule),const SizedBox(width:12),Expanded(child:LText(choice.value)),
     if(choice.key==current.preferences.day)const PaydayAppIcon(Icons.check_circle_outline,size:20),
    ]))),
  ]));
  if(selected!=null&&mounted)await run(()=>widget.reserves!.configure(enabled:current.preferences.enabled,day:selected));
 }
 @override Widget build(BuildContext context){
  final backupReady=state?.enabled==true&&state?.allowed==true;
  final billReady=billState?.preferences.enabled==true&&billState?.allowed==true;
  final reserveReady=reserveState?.preferences.enabled==true&&reserveState?.allowed==true;
  return SettingsPageScaffold(title:'Reminders',busy:busy,
    actions:[IconButton(tooltip:tr(context,'About notifications'),icon:const PaydayAppIcon(Icons.info_outline,size:20),onPressed:()=>showSettingsInfo(context,'Notifications',
     [backupNotificationExplanation,if(widget.bills!=null)billNotificationExplanation,if(widget.reserves!=null)reserveNotificationExplanation].join('\n\n')))],
    body:ListView(padding:settingsPagePadding,children:[
    if(busy||state==null&&error==null)const LinearProgressIndicator(),
    if(state!=null)Card(clipBehavior:Clip.antiAlias,child:SwitchListTile(key:const ValueKey('backup-notifications-toggle'),
     secondary:const PaydayAppIcon(Icons.notifications_none),title:const LText('Backup reminders'),
     subtitle:LText(state!.enabled&&!state!.allowed?'Blocked by Android':'Weekly'),
     value:state!.enabled,onChanged:busy?null:(v)=>run(()=>widget.reminders.setEnabled(v)))),
    if(billState!=null)Card(clipBehavior:Clip.antiAlias,child:Column(children:[
     SwitchListTile(key:const ValueKey('bill-notifications-toggle'),secondary:const PaydayAppIcon(Icons.event_note_outlined),title:const LText('Bill reminders'),
      subtitle:LText(billState!.preferences.enabled&&!billState!.allowed?'Blocked by Android':'Unpaid bills only'),
      value:billState!.preferences.enabled,onChanged:busy?null:(v)=>run(()=>widget.bills!.configure(enabled:v,leadDays:billState!.preferences.leadDays))),
     if(billState!.preferences.enabled)ListTile(key:const ValueKey('bill-reminder-timing'),leading:const PaydayAppIcon(Icons.schedule),title:const LText('Remind me'),
      subtitle:LText('${billReminderChoices[billState!.preferences.leadDays]} · 9:00 AM'),trailing:const PaydayAppIcon(Icons.chevron_right),onTap:busy?null:chooseTiming),
    ])),
    if(reserveState!=null)Card(clipBehavior:Clip.antiAlias,child:Column(children:[
     SwitchListTile(key:const ValueKey('reserve-notifications-toggle'),secondary:const PaydayAppIcon(Icons.savings_outlined),title:const LText('Reserve reminders'),
      subtitle:LText(reserveState!.preferences.enabled&&!reserveState!.allowed?'Blocked by Android':'Monthly contributions'),
      value:reserveState!.preferences.enabled,onChanged:busy?null:(v)=>run(()=>widget.reserves!.configure(enabled:v,day:reserveState!.preferences.day))),
     if(reserveState!.preferences.enabled)ListTile(key:const ValueKey('reserve-reminder-day'),leading:const PaydayAppIcon(Icons.schedule),title:const LText('Remind me'),
      subtitle:LText('${reserveReminderChoices[reserveState!.preferences.day]} · 9:00 AM'),trailing:const PaydayAppIcon(Icons.chevron_right),onTap:busy?null:chooseReserveDay),
     if(reserveReady)TextButton(onPressed:busy?null:()=>run(widget.reserves!.sendTest,success:'Test notification sent.'),child:const LText('Test reserve reminder')),
    ])),
    if(state?.allowed==false||billState?.allowed==false||reserveState?.allowed==false||error!=null)TextButton(onPressed:busy?null:()=>run(widget.reminders.openSettings),child:const LText('Android notification settings')),
    if(backupReady||billReady)OutlinedButton.icon(onPressed:busy?null:()=>run(backupReady?widget.reminders.sendTest:widget.bills!.sendTest,success:'Test notification sent.'),
     icon:const PaydayAppIcon(Icons.notifications_none),label:const LText('Send a test')),
    if(error!=null)...[
     Padding(padding:const EdgeInsets.all(12),child:LText(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
     TextButton(onPressed:busy?null:load,child:const LText('Try again')),
    ],
   ]));
 }
}



