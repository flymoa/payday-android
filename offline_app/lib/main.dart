import 'design_tokens.dart';
import 'ui_kit.dart';
import 'settings_home.dart';
import 'build_info.dart';
import 'wallets.dart';
import 'hijri.dart';
import 'localization.dart';
import 'app_language.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bill_reminders.dart';
import 'reserve_reminders.dart';
import 'backup_notifications.dart';
import 'notification_settings_page.dart';
import 'backup_cipher.dart';
import 'backup_password_dialog.dart';
import 'settings_pages.dart';
import 'settings_preferences_pages.dart';
import 'backup_settings_page.dart';
import 'backup_preview.dart';
import 'restore_snapshot.dart';
import 'csv_export.dart';
import 'recurring.dart';
import 'ledger.dart';
import 'pay_cycle.dart';
import 'payday_settings_page.dart';
import 'home_widget.dart';
import 'db_encryption.dart';
import 'dart:async';
import 'dart:math' show max;
import 'app_lock.dart';
import 'app_preferences.dart';
import 'add_button.dart';
import 'transaction_categories.dart';
import 'app_icon.dart';
import 'category_icon.dart';
import 'dart:io';
import 'dart:convert';
import 'v3_logic.dart';
import 'package:flutter/services.dart';
import 'brand.dart';
import 'opening.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'finance.dart';
import 'offline_store.dart';
part 'screens/home_screen.dart';
part 'screens/more_screen.dart';
part 'screens/records_budgets_savings.dart';
part 'screens/settings_screen.dart';
part 'screens/forms.dart';
part 'screens/backup_actions.dart';
part 'screens/welcome_screen.dart';
part 'screens/alerts_screen.dart';
part 'screens/reports_screen.dart';
part 'screens/v3_screens.dart';

void main(){
 WidgetsFlutterBinding.ensureInitialized();
 runApp(const PaydayStartup());
}
/// Never show financial screens if security preferences could not be read.
class PaydayStartup extends StatefulWidget{
 const PaydayStartup({super.key,this.store});
 final OfflineStore? store;
 @override State<PaydayStartup> createState()=>_PaydayStartupState();
}
class _PaydayStartupState extends State<PaydayStartup>{
 late final store=widget.store??OfflineStore();
 late Future<AppPreferences> preferences=store.loadAppPreferences();
 @override Widget build(BuildContext context)=>FutureBuilder<AppPreferences>(future:preferences,builder:(context,snapshot){
  if(snapshot.hasData)return PaydayLocal(store:store,initialPreferences:snapshot.data!,welcomeOnFirstRun:true);
  return MaterialApp(debugShowCheckedModeBanner:false,home:Scaffold(backgroundColor:paydaySand,
   body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(24),child:snapshot.hasError?
    Column(mainAxisSize:MainAxisSize.min,children:[
     const LText('Could not read your app settings. Your records have not been opened.',textAlign:TextAlign.center),
     const SizedBox(height:16),FilledButton(onPressed:(){final next=store.loadAppPreferences();setState((){preferences=next;});},child:const LText('Try again')),
    ]):const SizedBox.shrink())))));
 });
}
const kInk=PaydayColors.ink, kJade=paydayEmerald, kCream=paydaySand;
typedef RowData=Map<String,Object?>;
String st(RowData row,String key)=>row[key]?.toString()??'';
int val(RowData row,String key)=>(row[key] as num?)?.toInt()??0;
DateTime parseDay(String text)=>DateTime.tryParse(text)??DateTime.now();
class PaydayLocal extends StatefulWidget {
 const PaydayLocal({super.key,this.initialData,this.store,
  this.initialPreferences=const AppPreferences(),this.preferencesWriter,this.appLockController,this.welcomeOnFirstRun=false});
 /// Only the installed app (main) shows the welcome pages on an empty phone.
 final bool welcomeOnFirstRun;
 final OfflineStore? store;
 final AppPreferences initialPreferences;
 final AppLockController? appLockController;
 final Future<void> Function(AppPreferences)? preferencesWriter;
 final Future<Map<String,List<RowData>>>? initialData;
 @override State<PaydayLocal> createState()=>_PaydayLocalState();
}
class _PaydayLocalState extends State<PaydayLocal> {
 late AppPreferences preferences=widget.initialPreferences;
 late final localStore=widget.store??OfflineStore();
 final messengerKey=GlobalKey<ScaffoldMessengerState>();
 bool savingPreferences=false;
 late final appLock=widget.appLockController??AppLockController(enabled:preferences.appLock);
 late final lockRoutes=AppLockRouteGuard(appLock);
 @override void initState(){super.initState();appLock.language=preferences.language;unawaited(appLock.initializePrivacy());}
 @override void dispose(){lockRoutes.dispose();appLock.dispose();super.dispose();}
 ThemeMode get mode=>preferences.appearance;
 Future<bool> savePreferences(AppPreferences next)async{
  if(savingPreferences)return false;
  savingPreferences=true;
  final lockChanged=next.appLock!=preferences.appLock;
  var privacyChanged=false;
  try{
   if(lockChanged){
    final allowed=await appLock.authorize(next.appLock?'Enable Payday app lock':'Turn off Payday app lock');
    if(!mounted)return false;
    if(!allowed){
     messengerKey.currentState?.showSnackBar(SnackBar(content:LText(appLock.error??'App lock was not changed.')));
     return false;
    }
    privacyChanged=true;
    await appLock.configurePrivacy(next.appLock);
   }
   await (widget.preferencesWriter??localStore.saveAppPreferences)(next);
   if(!mounted)return false;
   setState(()=>preferences=next);
   appLock.language=next.language;
   if(lockChanged)appLock.setEnabled(next.appLock);
   return true;
  }catch(_){
   if(privacyChanged){try{await appLock.configurePrivacy(preferences.appLock);}catch(_){appLock.lockNow();}}
   messengerKey.currentState?.showSnackBar(const SnackBar(content:LText('Could not save preferences. Please try again.')));
   return false;
  }finally{savingPreferences=false;}
 }
 /// Light: sand, emerald and saffron. Dark: neutral charcoal with the same accents.
 ThemeData palette(Brightness brightness){
  final dark=brightness==Brightness.dark;
  final scheme=ColorScheme.fromSeed(seedColor:kJade,brightness:brightness,
   primary:dark?PaydayColors.darkPrimary:kJade,
   surface:dark?PaydayColors.darkSurface:Colors.white,
   onSurface:dark?PaydayColors.darkText:kInk,onSurfaceVariant:dark?PaydayColors.darkMuted:PaydayColors.muted,
   outlineVariant:dark?PaydayColors.darkLine:PaydayColors.line).copyWith(
    onPrimary:dark?PaydayColors.darkOnPrimary:Colors.white,
    primaryContainer:dark?PaydayColors.emerald:PaydayColors.mintTint,
    onPrimaryContainer:dark?PaydayColors.sand:PaydayColors.emerald,
    secondaryContainer:dark?PaydayColors.darkIconDisc:PaydayColors.mintTint,
    onSecondaryContainer:dark?PaydayColors.darkText:PaydayColors.emerald,
    tertiary:dark?PaydayColors.darkCopper:PaydayColors.saffron,onTertiary:PaydayColors.ink,
    error:dark?PaydayColors.darkStatusOver:PaydayColors.statusOver,
    surfaceTint:Colors.transparent,
    surfaceContainerLowest:dark?PaydayColors.darkBackground:Colors.white,
    surfaceContainerLow:dark?PaydayColors.darkSurfaceLow:PaydayColors.surfaceLow,
    surfaceContainer:dark?PaydayColors.darkSurfaceLow:PaydayColors.surfaceLow,
    surfaceContainerHigh:dark?PaydayColors.darkSurfaceHigh:PaydayColors.surfaceHigh,
    surfaceContainerHighest:dark?PaydayColors.darkLine:PaydayColors.line);
  final background=dark?PaydayColors.darkBackground:kCream;
  final base=ThemeData(useMaterial3:true,colorScheme:scheme,fontFamily:'DMSans',fontFamilyFallback:const ['PlexArabic','sans-serif']);
  return base.copyWith(
   textTheme:base.textTheme.copyWith(
    titleLarge:base.textTheme.titleLarge?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800),
    headlineSmall:base.textTheme.headlineSmall?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800)),
   scaffoldBackgroundColor:background,
   appBarTheme:AppBarTheme(backgroundColor:background,
    foregroundColor:scheme.onSurface,centerTitle:true,surfaceTintColor:Colors.transparent),
   bottomSheetTheme:BottomSheetThemeData(backgroundColor:scheme.surface,surfaceTintColor:Colors.transparent,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(PaydayRadius.dialog)))),
   dialogTheme:DialogThemeData(backgroundColor:scheme.surface,surfaceTintColor:Colors.transparent,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.dialog))),
   cardTheme:CardThemeData(elevation:0,color:Colors.transparent,surfaceTintColor:Colors.transparent,margin:const EdgeInsets.symmetric(vertical:PaydaySpace.xs),
    shape:Border.symmetric(horizontal:BorderSide(color:scheme.outlineVariant))),
   inputDecorationTheme:InputDecorationTheme(filled:true,
    fillColor:dark?PaydayControl.fillDark:PaydayControl.fillLight,
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md),borderSide:BorderSide.none),
    enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md),borderSide:BorderSide.none),
    focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md),borderSide:BorderSide(color:scheme.primary,width:2))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
    minimumSize:const Size(48,52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg)),textStyle:TextStyle(fontWeight:FontWeight.w800,fontFamily:'DMSans',fontFamilyFallback:const ['PlexArabic','sans-serif']))),
   // Secondary buttons: tonal fill, ink text, no outline. Filled emerald stays the one primary.
   outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(
    minimumSize:const Size(PaydayControl.target,PaydayControl.target),
    backgroundColor:dark?PaydayControl.fillDark:PaydayControl.fillLight,foregroundColor:scheme.onSurface,
    side:BorderSide.none,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg)),
    textStyle:const TextStyle(fontWeight:FontWeight.w700,fontFamily:'DMSans',fontFamilyFallback:['PlexArabic','sans-serif']))),
   listTileTheme:ListTileThemeData(iconColor:scheme.primary),
   dividerTheme:DividerThemeData(color:scheme.outlineVariant,thickness:1),
   snackBarTheme:SnackBarThemeData(backgroundColor:dark?PaydayColors.darkSurfaceHigh:kInk,
    contentTextStyle:TextStyle(color:dark?PaydayColors.darkText:paydaySand,fontFamily:'DMSans',fontFamilyFallback:const ['PlexArabic','sans-serif']),actionTextColor:paydaySaffron),
   navigationBarTheme:NavigationBarThemeData(backgroundColor:scheme.surface),
  );
 }
 @override Widget build(BuildContext context)=>MaterialApp(
  navigatorObservers:[lockRoutes],scaffoldMessengerKey:messengerKey,debugShowCheckedModeBanner:false,title:'Payday',
  locale:Locale(preferences.language),supportedLocales:const [Locale('en'),Locale('fr'),Locale('ar')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,theme:palette(Brightness.light),
  darkTheme:palette(Brightness.dark),themeMode:mode,
  builder:(context,child){
   return PaydayOpening(child:PaydayLockGate(controller:appLock,child:child??const SizedBox.shrink()));
  },
  home:FinanceScreen(store:localStore,initialData:widget.initialData,preferences:preferences,welcomeOnFirstRun:widget.welcomeOnFirstRun,
   onPreferencesChanged:savePreferences,onToggleTheme:(dark){
    savePreferences(preferences.copyWith(appearance:dark?ThemeMode.dark:ThemeMode.light));
   }));
}
class FinanceScreen extends StatefulWidget {const FinanceScreen({super.key,this.onToggleTheme,this.initialData,this.store,this.backupShare,this.backupCipher,this.backupNotifications,this.billReminders,this.reserveReminders,this.restoreSnapshot,
 this.preferences=const AppPreferences(),this.onPreferencesChanged,this.welcomeOnFirstRun=false});final ValueChanged<bool>? onToggleTheme;
 final bool welcomeOnFirstRun;
 final AppPreferences preferences;
 final Future<bool> Function(AppPreferences)? onPreferencesChanged;
 final OfflineStore? store;
 final BackupCipher? backupCipher;
 final RestoreSnapshot? restoreSnapshot;
 final BackupNotifications? backupNotifications;
 final BillReminders? billReminders;
 final ReserveReminders? reserveReminders;
 final Future<ShareResult> Function(String contents)? backupShare;
 final Future<Map<String,List<RowData>>>? initialData;@override State<FinanceScreen> createState()=>_FinanceState();}
class _FinanceState extends State<FinanceScreen> with WidgetsBindingObserver{
 bool get isDark=>Theme.of(context).brightness==Brightness.dark;
 Color get ink=>Theme.of(context).colorScheme.onSurface;
 Color get jade=>Theme.of(context).colorScheme.primary;
 Color get cream=>Theme.of(context).scaffoldBackgroundColor;
 Color get surface=>Theme.of(context).colorScheme.surface;
 Color get muted=>Theme.of(context).colorScheme.onSurfaceVariant;
 Color get homeNavy=>ink;
 Color get homeText=>muted;
 Color get homeGreen=>jade;
 Color get line=>Theme.of(context).colorScheme.outlineVariant;
 /// Status colours that stay readable on both sand and charcoal.
 Color get danger=>isDark?PaydayColors.darkStatusOver:PaydayColors.statusOver;
 Color get saffronText=>isDark?PaydayColors.darkSaffronText:PaydayColors.saffronText;
 Color get warn=>isDark?PaydayColors.darkStatusNear:PaydayColors.statusNear;
 Color get amber=>saffronText;
 bool writing=false;
 bool exportingBackup=false;
 bool restoringBackup=false;
 BackupCipher get backupCipher=>widget.backupCipher??const BackupCipher();
 late final RestoreSnapshot snapshots=widget.restoreSnapshot??RestoreSnapshot(password:DatabaseKey.obtain);
 bool preferencesSaving=false;
 final scaffoldKey=GlobalKey<ScaffoldState>();
 String get currency=>supportedCurrency(widget.preferences.currency);
 String get language=>widget.preferences.language;
 String money(int amount)=>localizedMoney(amount,currency,language);
 String inputNumber(int amount)=>localizedNumber(amount,language);
 String uiDay(DateTime day)=>localizedDay(day,language);
 String currencyMessage(String message)=>translateMessage(message.replaceAll(' MAD',' ${currencyLabel(currency,language)}'),language);
 /// Rebuilds the open Settings page after this screen rebuilds (new preferences or data).
 final settingsRefresh=ValueNotifier<int>(0);
 bool settingsOpen=false,alertsOpen=false;
 Set<String>? seenAlerts; // what the bell showed when last opened
 Future<void> openSettingsDrawer()async{
  if(settingsOpen)return;
  settingsOpen=true;
  try{
   await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder:(_)=>SettingsHomePage(refresh:settingsRefresh,
    builder:(page)=>FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(page,snap){
     if(snap.hasError)return Padding(padding:EdgeInsets.all(PaydaySpace.xl),child:LText('Could not load settings.'));
     if(!snap.hasData)return SizedBox(height:200);
     return appSettings(snap.data!);
    }))));
  }finally{settingsOpen=false;}
 }
 String recordQuery='';
 bool recordAllMonths=false;
 String recordType='All';
 final search=TextEditingController();
 late final store=widget.store??OfflineStore();
 late final reminders=widget.backupNotifications??BackupNotifications(store);
 late final billReminders=widget.billReminders??BillReminders(store);
 late final reserveReminders=widget.reserveReminders??ReserveReminders(store);
 bool reserveSyncErrorShown=false;
 bool reminderSyncErrorShown=false;
 late Future<Map<String,List<RowData>>> data=widget.initialData??store.snapshot();
 DateTime selected=DateTime(DateTime.now().year,DateTime.now().month);
 int page=0;
 WalletSetup? currentWallets; // read with each data load, for the wallet name on rows
 bool welcome=false; // first open on an empty phone
 /// Small tabs inside Records (1), Budgets (2) and Savings (3); each page remembers its last one.
 final subTab=<int,int>{1:0,2:0,3:0};
 static const subTabLabels=<int,List<String>>{1:['List','Calendar','Reports','Review'],2:['Budgets','Bills','Recurring'],3:['Goals','Reserves','Kridi','Daret','Wallets']};
 DateTime? calendarDay; // day picked in Records · Calendar
 bool reportYear=false;
 int? reportSlice; // slice tapped in the Reports ring
 /// Opens a tool in the tab it now lives in (0 bills, 1 reserves, 2 year, 4 review, 5 recurring, 6 Cash & Bank).
 void openTool(int tool){
  const at={0:[2,1],1:[3,1],2:[1,2],4:[1,3],5:[2,2],6:[3,4],7:[3,2],8:[3,3]};
  final t=at[tool]!;
  setState((){page=t[0];subTab[t[0]]=t[1];if(tool==2)reportYear=true;});
 }
 Widget subTabs(){
  final labels=subTabLabels[page]!,current=subTab[page]??0;
  final style=TextStyle(fontWeight:FontWeight.w700,fontSize:PaydayType.small);
  final measureStyle=DefaultTextStyle.of(context).style.merge(Theme.of(context).textTheme.bodyMedium).merge(style);
  const pad=14.0;
  return Padding(padding:EdgeInsets.only(bottom:PaydaySpace.md),child:LayoutBuilder(builder:(context,box){
   // Every tab keeps the same text size and is never cut: each is as wide as its own label,
   // spare room is shared out evenly, and when the labels do not fit the row scrolls sideways.
   final scaler=MediaQuery.textScalerOf(context);
   final text=[for(final l in labels)(TextPainter(text:TextSpan(text:tr(context,l),style:measureStyle),maxLines:1,textDirection:Directionality.of(context),textScaler:scaler)..layout()).width];
   final inner=box.maxWidth-PaydaySpace.xs*2;
   // Roomy padding when it fits, tighter padding before falling back to scrolling.
   final roomy=text.fold<double>(0,(a,b)=>a+b+pad*2)*1.06<=inner;
   final widths=[for(final w in text)w+(roomy?pad*2:16)];
   final total=widths.fold<double>(0,(a,b)=>a+b);
   final fits=total*1.06<=inner;
   Widget cell(int i,Widget child)=>fits?Expanded(flex:(widths[i]*10).round(),child:child):SizedBox(width:widths[i],child:child);
   final row=Row(mainAxisSize:fits?MainAxisSize.max:MainAxisSize.min,children:[for(var i=0;i<labels.length;i++)cell(i,Semantics(selected:i==current,button:true,
    child:Material(color:i==current?surface:Colors.transparent,borderRadius:BorderRadius.circular(PaydayRadius.pill),
     child:InkWell(key:ValueKey('subtab-$page-$i'),borderRadius:BorderRadius.circular(PaydayRadius.pill),
      onTap:()=>setState(()=>subTab[page]=i),
      child:ConstrainedBox(constraints:const BoxConstraints(minHeight:44),child:Center(
       child:LText(labels[i],maxLines:1,softWrap:false,textAlign:TextAlign.center,style:style.copyWith(color:i==current?ink:muted))))))))]);
   return Container(padding:EdgeInsets.all(PaydaySpace.xs),
    decoration:BoxDecoration(color:isDark?PaydayColors.darkSurfaceHigh:PaydayColors.surfaceHigh,borderRadius:BorderRadius.circular(PaydayRadius.pill)),
    child:fits?row:SingleChildScrollView(scrollDirection:Axis.horizontal,child:row));
  }));
 }
 final purchase=TextEditingController(text:'200');
 @override void initState(){
  super.initState();WidgetsBinding.instance.addObserver(this);
  if(widget.welcomeOnFirstRun&&widget.initialData==null)unawaited(data.then((d){if(mounted&&firstRun(d))setState(()=>welcome=true);}).catchError((Object _){}));
  unawaited(runRecurring());
  unawaited(updateHomeWidget());
  unawaited(syncBillReminders());
  WidgetsBinding.instance.addPostFrameCallback((_)=>unawaited(openWidgetAction()));
  unawaited(syncReserveReminders());
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){
  if(state==AppLifecycleState.resumed){
   unawaited(runRecurring());
   unawaited(openWidgetAction());
   unawaited(syncBillReminders());
   unawaited(syncReserveReminders());
  }
 }
 Future<void> openWidgetAction()async{
  if(widget.initialData!=null)return;
  final action=await takeHomeWidgetAction();
  if(action=='add_expense'&&mounted){
   setState(()=>page=0);
   await transactionForm(null);
  }
 }
 Future<void> runRecurring()async{
  if(widget.initialData!=null)return; // test screens with fixed data
  try{
   final created=await store.applyRecurring(DateTime.now());
   if(created>0&&mounted){refresh();inputError('$created recurring entries added.');}
  }catch(_){}
  await runRepeatingBills();
 }
 Future<void> runRepeatingBills()async{
  if(widget.initialData!=null)return; // test screens with fixed data
  try{
   final created=await store.applyRepeatingBills(DateTime.now());
   if(created>0&&mounted){refresh();inputError('$created monthly bills added.');}
  }catch(_){}
 }
 Future<void> syncBillReminders()async{
  if(!mounted||!BillReminders.supported&&widget.billReminders==null)return;
  try{await billReminders.synchronize();reminderSyncErrorShown=false;}
  catch(_){
   if(mounted&&!reminderSyncErrorShown){
    reminderSyncErrorShown=true;
    WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)inputError('Bill reminders could not refresh. Check Settings → Notifications.');});
    WidgetsBinding.instance.ensureVisualUpdate();
   }
  }
 }
 Future<void> refreshNotificationLanguage()async{
  if(BackupNotifications.supported||widget.backupNotifications!=null){try{await reminders.synchronizeLanguage();}catch(_){if(mounted)inputError('Could not change reminders. Please try again.');}}
  await syncBillReminders();await syncReserveReminders();
 }
 Future<void> syncReserveReminders()async{
  if(!mounted||!ReserveReminders.supported&&widget.reserveReminders==null)return;
  try{await reserveReminders.synchronize();reserveSyncErrorShown=false;}
  catch(_){
   if(mounted&&!reserveSyncErrorShown){
    reserveSyncErrorShown=true;
    WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)inputError('Reserve reminders could not refresh. Check Settings → Notifications.');});
    WidgetsBinding.instance.ensureVisualUpdate();
   }
  }
 }
 @override void dispose(){settingsRefresh.dispose();WidgetsBinding.instance.removeObserver(this);purchase.dispose();search.dispose();store.close();super.dispose();}
 void refresh(){
  if(!mounted)return;
  final next=store.snapshot();
  setState((){data=next;});
  unawaited(syncBillReminders());
  unawaited(syncReserveReminders());
  unawaited(updateHomeWidget());
 }
 String get month=>monthKey(selected);
 void shift(int n){setState((){selected=DateTime(selected.year,selected.month+n);reportSlice=null;});}
 /// The payday rule the user picked in Settings (default: the 28th, Friday before a weekend).
 PaydayRule paydayRuleOf(Map<String,List<RowData>> d){final l=Ledger(d);return PaydayRule.fromSettings(l.setting(PaydayRule.dayKey),l.setting(PaydayRule.weekendKey));}
 /// The pay cycle containing [today]; a logged salary near payday moves its start.
 PayCycle cycleOf(Map<String,List<RowData>> d,[DateTime? today])=>payCycleFor(today??DateTime.now(),paydayRuleOf(d),
  salaryDates:list(d,'transactions').where((t)=>st(t,'type')=='Income'&&st(t,'category')=='Salary')
   .map((t)=>DateTime.tryParse(st(t,'date'))).whereType<DateTime>());
 Future<bool> execute(Future<void> Function() fn,{String saved='Saved on this phone.'})async{
  if(writing)return false;
  writing=true;
  try{await fn();refresh();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText(saved)));return true;}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText('Could not save: ${currencyMessage(e.toString())}')));return false;}
  finally{writing=false;}
 }
 List<RowData> list(Map<String,List<RowData>> d,String table)=>d[table]??[];
 List<RowData> monthTransactionsFor(Map<String,List<RowData>> d,String key)=>list(d,'transactions').where((t)=>st(t,'date').startsWith(key)).toList();
 List<RowData> monthTransactions(Map<String,List<RowData>> d)=>list(d,'transactions').where((t)=>st(t,'date').startsWith(month)).toList()..sort((a,b)=>st(b,'date').compareTo(st(a,'date')));
 // Money rules live in ledger.dart (unit tested); these keep the screen code short.
 int sumType(Iterable<RowData> tx,String type)=>Ledger.sumType(tx,type);
 int budgetFor(Map<String,List<RowData>> d,String key,String category)=>Ledger(d).budgetFor(key,category);
 int billPaid(Map<String,List<RowData>> d,RowData bill)=>Ledger(d).billPaid(bill);
 int totalPool(Map<String,List<RowData>> d)=>Ledger(d).totalPool();
 int allocated(Map<String,List<RowData>> d)=>Ledger(d).allocated();
 int buffer(Map<String,List<RowData>> d)=>Ledger(d).buffer();
 List<RowData> reserveHistory(Map<String,List<RowData>> d,int reserveId)=>Ledger(d).reserveHistory(reserveId);
 int reserveNetForMonth(Map<String,List<RowData>> d,String key,{int? reserveId})=>Ledger(d).reserveNetForMonth(key,reserveId:reserveId);
 int reserveFundedAt(Map<String,List<RowData>> d,RowData reserve,String thruMonth)=>Ledger(d).reserveFundedAt(reserve,thruMonth);
 int monthlyReserves(Map<String,List<RowData>> d)=>Ledger(d).monthlyReserves(month);
 int unpaidBills(Map<String,List<RowData>> d)=>Ledger(d).unpaidBills(month);
 String monthLabel(DateTime d)=>localizedMonth(d,language,short:true);
 // Building blocks shared by the screens, matching the design canvas.
 /// " · Cash" or " · Bank" for entries made after Cash & Bank tracking started.
 String walletOf(RowData row)=>currentWallets!=null&&val(row,'id')>currentWallets!.afterId?' · ${tr(context,st(row,'account')=='Bank'?'Bank':'Cash')}':'';
 String shortDay(String iso){final d=DateTime.tryParse(iso);return d==null?iso:localizedShortDay(d,language);}
 /// Amount without the currency, for lists where the currency is obvious.
 String plain(int cents)=>localizedNumber(cents,language,grouped:true);
 Widget iconTile(IconData icon,{Color? color,Color? background,double size=40})=>Container(width:size,height:size,
  decoration:BoxDecoration(color:background??(isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint),borderRadius:BorderRadius.circular(PaydayRadius.lg)),
  child:Center(child:PaydayAppIcon(icon,size:size*.5,color:color)));
 /// A content card: lifted surface, 1px border, radius 14, no shadow.
 Widget contentCard(Widget child,{Key? key})=>Material(key:key,
  color:isDark?PaydayCard.surfaceDark:PaydayCard.surfaceLight,clipBehavior:Clip.antiAlias,
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.card),
   side:BorderSide(color:isDark?PaydayCard.borderDark:PaydayCard.borderLight)),
  child:child);
 /// Rows of one list. [separate]: each row is its own card (budget categories, each a
 /// separate object with its own bar). Otherwise the group shares one card with hairlines
 /// between rows (dense lists: records of a day, recent activity, goals, bills).
 Widget groupedRows(List<Widget> rows,{bool separate=false})=>separate
  ?Column(children:[for(var i=0;i<rows.length;i++)Padding(padding:EdgeInsets.only(top:i==0?0:PaydayCard.gap),child:contentCard(rows[i]))])
  :contentCard(Column(children:[for(var i=0;i<rows.length;i++)...[if(i>0)Divider(height:1,thickness:1,indent:PaydaySpace.md,endIndent:PaydaySpace.md,color:line),rows[i]]]));
 Widget rowTitle(String text,{bool raw=false,bool category=false}){
  final style=TextStyle(fontWeight:FontWeight.w700,fontSize:15,color:ink);
  return raw?Text(text,maxLines:1,overflow:TextOverflow.ellipsis,style:style):LText(text,category:category,maxLines:1,overflow:TextOverflow.ellipsis,style:style);
 }
 /// Icon, title with a line under it, an amount with an optional status, and an optional bar.
 Widget listRow({Key? key,required Widget leading,required Widget title,String? subtitle,Color? subtitleColor,String? amount,Color? amountColor,
  String? status,Color? statusColor,double? progress,Color? progressColor,Color? trackColor,VoidCallback? onTap,Widget? trailing})=>
  InkWell(key:key,onTap:onTap,child:Padding(padding:EdgeInsets.symmetric(horizontal:PaydaySpace.md+2,vertical:PaydaySpace.md),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LayoutBuilder(builder:(context,box)=>Row(children:[leading,SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title,
     if(subtitle!=null)Padding(padding:EdgeInsets.only(top:2),child:LText(subtitle,maxLines:2,
      style:TextStyle(fontSize:PaydayType.caption,color:subtitleColor??muted,fontWeight:subtitleColor==null?FontWeight.w400:FontWeight.w600)))])),
    if(amount!=null||status!=null)...[SizedBox(width:8),ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.45),
     child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
      if(amount!=null)FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
       child:LText(amount,style:PaydayText.amount.copyWith(fontSize:PaydayType.body,color:amountColor??ink))),
      if(status!=null)LText(status,textAlign:TextAlign.end,maxLines:2,style:TextStyle(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:statusColor??muted)),
     ]))],
    ?trailing,
   ])),
   if(progress!=null)...[SizedBox(height:9),PaydayProgress(value:progress.clamp(0,1).toDouble(),color:progressColor,trackColor:trackColor)],
  ])));
 /// Full-width secondary action at the end of a list ("Add a bill").
 Widget listAction(String label,IconData icon,VoidCallback onPressed,{Key? key})=>Padding(padding:EdgeInsets.only(top:12),
  child:SizedBox(width:double.infinity,child:OutlinedButton.icon(key:key,onPressed:onPressed,
   style:OutlinedButton.styleFrom(minimumSize:Size.fromHeight(52)),
   icon:PaydayAppIcon(icon,size:20),label:LText(label,style:TextStyle(fontWeight:FontWeight.w700)))));
 /// One summary line in a panel ("Still to pay … 728.00 MAD"), with optional content below.
 Widget summaryLine(String label,String value,{Widget? below,Widget? trailing,Key? key})=>Padding(key:key,
  padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.sm,PaydaySpace.xs,PaydaySpace.lg),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Expanded(child:LText(label,style:TextStyle(color:muted,fontWeight:FontWeight.w700))),SizedBox(width:8),
    Flexible(child:Align(alignment:AlignmentDirectional.centerEnd,child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
     child:LText(value,style:PaydayText.figure.copyWith(color:ink))))),
    ?trailing]),
   if(below!=null)...[SizedBox(height:10),below],
  ]));
 Widget header(String title,{String? subtitle,Widget? action})=>Padding(padding:EdgeInsetsDirectional.fromSTEB(4,12,4,10),
  child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:PaydayType.sectionTitle,fontWeight:FontWeight.w800,color:ink)),
   if(subtitle!=null)Padding(padding:EdgeInsets.only(top:4),child:LText(subtitle,style:TextStyle(color:muted)))
  ])),if(action!=null)Flexible(child:Align(alignment:AlignmentDirectional.centerEnd,child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,child:action)))]));
 Widget tile(String title,String subtitle,String trailing,{bool divider=true,VoidCallback? onTap,IconData icon=Icons.circle_outlined,Color? tone,Widget? leading,bool rawTitle=false,bool categoryTitle=false})=>
  Column(children:[ListTile(contentPadding:EdgeInsets.symmetric(horizontal:divider?PaydaySpace.xs:PaydaySpace.md+2,vertical:PaydaySpace.xs),
   leading:leading??CircleAvatar(backgroundColor:(tone??jade).withValues(alpha:.10),child:PaydayAppIcon(icon,color:tone??jade,size:20)),
   title:rawTitle?Text(title,style:TextStyle(fontWeight:FontWeight.w700)):LText(title,category:categoryTitle,style:TextStyle(fontWeight:FontWeight.w700)),
   subtitle:LText(subtitle,maxLines:3,overflow:TextOverflow.ellipsis),
   trailing:LText(trailing,style:PaydayText.amount.copyWith(fontSize:PaydayType.body,color:tone??ink)),onTap:onTap),
   if(divider)Divider(height:1,thickness:1,color:line)]);

 // Home V2.2 presentation helpers — finance data remains sourced from SQLite.
 @override Widget build(BuildContext context){
  if(settingsOpen||alertsOpen)WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)settingsRefresh.value++;});
  return buildScreen(context);
 }
 Widget buildScreen(BuildContext context)=>welcome?welcomeFlow():LayoutBuilder(builder:(context,constraints)=>PopScope<Object?>(
  // Back from a small tab returns to the first one before leaving the page.
  canPop:(subTab[page]??0)==0,
  onPopInvokedWithResult:(didPop,result){
   if(!didPop&&mounted&&(subTab[page]??0)!=0)setState(()=>subTab[page]=0);
  },child:Scaffold(
  key:scaffoldKey,
  appBar:AppBar(automaticallyImplyLeading:false,toolbarHeight:76,titleSpacing:16,
   // Home carries the brand; each tab shows its own name, as on the design canvas.
   title:page==0?FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:const PaydayBrand(compact:true))
    :LText(const ['','Records','Budgets','Money'][page],key:ValueKey('page-title-$page'),
     style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:26,color:ink)),centerTitle:false,
   // Notifications, then Settings; the tools that were under More now live in the small tabs.
   actions:[alertsButton(),SizedBox(width:8),Padding(padding:EdgeInsetsDirectional.only(end:12),child:IconButton(key:ValueKey('home-settings-button'),tooltip:tr(context,'Open settings'),onPressed:openSettingsDrawer,
     style:IconButton.styleFrom(backgroundColor:surface,side:BorderSide(color:line),fixedSize:Size(44,44)),icon:PaydayAppIcon(Icons.settings_outlined,size:22)))]),
  body:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
   if(snap.hasError) {
     return Center(child:Padding(padding:EdgeInsets.all(PaydaySpace.xl),child:Column(mainAxisSize:MainAxisSize.min,children:[
    PaydayAppIcon(Icons.error_outline,color:danger,size:36),SizedBox(height:PaydaySpace.md),
    LText('Your records could not be opened. Nothing was changed.',textAlign:TextAlign.center),
    SizedBox(height:PaydaySpace.lg),FilledButton(onPressed:refresh,child:LText('Try again')),
   ])));
   }
   // Blank while records load (encrypted open), so no spinner flashes before Home.
   if(!snap.hasData)return const SizedBox.shrink();
   final d=snap.data!;
   currentWallets=WalletSetup.decode(Ledger(d).setting(walletSetupKey));
   final tab=subTab[page]??0;
   Widget screen;
   switch(page){
    case 1:screen=[records,calendarView,reportsView,monthlyReview][tab](d);break;
    case 2:screen=[budgets,moreBills,moreRecurring][tab](d);break;
    case 3:screen=[savings,moreReserves,moreKridi,moreDaret,moreWallets][tab](d);break;
    default:screen=home(d);
   }
   // The month switcher shows where the content depends on the month; on Year it steps by year.
   final showMonth=page==1||page==2&&tab!=2;
   return SafeArea(child:ListView(key:ValueKey('page-$page-tab-$tab'),padding:EdgeInsetsDirectional.fromSTEB(16,4,16,100),children:[
    if(page!=0)subTabs(),if(showMonth)...[navMonth(year:page==1&&tab==2&&reportYear),SizedBox(height:12)],screen]));
  }),
  // Floating navigation bar: the selected tab is marked by a tinted pill.
  bottomNavigationBar:SafeArea(top:false,child:Padding(padding:EdgeInsetsDirectional.fromSTEB(12,0,12,10),child:Container(
   padding:EdgeInsets.all(6),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(PaydayRadius.hero),border:Border.all(color:line)),
   child:Row(children:[
    bottomItem('Home',Icons.space_dashboard_outlined,0),
    bottomItem('Records',Icons.receipt_long_outlined,1),
    Expanded(child:Align(heightFactor:1,child:Transform.translate(offset:Offset(0,-12),child:Semantics(button:true,label:tr(context,'Add transaction'),child:
     // Solid ring in the page colour separates the button from the bar; no glow or shadow.
     Container(width:56,height:56,decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(PaydayRadius.xl)),
      padding:EdgeInsets.all(4),child:PaydayAddButton(onPressed:()=>transactionForm(null))))))),
    bottomItem('Budgets',Icons.pie_chart_outline,2),bottomItem('Money',Icons.savings_outlined,3),
   ])))),
 )));

}






















