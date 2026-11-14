import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/brand.dart';
import 'package:payday_local/main.dart';

void main() {
  testWidgets('Home shows a visible Settings button that opens the drawer on a narrow phone', (t) async {
    await t.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(PaydayLocal(
      initialData: Future.value(<String, List<RowData>>{}),
      preferencesWriter: (_) async {},
      initialPreferences: const AppPreferences(),
    ));
    await t.pumpAndSettle();
    // The logo is decoration only; the gear button is the one way in.
    expect(find.ancestor(of: find.byType(PaydayMark).first, matching: find.byType(IconButton)), findsNothing);
    final button = find.byKey(const ValueKey('home-settings-button'));
    expect(button, findsOneWidget);
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await t.tap(find.byTooltip('Close settings'));
    await t.pumpAndSettle();
    // The button belongs to Home only.
    await t.tap(find.byKey(const ValueKey('bottom-2')));
    await t.pumpAndSettle();
    expect(button, findsNothing);
    expect(t.takeException(), isNull);
  });
}
