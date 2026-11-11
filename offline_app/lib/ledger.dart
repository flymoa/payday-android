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
 int budgetFor(String month,String category)=>rows('budgets').where((x)=>_s(x,'month')==month&&_s(x,'category')==category).fold(0,(n,x)=>n+_v(x,'amount'));
 int billPaid(LedgerRow bill)=>rows('transactions').where((x)=>_s(x,'type')=='Expense'&&_s(x,'bill_id')==_s(bill,'code')).fold(0,(n,x)=>n+_v(x,'amount'));
 int unpaidBills(String month)=>rows('bills').where((b)=>_s(b,'due').startsWith(month)).fold(0,(n,b)=>n+billOutstanding(_v(b,'amount'),billPaid(b)));
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
