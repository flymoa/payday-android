import 'package:flutter_test/flutter_test.dart';
import 'package:payday_local/pay_cycle.dart';

void main() {
  const rule = PaydayRule(); // 28th, paid the Friday before a weekend.

  test('weekend rule moves a Saturday payday', () {
    // 28 Nov 2026 is a Saturday.
    expect(rule.paydayIn(2026, 11), DateTime(2026, 11, 27));
    expect(const PaydayRule(weekend: WeekendRule.after).paydayIn(2026, 11), DateTime(2026, 11, 30));
    expect(const PaydayRule(weekend: WeekendRule.keep).paydayIn(2026, 11), DateTime(2026, 11, 28));
    // 28 Feb 2027 is a Sunday.
    expect(rule.paydayIn(2027, 2), DateTime(2027, 2, 26));
    expect(const PaydayRule(weekend: WeekendRule.after).paydayIn(2027, 2), DateTime(2027, 3, 1));
  });

  test('short months fall back to the last day', () {
    const r31 = PaydayRule(day: 31, weekend: WeekendRule.keep);
    expect(r31.paydayIn(2026, 4), DateTime(2026, 4, 30));
    expect(r31.paydayIn(2028, 2), DateTime(2028, 2, 29));
    const last = PaydayRule(day: 0, weekend: WeekendRule.keep);
    expect(last.paydayIn(2026, 2), DateTime(2026, 2, 28));
    expect(last.paydayIn(2026, 12), DateTime(2026, 12, 31));
  });

  test('the cycle runs from one payday to the day before the next', () {
    final c = payCycleFor(DateTime(2026, 11, 18), rule);
    expect(c.start, DateTime(2026, 10, 28)); // a Wednesday
    expect(c.nextPayday, DateTime(2026, 11, 27));
    expect(c.end, DateTime(2026, 11, 26));
    expect(c.daysToPayday(DateTime(2026, 11, 18)), 9);
    expect(c.dayIndex(DateTime(2026, 11, 18)), 22);
    expect(c.length, 30);
    expect(c.contains(DateTime(2026, 11, 26)), isTrue);
    expect(c.contains(DateTime(2026, 11, 27)), isFalse);
  });

  test('payday itself starts the new cycle', () {
    final c = payCycleFor(DateTime(2026, 11, 27), rule);
    expect(c.start, DateTime(2026, 11, 27));
    expect(c.nextPayday, DateTime(2026, 12, 28)); // 28 Dec 2026 is a Monday
  });

  test('a salary logged early or late moves the cycle start', () {
    // Salary arrived on the 25th, two days early.
    final early = payCycleFor(DateTime(2026, 11, 25), rule, salaryDates: [DateTime(2026, 11, 25)]);
    expect(early.start, DateTime(2026, 11, 25));
    expect(early.startedBySalary, isTrue);
    expect(early.nextPayday, DateTime(2026, 12, 28));
    // Salary two days late: the scheduled payday starts the cycle until it is logged.
    expect(payCycleFor(DateTime(2026, 11, 28), rule).start, DateTime(2026, 11, 27));
    final late = payCycleFor(DateTime(2026, 11, 30), rule, salaryDates: [DateTime(2026, 11, 29)]);
    expect(late.start, DateTime(2026, 11, 29));
    // A salary far from payday (a bonus) changes nothing.
    final bonus = payCycleFor(DateTime(2026, 11, 18), rule, salaryDates: [DateTime(2026, 11, 12)]);
    expect(bonus.start, DateTime(2026, 10, 28));
    expect(bonus.startedBySalary, isFalse);
    // A salary dated in the future is ignored.
    expect(payCycleFor(DateTime(2026, 11, 20), rule, salaryDates: [DateTime(2026, 11, 24)]).start, DateTime(2026, 10, 28));
  });

  test('settings round-trip and bad values fall back to the default', () {
    expect(PaydayRule.fromSettings(null, null), rule);
    expect(PaydayRule.fromSettings('last', 'after'), const PaydayRule(day: 0, weekend: WeekendRule.after));
    expect(PaydayRule.fromSettings('99', 'nonsense'), rule);
    expect(const PaydayRule(day: 0).encodedDay, 'last');
    expect(const PaydayRule(day: 5).encodedDay, '5');
  });

  test('upcoming cycles follow each other with no gap', () {
    final next = upcomingCycles(DateTime(2026, 11, 18), rule);
    expect(next.map((c) => c.start), [DateTime(2026, 11, 27), DateTime(2026, 12, 28), DateTime(2027, 1, 28)]);
    for (var i = 1; i < next.length; i++) {
      expect(next[i].start, next[i - 1].nextPayday);
    }
  });
}
