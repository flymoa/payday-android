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
 const AppPreferences({this.appearance=ThemeMode.light,this.currency='MAD'});
 final ThemeMode appearance;
 final String currency;
 String get appearanceLabel=>switch(appearance){
  ThemeMode.light=>'Light',ThemeMode.dark=>'Dark',ThemeMode.system=>'System',
 };
 factory AppPreferences.fromRows(Iterable<Map<String,Object?>> rows){
  final values={for(final row in rows)row['key']:row['value']?.toString()};
  return AppPreferences(
   appearance:switch(values['app_appearance']){'dark'=>ThemeMode.dark,'system'=>ThemeMode.system,_=>ThemeMode.light},
   currency:supportedCurrency(values['currency']));
 }
 AppPreferences copyWith({ThemeMode? appearance,String? currency})=>
  AppPreferences(appearance:appearance??this.appearance,currency:supportedCurrency(currency??this.currency));
 Map<String,String> get values=>{'app_appearance':appearance.name,'currency':supportedCurrency(currency)};
}
