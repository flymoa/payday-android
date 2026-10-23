import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_icon.dart';
import 'brand.dart';
import 'build_info.dart';

const appLockExplanation='Use your phone’s fingerprint, face unlock, or screen lock to open or return to PAYDAY. '
 'Screenshots and recent-app previews are blocked while App lock is on. '
 'App lock does not encrypt your records. New backup exports have separate password protection.';

Future<void> showSettingsInfo(BuildContext context,String title,String message)=>showDialog<void>(
 context:context,builder:(dialog)=>AlertDialog(title:Text(title),scrollable:true,
  content:Text(message),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Got it'))]));

const settingsPagePadding=EdgeInsets.fromLTRB(16,16,16,32);

/// Shared layout for every destination opened from the Home settings drawer.
class SettingsPageScaffold extends StatelessWidget{
 const SettingsPageScaffold({super.key,required this.title,required this.body,this.actions=const [],this.busy=false});
 final String title;
 final Widget body;
 final List<Widget> actions;
 final bool busy;
 @override Widget build(BuildContext context)=>PopScope<Object?>(canPop:!busy,child:Scaffold(
  appBar:AppBar(toolbarHeight:64,centerTitle:false,titleSpacing:0,
   title:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(title)),
   leading:IconButton(tooltip:'Back to Settings',onPressed:busy?null:()=>Navigator.pop(context),icon:const PaydayAppIcon(Icons.arrow_back)),
   actions:actions),
  body:SafeArea(child:body)));
}

class SecuritySettingsPage extends StatefulWidget{
 const SecuritySettingsPage({super.key,required this.initialEnabled,this.onChanged});
 final bool initialEnabled;
 final Future<bool> Function(bool)? onChanged;
 @override State<SecuritySettingsPage> createState()=>_SecuritySettingsPageState();
}
class _SecuritySettingsPageState extends State<SecuritySettingsPage>{
 late bool enabled=widget.initialEnabled;
 bool saving=false;
 Future<void> change(bool value)async{
  if(saving||widget.onChanged==null)return;
  setState(()=>saving=true);
  try{
   final saved=await widget.onChanged!(value);
   if(mounted&&saved)setState(()=>enabled=value);
  }catch(_){
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not change app lock. Please try again.')));
  }finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'Security',busy:saving,
   actions:[IconButton(key:const ValueKey('app-lock-info'),tooltip:'About app lock',
    icon:const PaydayAppIcon(Icons.info_outline,size:20),
    onPressed:()=>showSettingsInfo(context,'App lock',appLockExplanation))],
   body:ListView(padding:settingsPagePadding,children:[
    if(saving)const LinearProgressIndicator(),
    Card(clipBehavior:Clip.antiAlias,child:SwitchListTile(key:const ValueKey('app-lock-setting'),
     secondary:const PaydayAppIcon(Icons.lock_outline),title:const Text('App lock'),
     value:enabled,onChanged:saving||widget.onChanged==null?null:change)),
   ]));
}

class AboutHelpPage extends StatelessWidget{
 const AboutHelpPage({super.key});
 Widget topic(BuildContext context,String title,IconData icon,String message)=>Card(
  clipBehavior:Clip.antiAlias,child:ListTile(leading:PaydayAppIcon(icon),title:Text(title),
   trailing:const PaydayAppIcon(Icons.chevron_right),onTap:()=>showSettingsInfo(context,title,message)));
 Future<void> copyDetails(BuildContext context)async{
  try{
   await Clipboard.setData(const ClipboardData(text:'Payday $paydayVersion (build $paydayBuildNumber)'));
   if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('App details copied.')));
  }catch(_){
   if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not copy app details. Please try again.')));
  }
 }
 @override Widget build(BuildContext context)=>SettingsPageScaffold(title:'About & Help',
  body:ListView(padding:settingsPagePadding,children:[
   const Padding(padding:EdgeInsets.only(bottom:8),child:Align(alignment:Alignment.centerLeft,child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:PaydayBrand(compact:true)))),
   Text('Version $paydayVersion · Build $paydayBuildNumber',style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.onSurfaceVariant)),
   const SizedBox(height:20),
   topic(context,'Getting started',Icons.space_dashboard_outlined,
    'Use + to add income, expenses, or savings transfers. Set planned income and category amounts in Budgets. Find and edit your entries in Records.'),
   topic(context,'Budgets & savings',Icons.pie_chart_outline,
    'Category budgets and the savings goal share your planned income. You cannot assign more than that plan. Assigning existing savings to a goal does not create new savings.'),
   topic(context,'Backups & restore',Icons.ios_share,
    'Export a password-protected backup from Settings → Backups & data. Keep the file and password safe: PAYDAY cannot recover the password. Older JSON backups can still be restored. Restore replaces records and keeps this phone’s App lock setting.'),
   topic(context,'Privacy & security',Icons.lock_outline,
    'Your records stay on this phone. PAYDAY works without an account or internet connection. App lock controls access. Records on this phone are not encrypted by PAYDAY. New backup exports are encrypted with a separate password you choose.'),
   topic(context,'Updating PAYDAY',Icons.history,
    'Install the newer PAYDAY APK over your existing app. Uninstalling removes local records. Export a backup before changing phones or uninstalling.'),
   const SizedBox(height:12),
   OutlinedButton.icon(onPressed:()=>copyDetails(context),icon:const PaydayAppIcon(Icons.copy_outlined),label:const Text('Copy app details')),
  ]));
}


