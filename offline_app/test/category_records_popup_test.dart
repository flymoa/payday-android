import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';

void main() {
  testWidgets('tapping a Home budget card shows that category\'s records in a pop-up', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 2000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final m = monthKey(DateTime.now());
    final data = <String, List<RowData>>{
      'categories': [
        {'name': 'Groceries', 'group_name': 'Essential'},
        {'name': 'Housing', 'group_name': 'Essential'},
      ],
      'budgets': [
        {'month': m, 'category': 'Groceries', 'amount': 100000},
        {'month': m, 'category': 'Housing', 'amount': 200000},
      ],
      'transactions': [
        {'id': 1, 'date': '$m-02', 'type': 'Expense', 'category': 'Groceries', 'description': 'Market run', 'amount': 2500, 'note': '', 'bill_id': ''},
        {'id': 2, 'date': '$m-03', 'type': 'Expense', 'category': 'Groceries', 'description': 'Bakery', 'amount': 900, 'note': '', 'bill_id': ''},
        {'id': 3, 'date': '$m-04', 'type': 'Expense', 'category': 'Housing', 'description': 'Rent', 'amount': 150000, 'note': '', 'bill_id': ''},
      ],
    };
    await t.pumpWidget(MaterialApp(home: FinanceScreen(initialData: Future.value(data))));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('home-category-Groceries')));
    await t.tap(find.byKey(const ValueKey('home-category-Groceries')));
    await t.pumpAndSettle();

    final dialog = find.byType(Dialog).evaluate().isEmpty ? find.byTooltip('Close') : find.byType(Dialog);
    expect(dialog, findsWidgets);
    expect(find.text('Market run'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    expect(find.textContaining('2 records'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.byTooltip('Close'));
    await t.pumpAndSettle();
    expect(find.text('Market run'), findsNothing);
  });
}
