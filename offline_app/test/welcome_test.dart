import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/main.dart';

void main() {
  testWidgets('Screens built with data never show the welcome pages', (t) async {
    await t.pumpWidget(PaydayLocal(initialData: Future.value(<String, List<RowData>>{}), preferencesWriter: (_) async {}));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('welcome-start')), findsNothing);
    expect(find.byKey(const ValueKey('home-empty')), findsOneWidget, reason: 'a phone with no records opens on the empty Home');
    expect(t.takeException(), isNull);
  });
}
