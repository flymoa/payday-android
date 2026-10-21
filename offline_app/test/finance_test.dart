import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
void main() {
 test('month keys include year', () {
  expect(monthKey(DateTime(2026,1,31)), '2026-01');
  expect(monthKey(DateTime(2027,1,1)), '2027-01');
 });
 test('partial payment reduces bill balance', () {
  expect(billOutstanding(250000,100000),150000);
  expect(billOutstanding(250000,300000),0);
 });
 test('goals do not create new savings',(){
  final pool=savingsPool(opening:10000,transferredOut:120000,transferredIn:20000,confirmedExtra:30000);
  expect(pool,140000);
  expect(availableAllocation(pool,40000),100000);
 });
 test('reserves spread target over due months',(){
  expect(monthlyReserveTopUp(240000,0,DateTime(2027,3),DateTime(2027,1)),80000);
 });
 test('cash calculation holds bills, savings and buffer',(){
  expect(freeAfterPlan(income:1000000,expenses:300000,transferredOut:100000,transferredIn:0,unpaidBills:200000,savingsGap:50000,reserves:30000,buffer:20000),300000);
 });
}
