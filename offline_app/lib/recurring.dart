import 'dart:convert';
import 'finance.dart';

/// Recurring rules live in the settings table as JSON, so backups carry them
/// without a database or backup-format change.
const recurringSettingKey='recurring_rules';

class RecurringRule {
 const RecurringRule({required this.id,required this.type,required this.category,required this.description,
  required this.amount,required this.day,required this.start,this.last,this.account});
 final String id,type,category,description,start;
 final String? last; // last month already created, YYYY-MM
 final int amount,day;
 final String? account; // wallet for new entries, when wallets are on
 Map<String,Object?> toJson()=>{'id':id,'type':type,'category':category,'description':description,
  'amount':amount,'day':day,'start':start,'last':last,if(account!=null)'account':account};
 factory RecurringRule.fromJson(Map<String,dynamic> m)=>RecurringRule(id:'${m['id']}',type:'${m['type']}',
  category:'${m['category']}',description:'${m['description']??''}',amount:(m['amount'] as num).toInt(),
  day:(m['day'] as num).toInt(),start:'${m['start']}',last:m['last'] as String?,
  account:m['account']=='Bank'||m['account']=='Cash'?m['account'] as String:null);
 RecurringRule withLast(String month)=>RecurringRule(id:id,type:type,category:category,description:description,
  amount:amount,day:day,start:start,last:month,account:account);
 bool get valid=>['Income','Expense','Savings out','Savings in'].contains(type)&&validMoney(amount)&&
  day>=1&&day<=28&&RegExp(r'^\d{4}-\d{2}$').hasMatch(start)&&category.isNotEmpty;
}

List<RecurringRule> decodeRules(String? raw){
 if(raw==null||raw.isEmpty)return [];
 try{
  final value=jsonDecode(raw);
  if(value is! List)return [];
  return value.whereType<Map<String,dynamic>>().map(RecurringRule.fromJson).where((r)=>r.valid).toList();
 }catch(_){return [];}
}
String encodeRules(List<RecurringRule> rules)=>jsonEncode(rules.map((r)=>r.toJson()).toList());

class RecurringEntry {
 const RecurringEntry(this.rule,this.month,this.date);
 final RecurringRule rule;
 final String month,date;
}

/// Entries due up to today that were not created yet. Closed months are skipped:
/// nothing is ever added behind a confirmed month close.
List<RecurringEntry> dueRecurringEntries(List<RecurringRule> rules,DateTime now,Set<String> closedMonths){
 final today=dayKey(now),out=<RecurringEntry>[];
 for(final rule in rules){
  var m=monthFromKey(rule.start);
  if(rule.last!=null){final l=monthFromKey(rule.last!);m=DateTime(l.year,l.month+1);}
  for(var guard=0;guard<240;guard++){
   final date=dayKey(DateTime(m.year,m.month,rule.day));
   if(date.compareTo(today)>0)break;
   final key=monthKey(m);
   if(!closedMonths.contains(key))out.add(RecurringEntry(rule,key,date));
   m=DateTime(m.year,m.month+1);
  }
 }
 return out;
}
