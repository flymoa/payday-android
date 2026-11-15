import 'localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'brand.dart';
import 'app_icon.dart';

/// Android owns credentials and biometric matching; PAYDAY never receives them.
Future<bool> authenticateDevice(String reason)async{
 try{
  return await LocalAuthentication().authenticate(localizedReason:reason,
   biometricOnly:false,persistAcrossBackgrounding:false);
 }on LocalAuthException catch(e){
  switch(e.code){
   case LocalAuthExceptionCode.userCanceled:
   case LocalAuthExceptionCode.systemCanceled:
   case LocalAuthExceptionCode.timeout:return false;
   case LocalAuthExceptionCode.noCredentialsSet:
    throw const AppLockProblem('Set a screen lock in Android Settings, then try again.');
   case LocalAuthExceptionCode.temporaryLockout:
   case LocalAuthExceptionCode.biometricLockout:
    throw const AppLockProblem('Authentication is temporarily locked. Use your device PIN if offered, or try again later.');
   default:throw const AppLockProblem('Device authentication is unavailable. Check your phone’s screen lock and try again.');
  }
 }
}
class AppLockProblem implements Exception{
 const AppLockProblem(this.message);
 final String message;
 @override String toString()=>message;
}
Future<void> setScreenPrivacy(bool enabled)=>const MethodChannel('ma.payday/privacy')
 .invokeMethod<void>('setPrivacy',{'enabled':enabled});

class AppLockController extends ChangeNotifier with WidgetsBindingObserver{
 AppLockController({bool enabled=false,Future<bool> Function(String)? authenticate,
  Future<void> Function(bool)? privacyWriter}):_enabled=enabled,_locked=enabled,
  _authenticate=authenticate??authenticateDevice,_privacyWriter=privacyWriter??setScreenPrivacy{
  WidgetsBinding.instance.addObserver(this);
 }
 final Future<bool> Function(String) _authenticate;
 final Future<void> Function(bool) _privacyWriter;
 bool _enabled,_locked,_busy=false,_foreground=true,_disposed=false;
 String language='en';
 String? error;
 bool get enabled=>_enabled;
 bool get locked=>_locked;
 bool get busy=>_busy;
 bool get covered=>_enabled&&(_locked||!_foreground);
 void _changed(){if(!_disposed)notifyListeners();}
 Future<void> configurePrivacy(bool enabled)=>_privacyWriter(enabled);
 Future<void> initializePrivacy()async{
  if(!_enabled)return;
  try{await configurePrivacy(true);}catch(_){
   error='Screen privacy could not be enabled. Try reopening Payday.';_changed();
  }
 }
 // Only call after successful device authentication and durable preference save.
 void setEnabled(bool value){
  if(_disposed)return;
  _enabled=value;_locked=value&&!_foreground;error=null;_changed();
 }
 void lockNow(){if(_enabled){_locked=true;_changed();}}
 Future<bool> authorize(String reason,{bool requirePrivacy=false})async{
  if(_busy||_disposed)return false;
  _busy=true;error=null;_changed();
  try{
   if(requirePrivacy)await configurePrivacy(true);
   final result=await _authenticate(translateMessage(reason,language));
   if(!result)error='Authentication canceled. Please try again.';
   return result&&!_disposed;
  }on AppLockProblem catch(e){error=e.message;return false;}
  catch(_){error='Could not authenticate. Please try again.';return false;}
  finally{_busy=false;_changed();}
 }
 Future<void> unlock()async{
  if(!_enabled||!_locked||_busy)return;
  if(await authorize('Unlock Payday to view your finances',requirePrivacy:true)){
   if(!_disposed&&_enabled){_locked=false;error=null;_changed();}
  }
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){
  _foreground=state==AppLifecycleState.resumed;
  // A native authentication dialog may itself pause the activity. Its result,
  // including device-PIN fallback, controls unlocking; never start a second prompt.
  if(!_foreground&&_enabled&&!_busy)_locked=true;
  _changed();
 }
 @override Future<bool> didPopRoute()async=>covered;
 @override void dispose(){_disposed=true;WidgetsBinding.instance.removeObserver(this);super.dispose();}
}

/// Register the lock policy on every route, including dialogs and predictive Back.
class AppLockRouteGuard extends NavigatorObserver{
 AppLockRouteGuard(this.controller){controller.addListener(_update);}
 final AppLockController controller;
 final _entries=<ModalRoute<dynamic>,_LockPopEntry>{};
 void _track(Route<dynamic> route){
  if(route is! ModalRoute<dynamic>||_entries.containsKey(route))return;
  final entry=_LockPopEntry(!controller.covered);
  _entries[route]=entry;route.registerPopEntry(entry);
 }
 void _remove(Route<dynamic> route){
  if(route is! ModalRoute<dynamic>)return;
  final entry=_entries.remove(route);
  if(entry!=null){route.unregisterPopEntry(entry);entry.canPopNotifier.dispose();}
 }
 void _update(){for(final entry in _entries.values){entry.canPopNotifier.value=!controller.covered;}}
 @override void didPush(Route<dynamic> route,Route<dynamic>? previousRoute){_track(route);}
 @override void didPop(Route<dynamic> route,Route<dynamic>? previousRoute){_remove(route);}
 @override void didRemove(Route<dynamic> route,Route<dynamic>? previousRoute){_remove(route);}
 @override void didReplace({Route<dynamic>? newRoute,Route<dynamic>? oldRoute}){
  if(oldRoute!=null)_remove(oldRoute);if(newRoute!=null)_track(newRoute);
 }
 void dispose(){
  controller.removeListener(_update);
  for(final route in _entries.keys.toList()){_remove(route);}
 }
}
class _LockPopEntry extends PopEntry<Object?>{
 _LockPopEntry(bool canPop):canPopNotifier=ValueNotifier(canPop);
 @override final ValueNotifier<bool> canPopNotifier;
}

/// Above the Navigator: dialogs, forms, and every tab are hidden together.
/// Offstage preserves unsaved forms but removes their focus and semantics.
class PaydayLockGate extends StatelessWidget{
 const PaydayLockGate({super.key,required this.controller,required this.child});
 final AppLockController controller;
 final Widget child;
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(context,_)=>Stack(
  fit:StackFit.expand,children:[
   Offstage(offstage:controller.covered,child:ExcludeFocus(excluding:controller.covered,
    child:TickerMode(enabled:!controller.covered,child:child))),
   if(controller.covered)Positioned.fill(child:Material(key:const ValueKey('payday-lock-screen'),
    color:Theme.of(context).scaffoldBackgroundColor,child:SafeArea(child:Center(child:SingleChildScrollView(
     padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:340),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
       const PaydayMark(size:64),const SizedBox(height:24),
       LText('Payday is locked',style:Theme.of(context).textTheme.headlineSmall,textAlign:TextAlign.center),
       const SizedBox(height:10),const LText('Use your phone’s fingerprint, face unlock, or screen lock to continue.',textAlign:TextAlign.center),
       const SizedBox(height:24),
       FilledButton.icon(onPressed:controller.busy?null:controller.unlock,
        icon:controller.busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const PaydayAppIcon(Icons.lock_open_outlined),
        label:LText(controller.busy?'Authenticating…':'Unlock')),
       if(controller.error!=null)Padding(padding:const EdgeInsets.only(top:16),
        child:LText(controller.error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      ]))))))),
  ]));
}

