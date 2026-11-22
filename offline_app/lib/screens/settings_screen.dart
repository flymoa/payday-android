// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _SettingsScreen on _FinanceState {
 Future<bool> changePreferences(AppPreferences next)async{
  if(preferencesSaving||widget.onPreferencesChanged==null)return false;
  setState(()=>preferencesSaving=true);
  try{return await widget.onPreferencesChanged!(next);}
  finally{if(mounted)setState(()=>preferencesSaving=false);unawaited(updateHomeWidget());}
 }
 Future<void> openSettingsPage(WidgetBuilder builder)async{
  await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder:builder));
 }
 Future<void> appearancePicker()=>openSettingsPage((_)=>ThemeSettingsPage(
  initial:widget.preferences.appearance,onChanged:(value)=>changePreferences(widget.preferences.copyWith(appearance:value))));
 Future<void> currencyPicker()=>openSettingsPage((_)=>CurrencySettingsPage(initial:currency,onChanged:(value)async{
  final saved=await changePreferences(widget.preferences.copyWith(currency:value));
  if(saved&&mounted)refresh();
  return saved;
 }));
 /// Group label above a panel: small caps in English and French; Arabic has no
 /// capitals, so it stays a plain muted label.
 Widget settingsGroup(String title,List<Widget> children)=>Column(
  crossAxisAlignment:CrossAxisAlignment.start,children:[
   Padding(padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.lg,PaydaySpace.xs,PaydaySpace.sm),
    child:LText(language=='ar'?title:tr(context,title).toUpperCase(),style:TextStyle(color:muted,fontSize:PaydayType.caption,
     fontWeight:FontWeight.w800,letterSpacing:language=='ar'?0:.5))),
   groupedRows(children),
  ]);
 /// One settings row: icon disc, title, optional line below, and a value, switch or chevron at the end.
 Widget settingRow({Key? key,required IconData icon,required String title,String? subtitle,String? value,
   Widget? toggle,VoidCallback? onTap,bool rawValue=false})=>listRow(key:key,onTap:onTap,
  leading:iconTile(icon,size:36),title:rowTitle(title),subtitle:subtitle,
  trailing:toggle??Row(mainAxisSize:MainAxisSize.min,children:[
   if(value!=null)ConstrainedBox(constraints:BoxConstraints(maxWidth:140),child:Padding(padding:EdgeInsetsDirectional.only(start:8),
    child:rawValue?Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:muted))
     :LText(value,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:muted)))),
   SizedBox(width:4),PaydayAppIcon(Icons.chevron_right,size:18,color:muted)]));
 /// Settings grouped like a normal app: General first, then reminders,
 /// privacy, money and data, and help.
 Widget appSettings(Map<String,List<RowData>> d){
  final prefs=widget.preferences;
  final canChange=widget.onPreferencesChanged!=null&&!preferencesSaving;
  Future<void> openSecurity()=>openSettingsPage((_)=>SecuritySettingsPage(
   initialEnabled:widget.preferences.appLock,onChanged:widget.onPreferencesChanged==null?null:
    (value)=>changePreferences(widget.preferences.copyWith(appLock:value))));
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   if(preferencesSaving)LinearProgressIndicator(),
   settingsGroup('General',[
    settingRow(key:ValueKey('language-setting'),icon:Icons.translate,title:'Language',value:paydayLanguages[language]!,rawValue:true,
     onTap:canChange?()=>openSettingsPage((_)=>LanguageSettingsPage(initial:language,onChanged:(value)async{
      final saved=await changePreferences(widget.preferences.copyWith(language:value));
      if(saved&&mounted){await refreshNotificationLanguage();}
      return saved;
     })):null),
    settingRow(key:ValueKey('currency-setting'),icon:Icons.payments_outlined,title:'Currency',value:currencyLabel(currency,language),rawValue:true,
     onTap:canChange?currencyPicker:null),
    settingRow(key:ValueKey('theme-setting'),icon:Icons.dark_mode_outlined,title:'Appearance',value:prefs.appearanceLabel,
     onTap:canChange?appearancePicker:null),
    // Payday changes every number in the app, so it sits with the basics.
    settingRow(key:ValueKey('payday-setting'),icon:Icons.calendar_today_outlined,title:'Salary day',
     subtitle:'Next payday: ${shortDay(dayKey(cycleOf(d).nextPayday))}',
     onTap:()=>openSettingsPage((_)=>PaydaySettingsPage(initial:paydayRuleOf(d),onChanged:(rule)=>execute(()async{
      await store.setSetting(PaydayRule.dayKey,rule.encodedDay);
      await store.setSetting(PaydayRule.weekendKey,rule.weekend.name);
     },saved:'Payday saved.')))),
    settingRow(key:ValueKey('salary-early'),icon:Icons.event_outlined,title:'Salary came early',subtitle:'Add it now: the new cycle starts today',
     onTap:()=>transactionForm(null,initialType:'Income')),
   ]),
   settingsGroup('Reminders',[
    settingRow(key:ValueKey('notifications-setting'),icon:Icons.notifications_none,title:'Reminders',subtitle:'Bills, reserves and backups',
     onTap:()=>openSettingsPage((_)=>NotificationSettingsPage(reminders:reminders,bills:billReminders,reserves:reserveReminders))),
   ]),
   settingsGroup('Privacy & security',[
    settingRow(key:ValueKey('security-setting'),icon:Icons.lock_outline,title:'App lock',subtitle:'Fingerprint or phone PIN',
     onTap:openSecurity,
     // The switch opens the same page, where the phone confirms the change.
     toggle:Switch(key:ValueKey('app-lock-toggle'),value:prefs.appLock,onChanged:canChange?(_)=>openSecurity():null)),
    settingRow(key:ValueKey('home-widget-amount-row'),icon:Icons.visibility_outlined,title:'Widget shows amount',
     subtitle:prefs.appLock?'Hidden while App lock is on':null,
     toggle:Switch(key:ValueKey('home-widget-amount'),value:!prefs.appLock&&Ledger(d).setting(homeWidgetAmountKey)=='1',
      onChanged:prefs.appLock?null:(on)async{await execute(()=>store.setSetting(homeWidgetAmountKey,on?'1':'0'));})),
   ]),
   settingsGroup('Money & data',[
    settingRow(key:ValueKey('backups-setting'),icon:Icons.upload_outlined,title:'Backup & restore',subtitle:backupDateLabel(backupReminder(d)),
     onTap:()=>openSettingsPage((_)=>BackupSettingsPage(
      initialStatus:backupDateLabel(backupReminder(d)),
      refreshStatus:()async=>backupDateLabel(backupReminder(await data)),
      onExport:exportBackup,onRestore:importBackup,
      loadSnapshotDate:snapshots.savedAt,onUndoRestore:undoLastRestore,onExportCsv:exportCsv))),
    settingRow(key:ValueKey('import-csv'),icon:Icons.download_outlined,title:'Import CSV',subtitle:'From your bank or another app',onTap:importCsv),
    settingRow(key:ValueKey('money-settings'),icon:Icons.account_balance_wallet_outlined,title:'Money settings',
     subtitle:'Cash buffer and opening savings',onTap:()=>settingsForm(d)),
   ]),
   settingsGroup('Help',[
    settingRow(key:ValueKey('about-help-setting'),icon:Icons.info_outline,title:'About Payday',subtitle:'Version $paydayVersion',
     onTap:()=>openSettingsPage((_)=>const AboutHelpPage())),
   ]),
  ]);
 }
}
