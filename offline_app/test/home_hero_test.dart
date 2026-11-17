import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';
import 'package:payday_local/main.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Home leads with Safe to spend and shows the next bill (${brightness.name})', (t) async {
      await t.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final now = DateTime.now();
      final m = monthKey(now);
      final soon = DateTime(now.year, now.month, now.day + 2);
      final dueDay = soon.month == now.month ? dayKey(soon) : dayKey(now);
      final data = <String, List<RowData>>{
        'transactions': [
          {'id': 1, 'date': '$m-01', 'type': 'Income', 'category': 'Salary', 'amount': 1000000},
        ],
        'bills': [
          {'id': 1, 'code': 'NET', 'name': 'Internet', 'due': dueDay, 'amount': 34900, 'category': 'Utilities', 'note': ''},
        ],
      };
      await t.pumpWidget(MaterialApp(theme: ThemeData(brightness: brightness), home: FinanceScreen(initialData: Future.value(data))));
      await t.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const ValueKey('home-hero')), matching: find.text('Safe to spend')), findsOneWidget);
      expect(find.text('Bills ahead'), findsOneWidget);
      expect(find.text('Available this month'), findsOneWidget);
      expect(find.text('Expense'), findsNothing, reason: 'no shortcut tiles on Home');
      final card = find.byKey(const ValueKey('home-next-bill'));
      expect(card, findsOneWidget);
      await t.tap(card);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('page-2-tab-1')), findsOneWidget, reason: 'opens Budgets › Bills');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('A paid bill does not show on Home', (t) async {
    final now = DateTime.now();
    final data = <String, List<RowData>>{
      'transactions': [
        {'id': 1, 'date': dayKey(now), 'type': 'Expense', 'category': 'Utilities', 'amount': 34900, 'bill_id': 'NET'},
      ],
      'bills': [
        {'id': 1, 'code': 'NET', 'name': 'Internet', 'due': dayKey(now), 'amount': 34900, 'category': 'Utilities', 'note': ''},
      ],
    };
    await t.pumpWidget(MaterialApp(home: FinanceScreen(initialData: Future.value(data))));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-next-bill')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
