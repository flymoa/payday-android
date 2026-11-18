import 'package:flutter/material.dart';
import 'app_language.dart';
import 'translations.dart';

String languageOf(BuildContext context)=>supportedLanguage(Localizations.maybeLocaleOf(context)?.languageCode);
String tr(BuildContext context,String message)=>translateMessage(message,languageOf(context));

final _messageRules=paydayTranslations.keys.where((s)=>RegExp(r'\{\d+\}').hasMatch(s)).toList()
 ..sort((a,b)=>b.replaceAll(RegExp(r'\{\d+\}'),'').length.compareTo(a.replaceAll(RegExp(r'\{\d+\}'),'').length));
final _patterns=<String,RegExp>{for(final template in _messageRules)template:RegExp(
 '^${RegExp.escape(template).replaceAllMapped(RegExp(r'\\\{\d+\\\}'),(_)=>'(.*?)')}\$',dotAll:true)};

/// Only app-authored display text calls this function. Names and ledger keys remain raw.
String translateMessage(String message,String language){
 final code=supportedLanguage(language);
 if(code=='en')return message;
 final index=code=='fr'?0:1;
 final direct=paydayTranslations[message];
 if(direct!=null)return direct[index];
 // Several on-demand explanations are joined using blank lines.
 if(message.contains('\n\n'))return message.split('\n\n').map((s)=>translateMessage(s,code)).join('\n\n');
 for(final prefix in ['Bad state: ','Invalid argument(s): ','FormatException: ']){
  if(message.startsWith(prefix))return translateMessage(message.substring(prefix.length),code);
 }
 for(final template in _messageRules){
  final match=_patterns[template]!.firstMatch(message);
  if(match==null)continue;
  var value=paydayTranslations[template]![index];
  final tokens=RegExp(r'\{(\d+)\}').allMatches(template).toList();
  final captures=<String,String>{};
  for(var i=0;i<tokens.length;i++){
   var captured=match.group(i+1)!;
   if(template=='{0} · 9:00 AM'||template=='{0} · Spent {1} · {2}')captured=translateMessage(captured,code);
   captures[tokens[i].group(0)!]=captured;
  }
  return value.replaceAllMapped(RegExp(r'\{\d+\}'),(m)=>captures[m.group(0)]??m.group(0)!);
 }
 return message;
}

const _builtinCategories={
 'Housing','Utilities','Groceries','Transport','Health','Family','Eating out','Shopping','Leisure',
 'Subscriptions','Debt payment','Other','Salary','Freelance','Business','Gifts','Other income','Savings',
 'Income plan','Savings goal','Uncategorized',
};
String categoryLabel(BuildContext context,String name)=>_builtinCategories.contains(name)?tr(context,name):name;

String localizedNumber(int cents,String language,{bool grouped=false}){
 final negative=cents<0,absolute=cents.abs();var whole='${absolute~/100}';
 if(grouped)whole=whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(_)=>language=='fr'?'\u202f':',');
 return '${negative?'−':''}$whole${language=='fr'?',':'.'}${(absolute%100).toString().padLeft(2,'0')}';
}
/// Amounts on screen always group thousands (1,234.50 / 1 234,50). Inputs stay ungrouped.
/// In Arabic the currency is written as a word after the number ("1,240.00 درهم").
const arabicCurrency={'MAD':'درهم','EUR':'يورو','USD':'دولار','GBP':'جنيه'};
String currencyLabel(String currency,String language)=>language=='ar'?(arabicCurrency[currency]??currency):currency;
String localizedMoney(int cents,String currency,String language)=>'${language=='en'&&cents<0?'-'+localizedNumber(-cents,language,grouped:true):localizedNumber(cents,language,grouped:true)} ${currencyLabel(currency,language)}';
const _monthsEn=['January','February','March','April','May','June','July','August','September','October','November','December'];
String localizedMonth(DateTime date,String language,{bool short=false}){
 if(language=='en'&&short)return '${_monthsEn[date.month-1].substring(0,3)} ${date.year}';
 return '${translateMessage(_monthsEn[date.month-1],language)} ${date.year}';
}
String localizedDay(DateTime date,String language){
 if(language=='en')return '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
 return '${date.day} ${localizedMonth(date,language)}';
}
/// Arabic counts days the Arabic way: يوم واحد، يومان، 3–10 أيام، 11+ يومًا.
String arabicDays(int n,{bool after=false})=>n==1?(after?'يوم':'يوم واحد'):n==2?(after?'يومين':'يومان'):n>=3&&n<=10?'$n أيام':'$n يومًا';

/// Day and month only, e.g. "20 Nov" (English) or "20 novembre", as used in lists.
String localizedShortDay(DateTime date,String language){
 final name=_monthsEn[date.month-1];
 return language=='en'?'${date.day} ${name.substring(0,3)}':'${date.day} ${translateMessage(name,language)}';
}
String displayDay(BuildContext context,String iso){
 final date=DateTime.tryParse(iso);return date==null?iso:localizedDay(date,languageOf(context));
}

/// Arabic type rules from the design: no letter spacing, at least 13px, taller lines,
/// and weights IBM Plex Sans Arabic has (Bold at most).
TextStyle arabicStyle(TextStyle? style){
 final s=style??const TextStyle();
 final size=s.fontSize;
 final weight=s.fontWeight;
 return s.copyWith(letterSpacing:0,
  fontSize:size!=null&&size<13?13:null,
  height:s.height??((size??14)>=20?1.35:1.5),
  fontWeight:weight!=null&&weight.value>700?FontWeight.w700:null);
}

/// Keeps the existing Text properties and geometry; localization is display-only.
class LText extends StatelessWidget{
 const LText(this.data,{super.key,this.style,this.textAlign,this.textDirection,this.maxLines,
  this.softWrap,this.overflow,this.semanticsLabel,this.category=false});
 final String data;
 final TextStyle? style;
 final TextAlign? textAlign;
 final TextDirection? textDirection;
 final int? maxLines;
 final bool? softWrap;
 final TextOverflow? overflow;
 final String? semanticsLabel;
 final bool category;
 @override Widget build(BuildContext context){
  final value=category?categoryLabel(context,data):tr(context,data);
  final arabic=languageOf(context)=='ar';
  final numeric=RegExp(r'\d').hasMatch(value)&&RegExp(r'^(?:[\d\s.,+−%/()\u202f]|MAD|EUR|GBP|USD)+$').hasMatch(value);
  // Numbers stay left to right inside Arabic; the currency word follows the number.
  final displayed=arabic&&!numeric?value
   .replaceAllMapped(RegExp(r'[+−-]?[0-9][0-9.,\u202f]*\s+(?:MAD|EUR|GBP|USD)'),(m)=>'\u2066${m.group(0)}\u2069')
   .replaceAllMapped(RegExp(r'([+−-]?[0-9][0-9.,\u202f/ ]*[0-9%])(?=\s*(?:درهم|يورو|دولار|جنيه))'),(m)=>'\u2066${m.group(1)}\u2069'):value;
  return Text(displayed,style:arabic?arabicStyle(style):style,textAlign:textAlign,textDirection:textDirection??(numeric?TextDirection.ltr:null),
   maxLines:maxLines,softWrap:softWrap,overflow:overflow,
   semanticsLabel:semanticsLabel==null?null:tr(context,semanticsLabel!));
 }
}
