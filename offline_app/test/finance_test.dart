import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
void main() {
 test('category budget colors use correct boundaries',(){
  expect(categoryBudgetStatus(0,10000),CategoryBudgetStatus.withinBudget);
  expect(categoryBudgetStatus(8499,10000),CategoryBudgetStatus.withinBudget);
  expect(categoryBudgetStatus(8500,10000),CategoryBudgetStatus.nearLimit);
  expect(categoryBudgetStatus(10000,10000),CategoryBudgetStatus.nearLimit);
  expect(categoryBudgetStatus(10001,10000),CategoryBudgetStatus.overBudget);
  expect(categoryBudgetStatus(2500,0),CategoryBudgetStatus.unbudgeted);
 });
 test('month keys include year', () {
  expect(monthKey(DateTime(2026,1,31)), '2026-01');
  expect(monthKey(DateTime(2027,1,1)), '2027-01');
 });
 test('partial payment reduces bill balance', () {
  expect(billOutstanding(250000,100000),150000);
  expect(billOutstanding(250000,300000),0);
 });
 test('bill payment prefill copies the bill and defaults to its full amount',(){
  final draft=prepareBillPayment(
   name:'October rent',category:'Housing',code:'B0123',
   billAmountCents:250000,alreadyPaidCents:0,
  );
  expect(draft.type,'Expense');
  expect(draft.category,'Housing');
  expect(draft.description,'October rent');
  expect(draft.billId,'B0123');
  expect(draft.amountCents,250000);
 });
 test('bill payment prefill uses only the unpaid remainder',(){
  final draft=prepareBillPayment(
   name:'Electricity',category:'Utilities',code:'B0124',
   billAmountCents:47000,alreadyPaidCents:20000,
  );
  expect(draft.amountCents,27000);
  final paid=prepareBillPayment(
   name:'Electricity',category:'Utilities',code:'B0124',
   billAmountCents:47000,alreadyPaidCents:47000,
  );
  expect(paid.amountCents,0);
 });
 test('goals do not create new savings',(){
  final pool=savingsPool(opening:10000,transferredOut:120000,transferredIn:20000,confirmedExtra:30000);
  expect(pool,140000);
  expect(availableAllocation(pool,40000),100000);
 });
 test('reserves spread target over due months',(){
  expect(monthlyReserveTopUp(240000,0,DateTime(2027,3),DateTime(2027,1)),80000);
 });
 test('reserve deposits reduce spendable money, not expense totals',(){
  expect(reserveBalance(opening:0,deposits:30000,withdrawals:0),30000);
  expect(reserveNetSetAside(deposits:30000,withdrawals:0),30000);
  expect(freeAfterPlan(
   income:200000,expenses:50000+reserveNetSetAside(deposits:30000,withdrawals:0),
   transferredOut:0,transferredIn:0,unpaidBills:0,savingsGap:0,
   reserves:0,buffer:0),120000);
 });
 test('reserve withdrawals restore spendable cash',(){
  expect(reserveBalance(opening:10000,deposits:30000,withdrawals:15000),25000);
  expect(reserveNetSetAside(deposits:30000,withdrawals:15000),15000);
 });
 test('reserve does not double-count paid and planned top-up',(){
  // Goal 1,200 MAD due in 4 months; deposit 200 MAD this month.
  expect(reserveAdditionalHold(
   target:120000,fundedBeforeMonth:0,netContributedThisMonth:20000,
   due:DateTime(2027,4),month:DateTime(2027,1)),10000);
  // Deposit plus remaining hold equals 300 MAD, not 500 MAD.
  expect(20000+reserveAdditionalHold(
   target:120000,fundedBeforeMonth:0,netContributedThisMonth:20000,
   due:DateTime(2027,4),month:DateTime(2027,1)),30000);
 });
 test('reserve next month target recalculates from funded balance',(){
  expect(reserveNextMonthTopUp(
   target:120000,currentlyFunded:30000,
   due:DateTime(2027,4),selectedMonth:DateTime(2027,1)),30000);
  expect(reserveNextMonthTopUp(
   target:120000,currentlyFunded:120000,
   due:DateTime(2027,4),selectedMonth:DateTime(2027,1)),0);
  expect(reserveNextMonthTopUp(
   target:120000,currentlyFunded:30000,
   due:DateTime(2027,1),selectedMonth:DateTime(2027,1)),0);
 });
 test('cash calculation holds bills, savings and buffer',(){
  expect(freeAfterPlan(income:1000000,expenses:300000,transferredOut:100000,transferredIn:0,unpaidBills:200000,savingsGap:50000,reserves:30000,buffer:20000),300000);
 });
}
