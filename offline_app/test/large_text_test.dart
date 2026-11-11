import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';

Map<String, List<RowData>> sample() {
  final m = monthKey(DateTime.now());
  return {
    'transactions': [
      {'id': 1, 'date': '$m-01', 'type': 'Income', 'category': 'Salary', 'description': 'Monthly salary', 'amount': 1234567, 'note': '', 'bill_id': ''},
      {'id': 2, 'date': '$m-02', 'type': 'Expense', 'category': 'Groceries', 'description': 'A rather long supermarket description that keeps going', 'amount': 98765, 'note': '', 'bill_id': ''},
      {'id': 3, 'date': '$m-03', 'type': 'Expense', 'category': 'Eating out', 'description': '', 'amount': 4500, 'note': '', 'bill_id': ''},
    ],
    'budgets': [
      {'month': m, 'category': 'Income plan', 'amount': 1500000},
      {'month': m, 'category': 'Groceries', 'amount': 90000},
      {'month': m, 'category': 'Eating out', 'amount': 20000},
    ],
    'categories': [
      {'name': 'Groceries', 'group_name': 'Essential'},
      {'name': 'Eating out', 'group_name': 'Flexible'},
    ],
    'goals': [{'id': 1, 'name': 'Emergency fund', 'target': 2000000}],
    'bills': [{'id': 1, 'code': 'NET', 'name': 'Internet', 'due': '$m-20', 'amount': 30000, 'category': 'Utilities', 'note': ''}],
    'settings': [],
  };
}

void main() {
  for (final language in ['en', 'fr', 'ar']) {
    testWidgets('every main tab fits at double text size on a small phone ($language)', (t) async {
      await t.binding.setSurfaceSize(const Size(360, 780));
      t.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await t.pumpWidget(PaydayLocal(
          initialData: Future.value(sample()),
          preferencesWriter: (_) async {},
          initialPreferences: AppPreferences(language: language)));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'Home');
      for (final tab in [1, 2, 3]) {
        final items = find.byKey(ValueKey('bottom-$tab'));
        if (items.evaluate().isEmpty) continue;
        await t.tap(items.first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'tab $tab');
      }
    });
  }
}
