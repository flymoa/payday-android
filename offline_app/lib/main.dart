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
part 'screens/kridi_extras.dart';

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
  // Every role is set from tokens: no seed, so no generated purple tints anywhere.
  final scheme=paydayColorScheme(brightness);
  final background=dark?PaydayColors.darkBackground:kCream;
  final base=ThemeData(useMaterial3:true,colorScheme:scheme,fontFamily:'DMSans',fontFamilyFallback:const ['PlexArabic','sans-serif']);
  const ui=TextStyle(fontFamily:'DMSans',fontFamilyFallback:['PlexArabic','sans-serif']);
  return base.copyWith(
   textTheme:base.textTheme.copyWith(
    bodyLarge:base.textTheme.bodyLarge?.copyWith(fontSize:PaydayType.body),
    bodyMedium:base.textTheme.bodyMedium?.copyWith(fontSize:PaydayType.body),
    titleMedium:base.textTheme.titleMedium?.copyWith(fontSize:PaydayType.body),
    labelLarge:base.textTheme.labelLarge?.copyWith(fontSize:PaydayType.body),
    bodySmall:base.textTheme.bodySmall?.copyWith(fontSize:PaydayType.caption),
    titleLarge:base.textTheme.titleLarge?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:PaydayType.title),
    headlineSmall:base.textTheme.headlineSmall?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:PaydayType.title)),
   scaffoldBackgroundColor:background,
   appBarTheme:AppBarTheme(backgroundColor:background,
    foregroundColor:scheme.onSurface,centerTitle:false,surfaceTintColor:Colors.transparent,
    titleTextStyle:TextStyle(fontFamily:'Bricolage',fontFamilyFallback:const ['PlexArabic','sans-serif'],fontWeight:FontWeight.w800,fontSize:PaydayType.title,color:scheme.onSurface)),
   switchTheme:SwitchThemeData(
    thumbColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.disabled)?scheme.outlineVariant
     :s.contains(WidgetState.selected)?scheme.onPrimary:scheme.outline),
    trackColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)&&!s.contains(WidgetState.disabled)?scheme.primary:scheme.surfaceContainerHigh),
    trackOutlineColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?Colors.transparent:scheme.outline),
    trackOutlineWidth:const WidgetStatePropertyAll(1),
    thumbIcon:const WidgetStatePropertyAll(null)),
   datePickerTheme:DatePickerThemeData(backgroundColor:scheme.surface,surfaceTintColor:Colors.transparent,elevation:0,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg)),
    headerBackgroundColor:scheme.surface,headerForegroundColor:scheme.onSurface,
    headerHeadlineStyle:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:PaydayType.title,color:scheme.onSurface),
    headerHelpStyle:ui.copyWith(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:scheme.onSurfaceVariant),
    weekdayStyle:ui.copyWith(fontSize:PaydayType.caption,fontWeight:FontWeight.w700,color:scheme.onSurfaceVariant),
    dayStyle:ui.copyWith(fontSize:PaydayType.body,fontWeight:FontWeight.w600,fontFeatures:PaydayText.tabular),
    todayBorder:BorderSide(color:scheme.primary,width:1.5),
    todayForegroundColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?scheme.onPrimary:scheme.primary),
    dayBackgroundColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?scheme.primary:Colors.transparent),
    dayForegroundColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?scheme.onPrimary:s.contains(WidgetState.disabled)?scheme.outlineVariant:scheme.onSurface),
    dividerColor:scheme.outlineVariant,
    cancelButtonStyle:TextButton.styleFrom(foregroundColor:scheme.onSurface),
    confirmButtonStyle:TextButton.styleFrom(foregroundColor:scheme.primary,textStyle:ui.copyWith(fontWeight:FontWeight.w800))),
   progressIndicatorTheme:ProgressIndicatorThemeData(color:scheme.primary,linearTrackColor:scheme.surfaceContainerHigh,
    circularTrackColor:Colors.transparent,linearMinHeight:3),
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
    // Action in bright emerald: saffron stays on the add button and the badge.
    contentTextStyle:TextStyle(color:dark?PaydayColors.darkText:paydaySand,fontFamily:'DMSans',fontFamilyFallback:const ['PlexArabic','sans-serif']),actionTextColor:PaydayColors.darkPrimary),
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
 /// Near-limit bars: saffronText in light (5.5:1 on sand), never raw saffron or #D2A15A.
 Color get warn=>isDark?PaydayColors.darkStatusNear:PaydayColors.saffronText;
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
 Set<String> alertsHidden=<String>{}; // read before this opening, so not listed again
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
 static const subTabLabels=<int,List<String>>{1:['List','Calendar','Reports','Review'],2:['Categories','Bills','Recurring'],3:['Goals','Reserves','Owed & Daret','Wallets']};
 DateTime? calendarDay; // day picked in Records · Calendar
 bool reportYear=false;
 int? reportSlice; // slice tapped in the Reports ring
 /// Opens a tool in the tab it now lives in (0 bills, 1 reserves, 2 year, 4 review, 5 recurring, 6 Cash & Bank).
 void openTool(int tool){
  const at={0:[2,1],1:[3,1],2:[1,2],4:[1,3],5:[2,2],6:[3,3],7:[3,2],8:[3,2]};
  final t=at[tool]!;
  setState((){page=t[0];subTab[t[0]]=t[1];if(tool==2)reportYear=true;});
 }
 Widget subTabs(){
  final labels=subTabLabels[page]!,current=subTab[page]??0;
  final style=TextStyle(fontWeight:FontWeight.w700,fontSize:PaydayType.body);
  // Plain text tabs, start-aligned at their natural width: no track, no pill.
  // The selected one carries a 2px emerald underline; a 1px hairline anchors the row.
  // Each tab is 48dp tall to the thumb; the underline sits at 40dp so it reads tight.
  // Labels are never cut or shrunk: the gaps tighten first (12 down to 6), and only
  // when the labels still do not fit does the row scroll sideways.
  final measureStyle=DefaultTextStyle.of(context).style.merge(Theme.of(context).textTheme.bodyMedium).merge(style);
  return Padding(padding:EdgeInsets.only(bottom:PaydaySpace.md),child:DecoratedBox(
   decoration:BoxDecoration(border:Border(bottom:BorderSide(color:line))),
   child:LayoutBuilder(builder:(context,box){
    final scaler=MediaQuery.textScalerOf(context);
    final text=[for(final l in labels)(TextPainter(text:TextSpan(text:tr(context,l),style:measureStyle),maxLines:1,
     textDirection:Directionality.of(context),textScaler:scaler)..layout()).width.ceilToDouble()+1];
    final words=text.fold<double>(0,(a,b)=>a+b);
    // Space for 2n-1 gaps plus the small lead-in on the first tab.
    final room=(box.maxWidth-words-PaydaySpace.xs)/(labels.length*2-1);
    final gap=room.clamp(PaydaySpace.xs+2,PaydaySpace.md).toDouble();
    final row=Row(mainAxisSize:MainAxisSize.min,children:[for(var i=0;i<labels.length;i++)Semantics(selected:i==current,button:true,
     child:InkWell(key:ValueKey('subtab-$page-$i'),onTap:()=>setState(()=>subTab[page]=i),
      child:ConstrainedBox(constraints:const BoxConstraints(minHeight:PaydayControl.target),child:Padding(
       padding:EdgeInsetsDirectional.only(start:i==0?PaydaySpace.xs:gap,end:i==labels.length-1?0:gap),
       child:SizedBox(width:text[i],child:Column(mainAxisAlignment:MainAxisAlignment.end,mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        LText(labels[i],maxLines:1,softWrap:false,style:style.copyWith(color:i==current?ink:muted)),
        const SizedBox(height:PaydaySpace.sm+2),
        AnimatedContainer(duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:180),curve:Curves.easeOut,
         height:2,color:i==current?jade:Colors.transparent),
       ]))))))]);
    return Align(alignment:AlignmentDirectional.centerStart,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:row));
   })));
 }
 final purchase=TextEditingController(text:'200');
 @override void initState(){
  super.initState();WidgetsBinding.instance.addObserver(this);
  if(widget.welcomeOnFirstRun&&widget.initialData==null)unawaited(data.then((d){if(mounted&&firstRun(d))setState(()=>welcome=true);}).catchError((Object _){}));
  unawaited(runRecurring());
  unawaited(updateHomeWidget());
  unawaited(syncBillReminders());
  WidgetsBinding.instance.addPostFrameCallback((_)=>unawaited(openWidgetAction()));
  unawaited(runLoanAutopay());
  if(widget.welcomeOnFirstRun)WidgetsBinding.instance.addPostFrameCallback((_)=>unawaited(maybeShowInstalmentPopup()));
  unawaited(syncReserveReminders());
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){
  if(state==AppLifecycleState.resumed){
   unawaited(runRecurring());
   unawaited(openWidgetAction());
   unawaited(runLoanAutopay());
   if(widget.welcomeOnFirstRun)unawaited(maybeShowInstalmentPopup());
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
 /// Amounts in a list row: "50 DH" when the cents are ,00, else "63,50 DH".
 String listMoney(int cents)=>displayMoney(cents,currency,language,style:MoneyStyle.list);
 /// Totals above a list and hero sub-figures: whole units, "12 500 DH".
 String summaryMoney(int cents)=>displayMoney(cents,currency,language,style:MoneyStyle.summary);
 Widget iconTile(IconData icon,{Color? color,Color? background,double size=40})=>Container(width:size,height:size,
  decoration:BoxDecoration(color:background??(isDark?PaydayColors.darkIconDisc:PaydayColors.mintTint),borderRadius:BorderRadius.circular(PaydayRadius.lg)),
  child:Center(child:PaydayAppIcon(icon,size:size*.5,color:color)));
 /// A content card: lifted surface, 1px border, radius 14, no shadow. Kept for
 /// the two dense money lists (Recent, a Records day) and the add-sheet split box.
 Widget contentCard(Widget child,{Key? key})=>Material(key:key,
  color:isDark?PaydayCard.surfaceDark:PaydayCard.surfaceLight,clipBehavior:Clip.antiAlias,
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.card),
   side:BorderSide(color:isDark?PaydayCard.borderDark:PaydayCard.borderLight)),
  child:child);
 /// Rows of one list, directly on the page with 1px hairlines between them.
 /// [card]: the group sits in one bordered card instead (Recent and Records only).
 Widget groupedRows(List<Widget> rows,{bool card=false}){
  final hairline=Divider(height:1,thickness:1,indent:card?PaydaySpace.md:0,endIndent:card?PaydaySpace.md:0,color:line);
  final column=Column(children:[for(var i=0;i<rows.length;i++)...[if(i>0)hairline,rows[i]]]);
  return card?contentCard(column):PaydayRowInset(horizontal:PaydaySpace.xs,child:column);
 }
 Widget rowTitle(String text,{bool raw=false,bool category=false}){
  final style=PaydayText.rowTitle.copyWith(color:ink);
  return raw?Text(text,maxLines:1,overflow:TextOverflow.ellipsis,style:style):LText(text,category:category,maxLines:1,overflow:TextOverflow.ellipsis,style:style);
 }
 /// Icon, title with a line under it, an amount with an optional status, and an optional bar.
 Widget listRow({Key? key,required Widget leading,required Widget title,String? subtitle,Color? subtitleColor,String? amount,Color? amountColor,
  String? status,Color? statusColor,FontWeight? statusWeight,double? progress,Color? progressColor,Color? trackColor,VoidCallback? onTap,Widget? trailing})=>
  Builder(key:key,builder:(context)=>InkWell(onTap:onTap,child:Padding(padding:EdgeInsets.symmetric(horizontal:PaydayRowInset.of(context),vertical:PaydaySpace.md),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LayoutBuilder(builder:(context,box)=>Row(children:[leading,SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title,
     if(subtitle!=null)Padding(padding:EdgeInsets.only(top:2),child:LText(subtitle,maxLines:2,
      style:TextStyle(fontSize:PaydayType.caption,color:subtitleColor??muted,fontWeight:subtitleColor==null?FontWeight.w400:FontWeight.w700)))])),
    if(amount!=null||status!=null)...[SizedBox(width:8),ConstrainedBox(constraints:BoxConstraints(maxWidth:box.maxWidth*.45),
     child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
      if(amount!=null)FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
       child:LText(amount,style:PaydayText.amount.copyWith(fontSize:PaydayType.body,color:amountColor??ink))),
      if(status!=null)LText(status,textAlign:TextAlign.end,maxLines:2,style:TextStyle(fontSize:PaydayType.caption,fontWeight:statusWeight??FontWeight.w700,color:statusColor??muted)),
     ]))],
    ?trailing,
   ])),
   if(progress!=null)...[SizedBox(height:PaydaySpace.sm),PaydayProgress(value:progress.clamp(0,1).toDouble(),color:progressColor,trackColor:trackColor)],
  ]))));
 /// Full-width secondary action at the end of a list ("Add a bill").
 Widget listAction(String label,IconData icon,VoidCallback onPressed,{Key? key})=>Padding(padding:EdgeInsets.only(top:12),
  child:SizedBox(width:double.infinity,child:OutlinedButton.icon(key:key,onPressed:onPressed,
   style:OutlinedButton.styleFrom(minimumSize:Size.fromHeight(52)),
   icon:PaydayAppIcon(icon,size:20),label:LText(label,style:TextStyle(fontWeight:FontWeight.w700)))));
 /// One summary line in a panel ("Still to pay … 728.00 MAD"), with optional content below.
 Widget summaryLine(String label,String value,{Widget? below,Widget? trailing,Key? key})=>Padding(key:key,
  padding:EdgeInsetsDirectional.fromSTEB(PaydaySpace.xs,PaydaySpace.sm,PaydaySpace.xs,PaydaySpace.lg),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   // One line always: a long French label shrinks a little instead of wrapping under the figure.
   Row(children:[Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
    child:LText(label,maxLines:1,softWrap:false,style:TextStyle(color:muted,fontWeight:FontWeight.w700)))),SizedBox(width:8),
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
  appBar:AppBar(automaticallyImplyLeading:false,toolbarHeight:64,titleSpacing:20,
   // Home carries the brand; each tab shows its own name, as on the design canvas.
   title:page==0?FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:const PaydayBrand(compact:true))
    :LText(const ['','Records','Budgets','Money'][page],key:ValueKey('page-title-$page'),
     style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w800,fontSize:PaydayType.title,color:ink)),centerTitle:false,
   // Notifications, then Settings. Quiet chrome: bare glyphs, 48dp hit areas, no discs.
   actions:[alertsButton(),Padding(padding:EdgeInsetsDirectional.only(end:PaydaySpace.sm),child:IconButton(key:ValueKey('home-settings-button'),tooltip:tr(context,'Open settings'),onPressed:openSettingsDrawer,
     style:IconButton.styleFrom(minimumSize:const Size(PaydayControl.target,PaydayControl.target),tapTargetSize:MaterialTapTargetSize.padded),
     icon:PaydayAppIcon(Icons.settings_outlined,size:22,color:ink)))]),
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
    case 3:screen=[savings,moreReserves,owedAndDaret,moreWallets][tab](d);break;
    default:screen=home(d);
   }
   // The month switcher shows where the content depends on the month; on Year it steps by year.
   final showMonth=page==1||page==2&&tab!=2;
   // Under the title: the month as a quiet subtitle, then the text tabs, then content.
   return SafeArea(child:ListView(key:ValueKey('page-$page-tab-$tab'),padding:EdgeInsetsDirectional.fromSTEB(16,0,16,100),children:[
    if(showMonth)Transform.translate(offset:const Offset(0,-PaydaySpace.sm),child:Align(alignment:AlignmentDirectional.centerStart,heightFactor:.75,child:navMonth(year:page==1&&tab==2&&reportYear))),
    if(page!=0)subTabs(),screen]));
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






















