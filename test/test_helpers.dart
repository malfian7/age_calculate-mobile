import 'package:age_calculate/app.dart';
import 'package:age_calculate/core/age.dart' as age;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Today" for every test: November 19, 2026 (the date used throughout the design file).
final DateTime kToday = DateTime(2026, 11, 19, 10);

bool _fontsLoaded = false;

/// Real Plus Jakarta Sans instead of the test font, so text widths match the device.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('PlusJakartaSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$w.ttf'));
  }
  await loader.load();
  _fontsLoaded = true;
}

void phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Boots the real app. [onboarded] skips the first-launch pager; [skipLaunch] also waits out splash + skeleton.
Future<void> bootApp(
  WidgetTester tester, {
  bool onboarded = true,
  bool skipLaunch = true,
  Map<String, Object> prefs = const {},
  GlobalKey? boundaryKey,
}) async {
  age.clock = () => kToday;
  addTearDown(() => age.clock = DateTime.now);
  await loadAppFonts();
  phoneSize(tester);
  SharedPreferences.setMockInitialValues({if (onboarded) 'ac.onboarded': true, ...prefs});
  final sp = await SharedPreferences.getInstance();
  Widget app = AgeCalculateApp(prefs: sp);
  if (boundaryKey != null) app = RepaintBoundary(key: boundaryKey, child: app);
  await tester.pumpWidget(app);
  if (skipLaunch) await finishLaunch(tester, onboarded: onboarded);
}

/// splash (1.5 s) → cross-fade (0.3 s) → skeleton (0.7 s). Animations repeat forever, so never use pumpAndSettle here.
Future<void> finishLaunch(WidgetTester tester, {bool onboarded = true}) async {
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pump(const Duration(milliseconds: 400));
  if (onboarded) await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> settle(WidgetTester tester, [int ms = 600]) async {
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(Duration(milliseconds: ms));
}
