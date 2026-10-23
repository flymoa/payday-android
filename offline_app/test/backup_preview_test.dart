import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/backup_preview.dart';
import 'package:payday_local/offline_store.dart';

Map<String,Object?> document({int version=2})=>{
 'format':'payday-local','schema_version':version,'exported_at':'2026-10-23T12:00:00Z',
 'tables':{for(final name in localTables)name:<Map<String,Object?>>[]},
};
void main(){
 test('preview counts selected backup records without requiring local data',(){
  final d=document();final tables=d['tables'] as Map;
  tables['transactions']=[{'id':1},{'id':2}];tables['bills']=[{'id':1}];tables['reserves']=[{'id':1}];
  final raw=jsonEncode(d);final preview=BackupPreview.fromPlain(raw);
  expect(preview.counts,{'Transactions':2,'Bills':1,'Savings goals':0,'Reserves':1});
  expect(preview.exportedAt,DateTime.utc(2026,10,23,12));expect(jsonEncode(d),raw);
 });
 test('legacy backup may omit reserve movements; missing tables and malformed records are rejected',(){
  final legacy=document(version:1);(legacy['tables'] as Map).remove('reserve_movements');
  expect(BackupPreview.fromPlain(jsonEncode(legacy)).counts['Transactions'],0);
  final missing=document();(missing['tables'] as Map).remove('bills');
  expect(()=>BackupPreview.fromPlain(jsonEncode(missing)),throwsFormatException);
  final bad=document();(bad['tables'] as Map)['transactions']=['not a record'];
  expect(()=>BackupPreview.fromPlain(jsonEncode(bad)),throwsFormatException);
  final date=document()..['exported_at']='unknown';expect(BackupPreview.fromPlain(jsonEncode(date)).exportedAt,isNull);
 });
 for(final brightness in Brightness.values){
  testWidgets('restore summary is readable and requires explicit confirmation in ${brightness.name}',(t)async{
   await t.binding.setSurfaceSize(const Size(320,800));addTearDown(()=>t.binding.setSurfaceSize(null));
   bool? result;var imports=0;
   final preview=BackupPreview.fromPlain(jsonEncode(document()));
   await t.pumpWidget(MaterialApp(theme:ThemeData(brightness:brightness),
    builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(1.5)),child:child!),
    home:Builder(builder:(c)=>Scaffold(body:TextButton(onPressed:()async{
     result=await confirmBackupRestore(c,preview);if(result==true)imports++;
    },child:const Text('Preview'))))));
   await t.tap(find.text('Preview'));await t.pumpAndSettle();expect(imports,0);
   expect(find.text('Transactions'),findsOneWidget);expect(find.text('Reserves'),findsOneWidget);expect(find.text('Backup date: 2026-10-23'),findsOneWidget);
   await t.ensureVisible(find.text('Cancel'));await t.tap(find.text('Cancel'));await t.pumpAndSettle();expect(result,isFalse);expect(imports,0);
   await t.tap(find.text('Preview'));await t.pumpAndSettle();await t.ensureVisible(find.text('Replace local data'));
   await t.tap(find.text('Replace local data'));await t.pumpAndSettle();expect(result,isTrue);expect(imports,1);expect(t.takeException(),isNull);
  });
 }
}
