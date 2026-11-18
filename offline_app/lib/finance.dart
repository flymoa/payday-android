/// Pure finance calculations (amounts are integer centimes to avoid rounding drift).
String monthKey(DateTime date) => '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}';
DateTime monthFromKey(String key) => DateTime(int.parse(key.substring(0,4)), int.parse(key.substring(5,7)));
String dayKey(DateTime date) => '${monthKey(date)}-${date.day.toString().padLeft(2,'0')}';
int toCents(String input) => ((double.tryParse(input.trim().replaceAll(',','.')) ?? double.nan)*100).round();
double mad(int cents) => cents / 100.0;
bool validMoney(int cents) => cents > 0 && cents <= 100000000000;
int billOutstanding(int total, int payments) => (total-payments).clamp(0,total);
int savingsPool({required int opening,required int transferredOut,required int transferredIn,required int confirmedExtra}) => opening+transferredOut-transferredIn+confirmedExtra;
int availableAllocation(int pool,int allocated) => pool-allocated;
int remainingBudget(int budget,int spent) => budget-spent;
int monthlyReserveTopUp(int target,int funded,DateTime due,DateTime start) {
 final remaining=(target-funded).clamp(0,100000000000);
 final months=((due.year-start.year)*12+due.month-start.month+1).clamp(1,1000);
 return (remaining / months).ceil();
}
int freeAfterPlan({required int income,required int expenses,required int transferredOut,required int transferredIn,required int unpaidBills,required int savingsGap,required int reserves,required int buffer}) =>
 income-expenses-transferredOut+transferredIn-unpaidBills-savingsGap-reserves-buffer;


/// Prepares a new expense from a saved bill. The due date is deliberately not
/// copied: payment date is the day the user chooses (initially today).
/// Any subsequent edits in the transaction form are allowed.
class BillPaymentDraft {
 const BillPaymentDraft({
  required this.type,
  required this.category,
  required this.description,
  required this.billId,
  required this.amountCents,
 });
 final String type;
 final String category;
 final String description;
 final String billId;
 final int amountCents;
}

BillPaymentDraft prepareBillPayment({
 required String name,
 required String category,
 required String code,
 required int billAmountCents,
 required int alreadyPaidCents,
}) => BillPaymentDraft(
 type: 'Expense',
 category: category,
 description: name,
 billId: code,
 amountCents: billOutstanding(billAmountCents,alreadyPaidCents),
);


/// Money in a reserve is ring-fenced cash, not a new expense.
/// Opening funded money was already put aside before recording began.
int reserveBalance({required int opening,required int deposits,required int withdrawals}) =>
 opening+deposits-withdrawals;

/// Positive amount is removed from spendable cash; withdrawals reverse that transfer.
int reserveNetSetAside({required int deposits,required int withdrawals})=>deposits-withdrawals;

/// Remaining monthly amount to ring-fence after this month's actual deposits.
/// An explicit reserve transfer must not also be counted as an ordinary expense.
int reserveAdditionalHold({
 required int target,
 required int fundedBeforeMonth,
 required int netContributedThisMonth,
 required DateTime due,
 required DateTime month,
}){
 if(DateTime(due.year,due.month).isBefore(DateTime(month.year,month.month)))return 0;
 final expected=monthlyReserveTopUp(target,fundedBeforeMonth,due,month);
 return (expected-netContributedThisMonth).clamp(0,100000000000);
}

/// The following month's suggested contribution uses the *new* funded balance.
int reserveNextMonthTopUp({
 required int target,
 required int currentlyFunded,
 required DateTime due,
 required DateTime selectedMonth,
}){
 final next=DateTime(selectedMonth.year,selectedMonth.month+1);
 if(DateTime(due.year,due.month).isBefore(next))return 0;
 return monthlyReserveTopUp(target,currentlyFunded,due,next);
}


/// Visual budget status for the Home dashboard. Unbudgeted spending is not
/// silently treated as healthy, and exactly 100% remains at the limit.
enum CategoryBudgetStatus { withinBudget, nearLimit, fullySpent, overBudget, unbudgeted }

/// True when, in the current month, a category has used noticeably more of its
/// budget than the share of the month that has passed (before it is near the limit).
bool spendingAheadOfPace({required int spent,required int budget,required DateTime month,required DateTime now}){
 if(budget<=0||spent<=0||month.year!=now.year||month.month!=now.month)return false;
 if(spent*100>=budget*85)return false;
 final days=DateTime(now.year,now.month+1,0).day;
 return spent/budget>now.day/days+.15;
}

CategoryBudgetStatus categoryBudgetStatus(int spent,int budget){
 if(budget<=0)return CategoryBudgetStatus.unbudgeted;
 if(spent>budget)return CategoryBudgetStatus.overBudget;
 if(spent==budget)return CategoryBudgetStatus.fullySpent;
 if(spent*100>=budget*85)return CategoryBudgetStatus.nearLimit;
 return CategoryBudgetStatus.withinBudget;
}


/// Map Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits to ASCII,
/// the Arabic decimal separator (٫) to a dot, and drop the Arabic thousands
/// separator (٬), so an amount typed on an Arabic keyboard is accepted.
String normalizeDigits(String input){
 final out=StringBuffer();
 for(final r in input.runes){
  if(r>=0x0660&&r<=0x0669){out.writeCharCode(0x30+r-0x0660);}
  else if(r>=0x06F0&&r<=0x06F9){out.writeCharCode(0x30+r-0x06F0);}
  else if(r==0x066B){out.write('.');}
  else if(r!=0x066C){out.writeCharCode(r);}
 }
 return out.toString();
}

/// Accept decimal dirhams with a dot or comma and at most two decimal places.
/// Reject ambiguous thousands separators, rounding and non-finite values.
int? parseMoneyCents(String input,{bool allowZero=false}) {
 final text=normalizeDigits(input).trim();
 if(!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(text))return null;
 final parts=text.replaceAll(',','.').split('.');
 final whole=int.tryParse(parts[0]);
 if(whole==null||whole>1000000000)return null;
 final fraction=parts.length==1?0:int.parse(parts[1].padRight(2,'0'));
 final cents=whole*100+fraction;
 if(cents>100000000000||(!allowZero&&cents==0))return null;
 return cents;
}

bool matchesRecord(Map<String,Object?> row,String query,String type) {
 if(type!='All'&&row['type']!=type)return false;
 final text=query.trim().toLowerCase();
 return text.isEmpty||['description','category','note','bill_id','date']
  .any((key)=>(row[key]?.toString()??'').toLowerCase().contains(text));
}


/// All category budgets and the monthly savings goal share the income plan.
/// Existing amounts are replaced when editing; months and years stay isolated.
int assignedBudgetCents(Iterable<Map<String,Object?>> rows,String month) =>
 rows.where((r)=>r['month']==month&&r['category']!='Income plan')
  .fold<int>(0,(sum,r)=>sum+(r['amount'] as num).toInt());

String _budgetMoney(int cents) =>
 '${cents~/100}.${(cents%100).toString().padLeft(2,'0')} MAD';

class BudgetAssignmentCheck {
 const BudgetAssignmentCheck({required this.income,required this.assigned,
  required this.otherAssigned,required this.proposed,required this.incomeEdit});
 final int income,assigned,otherAssigned,proposed;
 final bool incomeEdit;
 bool get allowed=>assigned<=income;
 int get remaining=>income-assigned;
 int get maximum=>(income-otherAssigned).clamp(0,100000000000).toInt();
 int get exceededBy=>(assigned-income).clamp(0,100000000000).toInt();
 bool get fullyAssigned=>allowed&&income>0&&remaining==0;
 String get message {
  if(incomeEdit) {
   return 'Planned income cannot be lower than your assigned budget. '
    'Minimum planned income: ${_budgetMoney(assigned)}. '
    'You are short by ${_budgetMoney(exceededBy)}.';
  }
  if(otherAssigned>income) {
   return 'Other budgets already exceed planned income by '
    '${_budgetMoney(otherAssigned-income)}. Reduce those budgets or '
    'increase planned income before saving this category.';
  }
  final intro=income==0?'Set planned income before assigning money. ': 
   maximum==0?'No more money to assign. ':'';
  return '${intro}Maximum total for this category: ${_budgetMoney(maximum)}. '
   'You exceeded this limit by ${_budgetMoney(exceededBy)}.';
 }
}

BudgetAssignmentCheck checkBudgetAssignment({
 required Iterable<Map<String,Object?>> rows,required String month,
 required String category,required int proposed,
}) {
 if(proposed<0||proposed>100000000000)throw ArgumentError('Invalid budget amount');
 final chosen=rows.where((r)=>r['month']==month).toList();
 final income=chosen.where((r)=>r['category']=='Income plan')
  .fold<int>(0,(sum,r)=>sum+(r['amount'] as num).toInt());
 final existing=chosen.where((r)=>r['category']==category)
  .fold<int>(0,(sum,r)=>sum+(r['amount'] as num).toInt());
 final assigned=assignedBudgetCents(chosen,month);
 final incomeEdit=category=='Income plan';
 final other=incomeEdit?assigned:assigned-existing;
 return BudgetAssignmentCheck(income:incomeEdit?proposed:income,
  assigned:incomeEdit?assigned:other+proposed,
  otherAssigned:other,proposed:proposed,incomeEdit:incomeEdit);
}

class BudgetAssignmentException implements Exception {
 const BudgetAssignmentException(this.check);
 final BudgetAssignmentCheck check;
 @override String toString()=>check.message;
}


/// One source for the dashboard balances and their itemized explanation.
/// Net transfers may be negative when money is withdrawn back into cash.
class MonthlyBalance {
 const MonthlyBalance({required this.income,required this.expenses,
  required this.savingsNet,required this.reserveNet,required this.unpaidBills,
  required this.savingsGap,required this.reserveHold,required this.buffer});
 final int income,expenses,savingsNet,reserveNet,unpaidBills,savingsGap,reserveHold,buffer;
 int get available=>income-expenses-savingsNet-reserveNet;
 /// Money released from savings/reserves is available to spend again.
 int get fundsReceived=>income+(savingsNet<0?-savingsNet:0)+(reserveNet<0?-reserveNet:0);
 int get fundsUsed=>expenses+(savingsNet>0?savingsNet:0)+(reserveNet>0?reserveNet:0);
 double get usedFraction=>fundsUsed<=0?0:fundsReceived<=0?1:
  (fundsUsed/fundsReceived).clamp(0,1).toDouble();
 int get safe=>freeAfterPlan(income:income,expenses:expenses+reserveNet,
  transferredOut:savingsNet,transferredIn:0,unpaidBills:unpaidBills,
  savingsGap:savingsGap,reserves:reserveHold,buffer:buffer);
}


/// Copies missing entries only. Existing entries, including explicit zeroes, win.
class BudgetCopyPlan {
 BudgetCopyPlan(Iterable<Map<String,Object?>> rows,this.month){
  final date=monthFromKey(month);
  sourceMonth=monthKey(DateTime(date.year,date.month-1));
  final target=rows.where((r)=>r['month']==month).toList();
  final existing=target.map((r)=>r['category']).toSet();
  additions=rows.where((r)=>r['month']==sourceMonth&&!existing.contains(r['category']))
   .map((r)=><String,Object?>{'month':month,'category':r['category'],'amount':r['amount']}).toList()
   ..sort((a,b)=>(a['category'] as String).compareTo(b['category'] as String));
  final merged=[...target,...additions];
  income=merged.where((r)=>r['category']=='Income plan').fold(0,(n,r)=>n+(r['amount'] as num).toInt());
  assigned=assignedBudgetCents(merged,month);
 }
 final String month;
 late final String sourceMonth;
 late final List<Map<String,Object?>> additions;
 late final int income,assigned;
 bool get allowed=>assigned<=income;
 int get exceededBy=>assigned-income;
}

/// Stable snapshot of both months so a preview cannot apply changed data.
String budgetCopyState(Iterable<Map<String,Object?>> rows,String month){
 final date=monthFromKey(month);
 final previous=monthKey(DateTime(date.year,date.month-1));
 final values=rows.where((r)=>r['month']==month||r['month']==previous)
  .map((r)=>'${r['month']}:${r['category'].toString().length}:${r['category']}:${r['amount']}').toList()..sort();
 return values.join('\n');
}


/// Preserve the day where possible; never overflow a short month.
DateTime nextBillDue(DateTime due){
 final last=DateTime(due.year,due.month+2,0).day;
 return DateTime(due.year,due.month+1,due.day>last?last:due.day);
}


/// Guidance is a suggestion only: actual deposits must still be recorded.
int reserveThisMonthRemaining({required int target,required int fundedBeforeMonth,
 required int netContributedThisMonth,required DateTime due,
 required DateTime start,required DateTime month}){
 final key=monthKey(month);
 if(key.compareTo(monthKey(start))<0||key.compareTo(monthKey(due))>0)return 0;
 final needed=(target-fundedBeforeMonth-netContributedThisMonth).clamp(0,target);
 return reserveAdditionalHold(target:target,fundedBeforeMonth:fundedBeforeMonth,
  netContributedThisMonth:netContributedThisMonth,due:due,month:month).clamp(0,needed);
}


/// Aggregate only the already-selected month's expense rows.
class MonthlyReview {
 MonthlyReview(Iterable<Map<String,Object?>> transactions){
  for(final row in transactions){
   if(row['type']!='Expense')continue;
   final name=row['category']?.toString()??'';
   spending[name]=(spending[name]??0)+(row['amount'] as num).toInt();
  }
 }
 final Map<String,int> spending={};
 List<String> get rankedCategories=>spending.keys.toList()..sort((a,b){
  final difference=spending[b]!.compareTo(spending[a]!);
  return difference==0?a.compareTo(b):difference;
 });
}


/// Reminder dates describe successful export handoffs, not cloud verification.
class BackupReminder {
 BackupReminder({required this.now,required this.hasData,String? lastExport,String? snoozeUntil})
  :lastExport=DateTime.tryParse(lastExport??''),snoozeUntil=DateTime.tryParse(snoozeUntil??'');
 final DateTime now;
 final bool hasData;
 final DateTime? lastExport,snoozeUntil;
 bool get due=>hasData&&(lastExport==null||lastExport!.isAfter(now)||now.difference(lastExport!)>=const Duration(days:7));
 bool get visible=>due&&!(snoozeUntil?.isAfter(now)??false);
}


/// Home shows only the current and previous local calendar day, across months.
List<Map<String,Object?>> recentActivityRows(Iterable<Map<String,Object?>> rows,DateTime now){
 final today=dayKey(now),yesterday=dayKey(DateTime(now.year,now.month,now.day-1));
 final selected=rows.where((r)=>r['date']==today||r['date']==yesterday).toList();
 selected.sort((a,b){
  final date=b['date'].toString().compareTo(a['date'].toString());
  if(date!=0)return date;
  return ((b['id'] as num?)?.toInt()??0).compareTo((a['id'] as num?)?.toInt()??0);
 });
 return selected;
}
String recentActivityDay(String date,DateTime now)=>date==dayKey(now)?'Today':'Yesterday';



/// Straight-line month-end forecast from spending so far. Null for past or
/// future months, and before any spending (no basis for a forecast).
int? projectedMonthSpend({required int spentSoFar,required DateTime month,required DateTime now}){
 if(month.year!=now.year||month.month!=now.month||spentSoFar<=0)return null;
 final days=DateTime(now.year,now.month+1,0).day;
 return (spentSoFar*days/now.day).round();
}

/// Total Expense amount of one category in one month (YYYY-MM).
int categoryMonthTotal(Iterable<Map<String,Object?>> transactions,String category,String month)=>transactions
 .where((t)=>t['type']=='Expense'&&t['category']==category&&(t['date']?.toString()??'').startsWith(month))
 .fold(0,(n,t)=>n+((t['amount'] as num?)?.toInt()??0));

enum BudgetCrossing { nearLimit, overBudget }

/// Reports only the save that crosses a threshold (85% or over budget),
/// so the warning appears once rather than on every later expense.
BudgetCrossing? budgetCrossing({required int before,required int after,required int budget}){
 if(budget<=0||after<=before)return null;
 if(after>budget&&before<=budget)return BudgetCrossing.overBudget;
 if(after<=budget&&after*100>=budget*85&&before*100<budget*85)return BudgetCrossing.nearLimit;
 return null;
}
