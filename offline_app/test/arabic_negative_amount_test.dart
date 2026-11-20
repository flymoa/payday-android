import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payday_local/localization.dart';

/// A negative amount in Arabic must read as one left-to-right unit inside RTL text:
/// minus on the number's left, digit groups in order, and the currency word after it.
void main(){
 test('Arabic money keeps the number as one LTR unit with marks',(){
  expect(localizedMoney(-1541550,'MAD','ar'),'\u200e\u221215\u00a0415,50\u200e درهم');
  expect(localizedWhole(-20000,'ar'),'\u200e\u2212200\u200e');
  expect(localizedMoney(-1541550,'MAD','en'),'\u221215\u00a0415,50 DH');
 });
 testWidgets('negative Arabic amount renders minus, digits and currency in order',(t)async{
  for(final cents in [-1541550,-20000,-518693]){
   final v=localizedMoney(cents,'MAD','ar');
   await t.pumpWidget(MaterialApp(locale:const Locale('ar'),supportedLocales:const [Locale('ar')],
    localizationsDelegates:GlobalMaterialLocalizations.delegates,
    home:Scaffold(body:Center(child:Text.rich(TextSpan(text:v),textDirection:TextDirection.rtl)))));
   final p=t.renderObject<RenderParagraph>(find.byType(RichText).last);
   final s=p.text.toPlainText();
   double x(int i)=>p.getBoxesForSelection(TextSelection(baseOffset:i,extentOffset:i+1)).first.left;
   final minus=s.indexOf('\u2212'),first=minus+1,last=s.lastIndexOf(RegExp(r'\d')),currency=s.indexOf('د');
   expect(x(minus)<x(first),isTrue,reason:'minus sits left of the digits: $v');
   expect(x(first)<x(last),isTrue,reason:'digits stay left to right: $v');
   expect(x(currency)<x(minus),isTrue,reason:'currency word follows the number in RTL: $v');
  }
 });
}
