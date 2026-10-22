import 'package:flutter/material.dart';

const paydayCurrencies={
 'MAD':'Moroccan dirham',
 'EUR':'Euro',
 'GBP':'British pound',
 'USD':'US dollar',
};
String supportedCurrency(String? value)=>paydayCurrencies.containsKey(value)?value!:'MAD';
String formatMoney(int cents,String currency)=>'${(cents/100).toStringAsFixed(2)} ${supportedCurrency(currency)}';

class AppPreferences {
 const AppPreferences({this.appearance=ThemeMode.light,this.currency='MAD',this.appLock=false});
 final ThemeMode appearance;
 final String currency;
 final bool appLock;
 String get appearanceLabel=>switch(appearance){
  ThemeMode.light=>'Light',ThemeMode.dark=>'Dark',ThemeMode.system=>'System',
 };
 factory AppPreferences.fromRows(Iterable<Map<String,Object?>> rows){
  final values={for(final row in rows)row['key']:row['value']?.toString()};
  if(values.containsKey('app_lock_enabled')&&!['0','1'].contains(values['app_lock_enabled'])){
   throw const FormatException('Invalid app security preference');
  }
  return AppPreferences(
   appearance:switch(values['app_appearance']){'dark'=>ThemeMode.dark,'system'=>ThemeMode.system,_=>ThemeMode.light},
   currency:supportedCurrency(values['currency']),appLock:values['app_lock_enabled']=='1');
 }
 AppPreferences copyWith({ThemeMode? appearance,String? currency,bool? appLock})=>
  AppPreferences(appearance:appearance??this.appearance,currency:supportedCurrency(currency??this.currency),appLock:appLock??this.appLock);
 Map<String,String> get values=>{'app_appearance':appearance.name,'currency':supportedCurrency(currency),'app_lock_enabled':appLock?'1':'0'};
}
