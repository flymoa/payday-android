import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/category_icon.dart';

void main() {
  test('built-in categories keep their own glyph', () {
    for (final name in ['Housing', 'Groceries', 'Freelance', 'Business', 'Gifts', 'Other income', 'Other', 'Salary']) {
      expect(categoryGlyph(name), name.toLowerCase());
    }
  });
  test('custom categories get the closest glyph from their name in any app language', () {
    expect(categoryGlyph('Car fuel'), 'transport');
    expect(categoryGlyph('Loyer appartement'), 'housing');
    expect(categoryGlyph('School fees'), 'education');
    expect(categoryGlyph('Dog food & vet'), 'groceries'); // first matching word wins
    expect(categoryGlyph('Vétérinaire'), 'pets');
    expect(categoryGlyph('سفر الصيف'), 'travel');
    expect(categoryGlyph('Netflix'), 'subscriptions');
  });
  test('unknown names and Uncategorized use the neutral tag', () {
    expect(categoryGlyph('Zxq'), 'tag');
    expect(categoryGlyph('Uncategorized'), 'tag');
  });
}
