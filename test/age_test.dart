import 'package:age_calculate/core/age.dart';
import 'package:flutter_test/flutter_test.dart';

// Same cases as the web app's age.test.js — the two apps must agree.
void main() {
  group('diffYMD', () {
    test('matches the Figma sample: 14 Aug 1998 → 19 Nov 2026 = 28y 3m 5d', () {
      final d = diffYMD(const YMD(1998, 8, 14), const YMD(2026, 11, 19));
      expect([d.years, d.months, d.days, d.totalMonths], [28, 3, 5, 339]);
    });
    test('exact birthday gives 0 months / 0 days', () {
      final d = diffYMD(const YMD(2000, 5, 10), const YMD(2026, 5, 10));
      expect([d.years, d.months, d.days], [26, 0, 0]);
    });
    test('day before birthday borrows a month', () {
      final d = diffYMD(const YMD(2000, 5, 10), const YMD(2026, 5, 9));
      expect([d.years, d.months], [25, 11]);
    });
    test('31 Jan → 1 Mar (common year) clamps the anniversary to 28 Feb', () {
      final d = diffYMD(const YMD(2025, 1, 31), const YMD(2025, 3, 1));
      expect([d.years, d.months, d.days], [0, 1, 1]);
    });
    test('29 Feb birth: birthday in a common year is observed on 28 Feb', () {
      final a = diffYMD(const YMD(2024, 2, 29), const YMD(2025, 2, 27));
      expect([a.years, a.months, a.days], [0, 11, 29]);
      final b = diffYMD(const YMD(2024, 2, 29), const YMD(2025, 2, 28));
      expect([b.years, b.months, b.days], [1, 0, 0]);
    });
  });

  group('computeAge', () {
    final r = computeAge(const YMD(1998, 8, 14), const YMD(2026, 11, 19));
    test('totals', () {
      expect(r.totalDays, 10324);
      expect(r.totalWeeks, 1474);
      expect(r.totalHours, 247776);
      expect(r.totalMinutes, 14866560);
    });
    test('next birthday', () {
      expect(r.next.date, const YMD(2027, 8, 14));
      expect(r.next.age, 29);
      expect(r.next.daysToNext, 268);
      expect([r.next.until.months, r.next.until.days], [8, 26]);
      expect(r.next.progress, inInclusiveRange(0.26, 0.28));
    });
    test('profile', () {
      expect(r.zodiac.name, 'Leo');
      expect(r.generation, 'Gen Z');
      expect(r.bornOn, 'Friday');
    });
    test('milestones: 10,000 days passed, 1 billion seconds still ahead', () {
      final m = {for (final x in r.milestones) x.label: x};
      expect(m['10,000 days']!.past, true);
      expect(m['1 billion seconds']!.past, false);
      expect(r.milestones, hasLength(5));
    });
    test('rejects 31 Feb and names the field', () {
      expect(
        () => computeAge(const YMD(1998, 2, 31), const YMD(2026, 1, 1)),
        throwsA(isA<AgeError>().having((e) => e.field, 'field', AgeErrorField.day).having((e) => e.message, 'message', contains('28 days'))),
      );
    });
    test('rejects future births', () {
      expect(() => computeAge(const YMD(2030, 1, 1), const YMD(2026, 1, 1)), throwsA(isA<AgeError>().having((e) => e.message, 'm', contains('after'))));
    });
    test('birthday today', () {
      final t = computeAge(const YMD(2000, 11, 19), const YMD(2026, 11, 19));
      expect([t.next.isToday, t.next.daysToNext, t.next.age], [true, 0, 26]);
    });
  });

  group('compareBirths', () {
    test('matches the Figma sample: 2y 5m 12d, 896 days', () {
      final c = compareBirths(const YMD(1998, 8, 14), const YMD(2001, 1, 26))!;
      expect([c.years, c.months, c.days, c.totalDays, c.totalWeeks, c.totalHours, c.olderIsA], [2, 5, 12, 896, 128, 21504, true]);
    });
    test('is symmetric', () {
      final c = compareBirths(const YMD(2001, 1, 26), const YMD(1998, 8, 14))!;
      expect([c.totalDays, c.olderIsA], [896, false]);
    });
    test('same day', () => expect(compareBirths(const YMD(2000, 1, 1), const YMD(2000, 1, 1))!.same, true));
  });

  group('helpers', () {
    test('addMonths clamps', () => expect(addMonths(const YMD(2024, 1, 31), 1), const YMD(2024, 2, 29)));
    test('29 Feb birthday in a common year is 28 Feb', () => expect(nextBirthday(const YMD(2000, 2, 29), const YMD(2026, 1, 10)).date, const YMD(2026, 2, 28)));
    test('validation', () {
      expect(const YMD(2024, 2, 29).isValid, true);
      expect(const YMD(2023, 2, 29).isValid, false);
      expect(const YMD(1899, 1, 1).isValid, false);
      expect(daysInMonth(1900, 2), 28);
    });
    test('zodiac boundaries', () {
      expect(zodiacOf(const YMD(2000, 12, 21)).name, 'Sagittarius');
      expect(zodiacOf(const YMD(2000, 12, 22)).name, 'Capricorn');
      expect(zodiacOf(const YMD(2000, 1, 19)).name, 'Capricorn');
      expect(zodiacOf(const YMD(2000, 1, 20)).name, 'Aquarius');
    });
    test('generations', () {
      expect(generationOf(1996), contains('Millennial'));
      expect(generationOf(1997), 'Gen Z');
      expect(generationOf(2013), 'Gen Alpha');
    });
    test('milestones never crash for a newborn or an elder', () {
      expect(milestonesFor(const YMD(2026, 11, 1), const YMD(2026, 11, 19)), hasLength(5));
      expect(milestonesFor(const YMD(1920, 1, 1), const YMD(2026, 11, 19)), hasLength(5));
    });
    test('number format uses commas', () {
      expect(fmtInt(247776), '247,776');
      expect(fmtInt(999), '999');
      expect(fmtInt(14866560), '14,866,560');
    });
    test('weekday', () => expect(const YMD(1998, 8, 14).weekday, 'Friday'));
    test('date formats are US English', () {
      const d = YMD(1998, 8, 14);
      expect(formatShort(d), 'Aug 14, 1998');
      expect(formatMedium(d), 'August 14, 1998');
      expect(formatLong(d), 'Friday, August 14, 1998');
    });
    test('duration formats', () {
      expect(ageText(28, 3, 5), '28 years, 3 months, 5 days');
      expect(ageText(1, 1, 1), '1 year, 1 month, 1 day');
      expect(ageShort(56, 8, 0), '56y 8mo 0d');
    });
    test('ordinals', () {
      expect(
        [for (final n in [1, 2, 3, 4, 11, 12, 13, 21, 22, 29, 101, 111]) ordinal(n)],
        ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', '29th', '101st', '111th'],
      );
    });
  });
}
