import 'dart:convert';
import 'finance.dart';

typedef LedgerRow=Map<String,Object?>;

/// Read-only money rules over one database snapshot. Moved out of the UI so
/// every rule is unit tested; behaviour matches the previous screen code.
class Ledger {
 const Ledger(this.data);
 final Map<String,List<LedgerRow>> data;
 static String _s(LedgerRow r,String k)=>r[k]?.toString()??'';
 static int _v(LedgerRow r,String k)=>(r[k] as num?)?.toInt()??0;
 List<LedgerRow> rows(String table)=>data[table]??[];
 String? setting(String key)=>rows('settings').where((r)=>_s(r,'key')==key).firstOrNull?['value']?.toString();

 List<LedgerRow> monthTransactions(String month)=>rows('transactions').where((t)=>_s(t,'date').startsWith(month)).toList();
 static int sumType(Iterable<LedgerRow> tx,String type)=>tx.where((t)=>_s(t,'type')==type).fold(0,(n,t)=>n+_v(t,'amount'));
 /// Budget as planned on the Budgets screen (no carry-over). Use this to edit plans.
 int plannedBudget(String month,String category)=>rows('budgets').where((x)=>_s(x,'month')==month&&_s(x,'category')==category).fold(0,(n,x)=>n+_v(x,'amount'));
 /// Spending limit for a month: the plan plus any unspent budget carried in.
 int budgetFor(String month,String category)=>plannedBudget(month,category)+carriedInto(month,category);
 static const notCarried={'Income plan','Savings goal'};
 Map<String,int> carriedIntoMonth(String month){
  try{
   final raw=jsonDecode(setting(budgetCarryKey(month))??'{}');
   if(raw is! Map)return {};
   return {for(final e in raw.entries)if(e.value is num&&(e.value as num)>0)'${e.key}':(e.value as num).toInt()};
  }catch(_){return {};}
 }
 int carriedInto(String month,String category)=>notCarried.contains(category)?0:carriedIntoMonth(month)[category]??0;
 /// Unspent amount per budgeted spending category (only positive amounts).
 Map<String,int> unspentBudgets(String month){
  final spent=<String,int>{};
  for(final t in monthTransactions(month).where((t)=>_s(t,'type')=='Expense')){spent[_s(t,'category')]=(spent[_s(t,'category')]??0)+_v(t,'amount');}
  final cats=rows('budgets').where((r)=>_s(r,'month')==month).map((r)=>_s(r,'category')).toSet()..removeAll(notCarried);
  final out=<String,int>{};
  for(final c in cats){final left=budgetFor(month,c)-(spent[c]??0);if(left>0)out[c]=left;}
  return out;
 }
 int billPaid(LedgerRow bill)=>rows('transactions').where((x)=>_s(x,'type')=='Expense'&&_s(x,'bill_id')==_s(bill,'code')).fold(0,(n,x)=>n+_v(x,'amount'));
 /// Date of the latest payment recorded against [bill], or null if none.
 String? billPaidOn(LedgerRow bill){
  final dates=rows('transactions').where((x)=>_s(x,'type')=='Expense'&&_s(x,'bill_id')==_s(bill,'code')).map((x)=>_s(x,'date')).where((d)=>d.isNotEmpty).toList()..sort();
  return dates.isEmpty?null:dates.last;
 }
 /// Whether [bill] belongs to [month]: due in that month, or due earlier and
 /// still owed. An unpaid bill stays visible until it is paid, so it never
 /// drops out of "still to pay" when the month changes.
 bool billCountsFor(LedgerRow bill,String month){
  final due=_s(bill,'due');
  if(due.isEmpty)return false;
  if(due.startsWith(month))return true;
  return due.compareTo(month)<0&&billOutstanding(_v(bill,'amount'),billPaid(bill))>0;
 }
 int unpaidBills(String month)=>rows('bills').where((b)=>billCountsFor(b,month)).fold(0,(n,b)=>n+billOutstanding(_v(b,'amount'),billPaid(b)));
 int totalPool(){
  final ts=rows('transactions');
  final extra=rows('month_closes').where((x)=>_v(x,'entries_ok')==1&&_v(x,'balance_ok')==1).fold(0,(n,x)=>n+_v(x,'extra'));
  return savingsPool(opening:int.tryParse(setting('opening_savings')??'')??0,transferredOut:sumType(ts,'Savings out'),
   transferredIn:sumType(ts,'Savings in'),confirmedExtra:extra);
 }
 int allocated()=>rows('allocations').fold(0,(n,x)=>n+_v(x,'amount'));
 int buffer()=>int.tryParse(setting('buffer')??'')??20000;

 List<LedgerRow> reserveHistory(int reserveId){
  final out=rows('reserve_movements').where((r)=>_v(r,'reserve_id')==reserveId).toList();
  out.sort((a,b){final d=_s(b,'date').compareTo(_s(a,'date'));return d!=0?d:_v(b,'id').compareTo(_v(a,'id'));});
  return out;
 }
 static int _signed(LedgerRow r)=>_s(r,'kind')=='add'?_v(r,'amount'):-_v(r,'amount');
 int reserveNetForMonth(String month,{int? reserveId})=>rows('reserve_movements')
  .where((r)=>_s(r,'date').startsWith(month)&&(reserveId==null||_v(r,'reserve_id')==reserveId)).fold(0,(n,r)=>n+_signed(r));
 int reserveFundedAt(LedgerRow reserve,String thruMonth){
  final m=monthFromKey(thruMonth),lastDay=dayKey(DateTime(m.year,m.month+1,0)),id=_v(reserve,'id');
  return _v(reserve,'funded')+rows('reserve_movements').where((r)=>_v(r,'reserve_id')==id&&_s(r,'date').compareTo(lastDay)<=0).fold(0,(n,r)=>n+_signed(r));
 }
 int monthlyReserves(String month){
  final chosen=monthFromKey(month),preceding=monthKey(DateTime(chosen.year,chosen.month-1));
  return rows('reserves').where((r)=>_s(r,'start_month').compareTo(month)<=0&&_s(r,'due').substring(0,7).compareTo(month)>=0)
   .fold(0,(n,r)=>n+reserveAdditionalHold(target:_v(r,'target'),fundedBeforeMonth:reserveFundedAt(r,preceding),
    netContributedThisMonth:reserveNetForMonth(month,reserveId:_v(r,'id')),
    due:DateTime.tryParse(_s(r,'due'))??DateTime.now(),month:chosen));
 }
}

String budgetCarryKey(String month)=>'budget_carry_$month';
