import 'design_tokens.dart';
import 'ui_kit.dart';
import 'localization.dart';
import 'app_language.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bill_reminders.dart';
import 'reserve_reminders.dart';
import 'safe_to_spend_row.dart';
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
import 'home_widget.dart';
import 'db_encryption.dart';
import 'dart:async';
import 'dart:math' show max;
import 'app_lock.dart';
import 'app_preferences.dart';
import 'month_usage_bar.dart';
import 'add_button.dart';
import 'transaction_categories.dart';
import 'app_icon.dart';
import 'category_icon.dart';
import 'dart:io';
import 'dart:convert';
import 'brand.dart';
import 'opening.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  if(snapshot.hasData)return PaydayLocal(store:store,initialPreferences:snapshot.data!);
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
  this.initialPreferences=const AppPreferences(),this.preferencesWriter,this.appLockController});
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
    final allowed=await appLock.authorize(next.appLock?'Enable PAYDAY app lock':'Turn off PAYDAY app lock');
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
  final base=ThemeData(useMaterial3:true,colorScheme:scheme,fontFamily:'DMSans',fontFamilyFallback:const ['Noto Sans Arabic','sans-serif']);
  return base.copyWith(
   textTheme:base.textTheme.copyWith(
    titleLarge:base.textTheme.titleLarge?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800),
    headlineSmall:base.textTheme.headlineSmall?.copyWith(fontFamily:'Bricolage',fontWeight:FontWeight.w800)),
   scaffoldBackgroundColor:background,
   appBarTheme:AppBarTheme(backgroundColor:background,
    foregroundColor:scheme.onSurface,centerTitle:true,surfaceTintColor:Colors.transparent),
   bottomSheetTheme:BottomSheetThemeData(backgroundColor:scheme.surface,surfaceTintColor:Colors.transparent,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(PaydayRadius.dialog)))),
   dialogTheme:DialogThemeData(backgroundColor:scheme.surface,surfaceTintColor:Colors.transparent),
   cardTheme:CardThemeData(elevation:0,color:scheme.surface,surfaceTintColor:Colors.transparent,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.card),side:BorderSide(color:scheme.outlineVariant))),
   inputDecorationTheme:InputDecorationTheme(filled:true,
    fillColor:scheme.surfaceContainerLow,
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md)),
    enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md),borderSide:BorderSide(color:scheme.outlineVariant)),
    focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(PaydayRadius.md),borderSide:BorderSide(color:scheme.primary,width:2))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
    minimumSize:const Size(48,52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg)),textStyle:TextStyle(fontWeight:FontWeight.w800,fontFamily:'DMSans'))),
   outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(
    side:BorderSide(color:scheme.outlineVariant),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg)))),
   listTileTheme:ListTileThemeData(iconColor:scheme.primary),
   dividerTheme:DividerThemeData(color:scheme.outlineVariant,thickness:1),
   snackBarTheme:SnackBarThemeData(backgroundColor:dark?PaydayColors.darkSurfaceHigh:kInk,
    contentTextStyle:TextStyle(color:dark?PaydayColors.darkText:paydaySand,fontFamily:'DMSans'),actionTextColor:paydaySaffron),
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
  home:FinanceScreen(store:localStore,initialData:widget.initialData,preferences:preferences,
   onPreferencesChanged:savePreferences,onToggleTheme:(dark){
    savePreferences(preferences.copyWith(appearance:dark?ThemeMode.dark:ThemeMode.light));
   }));
}
class FinanceScreen extends StatefulWidget {const FinanceScreen({super.key,this.onToggleTheme,this.initialData,this.store,this.backupShare,this.backupCipher,this.backupNotifications,this.billReminders,this.reserveReminders,this.restoreSnapshot,
 this.preferences=const AppPreferences(),this.onPreferencesChanged});final ValueChanged<bool>? onToggleTheme;
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
 Color get warn=>isDark?PaydayColors.darkStatusNear:PaydayColors.statusNear;
 Color get amber=>isDark?PaydayColors.darkStatusNear:PaydayColors.amber;
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
 String currencyMessage(String message)=>translateMessage(message.replaceAll(' MAD',' $currency'),language);
 void openSettingsDrawer(){
  scaffoldKey.currentState?.openDrawer();
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
 int? moreSection; // null means More menu; index selects the opened section.
 final purchase=TextEditingController(text:'200');
 @override void initState(){
  super.initState();WidgetsBinding.instance.addObserver(this);
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
   setState((){page=0;moreSection=null;});
   await transactionForm(null);
  }
 }
 Future<void> runRecurring()async{
  if(widget.initialData!=null)return; // test screens with fixed data
  try{
   final created=await store.applyRecurring(DateTime.now());
   if(created>0&&mounted){refresh();inputError('$created recurring entries added.');}
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
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);purchase.dispose();search.dispose();store.close();super.dispose();}
 void refresh(){
  if(!mounted)return;
  final next=store.snapshot();
  setState((){data=next;});
  unawaited(syncBillReminders());
  unawaited(syncReserveReminders());
  unawaited(updateHomeWidget());
 }
 String get month=>monthKey(selected);
 void shift(int n){setState(()=>selected=DateTime(selected.year,selected.month+n));}
 Future<bool> execute(Future<void> Function() fn)async{
  if(writing)return false;
  writing=true;
  try{await fn();refresh();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:LText('Saved on this phone.')));return true;}
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
 Widget header(String title,{String? subtitle,Widget? action})=>Padding(padding:EdgeInsetsDirectional.fromSTEB(4,12,4,10),
  child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   LText(title,style:TextStyle(fontFamily:'Bricolage',fontSize:24,fontWeight:FontWeight.w800,color:ink)),
   if(subtitle!=null)Padding(padding:EdgeInsets.only(top:4),child:LText(subtitle,style:TextStyle(color:muted)))
  ])),if(action!=null)action]));
 Widget tile(String title,String subtitle,String trailing,{VoidCallback? onTap,IconData icon=Icons.circle_outlined,Color? tone,Widget? leading,bool rawTitle=false,bool categoryTitle=false})=>
  Card(child:ListTile(contentPadding:EdgeInsets.symmetric(horizontal:16,vertical:5),
   leading:leading??CircleAvatar(backgroundColor:(tone??jade).withValues(alpha:.10),child:PaydayAppIcon(icon,color:tone??jade,size:20)),
   title:rawTitle?Text(title,style:TextStyle(fontWeight:FontWeight.w700)):LText(title,category:categoryTitle,style:TextStyle(fontWeight:FontWeight.w700)),
   subtitle:LText(subtitle,maxLines:2,overflow:TextOverflow.ellipsis),
   trailing:LText(trailing,style:TextStyle(fontWeight:FontWeight.w800,color:tone??ink)),onTap:onTap));

 // Home V2.2 presentation helpers — finance data remains sourced from SQLite.
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints)=>PopScope<Object?>(
  canPop:page!=4||moreSection==null,
  onPopInvokedWithResult:(didPop,result){
   if(!didPop&&mounted&&page==4&&moreSection!=null){
    setState(()=>moreSection=null);
   }
  },child:Scaffold(
  key:scaffoldKey,
  drawerEnableOpenDragGesture:false,
  drawer:page==0?Drawer(width:(constraints.maxWidth*.86).clamp(0,360).toDouble(),
   backgroundColor:cream,child:SafeArea(child:Column(children:[
    Padding(padding:EdgeInsetsDirectional.fromSTEB(16,12,4,8),child:Row(children:[
     const Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:PaydayBrand(compact:true))),
     IconButton(tooltip:tr(context,'Close settings'),onPressed:()=>scaffoldKey.currentState?.closeDrawer(),icon:PaydayAppIcon(Icons.close)),
    ])),
    Expanded(child:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
     if(snap.hasError)return Center(child:LText('Could not load settings.'));
     if(!snap.hasData)return Center(child:CircularProgressIndicator());
     return ListView(key:ValueKey('settings-drawer-list'),padding:EdgeInsetsDirectional.fromSTEB(12,0,12,24),
      children:[appSettings(snap.data!)]);
    })),
   ]))):null,
  appBar:AppBar(automaticallyImplyLeading:false,toolbarHeight:76,titleSpacing:16,
   title:page==0?Row(children:[const PaydayMark(size:42),SizedBox(width:10),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     LText(uiDay(DateTime.now()),style:TextStyle(fontSize:12,color:muted)),
     FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,
      child:LText(paydaySlogan,maxLines:1,softWrap:false,
       style:TextStyle(fontFamily:'Bricolage',fontWeight:FontWeight.w700,fontSize:14))),
    ]))]):FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:const PaydayBrand(compact:true)),centerTitle:false,
   actions:[if(page==0)IconButton(key:ValueKey('home-settings-button'),tooltip:tr(context,'Open settings'),onPressed:openSettingsDrawer,icon:PaydayAppIcon(Icons.settings_outlined)),
    Padding(padding:EdgeInsetsDirectional.only(end:8),child:TextButton(
     style:TextButton.styleFrom(backgroundColor:page==4?jade.withValues(alpha:.14):surface,foregroundColor:ink,
      shape:StadiumBorder(side:BorderSide(color:page==4?jade:line))),
     onPressed:()=>setState((){page=4;moreSection=null;}),child:LText('More',style:TextStyle(fontWeight:FontWeight.w700))))]),
  body:FutureBuilder<Map<String,List<RowData>>>(future:data,builder:(context,snap){
   if(snap.hasError)return Center(child:Padding(padding:EdgeInsets.all(PaydaySpace.xl),child:Column(mainAxisSize:MainAxisSize.min,children:[
    PaydayAppIcon(Icons.error_outline,color:danger,size:36),SizedBox(height:PaydaySpace.md),
    LText('Your records could not be opened. Nothing was changed.',textAlign:TextAlign.center),
    SizedBox(height:PaydaySpace.lg),FilledButton(onPressed:refresh,child:LText('Try again')),
   ])));
   // Blank while records load (encrypted open), so no spinner flashes before Home.
   if(!snap.hasData)return const SizedBox.shrink();
   final d=snap.data!;
   Widget screen;
   switch(page){
    case 0:screen=home(d);break;
    case 1:screen=records(d);break;
    case 2:screen=budgets(d);break;
    case 3:screen=savings(d);break;
    default:screen=more(d);
   }
   return SafeArea(child:ListView(key:ValueKey('page-$page-section-$moreSection'),padding:EdgeInsetsDirectional.fromSTEB(16,4,16,100),children:[if(page!=0 && (page!=4 || moreSection==0 || moreSection==2)) navMonth(),screen]));
  }),
  // Floating navigation bar: the selected tab is marked by a tinted pill.
  bottomNavigationBar:SafeArea(top:false,child:Padding(padding:EdgeInsetsDirectional.fromSTEB(12,0,12,10),child:Container(
   padding:EdgeInsets.all(6),
   decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(PaydayRadius.hero),border:Border.all(color:line),
    boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:isDark ? .40 : .08),blurRadius:18,offset:Offset(0,6))]),
   child:Row(children:[
    bottomItem('Home',Icons.space_dashboard_outlined,0),
    bottomItem('Budgets',Icons.pie_chart_outline,2),
    Expanded(child:Align(heightFactor:1,child:Transform.translate(offset:Offset(0,-12),child:Semantics(button:true,label:tr(context,'Add transaction'),child:
     Container(width:56,height:56,decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(PaydayRadius.xl),
      boxShadow:[BoxShadow(color:paydaySaffron.withValues(alpha:isDark ? .22 : .28),blurRadius:16,offset:Offset(0,6))]),
      padding:EdgeInsets.all(4),child:PaydayAddButton(onPressed:()=>transactionForm(null))))))),
    bottomItem('Savings',Icons.savings_outlined,3),bottomItem('Records',Icons.receipt_long_outlined,1),
   ])))),
 )));

}






















