// Runs the real app on an Android emulator (see the emulator job in CI).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:payday_local/add_button.dart';
import 'package:payday_local/main.dart' as app;

Future<void> settle(WidgetTester t, {int seconds = 4}) async {
  // The opening animation and progress indicators can keep frames scheduled,
  // so pump for a fixed time instead of pumpAndSettle.
  for (var i = 0; i < seconds * 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester t, Finder finder, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 10 && finder.evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: 'Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add an expense on a fresh install and see it on Home', (t) async {
    app.main();
    await waitFor(t, find.byType(PaydayAddButton));
    await settle(t);

    await t.tap(find.byType(PaydayAddButton));
    await settle(t, seconds: 2);
    await t.enterText(find.widgetWithText(TextField, 'Amount (MAD)'), '12.50');
    await t.enterText(find.widgetWithText(TextField, 'Description'), 'Emulator coffee');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t, seconds: 1);
    await t.tap(find.text('Save locally'));
    await settle(t, seconds: 3);

    await waitFor(t, find.text('Emulator coffee'));
    expect(find.textContaining('12.50'), findsWidgets);
  });
}
