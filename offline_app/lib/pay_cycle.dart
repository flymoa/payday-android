// Pay cycle: money runs from one payday to the day before the next.
//
// The schedule comes from a rule the user picks (day of the month, or the
// last day, and what happens when that lands on a weekend). The real salary
// can still move a cycle: a salary logged within [salaryWindowDays] of an
// expected payday starts that cycle on the day it arrived.

/// What to do when payday falls on a Saturday or Sunday.
enum WeekendRule { before, after, keep }

/// How many days early or late a logged salary may arrive and still start the cycle.
const salaryWindowDays = 5;

class PaydayRule {
  const PaydayRule({this.day = 28, this.weekend = WeekendRule.before});

  /// Day of the month, 1–31. 0 means the last day of the month.
  final int day;
  final WeekendRule weekend;

  static const dayKey = 'payday_day';
  static const weekendKey = 'payday_weekend';

  bool get lastDay => day == 0;
  String get encodedDay => lastDay ? 'last' : '$day';

  /// Read from settings; anything missing or invalid falls back to the 28th, Friday before.
  static PaydayRule fromSettings(String? day, String? weekend) {
    final d = day == 'last' ? 0 : int.tryParse(day ?? '');
    return PaydayRule(
      day: d != null && d >= 0 && d <= 31 ? d : 28,
      weekend: WeekendRule.values.where((w) => w.name == weekend).firstOrNull ?? WeekendRule.before,
    );
  }

  /// The scheduled payday in [year]/[month], after short months and the weekend rule.
  DateTime paydayIn(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;
    final d = lastDay || day > last ? last : day;
    final date = DateTime(year, month, d);
    final weekday = date.weekday; // Monday 1 … Sunday 7.
    if (weekday < DateTime.saturday || weekend == WeekendRule.keep) return date;
    if (weekend == WeekendRule.before) return DateTime(year, month, d - (weekday == DateTime.saturday ? 1 : 2));
    return DateTime(year, month, d + (weekday == DateTime.saturday ? 2 : 1));
  }

  @override
  bool operator ==(Object other) => other is PaydayRule && other.day == day && other.weekend == weekend;
  @override
  int get hashCode => Object.hash(day, weekend);
}

class PayCycle {
  const PayCycle({required this.start, required this.nextPayday, required this.startedBySalary});

  /// First day of the cycle (a payday, or the day the salary arrived).
  final DateTime start;

  /// Next scheduled payday; the cycle ends the day before.
  final DateTime nextPayday;

  /// True when a logged salary, not the schedule, set [start].
  final bool startedBySalary;

  DateTime get end => DateTime(nextPayday.year, nextPayday.month, nextPayday.day - 1);
  int get length => _days(start, nextPayday);
  bool contains(DateTime day) => !_date(day).isBefore(start) && _date(day).isBefore(nextPayday);

  /// 1 on the first day of the cycle.
  int dayIndex(DateTime today) => _days(start, today) + 1;

  /// Whole days from [today] to the next payday (1 = tomorrow).
  int daysToPayday(DateTime today) => _days(today, nextPayday);
}

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);
// Counted in UTC so a daylight-saving change never makes a day 23 or 25 hours.
int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The cycle that contains [today].
///
/// [salaryDates] are the dates of logged salary income. A salary within
/// [salaryWindowDays] of a scheduled payday (and not after [today]) moves that
/// cycle's start to the day it arrived.
PayCycle payCycleFor(DateTime today, PaydayRule rule, {Iterable<DateTime> salaryDates = const []}) {
  final t = _date(today);
  final salaries = salaryDates.map(_date).where((s) => !s.isAfter(t)).toList();

  // Actual start of the cycle that begins at scheduled payday [p].
  (DateTime, bool) actual(DateTime p) {
    DateTime? best;
    for (final s in salaries) {
      final gap = _days(p, s).abs();
      if (gap <= salaryWindowDays && (best == null || gap < _days(p, best).abs())) best = s;
    }
    return best == null ? (p, false) : (best, true);
  }

  final scheduled = [for (var m = -2; m <= 2; m++) rule.paydayIn(t.year, t.month + m)];
  var start = actual(scheduled.first);
  var next = scheduled.last;
  for (var i = 0; i < scheduled.length; i++) {
    final a = actual(scheduled[i]);
    if (!a.$1.isAfter(t)) {
      start = a;
    } else {
      next = scheduled[i];
      break;
    }
  }
  return PayCycle(start: start.$1, nextPayday: next, startedBySalary: start.$2);
}

/// The next [count] cycles from the one containing [today], for previews.
List<PayCycle> upcomingCycles(DateTime today, PaydayRule rule, {int count = 3}) {
  final out = <PayCycle>[];
  var c = payCycleFor(today, rule);
  for (var i = 0; i < count; i++) {
    c = payCycleFor(c.nextPayday, rule);
    out.add(c);
  }
  return out;
}
