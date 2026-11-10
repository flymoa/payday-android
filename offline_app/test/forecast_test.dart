import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/finance.dart';

void main() {
  test('forecast scales spending to the full month, current month only', () {
    final now = DateTime(2026, 11, 10);
    expect(projectedMonthSpend(spentSoFar: 100000, month: DateTime(2026, 11), now: now), 300000);
    expect(projectedMonthSpend(spentSoFar: 100000, month: DateTime(2026, 10), now: now), isNull);
    expect(projectedMonthSpend(spentSoFar: 0, month: DateTime(2026, 11), now: now), isNull);
    expect(projectedMonthSpend(spentSoFar: 2800, month: DateTime(2026, 2), now: DateTime(2026, 2, 28)), 2800);
  });
}
