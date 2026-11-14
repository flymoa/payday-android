import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/backup_cipher.dart';
void main(){
 const cipher=BackupCipher();
 final plain=jsonEncode({'format':'payday-local','schema_version':2,'tables':{'transactions':[{'title':'Private purchase','amount':300}]}});
 test('authenticated round trip, random envelopes, exact Unicode password and tamper rejection',()async{
  const password='  My café backup 🔐  ';
  final raw=await cipher.seal(plain,password);
  final second=await cipher.seal(plain,password);
  expect(raw, isNot(contains('Private purchase')));
  expect(raw,isNot(contains(password)));
  expect(BackupCipher.isProtected(raw),isTrue);
  final d=jsonDecode(raw) as Map<String,dynamic>;
  final other=jsonDecode(second) as Map<String,dynamic>;
  for(final key in ['salt','nonce','ciphertext']){expect(d[key],isNot(other[key]));}
  expect(await cipher.open(raw,password),plain);
  await expectLater(cipher.open(raw,password.trim()),throwsFormatException);
  for(final key in ['ciphertext','tag','salt','nonce']){
   final changed=Map<String,dynamic>.from(d);
   final bytes=base64Decode(changed[key] as String);bytes[0]^=1;changed[key]=base64Encode(bytes);
   await expectLater(cipher.open(jsonEncode(changed),password),throwsFormatException);
  }
 },timeout:const Timeout(Duration(minutes:3)));
 test('legacy backups supported and invalid formats rejected before derivation',()async{
  expect(BackupCipher.isProtected(plain),isFalse);
  expect(BackupCipher.isProtected(jsonEncode({'format':'payday-local','schema_version':1,'tables':{}})),isFalse);
  for(final raw in ['{}','[]','broken',jsonEncode({'format':'payday-encrypted','version':2}),
   jsonEncode({'format':'payday-encrypted','version':1,'cipher':'AES-256-GCM','kdf':'PBKDF2-HMAC-SHA256','iterations':1})]){
   expect(()=>BackupCipher.isProtected(raw),throwsFormatException);
  }
  await expectLater(cipher.seal('{}','a long password'),throwsFormatException);
 });
}
