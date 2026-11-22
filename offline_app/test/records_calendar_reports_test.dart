import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';

void main() {
  final m = DateTime.now().toIso8601String().substring(0, 7);
  final prev = DateTime(DateTime.now().year, DateTime.now().month - 1).toIso8601String().substring(0, 7);
  final data = <String, List<RowData>>{
    'transactions': [
      {'id': 1, 'date': '$m-03', 'type': 'Expense', 'category': 'Groceries', 'description': 'Marjane', 'amount': 30000, 'note': '', 'bill_id': ''},
      {'id': 2, 'date': '$m-03', 'type': 'Expense', 'category': 'Transport', 'description': 'Taxi', 'amount': 2500, 'note': '', 'bill_id': ''},
      {'id': 3, 'date': '$m-01', 'type': 'Income', 'category': 'Salary', 'description': '', 'amount': 900000, 'note': '', 'bill_id': ''},
      {'id': 4, 'date': '$prev-05', 'type': 'Expense', 'category': 'Groceries', 'description': '', 'amount': 20000, 'note': '', 'bill_id': ''},
    ],
  };
  Future<void> openRecords(WidgetTester t, int tab, {String language = 'en'}) async {
    await t.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(PaydayLocal(initialData: Future.value(data), preferencesWriter: (_) async {}, initialPreferences: AppPreferences(language: language)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bottom-1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('subtab-1-$tab')));
    await t.pumpAndSettle();
  }

  testWidgets('Records has List, Calendar, Reports and Review in that order', (t) async {
    await openRecords(t, 0);
    for (final label in ['List', 'Calendar', 'Reports', 'Review']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('Calendar shows the day entries when a day is tapped', (t) async {
    await openRecords(t, 1);
    expect(find.byKey(const ValueKey('records-calendar')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('calendar-day-3')));
    await t.pumpAndSettle();
    expect(find.text('Marjane'), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Reports shows the ring, the categories and the rise against last month', (t) async {
    await openRecords(t, 2);
    expect(find.byKey(const ValueKey('reports-donut')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-Groceries')), findsOneWidget);
    expect(find.textContaining('+50% vs last month'), findsOneWidget);
    expect(find.byKey(const ValueKey('reports-insight')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('reports-year')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-year-previous')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Calendar and Reports read in French', (t) async {
    await openRecords(t, 1, language: 'fr');
    expect(find.text('Calendrier'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping a slice of the ring shows its category and amount', (t) async {
    await openRecords(t, 2);
    final ring = find.byKey(const ValueKey('reports-donut-tap'));
    await t.tapAt(t.getCenter(ring) + const Offset(88, 0));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('reports-slice-detail')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('reports-slice-detail')), matching: find.text('Groceries')), findsOneWidget);
    await t.tapAt(t.getCenter(ring));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('reports-slice-detail')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('small tabs keep one text size and never cut a label at large text', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MediaQuery(data: const MediaQueryData(size: Size(360, 800), textScaler: TextScaler.linear(1.3)),
        child: PaydayLocal(initialData: Future.value(data), preferencesWriter: (_) async {}, initialPreferences: const AppPreferences(language: 'fr'))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bottom-3')));
    await t.pumpAndSettle();
    for (final label in ['Objectifs', 'Réserves', 'Kridi', 'Daret', 'Comptes']) {
      final text = t.widget<Text>(find.descendant(of: find.byKey(ValueKey('subtab-3-${['Objectifs', 'Réserves', 'Kridi', 'Daret', 'Comptes'].indexOf(label)}')), matching: find.byType(Text)));
      expect(text.style?.fontSize, 14, reason: label);
      expect(text.overflow, isNot(TextOverflow.ellipsis), reason: label);
    }
    expect(t.takeException(), isNull);
  });
}
