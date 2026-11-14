import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/month_usage_bar.dart';

void main(){
 for(final brightness in Brightness.values){
  testWidgets('solid saffron marker remains visible from empty to full in ${brightness.name}',(tester)async{
   const saffron=Color(0xffF4A62A);
   for(final value in [0.0,.001,.25,.5,1.0]){
    await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
     home:Scaffold(body:SizedBox(width:280,child:MonthUsageBar(
      value:value,trackColor:Colors.grey,fillColor:Colors.white,markerColor:saffron)))));
    await tester.pumpAndSettle();
    final marker=find.byKey(const ValueKey('month-usage-marker'));
    expect(marker,findsOneWidget);
    expect(tester.widget<ColoredBox>(marker).color,saffron);
    expect(tester.getSize(marker).height,27);
    expect(tester.getSize(marker).width,greaterThan(5));
    final bar=tester.getRect(find.byType(MonthUsageBar));
    final markerRect=tester.getRect(marker);
    if(value==0)expect(markerRect.left,bar.left);
    if(value==1)expect(markerRect.right,closeTo(bar.right-3,.01));
    expect(tester.widget<MonthUsageBar>(find.byType(MonthUsageBar)).value,value);
    expect(tester.takeException(),isNull);
   }
  });
 }
}
