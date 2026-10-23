import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'backup_cipher.dart';
import 'offline_store.dart';
import 'finance.dart';

/// Counts records only after the selected file has been decrypted and validated.
/// This reads the file in memory; it never opens or changes the local database.
class BackupPreview{
 const BackupPreview({required this.counts,this.exportedAt});
 final Map<String,int> counts;
 final DateTime? exportedAt;
 factory BackupPreview.fromPlain(String plain){
  BackupCipher.validatePlain(plain);
  final document=BackupCipher.document(plain);
  final tables=document['tables'] as Map;
  final legacy=document['schema_version']==1;
  for(final name in localTables){
   if(legacy&&name=='reserve_movements'&&!tables.containsKey(name))continue;
   final rows=tables[name];
   if(rows is! List||rows.any((row)=>row is! Map||row.keys.any((key)=>key is! String))){
    throw const FormatException('This backup is incomplete or has invalid records.');
   }
  }
  return BackupPreview(counts:Map.unmodifiable({
   'Transactions':(tables['transactions'] as List).length,
   'Bills':(tables['bills'] as List).length,
   'Savings goals':(tables['goals'] as List).length,
   'Reserves':(tables['reserves'] as List).length,
  }),exportedAt:document['exported_at'] is String?DateTime.tryParse(document['exported_at'] as String):null);
 }
}

Future<bool> confirmBackupRestore(BuildContext context,BackupPreview preview)async=>
 await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
  title:const Text('Restore this backup?'),scrollable:true,
  content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   if(preview.exportedAt!=null)Padding(padding:const EdgeInsets.only(bottom:12),child:Text('Backup date: ${dayKey(preview.exportedAt!.toLocal())}')),
   for(final entry in preview.counts.entries)Padding(padding:const EdgeInsets.symmetric(vertical:5),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(entry.key)),
     const SizedBox(width:16),Text('${entry.value}',style:const TextStyle(fontWeight:FontWeight.w700,fontFeatures:[FontFeature.tabularFigures()]))])),
   const SizedBox(height:16),
   const Text('This replaces all records on this phone. Export a backup first.'),
   const SizedBox(height:8),
   const Text('App lock and reminder settings stay as they are.'),
  ]),
  actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
   FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Replace local data'))]))??false;
