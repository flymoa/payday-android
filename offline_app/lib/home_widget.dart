import 'dart:io';
import 'package:flutter/services.dart';

/// Device-local opt-in: show this month's safe-to-spend amount on the home screen.
const homeWidgetAmountKey='home_widget_show_amount';

class HomeWidgetText {
 const HomeWidgetText(this.title,this.body);
 final String title,body;
}

/// The amount is shown only when the user opted in and App lock is off,
/// because a home-screen widget is visible without unlocking Payday.
HomeWidgetText homeWidgetText({required bool showAmount,required bool appLock,required String safeToSpend,
 required String Function(String) translate}){
 if(!showAmount||appLock)return HomeWidgetText('Payday',translate('Tap to open'));
 return HomeWidgetText(translate('Safe to spend'),safeToSpend);
}

Future<void> pushHomeWidget(HomeWidgetText text)async{
 if(!Platform.isAndroid)return;
 try{
  await const MethodChannel('ma.payday/widget').invokeMethod<void>('update',{'title':text.title,'body':text.body});
 }on MissingPluginException{/* widget support not built in */}
 on PlatformException{/* never block finance screens on the widget */}
}
