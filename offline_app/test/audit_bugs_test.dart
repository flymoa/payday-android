import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/localization.dart';
import 'package:payday_local/main.dart';

// Regression tests for the bugs found in the November 2026 design audit.
void main() {
  Future<void> open(WidgetTester t, Map<String, List<RowData>> data, {required int page, required int tab}) async {
    await t.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: FinanceScreen(initialData: Future.value(data))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('bottom-$page')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('subtab-$page-$tab')));
    await t.pumpAndSettle();
  }

  String label(WidgetTester t) => t.widget<LText>(find.byKey(const ValueKey('nav-period-label'))).data;

  testWidgets('Year shows a year switcher that steps a whole year', (t) async {
    await open(t, {'transactions': []}, page: 1, tab: 2);
    final year = DateTime.now().year;
    expect(label(t), '$year');
    expect(find.byKey(const ValueKey('nav-month-previous')), findsNothing);
    await t.tap(find.byKey(const ValueKey('nav-year-previous')));
    await t.pumpAndSettle();
    expect(label(t), '${year - 1}');
    // Back on the List tab the switcher is a month switcher again, still in the year chosen.
    await t.tap(find.byKey(const ValueKey('subtab-1-0')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-month-previous')), findsOneWidget);
    expect(label(t), contains('${year - 1}'));
    expect(t.takeException(), isNull);
  });

  testWidgets('Savings lists this month\'s allocations even after browsing another month', (t) async {
    final now = DateTime.now();
    final current = monthKey(now), previous = monthKey(DateTime(now.year, now.month - 1));
    final data = <String, List<RowData>>{
      'transactions': [],
      'goals': [
        {'id': 1, 'name': 'Car', 'target': 4000000},
        {'id': 2, 'name': 'Eid', 'target': 450000},
      ],
      'allocations': [
        {'id': 1, 'goal_id': 1, 'month': current, 'amount': 50000},
        {'id': 2, 'goal_id': 2, 'month': previous, 'amount': 70000},
      ],
    };
    await t.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: FinanceScreen(initialData: Future.value(data))));
    await t.pumpAndSettle();
    // Browse to last month on Budgets, then open Savings.
    await t.tap(find.byKey(const ValueKey('bottom-2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('nav-month-previous')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bottom-3')));
    await t.pumpAndSettle();
    // Each goal has one row; only the goal with an allocation this month appears a second time.
    expect(find.text('Car'), findsNWidgets(2), reason: 'this month\'s allocation is listed');
    expect(find.text('Eid'), findsOneWidget, reason: 'last month\'s allocation is not');
    expect(find.text(current), findsNothing, reason: 'no raw month key as a subtitle');
    expect(t.takeException(), isNull);
  });

  testWidgets('A paid bill shows the day it was paid, not its due day', (t) async {
    final now = DateTime.now();
    final m = monthKey(now);
    final data = <String, List<RowData>>{
      'transactions': [
        {'id': 1, 'date': '$m-03', 'type': 'Expense', 'category': 'Utilities', 'amount': 41280, 'bill_id': 'LYDEC'},
      ],
      'bills': [
        {'id': 1, 'code': 'LYDEC', 'name': 'Lydec', 'due': '$m-20', 'amount': 41280, 'category': 'Utilities', 'note': ''},
      ],
    };
    await open(t, data, page: 2, tab: 1);
    final paidOn = localizedShortDay(DateTime.parse('$m-03'), 'en'), dueOn = localizedShortDay(DateTime.parse('$m-20'), 'en');
    expect(find.textContaining('Paid $paidOn'), findsOneWidget);
    expect(find.textContaining('Paid $dueOn'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
