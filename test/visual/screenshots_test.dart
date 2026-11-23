// Renders the real screens (with the real font) to PNG files in build/screenshots/ so the design can be reviewed
// without a device:   flutter test test/visual/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/screenshots/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';
    testWidgets('screens ($tag)', (tester) async {
      final key = GlobalKey();
      await bootApp(tester, skipLaunch: false, boundaryKey: key, prefs: {'ac.theme': dark ? 'dark' : 'light'});
      await tester.pump(const Duration(milliseconds: 700));
      await shoot(tester, key, '$tag-1-splash');
      await finishLaunch(tester);
      await tester.pump(const Duration(milliseconds: 700)); // let the stagger entrance finish
      await shoot(tester, key, '$tag-2-calculate');

      await tester.tap(find.text('Calculate Age'));
      await tester.pump(const Duration(milliseconds: 150));
      await shoot(tester, key, '$tag-3-calculating');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 1000));
      await shoot(tester, key, '$tag-4-result');
      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester, 500);

      await tester.tap(find.text('Difference').last);
      await settle(tester);
      await shoot(tester, key, '$tag-5-difference');
      await tester.tap(find.text('History').last);
      await settle(tester);
      await shoot(tester, key, '$tag-6-history');
      await tester.tap(find.text('Settings').last);
      await settle(tester);
      await shoot(tester, key, '$tag-7-settings');
    });
  }

  testWidgets('onboarding + date sheet', (tester) async {
    final key = GlobalKey();
    await bootApp(tester, onboarded: false, skipLaunch: false, boundaryKey: key, prefs: {'ac.theme': 'light'});
    await tester.pump(const Duration(milliseconds: 2000));
    await shoot(tester, key, 'light-0-onboarding');
    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(find.bySemanticsLabel(RegExp('Date of birth, month')).first);
    await settle(tester, 600);
    await shoot(tester, key, 'light-8-sheet-date');
  });
}
