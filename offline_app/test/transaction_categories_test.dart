import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/transaction_categories.dart';
void main(){
 const configured=['Groceries','Housing','Salary','Savings'];
 const history=[
  {'type':'Income','category':'Salary'},
  {'type':'Income','category':'Consulting'},
  {'type':'Expense','category':'Pharmacy'},
  {'type':'Savings in','category':'Savings'},
  {'type':'Income','category':'Groceries'},
 ];
 test('each transaction group shows relevant categories',(){
  final income=transactionCategories(type:'Income',configured:configured,history:history);
  expect(income,containsAll(['Salary','Consulting','Freelance']));expect(income, isNot(contains('Groceries')));expect(income,isNot(contains('Housing')));
  final expense=transactionCategories(type:'Expense',configured:configured,history:history);
  expect(expense,containsAll(['Groceries','Housing','Pharmacy']));expect(expense,isNot(contains('Salary')));expect(expense,isNot(contains('Savings')));
  final savings=transactionCategories(type:'Savings out',configured:configured,history:history);
  expect(savings,['Savings']);
 });
 test('editing a legacy record retains its category without rewriting it',(){
  final values=transactionCategories(type:'Income',configured:configured,history:history,existingCategory:'Housing');
  expect(values,contains('Housing'));
 });
 test('empty expense configuration still has an expense category',(){
  expect(transactionCategories(type:'Expense',configured:[],history:[]),['Groceries']);
 });
}
