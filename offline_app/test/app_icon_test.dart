import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_icon.dart';
void main(){
 final symbols=[Icons.account_balance_wallet_outlined,Icons.add,Icons.arrow_back,Icons.arrow_downward,Icons.arrow_upward,Icons.bar_chart_rounded,Icons.beach_access_outlined,Icons.calendar_today_outlined,Icons.call_made,Icons.call_received,Icons.check_circle_outline,Icons.chevron_left,Icons.chevron_right,Icons.circle_outlined,Icons.close,Icons.copy_outlined,Icons.dark_mode_outlined,Icons.edit_calendar_outlined,Icons.edit_outlined,Icons.error_outline,Icons.event_outlined,Icons.fact_check_outlined,Icons.file_open,Icons.grid_view,Icons.grid_view_outlined,Icons.history,Icons.info_outline,Icons.ios_share,Icons.light_mode_outlined,Icons.payments_outlined,Icons.pie_chart_outline,Icons.receipt_long,Icons.receipt_long_outlined,Icons.remove,Icons.repeat,Icons.savings,Icons.savings_outlined,Icons.search,Icons.settings_outlined,Icons.space_dashboard,Icons.space_dashboard_outlined,Icons.today,Icons.trending_up,Icons.tune,Icons.tune_outlined,Icons.undo];
 for(final brightness in Brightness.values){
  testWidgets('all PAYDAY control vectors paint in ${brightness.name}',(tester)async{
   await tester.binding.setSurfaceSize(const Size(320,800));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:Scaffold(
    body:SingleChildScrollView(child:Wrap(children:[
     for(final symbol in symbols)Padding(padding:const EdgeInsets.all(8),child:PaydayAppIcon(symbol)),
     const IconTheme(data:IconThemeData(opacity:.4),child:PaydayAppIcon(Icons.add)),
    ])))));
   await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   expect(find.byType(PaydayAppIcon),findsNWidgets(symbols.length+1));
  });
 }
}
