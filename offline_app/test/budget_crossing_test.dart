import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';

void main() {
  test('warns once when a save crosses 85% or the budget', () {
    expect(budgetCrossing(before: 8000, after: 8600, budget: 10000), BudgetCrossing.nearLimit);
    expect(budgetCrossing(before: 8600, after: 9000, budget: 10000), isNull, reason: 'already near');
    expect(budgetCrossing(before: 9000, after: 10500, budget: 10000), BudgetCrossing.overBudget);
    expect(budgetCrossing(before: 10500, after: 11000, budget: 10000), isNull, reason: 'already over');
    expect(budgetCrossing(before: 1000, after: 12000, budget: 10000), BudgetCrossing.overBudget);
    expect(budgetCrossing(before: 9000, after: 10000, budget: 10000), isNull, reason: 'exactly at limit is not over');
    expect(budgetCrossing(before: 1000, after: 2000, budget: 0), isNull, reason: 'no budget');
    expect(budgetCrossing(before: 9000, after: 8000, budget: 10000), isNull, reason: 'edit lowered spending');
  });
}
