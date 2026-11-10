/// Plain CSV of all transactions, for spreadsheets. Not encrypted.
const csvHeader=['date','type','category','description','amount','note','bill_id'];

/// Text that a spreadsheet could run as a formula is prefixed with an apostrophe.
String csvCell(Object? value,{bool text=true}){
 var s=value?.toString()??'';
 if(text&&s.isNotEmpty&&'=+-@\t\r'.contains(s[0]))s="'$s";
 if(s.contains(RegExp(r'[",\n\r]')))s='"${s.replaceAll('"','""')}"';
 return s;
}
String csvAmount(Object? cents){
 final v=(cents as num?)?.toInt()??0;
 final a=v.abs();
 return '${v<0?'-':''}${a~/100}.${(a%100).toString().padLeft(2,'0')}';
}
/// Sorted by date, then entry order. Starts with a UTF-8 BOM so Excel shows Arabic and accents.
String transactionsCsv(Iterable<Map<String,Object?>> rows){
 final sorted=rows.toList()..sort((a,b){
  final d='${a['date']}'.compareTo('${b['date']}');
  return d!=0?d:((a['id'] as num?)??0).compareTo((b['id'] as num?)??0);
 });
 final lines=<String>[csvHeader.join(',')];
 for(final r in sorted){
  lines.add([csvCell(r['date']),csvCell(r['type']),csvCell(r['category']),csvCell(r['description']),
   csvAmount(r['amount']),csvCell(r['note']),csvCell(r['bill_id'])].join(','));
 }
 return '﻿${lines.join('\r\n')}\r\n';
}
