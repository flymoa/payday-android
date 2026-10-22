import 'package:flutter/material.dart';

class AppPreferences {
 const AppPreferences({this.appearance=ThemeMode.light,this.openingAnimation=true,
  this.reduceMotion=false});
 final ThemeMode appearance;
 final bool openingAnimation,reduceMotion;
 String get appearanceLabel=>switch(appearance){
  ThemeMode.light=>'Light',ThemeMode.dark=>'Dark',ThemeMode.system=>'System',
 };
 factory AppPreferences.fromRows(Iterable<Map<String,Object?>> rows){
  final values={for(final row in rows)row['key']:row['value']?.toString()};
  return AppPreferences(
   appearance:switch(values['app_appearance']){'dark'=>ThemeMode.dark,'system'=>ThemeMode.system,_=>ThemeMode.light},
   openingAnimation:values['app_opening_animation']!='0',
   reduceMotion:values['app_reduce_motion']=='1');
 }
 AppPreferences copyWith({ThemeMode? appearance,bool? openingAnimation,bool? reduceMotion})=>
  AppPreferences(appearance:appearance??this.appearance,
   openingAnimation:openingAnimation??this.openingAnimation,reduceMotion:reduceMotion??this.reduceMotion);
 Map<String,String> get values=>{
  'app_appearance':appearance.name,
  'app_opening_animation':openingAnimation?'1':'0',
  'app_reduce_motion':reduceMotion?'1':'0',
 };
}
