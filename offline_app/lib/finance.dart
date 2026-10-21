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
enum CategoryBudgetStatus { withinBudget, nearLimit, overBudget, unbudgeted }

CategoryBudgetStatus categoryBudgetStatus(int spent,int budget){
 if(budget<=0)return CategoryBudgetStatus.unbudgeted;
 if(spent>budget)return CategoryBudgetStatus.overBudget;
 if(spent*100>=budget*85)return CategoryBudgetStatus.nearLimit;
 return CategoryBudgetStatus.withinBudget;
}


/// Accept decimal dirhams with a dot or comma and at most two decimal places.
/// Reject ambiguous thousands separators, rounding and non-finite values.
int? parseMoneyCents(String input,{bool allowZero=false}) {
 final text=input.trim();
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
