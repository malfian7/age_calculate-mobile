import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  group('launch', () {
    testWidgets('first launch: splash → onboarding → "Skip" → home', (tester) async {
      await bootApp(tester, onboarded: false, skipLaunch: false);
      expect(find.text('Loading…'), findsOneWidget); // splash
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('with precision'), findsOneWidget); // onboarding page 1
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Calculate age'), findsWidgets);
    });

    testWidgets('onboarding pages advance with "Next" and finish with "Start Calculating"', (tester) async {
      await bootApp(tester, onboarded: false, skipLaunch: false);
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.tap(find.text('Next'));
      await settle(tester, 500);
      expect(find.textContaining('number of years'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await settle(tester, 500);
      expect(find.text('Start Calculating'), findsOneWidget);
      expect(find.textContaining('on your device'), findsOneWidget);
    });

    testWidgets('returning user goes straight to home (no onboarding)', (tester) async {
      await bootApp(tester);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Recently calculated'), findsOneWidget);
    });
  });

  group('calculator', () {
    testWidgets('Calculate Age shows a loading state, then the result with the Figma sample numbers', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('Calculate Age'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Calculating…'), findsOneWidget); // loading label
      await tester.pump(const Duration(milliseconds: 700)); // calc delay
      await tester.pump(const Duration(milliseconds: 400)); // page push
      await tester.pump(const Duration(milliseconds: 1000)); // count-up
      expect(find.text('Age result'), findsOneWidget);
      expect(find.text('28'), findsWidgets); // years (ring + well)
      expect(find.text('10,324'), findsOneWidget); // total days
      expect(find.text('247,776'), findsOneWidget); // total hours
      expect(find.text('268 days to go'), findsOneWidget);
    });

    testWidgets('date fields open the wheel sheet and apply the chosen date', (tester) async {
      await bootApp(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('Date of birth, month')).first);
      await settle(tester, 500);
      expect(find.text('Select Date'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester, 500);
      expect(find.text('Select Date'), findsNothing);
    });

    testWidgets('reference date defaults to today (November 19, 2026)', (tester) async {
      await bootApp(tester);
      expect(find.textContaining("Use today's date · November 19, 2026"), findsOneWidget);
    });
  });

  group('tabs', () {
    testWidgets('tab bar switches screens', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('History').last);
      await settle(tester);
      expect(find.text('7 saved calculations'), findsOneWidget);
      await tester.tap(find.text('Settings').last);
      await settle(tester);
      expect(find.text('Theme'), findsOneWidget);
      await tester.tap(find.text('Difference').last);
      await settle(tester);
      expect(find.text('Age difference'), findsOneWidget);
    });

    testWidgets('there is no UI Kit and no profile / login anywhere in the app', (tester) async {
      await bootApp(tester);
      for (final tab in ['Calculate', 'Difference', 'History', 'Settings']) {
        await tester.tap(find.text(tab).last);
        await settle(tester);
        expect(find.textContaining('UI Kit'), findsNothing);
        expect(find.textContaining('Sign in'), findsNothing);
        expect(find.textContaining('Profile'), findsNothing);
      }
    });
  });

  group('compare', () {
    testWidgets('default pair matches the Figma sample and names are editable', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('Difference').last);
      await settle(tester);
      expect(find.text('2 years, 5 months, 12 days'), findsOneWidget);
      expect(find.textContaining('Total 896 days, or 128 weeks'), findsOneWidget);

      final field = find.byType(EditableText).first;
      await tester.tap(field);
      await tester.enterText(field, 'Budi Santoso');
      await settle(tester, 200);
      expect(find.textContaining('Budi Santoso is older than Dimas'), findsOneWidget);

      await tester.enterText(field, '');
      await settle(tester, 200);
      expect(find.textContaining('Person 1 is older than Dimas'), findsOneWidget);
    });

    testWidgets('swap keeps the same difference', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('Difference').last);
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Swap person 1 and person 2'));
      await settle(tester, 300);
      expect(find.text('2 years, 5 months, 12 days'), findsOneWidget);
      expect(find.textContaining('Dimas is older'), findsNothing);
      expect(find.textContaining('Anita is older than Dimas'), findsOneWidget);
    });
  });

  group('history', () {
    testWidgets('swipe left deletes a row and "Undo" brings it back', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('History').last);
      await settle(tester);
      expect(find.text('Anita'), findsWidgets);
      await tester.drag(find.byType(Dismissible).first, const Offset(-400, 0));
      await settle(tester, 700);
      expect(find.text('6 saved calculations'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester, 600);
      expect(find.text('7 saved calculations'), findsOneWidget);
    });

    testWidgets('search filters and empty result offers a reset', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('History').last);
      await settle(tester);
      final search = find.byType(EditableText).first;
      await tester.enterText(search, 'mom');
      await settle(tester, 200);
      expect(find.text('Mom'), findsOneWidget);
      expect(find.text('Dimas'), findsNothing);
      await tester.enterText(search, 'zzz');
      await settle(tester, 200);
      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Reset search'), findsOneWidget);
    });

    testWidgets('trash → confirm dialog → history empties; the empty state invites the first calculation', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('History').last);
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Clear all history'));
      await settle(tester, 400);
      expect(find.text('Clear all history?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await settle(tester, 600);
      expect(find.text('No history yet'), findsOneWidget);
      expect(find.text('Calculate your first age'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('theme can be switched to dark and the choice is remembered', (tester) async {
      await bootApp(tester);
      await tester.tap(find.text('Settings').last);
      await settle(tester);
      await tester.tap(find.text('Dark'));
      await settle(tester, 500);
      final ctx = tester.element(find.text('Theme'));
      expect(Theme.of(ctx).brightness, Brightness.dark);
    });
  });
}
