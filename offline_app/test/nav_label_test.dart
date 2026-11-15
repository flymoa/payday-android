import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/main.dart';

void main() {
  for (final language in ['en', 'fr', 'ar']) {
    testWidgets('bottom navigation labels stay on one line ($language)', (t) async {
      await t.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(PaydayLocal(
          initialData: Future.value(<String, List<RowData>>{}),
          preferencesWriter: (_) async {},
          initialPreferences: AppPreferences(language: language)));
      await t.pumpAndSettle();
      for (final tab in [0, 1, 2, 3]) {
        final label = find.descendant(of: find.byKey(ValueKey('bottom-label-$tab')), matching: find.byType(RichText));
        final paragraph = t.renderObject<RenderParagraph>(label);
        expect(paragraph.maxLines, 1, reason: 'tab $tab');
        expect(paragraph.didExceedMaxLines, isFalse, reason: 'tab $tab');
      }
      expect(t.takeException(), isNull);
    });
  }
}
