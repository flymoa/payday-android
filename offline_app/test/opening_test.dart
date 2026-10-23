import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/opening.dart';
import 'package:payday_local/brand.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.onCreate,required this.onTap});
  final VoidCallback onCreate,onTap;
  @override State<_Probe> createState()=>_ProbeState();
}
class _ProbeState extends State<_Probe> {
  @override void initState(){super.initState();widget.onCreate();}
  @override Widget build(BuildContext context)=>Center(child:TextButton(
    onPressed:widget.onTap,child:const Text('Home action')));
}

void main(){
  const overlay=ValueKey('payday-opening-overlay');
  for(final brightness in Brightness.values){
    testWidgets('1.6-second opening preserves Home and enables it after completion in ${brightness.name}',(tester)async{
      var creates=0,taps=0;
      await tester.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
        home:PaydayOpening(child:Scaffold(body:_Probe(onCreate:()=>creates++,onTap:()=>taps++)))));
      expect(find.text(paydaySlogan),findsOneWidget);
      expect(find.byKey(overlay),findsOneWidget);
      await tester.pump(const Duration(milliseconds:1200));
      expect(find.byKey(overlay),findsOneWidget);
      expect(creates,1);
      await tester.pump(const Duration(milliseconds:450));
      await tester.pumpAndSettle();
      expect(find.byKey(overlay),findsNothing);
      expect(creates,1,reason:'Finishing the intro must not remount Home');
      await tester.tap(find.text('Home action'));
      expect(taps,1);
      await tester.pump(const Duration(seconds:3));
      expect(find.byKey(overlay),findsNothing);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('P and yellow marker paint throughout the short sequence on a narrow screen',(tester)async{
    await tester.binding.setSurfaceSize(const Size(320,640));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home:PaydayOpening(child:Scaffold(body:Text('Ready')))));
    for(final milliseconds in [160,400,400,400]){
      await tester.pump(Duration(milliseconds:milliseconds));
      final paint=tester.widget<CustomPaint>(find.byKey(const ValueKey('payday-opening-mark')));
      final painter=paint.painter! as PaydayOpeningPainter;
      expect(painter.progress,greaterThan(0));expect(painter.progress,lessThan(1));
      expect(tester.takeException(),isNull);
    }
    await tester.pumpAndSettle();expect(find.byKey(overlay),findsNothing);
  });
  testWidgets('reduced motion uses a short fade instead of the full sequence',(tester)async{
    await tester.pumpWidget(MaterialApp(home:MediaQuery(
      data:const MediaQueryData(disableAnimations:true),
      child:const PaydayOpening(child:Scaffold(body:Text('Home'))))));
    await tester.pump(const Duration(milliseconds:200));
    await tester.pumpAndSettle();
    expect(find.byKey(overlay),findsNothing);
    expect(tester.takeException(),isNull);
  });
  testWidgets('launch defaults to light on a dark phone and theme changes do not replay the opening',(tester)async{
    tester.platformDispatcher.platformBrightnessTestValue=Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(PaydayLocal(initialData:Future.value(<String,List<RowData>>{}),preferencesWriter:(_)async{}));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.light);
    await tester.pumpAndSettle();
    expect(find.byKey(overlay),findsNothing);
    expect(find.text('Salam'),findsNothing);
    expect(find.text('Plan today, enjoy tomorrow.'),findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-settings-logo')));await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.dark);
    expect(find.byKey(overlay),findsNothing);
    await tester.tap(find.text('Theme'));await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,ThemeMode.light);
    expect(find.byKey(overlay),findsNothing);
    expect(tester.takeException(),isNull);
  });
}


