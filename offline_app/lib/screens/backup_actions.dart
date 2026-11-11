// Part of the main finance screen, split from main.dart. Same library, so private
// members stay accessible; extensions keep behaviour identical to the old methods.
// ignore_for_file: invalid_use_of_protected_member
part of '../main.dart';

extension _BackupActions on _FinanceState {
 Future<ShareResult> shareBackupFile(String contents)async{
  final dir=await getTemporaryDirectory();
  // Remove leftovers from earlier exports. The current file is not deleted right
  // after sharing because the receiving app may still be reading it.
  try{
   await for(final entity in dir.list()){
    final name=entity.path.split(Platform.pathSeparator).last;
    if(entity is File&&name.startsWith('payday-backup-')&&name.endsWith('.json')){await entity.delete();}
   }
  }catch(_){}
  final f=File('${dir.path}/payday-backup-${DateTime.now().microsecondsSinceEpoch}.json');
  await f.writeAsString(contents,flush:true);
  return Share.shareXFiles([XFile(f.path)],text:tr(context,'Payday backup — store this file privately'));
 }
 Future<void> exportBackup() async{
  if(exportingBackup||restoringBackup)return;
  setState(()=>exportingBackup=true);
  try{
   final started=DateTime.now().toUtc();
   final json=await showDialog<String>(context:context,barrierDismissible:false,builder:(_)=>BackupPasswordDialog(
    creating:true,submit:(password)async=>backupCipher.seal(await store.exportJson(),password)));
   if(json==null||!mounted)return;
   final result=await (widget.backupShare??shareBackupFile)(json);
   if(!mounted)return;
   var completed=result.status==ShareResultStatus.success;
   if(result.status==ShareResultStatus.unavailable){
    completed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
     title:LText('Did you save the backup?'),
     content:LText('This device cannot confirm the export. Mark it complete only if you saved the JSON file.'),
     actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:LText('Not saved')),
      FilledButton(onPressed:()=>Navigator.pop(c,true),child:LText('I saved it'))]))??false;
   }
   if(!completed){if(mounted)inputError('Export not confirmed. Your backup reminder stays active.');return;}
   await store.setSetting('last_backup_export',started.toIso8601String());
   await store.setSetting('backup_snooze_until','');
   refresh();
   if(BackupNotifications.supported||widget.backupNotifications!=null){
    try{await reminders.resetAfterExport();}
    catch(_){if(mounted)inputError('Backup saved, but the notification reminder could not be reset. Check Settings → Notifications.');return;}
   }
   if(mounted)inputError('Password-protected backup exported. Keep the file and password safe.');
  }catch(e){if(mounted)inputError('Backup export failed: $e');}
  finally{if(mounted)setState(()=>exportingBackup=false);}
 }
 Future<void> exportCsv()async{
  if(exportingBackup||restoringBackup)return;
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:LText('Export transactions as CSV?'),
   content:LText('The CSV file is not password protected and cannot be restored into Payday. Use a password-protected backup to keep your records safe.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:LText('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(c,true),child:LText('Export CSV'))]));
  if(yes!=true||!mounted)return;
  try{
   final dir=await getTemporaryDirectory();
   await for(final e in dir.list()){
    final name=e.path.split(Platform.pathSeparator).last;
    if(e is File&&name.startsWith('payday-transactions-')&&name.endsWith('.csv'))await e.delete();
   }
   final f=File('${dir.path}/payday-transactions-${dayKey(DateTime.now())}.csv');
   await f.writeAsString(transactionsCsv(await store.table('transactions')),flush:true);
   await Share.shareXFiles([XFile(f.path,mimeType:'text/csv')]);
  }catch(e){if(mounted)inputError('CSV export failed: $e');}
 }
 Future<void> applyRestoredPreferences(bool restored)async{
  if(restored&&mounted&&widget.onPreferencesChanged!=null){
   await widget.onPreferencesChanged!(await store.loadAppPreferences());
   if(mounted)await refreshNotificationLanguage();
  }
 }
 Future<void> undoLastRestore()async{
  if(exportingBackup||restoringBackup)return;
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:LText('Undo last restore?'),
   content:LText('This replaces all records on this phone with your data from before the last restore. Changes made since then will be lost.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:LText('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(c,true),child:LText('Undo restore'))]));
  if(yes!=true||!mounted)return;
  setState(()=>restoringBackup=true);
  try{
   final restored=await execute(()=>revertToSnapshot(store,snapshots));
   await applyRestoredPreferences(restored);
  }finally{if(mounted)setState(()=>restoringBackup=false);}
 }
 Future<void> importBackup() async{
  if(exportingBackup||restoringBackup)return;
  setState(()=>restoringBackup=true);
  try{
   final picker=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json']);
   if(picker==null)return;
   final file=picker.files.single;
   if(file.size>BackupCipher.maxFileBytes||(file.path!=null&&await File(file.path!).length()>BackupCipher.maxFileBytes)){
    throw const FormatException('This backup is too large.');
   }
   final raw=file.path!=null?await File(file.path!).readAsString():file.bytes!=null?utf8.decode(file.bytes!):null;
   if(raw==null)throw const FormatException('Could not read the backup.');
   if(!mounted)return;
   String? plain=raw;
   if(BackupCipher.isProtected(raw)){
    plain=await showDialog<String>(context:context,barrierDismissible:false,builder:(_)=>BackupPasswordDialog(
     creating:false,submit:(password)=>backupCipher.open(raw,password)));
   }
   if(plain==null||!mounted)return;
   final preview=BackupPreview.fromPlain(plain);
   final contents=plain;
   final yes=await confirmBackupRestore(context,preview);
   if(yes==true){
    final restored=await execute(()=>restoreWithSafetyCopy(store,snapshots,contents));
    await applyRestoredPreferences(restored);
   }
  }on FormatException catch(e){if(mounted)inputError(e.message);}
  catch(_){if(mounted)inputError('Could not restore the backup. Please try again.');}
  finally{if(mounted)setState(()=>restoringBackup=false);}
 }
}
