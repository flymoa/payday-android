import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/v3_logic.dart';

Kridi loan({int day = 27}) => Kridi(id: 1, name: 'Mortgage', kind: 'loan', monthly: 320000, months: 240, payDay: day,
    moves: [{'date': '2026-01-01', 'amount': 320000 * 240, 'note': ''}]);

void main() {
  test('next instalment date: this month, next month, short months', () {
    expect(nextInstalmentDate(loan(), DateTime(2026, 11, 24)), DateTime(2026, 11, 27));
    expect(nextInstalmentDate(loan(), DateTime(2026, 11, 28)), DateTime(2026, 12, 27));
    expect(nextInstalmentDate(loan(day: 31), DateTime(2027, 2, 10)), DateTime(2027, 2, 28));
    expect(nextInstalmentDate(loan(day: 0), DateTime(2026, 11, 24)), isNull);
  });
  test('only instalments within 3 days are due soon', () {
    expect(instalmentsDueSoon([loan()], DateTime(2026, 11, 24)).length, 1);
    expect(instalmentsDueSoon([loan()], DateTime(2026, 11, 20)), isEmpty);
  });
  test('new fields survive saving, old records still load', () {
    final shop = Kridi(id: 2, name: 'Hanout', kind: 'shop', limit: 100000, moves: [{'date': '2026-11-01', 'amount': 112000, 'note': ''}]);
    final back = decodeKridi(encodeKridi([shop, loan()]));
    expect(back.first.limit, 100000);
    expect(back.first.overLimit, isTrue);
    expect(back.last.payDay, 27);
    final old = decodeKridi('[{"id":3,"name":"Ali","kind":"borrowed","moves":[]}]');
    expect(old.single.dueDate, isNull);
    expect(old.single.limit, 0);
  });
}
