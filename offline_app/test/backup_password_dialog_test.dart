import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/backup_password_dialog.dart';
void main(){
 for(final brightness in Brightness.values){
  testWidgets('export validates password and cancellation in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   var calls=0;
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),home:Builder(builder:(c)=>Scaffold(body:TextButton(
    onPressed:()=>showDialog<String>(context:c,builder:(_)=>BackupPasswordDialog(creating:true,submit:(p)async{calls++;return p;})),child:const Text('Open'))))));
   await t.tap(find.text('Open'));await t.pumpAndSettle();
   await t.tap(find.byKey(const ValueKey('backup-password-submit')));await t.pump();
   expect(find.text('Enter a password.'),findsOneWidget);
   await t.enterText(find.byKey(const ValueKey('backup-password')),'short');
   await t.tap(find.byKey(const ValueKey('backup-password-submit')));await t.pump();
   expect(find.text('Use at least 12 characters.'),findsOneWidget);
   await t.enterText(find.byKey(const ValueKey('backup-password')),'  Twelve words here  ');
   await t.enterText(find.byKey(const ValueKey('backup-password-confirm')),'different');
   await t.tap(find.byKey(const ValueKey('backup-password-submit')));await t.pump();
   expect(find.text('The passwords do not match.'),findsOneWidget);
   await t.enterText(find.byKey(const ValueKey('backup-password-confirm')),'  Twelve words here  ');
   await t.tap(find.byKey(const ValueKey('backup-password-submit')));await t.pump();
   expect(find.text('Confirm that you have saved this password.'),findsOneWidget);
   await t.tap(find.text('Cancel'));await t.pumpAndSettle();
   expect(calls,0);expect(t.takeException(),isNull);
  });
 }
 testWidgets('wrong restore password keeps dialog open for retry and preserves exact input',(t)async{
  var calls=0;String? result;
  await t.pumpWidget(MaterialApp(home:Builder(builder:(c)=>Scaffold(body:TextButton(onPressed:()async{
   result=await showDialog<String>(context:c,builder:(_)=>BackupPasswordDialog(creating:false,submit:(p)async{
    calls++;if(calls==1)throw const FormatException('Incorrect password or damaged backup.');return p;
   }));
  },child:const Text('Open'))))));
  await t.tap(find.text('Open'));await t.pumpAndSettle();
  await t.enterText(find.byKey(const ValueKey('backup-password')),'  exact password  ');
  await t.tap(find.text('Unlock'));await t.pumpAndSettle();
  expect(result,isNull);expect(find.text('Incorrect password or damaged backup.'),findsOneWidget);
  await t.tap(find.text('Unlock'));await t.pumpAndSettle();
  expect(result,'  exact password  ');expect(calls,2);
 });
}
