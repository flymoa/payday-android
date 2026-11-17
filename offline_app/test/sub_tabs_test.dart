import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';

void main() {
  for (final language in ['en', 'fr', 'ar']) {
    for (final brightness in Brightness.values) {
      testWidgets('small tabs open every tool without a More button ($language, ${brightness.name})', (t) async {
        await t.binding.setSurfaceSize(const Size(360, 780));
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(PaydayLocal(
            initialData: Future.value(<String, List<RowData>>{}),
            preferencesWriter: (_) async {},
            initialPreferences: AppPreferences(
                language: language, appearance: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light)));
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('more-button')), findsNothing);
        for (final page in [1, 2, 3]) {
          await t.tap(find.byKey(ValueKey('bottom-$page')));
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('home-settings-button')), findsOneWidget, reason: 'gear on page $page');
          for (final tab in [1, 2, 0]) {
            await t.tap(find.byKey(ValueKey('subtab-$page-$tab')));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull, reason: 'page $page tab $tab');
          }
        }
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('each page remembers its small tab, and back returns to the first one', (t) async {
    await t.pumpWidget(PaydayLocal(
        initialData: Future.value(<String, List<RowData>>{}), preferencesWriter: (_) async {}, initialPreferences: const AppPreferences()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bottom-2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('subtab-2-1')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-2-tab-1')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('bottom-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bottom-2')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-2-tab-1')), findsOneWidget, reason: 'Budgets remembers the Bills tab');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-2-tab-0')), findsOneWidget, reason: 'back returns to the Budgets tab');
    expect(t.takeException(), isNull);
  });
}
