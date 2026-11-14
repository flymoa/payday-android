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
 Widget settingsGroup(String title,List<Widget> children)=>Column(
  crossAxisAlignment:CrossAxisAlignment.start,children:[
   Padding(padding:EdgeInsetsDirectional.fromSTEB(8,20,8,8),child:LText(title,style:TextStyle(color:muted,fontSize:PaydayType.small,fontWeight:FontWeight.w800))),
   Card(clipBehavior:Clip.antiAlias,margin:EdgeInsets.zero,child:Column(children:[
    for(var i=0;i<children.length;i++)...[
     if(i>0)Divider(height:1,thickness:1,indent:56,color:line),
     children[i],
    ],
   ])),
  ]);
 Widget appSettings(Map<String,List<RowData>> d){
  final prefs=widget.preferences;
  final canChange=widget.onPreferencesChanged!=null&&!preferencesSaving;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   header('Settings',subtitle:'Make PAYDAY work your way'),
   if(preferencesSaving)LinearProgressIndicator(),
   settingsGroup('Appearance',[
    ListTile(leading:PaydayAppIcon(Icons.light_mode_outlined),title:LText('Theme'),
     subtitle:LText(prefs.appearanceLabel),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:canChange?appearancePicker:null),
    ListTile(key:ValueKey('language-setting'),leading:PaydayAppIcon(Icons.translate),title:LText('Language'),
     subtitle:Text(paydayLanguages[language]!),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:canChange?()=>openSettingsPage((_)=>LanguageSettingsPage(initial:language,onChanged:(value)async{
      final saved=await changePreferences(widget.preferences.copyWith(language:value));
      if(saved&&mounted){await refreshNotificationLanguage();}
      return saved;
     })):null),
   ]),
   settingsGroup('Reminders',[
    ListTile(key:ValueKey('notifications-setting'),leading:PaydayAppIcon(Icons.notifications_none),title:LText('Notifications'),
     trailing:PaydayAppIcon(Icons.chevron_right),onTap:()=>openSettingsPage((_)=>NotificationSettingsPage(reminders:reminders,bills:billReminders,reserves:reserveReminders))),
   ]),
   settingsGroup('Security',[
    ListTile(key:ValueKey('security-setting'),leading:PaydayAppIcon(Icons.lock_outline),
     title:LText('App lock'),subtitle:LText(prefs.appLock?'On':'Off'),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:()=>openSettingsPage((_)=>SecuritySettingsPage(
      initialEnabled:widget.preferences.appLock,onChanged:widget.onPreferencesChanged==null?null:
       (value)=>changePreferences(widget.preferences.copyWith(appLock:value))))),
    SwitchListTile(key:ValueKey('home-widget-amount'),secondary:PaydayAppIcon(Icons.widgets_outlined),
     title:LText('Show amount on home-screen widget'),
     subtitle:LText(prefs.appLock?'Hidden while App lock is on':'Shows this month\'s safe-to-spend amount without unlocking Payday'),
     value:Ledger(d).setting(homeWidgetAmountKey)=='1',
     onChanged:prefs.appLock?null:(on)async{await execute(()=>store.setSetting(homeWidgetAmountKey,on?'1':'0'));}),
   ]),
   settingsGroup('Money & data',[
    ListTile(key:ValueKey('currency-setting'),leading:PaydayAppIcon(Icons.payments_outlined),title:LText('Currency'),
     subtitle:LText('${tr(context,paydayCurrencies[currency]!)} · $currency'),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:canChange?currencyPicker:null),
    ListTile(key:ValueKey('money-settings'),leading:PaydayAppIcon(Icons.account_balance_wallet_outlined),title:LText('Money settings'),
     subtitle:LText('Cash buffer and opening savings'),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:()=>settingsForm(d)),
    ListTile(key:ValueKey('backups-setting'),leading:PaydayAppIcon(Icons.ios_share),title:LText('Backups & data'),
     subtitle:LText(backupDateLabel(backupReminder(d))),trailing:PaydayAppIcon(Icons.chevron_right),
     onTap:()=>openSettingsPage((_)=>BackupSettingsPage(
      initialStatus:backupDateLabel(backupReminder(d)),
      refreshStatus:()async=>backupDateLabel(backupReminder(await data)),
      onExport:exportBackup,onRestore:importBackup,
      loadSnapshotDate:snapshots.savedAt,onUndoRestore:undoLastRestore,onExportCsv:exportCsv))),
   ]),
   settingsGroup('Help',[
    ListTile(key:ValueKey('about-help-setting'),leading:PaydayAppIcon(Icons.info_outline),title:LText('About & Help'),
     trailing:PaydayAppIcon(Icons.chevron_right),onTap:()=>openSettingsPage((_)=>const AboutHelpPage())),
   ]),
  ]);
 }
}
