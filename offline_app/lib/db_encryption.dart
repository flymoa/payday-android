import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

/// The database key never leaves this phone: it is created once with a secure
/// random generator and kept in Android's Keystore-backed secure storage.
/// It is not in backups (Android backup is disabled; Payday backups are JSON).
class DatabaseKey {
 static const _storageKey='payday_database_key_v1';
 static const _storage=FlutterSecureStorage();
 static Future<String> obtain()async{
  final existing=await _storage.read(key:_storageKey);
  if(existing!=null&&RegExp(r'^[0-9a-f]{64}$').hasMatch(existing))return existing;
  final random=Random.secure();
  final key=List.generate(32,(_)=>random.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
  await _storage.write(key:_storageKey,value:key);
  // Read back so a storage problem is found before any data depends on this key.
  if(await _storage.read(key:_storageKey)!=key)throw StateError('Could not store the database key.');
  return key;
 }
}

/// True for an ordinary (unencrypted) SQLite file. Encrypted files have no readable header.
bool isPlainSqlite(List<int> header)=>header.length>=16&&
 String.fromCharCodes(header.sublist(0,15))=='SQLite format 3'&&header[15]==0;

Future<bool> fileIsPlainSqlite(String path)async{
 final file=File(path);
 if(!await file.exists()||await file.length()<16)return false;
 final raf=await file.open();
 try{return isPlainSqlite(await raf.read(16));}finally{await raf.close();}
}

int? _firstInt(List<Map<String,Object?>> rows)=>rows.isEmpty||rows.first.isEmpty?null:(rows.first.values.first as num?)?.toInt();

String _quote(String s)=>"'${s.replaceAll("'","''")}'";

/// One-time move of an existing unencrypted database to an encrypted file.
/// The original stays untouched until the encrypted copy is verified, and an
/// interrupted swap is repaired on the next launch. Returns true if it encrypted.
Future<bool> encryptDatabaseIfNeeded(String path,String key)async{
 final previous='$path.pre-encryption',temp='$path.encrypting';
 // Repair an interrupted swap from an earlier launch.
 if(!await File(path).exists()&&await File(previous).exists())await File(previous).rename(path);
 if(await File(path).exists()&&!await fileIsPlainSqlite(path)){
  await _deleteDatabaseFiles(previous);
  await _deleteDatabaseFiles(temp);
  return false;
 }
 if(!await File(path).exists())return false; // fresh install: created encrypted
 await _deleteDatabaseFiles(temp);
 final plain=await cipher.openDatabase(path,singleInstance:false);
 final tables=<String,int>{};
 try{
  final version=_firstInt(await plain.rawQuery('PRAGMA user_version'))??0;
  for(final row in await plain.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name<>'android_metadata'")){
   final name=row['name'] as String;
   tables[name]=_firstInt(await plain.rawQuery('SELECT COUNT(*) FROM "${name.replaceAll('"','""')}"'))??0;
  }
  await plain.execute('ATTACH DATABASE ${_quote(temp)} AS encrypted KEY ${_quote(key)}');
  await plain.rawQuery("SELECT sqlcipher_export('encrypted')");
  await plain.execute('PRAGMA encrypted.user_version = $version');
  await plain.execute('DETACH DATABASE encrypted');
 }finally{await plain.close();}
 // Verify every table and row count before replacing anything.
 final check=await cipher.openDatabase(temp,password:key,singleInstance:false);
 try{
  for(final entry in tables.entries){
   final n=_firstInt(await check.rawQuery('SELECT COUNT(*) FROM "${entry.key.replaceAll('"','""')}"'));
   if(n!=entry.value)throw StateError('Encrypted copy does not match the original.');
  }
 }finally{await check.close();}
 await File(path).rename(previous);
 await File(temp).rename(path);
 await _deleteDatabaseFiles(previous);
 return true;
}

Future<void> _deleteDatabaseFiles(String path)async{
 for(final suffix in ['','-journal','-wal','-shm']){
  final f=File('$path$suffix');
  if(await f.exists())await f.delete();
 }
}
