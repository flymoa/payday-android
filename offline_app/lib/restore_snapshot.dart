import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_cipher.dart';
import 'offline_store.dart';

/// One private copy of the data that existed before the latest restore.
/// It lives in the app's own storage (like the database itself), is never
/// shared, and Android system backup is disabled for the app.
class RestoreSnapshot {
 RestoreSnapshot({Future<Directory> Function()? directory})
  :_directory=directory??getApplicationSupportDirectory;
 final Future<Directory> Function() _directory;
 static const fileName='payday-before-restore.json';

 Future<File> _file()async{
  final dir=await _directory();
  await dir.create(recursive:true);
  return File('${dir.path}${Platform.pathSeparator}$fileName');
 }

 /// Written to a temporary file first, so a crash never leaves a half-written copy.
 Future<void> save(String json)async{
  final target=await _file();
  final temp=File('${target.path}.tmp');
  await temp.writeAsString(json,flush:true);
  await temp.rename(target.path);
 }
 Future<String?> read()async{
  final file=await _file();
  return await file.exists()?file.readAsString():null;
 }
 Future<DateTime?> savedAt()async{
  final file=await _file();
  return await file.exists()?file.lastModified():null;
 }
 Future<void> clear()async{
  final file=await _file();
  if(await file.exists())await file.delete();
 }
}

/// Saves a safety copy first. If that copy cannot be written, nothing is replaced.
Future<void> restoreWithSafetyCopy(OfflineStore store,RestoreSnapshot snapshot,String plainBackup)async{
 try{
  await snapshot.save(await store.exportJson());
 }catch(_){
  throw StateError('Could not save a safety copy, so nothing was restored.');
 }
 await store.importJson(plainBackup);
}

/// Puts back the data saved before the latest restore, then discards that copy.
Future<void> revertToSnapshot(OfflineStore store,RestoreSnapshot snapshot)async{
 final plain=await snapshot.read();
 if(plain==null)throw StateError('There is no restore to undo.');
 BackupCipher.validatePlain(plain);
 await store.importJson(plain);
 await snapshot.clear();
}
