import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/app_preferences.dart';
import 'package:payday_local/localization.dart';
import 'package:payday_local/main.dart';
import 'package:payday_local/offline_store.dart';
import 'package:payday_local/translations.dart';

class CategoryStore extends OfflineStore {
  @override
  Future<Map<String, List<RowData>>> snapshot() async => {
        'categories': [
          {'name': 'Groceries', 'group_name': 'Essential'},
          {'name': 'Eating out', 'group_name': 'Flexible'},
          {'name': 'Housing', 'group_name': 'Essential'},
          {'name': 'Transport', 'group_name': 'Essential'},
        ],
      };
  @override
  Future<void> close() async {}
}

void main() {
  test('amounts on screen group thousands in every language', () {
    expect(localizedMoney(123456789, 'MAD', 'en'), '1\u00a0234\u00a0567,89 DH');
    expect(localizedMoney(123456, 'MAD', 'fr'), '1\u00a0234,56 DH');
    expect(localizedMoney(-250000, 'EUR', 'en'), '−2\u00a0500,00 EUR');
    expect(localizedMoney(4550, 'MAD', 'en'), '45,50 DH');
  });

  test('brand name is written Payday in every visible sentence', () {
    for (final entry in paydayTranslations.entries) {
      expect(entry.key.contains('PAYDAY'), isFalse, reason: entry.key);
      for (final value in entry.value) {
        expect(value.contains('PAYDAY'), isFalse, reason: value);
      }
    }
  });

  testWidgets('one-word category names stay whole in French', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final store = CategoryStore();
    await t.pumpWidget(PaydayLocal(
        store: store,
        initialData: store.snapshot(),
        preferencesWriter: (_) async {},
        initialPreferences: const AppPreferences(language: 'fr')));
    await t.pumpAndSettle();
    final semantics = t.ensureSemantics();
    await t.tap(find.bySemanticsLabel(translateMessage('Add transaction', 'fr')));
    await t.pumpAndSettle();
    semantics.dispose();
    for (final word in ['Alimentation', 'Restaurants', 'Logement']) {
      final paragraph = t.renderObject<RenderParagraph>(
          find.descendant(of: find.text(word).first, matching: find.byType(RichText)).first);
      expect(paragraph.maxLines, 1, reason: word);
      expect(paragraph.didExceedMaxLines, isFalse, reason: word);
    }
    expect(t.takeException(), isNull);
  });
}
