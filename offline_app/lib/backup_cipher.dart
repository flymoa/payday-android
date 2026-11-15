import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Versioned, authenticated backup envelope. Passwords are never persisted.
class BackupCipher {
 const BackupCipher();
 static const maxPlainBytes=16*1024*1024;
 static const maxFileBytes=24*1024*1024;
 static const format='payday-encrypted';
 static const rounds=600000;
 static const _aad='PAYDAY|encrypted-backup|1|AES-256-GCM|PBKDF2-HMAC-SHA256|600000';
 Future<String> seal(String plain,String password)=>compute(_seal,[plain,password]);
 Future<String> open(String raw,String password)=>compute(_open,[raw,password]);
 static Map<String,dynamic> document(String raw){
  if(utf8.encode(raw).length>maxFileBytes)throw const FormatException('This backup is too large.');
  try{
   final value=jsonDecode(raw);
   if(value is! Map<String,dynamic>)throw const FormatException();
   return value;
  }catch(_){throw const FormatException('This is not a valid Payday backup.');}
 }
 static bool isProtected(String raw){
  final d=document(raw);
  if(d['format']==format){_envelope(d);return true;}
  validatePlain(raw);return false;
 }
 static void validatePlain(String raw){
  if(utf8.encode(raw).length>maxPlainBytes)throw const FormatException('This backup is too large.');
  final d=document(raw);
  if(d['format']!='payday-local'||![1,2,3].contains(d['schema_version'])||d['tables'] is! Map){
   throw const FormatException('This is not a supported Payday backup.');
  }
 }
 static void _password(String password){
  if(password.isEmpty||utf8.encode(password).length>1024)throw const FormatException('Enter a valid backup password.');
 }
 static Map<String,Uint8List> _envelope(Map<String,dynamic> d){
  if(d['version']!=1||d['cipher']!='AES-256-GCM'||d['kdf']!='PBKDF2-HMAC-SHA256'||d['iterations']!=rounds){
   throw const FormatException('This backup format is not supported.');
  }
  try{
   final parts={for(final name in ['salt','nonce','ciphertext','tag'])name:base64Decode(d[name] as String)};
   if(parts['salt']!.length!=16||parts['nonce']!.length!=12||parts['tag']!.length!=16||parts['ciphertext']!.isEmpty||parts['ciphertext']!.length>maxPlainBytes)throw const FormatException();
   return parts;
  }catch(_){throw const FormatException('This backup is damaged.');}
 }
 static Future<SecretKey> _key(String password,List<int> salt)=>Pbkdf2(macAlgorithm:Hmac.sha256(),iterations:rounds,bits:256)
  .deriveKey(secretKey:SecretKey(utf8.encode(password)),nonce:salt);
 static Future<String> _seal(List<String> input)async{
  final plain=input[0],password=input[1];validatePlain(plain);_password(password);
  final random=Random.secure();
  final salt=List<int>.generate(16,(_)=>random.nextInt(256));
  final nonce=List<int>.generate(12,(_)=>random.nextInt(256));
  final box=await AesGcm.with256bits().encrypt(utf8.encode(plain),secretKey:await _key(password,salt),nonce:nonce,aad:utf8.encode(_aad));
  return jsonEncode({'format':format,'version':1,'cipher':'AES-256-GCM','kdf':'PBKDF2-HMAC-SHA256','iterations':rounds,
   'salt':base64Encode(salt),'nonce':base64Encode(nonce),'ciphertext':base64Encode(box.cipherText),'tag':base64Encode(box.mac.bytes)});
 }
 static Future<String> _open(List<String> input)async{
  _password(input[1]);final d=document(input[0]);
  if(d['format']!=format)throw const FormatException('This is not a protected Payday backup.');
  final parts=_envelope(d);
  try{
   final plain=await AesGcm.with256bits().decrypt(SecretBox(parts['ciphertext']!,nonce:parts['nonce']!,mac:Mac(parts['tag']!)),
    secretKey:await _key(input[1],parts['salt']!),aad:utf8.encode(_aad));
   final text=utf8.decode(plain);validatePlain(text);return text;
  }catch(_){throw const FormatException('Incorrect password or damaged backup.');}
 }
}
