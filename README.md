# Age Calculate — Mobile App (Flutter)

A native mobile app (not a web view) built from the Figma design "Age Calculate": purple-and-white neumorphism, light and dark mode.
No account, no server. All data stays on the device. **There is no UI Kit menu in this app.**

## Verification status - read this first

Last checked with Flutter 3.50.0 (Dart 3.14.0), after translating the app to English:
`flutter analyze lib test` reports two errors in `lib/ui/overlays.dart` (`Semantics` no longer accepts `increasable` / `decreasable`)
plus deprecation infos; the age unit tests (`test/age_test.dart`) pass; 4 of the screen-flow tests in `test/app_flow_test.dart`
and the onboarding screenshot test fail the same way they did before the translation (hit-test / animation issues with this Flutter version).
It has still not been verified on a device.

## Running

Requires Flutter 3.27 or newer (Dart 3.6+).

```bash
# 1. from this folder, create the Android and iOS platform folders (once)
flutter create . --platforms=android,ios --project-name age_calculate --org app.agecalculate

# 2. delete the default sample test if it appears (it is for the counter app)
#    del test\widget_test.dart

flutter pub get

# 3. check first
flutter analyze
flutter test                      # age unit tests + screen flows
flutter test test/visual          # writes screenshots to build/screenshots/

# 4. app icon (from assets/icon), then run
dart run flutter_launcher_icons
flutter run
```

After `flutter create`, change the name shown in the launcher:
`android/app/src/main/AndroidManifest.xml` → `android:label="Age Calculate"` and `ios/Runner/Info.plist` → `CFBundleDisplayName` = `Age Calculate`.
Replace `--org app.agecalculate` with your own ID if you will publish to the stores.

## Screens

| Screen | Contents |
|---|---|
| Splash | Orb, logo, wordmark, progress (1.5 s) |
| Onboarding | 3 pages, only on first launch |
| **Calculate** | Date of birth and reference date (date wheels in a bottom sheet), "use today's date" toggle, Calculate Age button (loads for 620 ms), recent history |
| Result | Age ring fills over 900 ms with a number count-up, years/months/days breakdown, total days/hours/weeks/months, next birthday + milestones, Save, Share (copy, send, image) |
| **Difference** | Two people with **editable names**, dates of birth, swap, age difference result, share, save |
| **History** | Search, category filter, swipe left to delete (with "Undo"), long-press for the action menu, empty / no-results states |
| **Settings** | Theme (system/light/dark), birthday marker, data & privacy, about |

## Structure

```
lib/
  core/age.dart          age calculation (port of the web app: age.js)
  core/tokens.dart       light + dark colors, typography, radii, motion
  state/stores.dart      AppState (theme, history, onboarding), CalcState, ToastController, TabNav
  ui/neu.dart            Neu (raised/inset), NeuPressable, buttons, chip, toggle, segmented, skeleton, stagger
  ui/overlays.dart       page route, bottom sheet, date wheels, dialog, toast, text field, save sheet
  ui/ring.dart           age ring + ResultMotion (one curve for the ring and the numbers)
  ui/logo.dart, icons.dart   logo (CustomPainter) and 41 icons (the same SVG paths as Figma)
  screens/               splash_onboarding, shell (tab bar), hitung, result, compare, history, settings
test/                    age_test (port of the web tests), app_flow_test (flows), visual/screenshots_test
assets/fonts             Plus Jakarta Sans (OFL license, see OFL.txt)
assets/icon              app icon and Android adaptive foreground
```

## Decisions worth knowing

- **One surface, two shadows.** Flutter has no inset shadow, so `InsetPainter` draws it itself. Buttons are "raised" and fade to "inset" when pressed, along with a 0.98 scale.
- **Motion follows the spec in Figma** (Interaction page): duration/curve tokens in `Motion`; page push 320 ms with −30% parallax; bottom sheet 320/240 ms; dialog 240 ms; toast rises 24 px; error shake ±8 px × 3; stagger 40 ms. The system "reduce motion" setting is honored: movement is replaced by a short fade.
- **Haptics:** a tick on every date wheel row and every chip/toggle, light on the primary button, medium on delete.
- **Accessibility:** every control has a Semantics label, touch targets are at least 44 px, keyboard focus is visible, and results are announced as a live region.
- **Dates are always valid:** they are picked with the wheels, so the only possible error is a date of birth after the reference date. The day adjusts to the number of days in the month.
- **History starts with 7 sample entries** (made-up names) as on the web. Set `kSeedDemoHistory` in `lib/state/stores.dart` to `false` to start empty.
- **Differences from Figma:** the Settings menu has no "Date format" or "Language" (not implemented); the web version's Age Details page is merged into the Result screen (tap the birthday card for the countdown and milestones).
- English only (`locale: en_US`): numbers like `1,474`, dates like `Aug 14, 1998` (short) and `Friday, August 14, 1998` (long), durations like `28 years, 3 months, 5 days`, compact `56y 8mo`.
- History categories are stored as `Family`, `Friends`, `Work` and `Personal`. Entries saved by earlier (Indonesian) builds are migrated on load.

## Not done yet

Real birthday reminder notifications, other languages, and release builds (Android signing, iOS provisioning).
