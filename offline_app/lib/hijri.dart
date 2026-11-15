/// Approximate Hijri dates from the tabular (arithmetic) Islamic calendar.
/// Real dates follow moon sighting and can differ by a day or two, so the
/// app always shows these with "≈". Used only for planning reserves.
library;

int _gregorianToJd(int year, int month, int day) {
  final a = (14 - month) ~/ 12, y = year + 4800 - a, m = month + 12 * a - 3;
  return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
}

DateTime _jdToGregorian(int jd) {
  final a = jd + 32044, b = (4 * a + 3) ~/ 146097, c = a - 146097 * b ~/ 4;
  final d = (4 * c + 3) ~/ 1461, e = c - 1461 * d ~/ 4, m = (5 * e + 2) ~/ 153;
  return DateTime(100 * b + d - 4800 + m ~/ 10, m + 3 - 12 * (m ~/ 10), e - (153 * m + 2) ~/ 5 + 1);
}

int _hijriToJd(int year, int month, int day) =>
    day + (29.5 * (month - 1)).ceil() + (year - 1) * 354 + (3 + 11 * year) ~/ 30 + 1948439;

class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year, month, day;
  factory HijriDate.fromGregorian(DateTime date) {
    final jd = _gregorianToJd(date.year, date.month, date.day);
    final year = (30 * (jd - 1948440) + 10646) ~/ 10631;
    var month = ((jd - 29 - _hijriToJd(year, 1, 1)) / 29.5).ceil() + 1;
    if (month > 12) month = 12;
    if (month < 1) month = 1;
    return HijriDate(year, month, jd - _hijriToJd(year, month, 1) + 1);
  }
  DateTime toGregorian() => _jdToGregorian(_hijriToJd(year, month, day));
}

/// The next date (from [today]) on which the given Hijri month and day fall.
DateTime nextHijriOccurrence(DateTime today, int month, int day) {
  final start = DateTime(today.year, today.month, today.day);
  var year = HijriDate.fromGregorian(start).year;
  for (var i = 0; i < 3; i++, year++) {
    final date = HijriDate(year, month, day).toGregorian();
    if (!date.isBefore(start)) return date;
  }
  return HijriDate(year, month, day).toGregorian();
}

const hijriMonthNames = [
  'Muharram', 'Safar', 'Rabiʿ al-awwal', 'Rabiʿ al-thani', 'Jumada al-ula', 'Jumada al-akhira',
  'Rajab', 'Shaʿban', 'Ramadan', 'Shawwal', 'Dhu al-Qaʿda', 'Dhu al-Hijja',
];

/// One-tap reserves for Morocco's big yearly spending moments.
enum SeasonPreset { ramadan, eidAlAdha, backToSchool, summer }

const seasonPresetNames = {
  SeasonPreset.ramadan: 'Ramadan',
  SeasonPreset.eidAlAdha: 'Eid al-Adha',
  SeasonPreset.backToSchool: 'Back to school',
  SeasonPreset.summer: 'Summer holidays',
};

DateTime _nextYearly(DateTime today, int month, int day) {
  final start = DateTime(today.year, today.month, today.day);
  final thisYear = DateTime(today.year, month, day);
  return thisYear.isBefore(start) ? DateTime(today.year + 1, month, day) : thisYear;
}

/// When the money should be ready: the day before Ramadan or Eid starts,
/// 1 September for the school year, 1 July for the summer.
DateTime seasonDueDate(SeasonPreset preset, DateTime today) {
  switch (preset) {
    case SeasonPreset.ramadan:
      return nextHijriOccurrence(today.add(const Duration(days: 1)), 9, 1).subtract(const Duration(days: 1));
    case SeasonPreset.eidAlAdha:
      return nextHijriOccurrence(today.add(const Duration(days: 1)), 12, 10).subtract(const Duration(days: 1));
    case SeasonPreset.backToSchool:
      return _nextYearly(today.add(const Duration(days: 1)), 9, 1);
    case SeasonPreset.summer:
      return _nextYearly(today.add(const Duration(days: 1)), 7, 1);
  }
}
