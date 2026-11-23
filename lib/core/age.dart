// Age maths — a direct port of the web app's src/lib/age.js so both apps agree to the day.
// Dates are plain year/month/day (no time zones); everything goes through DateTime.utc so DST never shifts a day.

const List<String> kMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const List<String> kMonthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const List<String> kWeekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const int kMinYear = 1900;
const int kMaxYear = 9999;

/// Replaceable clock so tests (and screenshots) can pin "today".
DateTime Function() clock = DateTime.now;

/// 12345 → "12,345" (English thousands separator, no intl dependency).
String fmtInt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

bool isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
int daysInMonth(int y, int m) => const [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1] + (m == 2 && isLeap(y) ? 1 : 0);

class YMD implements Comparable<YMD> {
  const YMD(this.y, this.m, this.d);
  final int y;
  final int m;
  final int d;

  factory YMD.fromUtcMs(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return YMD(dt.year, dt.month, dt.day);
  }

  static YMD today() {
    final n = clock();
    return YMD(n.year, n.month, n.day);
  }

  bool get isValid => y >= kMinYear && y <= kMaxYear && m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(y, m);
  int get utcMs => DateTime.utc(y, m, d).millisecondsSinceEpoch;
  int get weekdayIndex => DateTime.utc(y, m, d).weekday % 7; // 0 = Sunday
  String get weekday => kWeekdays[weekdayIndex];

  YMD addDays(int n) => YMD.fromUtcMs(utcMs + n * 86400000);
  YMD copyWith({int? y, int? m, int? d}) => YMD(y ?? this.y, m ?? this.m, d ?? this.d);

  @override
  int compareTo(YMD other) => utcMs.compareTo(other.utcMs);
  bool operator <(YMD o) => compareTo(o) < 0;
  bool operator >(YMD o) => compareTo(o) > 0;
  bool operator <=(YMD o) => compareTo(o) <= 0;
  bool operator >=(YMD o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) => other is YMD && other.y == y && other.m == m && other.d == d;
  @override
  int get hashCode => Object.hash(y, m, d);
  @override
  String toString() => '$y-$m-$d';

  Map<String, int> toJson() => {'y': y, 'm': m, 'd': d};
  factory YMD.fromJson(Map<String, dynamic> j) => YMD(j['y'] as int, j['m'] as int, j['d'] as int);
}

int daysBetween(YMD a, YMD b) => ((b.utcMs - a.utcMs) / 86400000).round();

/// Add whole months; the day is clamped to the target month (31 Jan + 1 mo = 28/29 Feb).
YMD addMonths(YMD date, int n) {
  final idx = date.y * 12 + (date.m - 1) + n;
  final y = idx ~/ 12;
  final m = (idx % 12) + 1;
  return YMD(y, m, date.d < daysInMonth(y, m) ? date.d : daysInMonth(y, m));
}

class Diff {
  const Diff(this.years, this.months, this.days, this.totalMonths);
  final int years, months, days, totalMonths;
}

/// Calendar difference from → to (to >= from): whole years, months, then leftover days.
Diff diffYMD(YMD from, YMD to) {
  var months = (to.y - from.y) * 12 + (to.m - from.m);
  var anchor = addMonths(from, months);
  if (anchor > to) {
    months -= 1;
    anchor = addMonths(from, months);
  }
  return Diff(months ~/ 12, months % 12, daysBetween(anchor, to), months);
}

/// Birthday in a given year. 29 Feb in a common year is observed on 28 Feb.
YMD birthdayIn(YMD birth, int year) => YMD(year, birth.m, birth.d < daysInMonth(year, birth.m) ? birth.d : daysInMonth(year, birth.m));

class NextBirthday {
  const NextBirthday({required this.date, required this.age, required this.daysToNext, required this.until, required this.progress});
  final YMD date;
  final int age;
  final int daysToNext;
  final Diff until;

  /// 0 → just had a birthday, 1 → birthday is today. Drives the ring.
  final double progress;
  bool get isToday => daysToNext == 0;
}

NextBirthday nextBirthday(YMD birth, YMD ref) {
  var next = birthdayIn(birth, ref.y);
  if (next < ref) next = birthdayIn(birth, ref.y + 1);
  final prev = birthdayIn(birth, next.y - 1);
  final toNext = daysBetween(ref, next);
  final span = daysBetween(prev, next);
  return NextBirthday(
    date: next,
    age: next.y - birth.y,
    daysToNext: toNext,
    until: diffYMD(ref, next),
    progress: span > 0 ? ((span - toNext) / span).clamp(0.0, 1.0).toDouble() : 0.0,
  );
}

class Zodiac {
  const Zodiac(this.name, this.range, this.fromM, this.fromD);
  final String name, range;
  final int fromM, fromD;
}

// chronological by start date; Capricorn (22 Dec) is last and is also the default for 1–19 Jan
const List<Zodiac> _zodiac = [
  Zodiac('Aquarius', 'Jan 20 – Feb 18', 1, 20), Zodiac('Pisces', 'Feb 19 – Mar 20', 2, 19), Zodiac('Aries', 'Mar 21 – Apr 19', 3, 21),
  Zodiac('Taurus', 'Apr 20 – May 20', 4, 20), Zodiac('Gemini', 'May 21 – Jun 20', 5, 21), Zodiac('Cancer', 'Jun 21 – Jul 22', 6, 21),
  Zodiac('Leo', 'Jul 23 – Aug 22', 7, 23), Zodiac('Virgo', 'Aug 23 – Sep 22', 8, 23), Zodiac('Libra', 'Sep 23 – Oct 22', 9, 23),
  Zodiac('Scorpio', 'Oct 23 – Nov 21', 10, 23), Zodiac('Sagittarius', 'Nov 22 – Dec 21', 11, 22), Zodiac('Capricorn', 'Dec 22 – Jan 19', 12, 22),
];

Zodiac zodiacOf(YMD d) {
  var hit = _zodiac.last;
  for (final z in _zodiac) {
    if (d.m > z.fromM || (d.m == z.fromM && d.d >= z.fromD)) hit = z;
  }
  return hit;
}

String generationOf(int year) {
  if (year <= 1945) return 'Earlier Generations';
  if (year <= 1964) return 'Baby Boomer';
  if (year <= 1980) return 'Gen X';
  if (year <= 1996) return 'Millennial (Gen Y)';
  if (year <= 2012) return 'Gen Z';
  return 'Gen Alpha';
}

String generationShort(int year) => generationOf(year).replaceAll(RegExp(r' \(.*\)'), '');

class Milestone {
  const Milestone(this.label, this.date, this.past);
  final String label;
  final YMD date;
  final bool past;
}

List<Milestone> milestonesFor(YMD birth, YMD ref) {
  final c = <(String, YMD)>[
    for (final n in [1000, 2500, 5000, 7500, 10000, 12000, 15000, 20000, 25000, 30000]) ('${fmtInt(n)} days', birth.addDays(n)),
    ('1 billion seconds', birth.addDays((1e9 / 86400).round())),
    ('1 million minutes', birth.addDays((1e6 / 1440).round())),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  final firstFuture = c.indexWhere((e) => e.$2 > ref);
  final f = firstFuture == -1 ? c.length : firstFuture;
  final start = (f - 2).clamp(0, c.length - 5).toInt();
  return [for (final e in c.sublist(start, start + 5)) Milestone(e.$1, e.$2, e.$2 <= ref)];
}

enum AgeErrorField { day, month, year, ref }

class AgeError implements Exception {
  AgeError(this.code, this.message, this.field);
  final String code, message;
  final AgeErrorField field;
  @override
  String toString() => 'AgeError($code): $message';
}

class AgeResult {
  const AgeResult({
    required this.birth, required this.ref, required this.years, required this.months, required this.days, required this.totalMonths,
    required this.totalDays, required this.totalWeeks, required this.totalHours, required this.totalMinutes,
    required this.next, required this.zodiac, required this.generation, required this.bornOn, required this.milestones,
  });
  final YMD birth, ref;
  final int years, months, days, totalMonths, totalDays, totalWeeks, totalHours, totalMinutes;
  final NextBirthday next;
  final Zodiac zodiac;
  final String generation, bornOn;
  final List<Milestone> milestones;
}

/// Validate + compute everything the UI shows. Throws [AgeError] with the field to highlight.
AgeResult computeAge(YMD birth, YMD ref) {
  if (!birth.isValid) {
    if (birth.y < kMinYear || birth.y > kMaxYear) {
      throw AgeError('birth-invalid', 'Birth year must be between $kMinYear and $kMaxYear', AgeErrorField.year);
    }
    if (birth.m >= 1 && birth.m <= 12 && birth.d > daysInMonth(birth.y, birth.m)) {
      throw AgeError('birth-invalid', '${kMonths[birth.m - 1]} ${birth.y} only has ${daysInMonth(birth.y, birth.m)} days', AgeErrorField.day);
    }
    throw AgeError('birth-invalid', 'Invalid date of birth', AgeErrorField.day);
  }
  if (!ref.isValid) throw AgeError('ref-invalid', 'Invalid reference date', AgeErrorField.ref);
  if (birth > ref) throw AgeError('future', 'Date of birth cannot be after the reference date', AgeErrorField.day);
  final diff = diffYMD(birth, ref);
  final days = daysBetween(birth, ref);
  return AgeResult(
    birth: birth, ref: ref, years: diff.years, months: diff.months, days: diff.days, totalMonths: diff.totalMonths,
    totalDays: days, totalWeeks: days ~/ 7, totalHours: days * 24, totalMinutes: days * 1440,
    next: nextBirthday(birth, ref), zodiac: zodiacOf(birth), generation: generationOf(birth.y), bornOn: birth.weekday,
    milestones: milestonesFor(birth, ref),
  );
}

class BirthCompare {
  const BirthCompare({required this.years, required this.months, required this.days, required this.totalDays, required this.totalWeeks, required this.totalHours, required this.totalMonths, required this.olderIsA, required this.same});
  final int years, months, days, totalDays, totalWeeks, totalHours, totalMonths;
  final bool olderIsA, same;
}

/// Difference between two people's birth dates; null if either date is invalid.
BirthCompare? compareBirths(YMD a, YMD b) {
  if (!a.isValid || !b.isValid) return null;
  final aOlder = a <= b;
  final older = aOlder ? a : b;
  final younger = aOlder ? b : a;
  final diff = diffYMD(older, younger);
  final days = daysBetween(older, younger);
  return BirthCompare(
    years: diff.years, months: diff.months, days: diff.days, totalDays: days, totalWeeks: days ~/ 7, totalHours: days * 24,
    totalMonths: diff.totalMonths, olderIsA: aOlder, same: days == 0,
  );
}

/// 1 → "1st", 22 → "22nd", 29 → "29th".
String ordinal(int n) {
  final r100 = n % 100;
  if (r100 >= 11 && r100 <= 13) return '${n}th';
  return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
}

/// "day" → "days" unless n is exactly 1.
String pluralize(int n, String word) => n == 1 ? word : '${word}s';
String ageText(int years, int months, int days) => '$years ${pluralize(years, 'year')}, $months ${pluralize(months, 'month')}, $days ${pluralize(days, 'day')}';
String ageShort(int years, int months, int days) => '${years}y ${months}mo ${days}d';
String formatLong(YMD d) => '${d.weekday}, ${kMonths[d.m - 1]} ${d.d}, ${d.y}';
String formatMedium(YMD d) => '${kMonths[d.m - 1]} ${d.d}, ${d.y}';
String formatShort(YMD d) => '${kMonthsShort[d.m - 1]} ${d.d}, ${d.y}';
