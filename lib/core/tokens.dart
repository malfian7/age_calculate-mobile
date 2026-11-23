import 'package:flutter/material.dart';

// Design tokens — the same values as the Figma "Design System" variables and the web app's tokens.css.
// Depth strategy: neumorphism. ONE surface colour; depth only from a light shadow (top-left) and a dark shadow (bottom-right).

/// Purple scale (identical in both themes).
abstract final class P {
  static const p50 = Color(0xFFF4F0FF);
  static const p100 = Color(0xFFE8E1FF);
  static const p200 = Color(0xFFD3C8FF);
  static const p300 = Color(0xFFB7A4FF);
  static const p400 = Color(0xFF9A80FF);
  static const p500 = Color(0xFF7C5CFC);
  static const p600 = Color(0xFF6845EA);
  static const p700 = Color(0xFF5232C8);
  static const p800 = Color(0xFF3B2391);
  static const p900 = Color(0xFF2A1869);

  static const gradStart = Color(0xFF7352F0);
  static const gradEnd = Color(0xFF5B3BE0);
  static const gradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gradStart, gradEnd]);
  static const gradientHover = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8261FF), Color(0xFF6A49EA)]);
  static const gradientPress = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5B3BE0), Color(0xFF4A2DBA)]);
}

@immutable
class AcColors extends ThemeExtension<AcColors> {
  const AcColors({
    required this.dark, required this.surface, required this.surfaceHi, required this.shLight, required this.shDark, required this.shInset,
    required this.line, required this.ink, required this.ink2, required this.ink3, required this.accent, required this.accentStrong,
    required this.accentSoft, required this.accentFaint, required this.ringTrack, required this.skeleton, required this.skeletonHi,
    required this.scrim, required this.ok, required this.okText, required this.okBg, required this.err, required this.errBg, required this.warn,
  });

  final bool dark;
  final Color surface, surfaceHi, shLight, shDark, shInset, line, ink, ink2, ink3, accent, accentStrong, accentSoft, accentFaint, ringTrack, skeleton, skeletonHi, scrim, ok, okText, okBg, err, errBg, warn;

  static const light = AcColors(
    dark: false, surface: Color(0xFFEEEBF8), surfaceHi: Color(0xFFF6F4FD), shLight: Color(0xFFFFFFFF), shDark: Color(0xFFC9C0E6), shInset: Color(0xFFC2B8E2),
    line: Color(0xFFD9D3EE), ink: Color(0xFF2B2150), ink2: Color(0xFF5C5480), ink3: Color(0xFF686088), accent: P.p600, accentStrong: P.p700,
    accentSoft: P.p100, accentFaint: P.p50, ringTrack: Color(0xFFDCD5F0), skeleton: P.p100, skeletonHi: Color(0xFFFFFFFF), scrim: Color(0x731D1740),
    ok: Color(0xFF2FB67C), okText: Color(0xFF16784F), okBg: Color(0xFFD9F3E8), err: Color(0xFFC93036), errBg: Color(0xFFFBE0E1), warn: Color(0xFFF5A524),
  );

  // Same hue, only lightness shifts. Shadows are weak on dark, so the pair is pushed apart.
  static const darkTheme = AcColors(
    dark: true, surface: Color(0xFF221E3D), surfaceHi: Color(0xFF2A2549), shLight: Color(0xFF2F2A55), shDark: Color(0xFF141126), shInset: Color(0xFF15122A),
    line: Color(0xFF352F5D), ink: Color(0xFFF1EEFF), ink2: Color(0xFFC5BEEA), ink3: Color(0xFFA39BD0), accent: P.p300, accentStrong: P.p200,
    accentSoft: Color(0xFF342C63), accentFaint: Color(0xFF2B2552), ringTrack: Color(0xFF302A58), skeleton: Color(0xFF2F2956), skeletonHi: Color(0xFF3D3670),
    scrim: Color(0x9E080614), ok: Color(0xFF2FB67C), okText: Color(0xFF6FDCAE), okBg: Color(0xFF173A31), err: Color(0xFFFF8085), errBg: Color(0xFF4A2230), warn: Color(0xFFF5A524),
  );

  @override
  AcColors copyWith() => this;

  @override
  AcColors lerp(ThemeExtension<AcColors>? other, double t) => other is AcColors ? (t < 0.5 ? this : other) : this;
}

extension AcContext on BuildContext {
  AcColors get ac => Theme.of(this).extension<AcColors>()!;
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Radii (Figma: r-12 … r-full).
abstract final class R {
  static const r12 = 12.0, r16 = 16.0, r20 = 20.0, r24 = 24.0, r28 = 28.0, r32 = 32.0, r36 = 36.0;
}

/// Motion tokens (Figma "Motion" variables). UI stays under 300 ms; the result is the one slow moment.
abstract final class Motion {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 120);
  static const press = Duration(milliseconds: 80);
  static const base = Duration(milliseconds: 200);
  static const moderate = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);
  static const draw = Duration(milliseconds: 900);
  static const splash = Duration(milliseconds: 1500);

  static const Curve out = Cubic(0.23, 1, 0.32, 1); // enter / interactive
  static const Curve inOut = Cubic(0.77, 0, 0.175, 1); // movement already on screen
  static const Curve standard = Cubic(0.2, 0, 0, 1); // state changes, page push
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1); // sheets
  static const Curve exit = Cubic(0.4, 0, 1, 1);
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1); // small overshoot - selection pops, playful moments only

  /// Reduced motion keeps the information but drops movement: durations collapse to a short fade.
  static Duration of(BuildContext c, Duration d) => c.reduceMotion ? (d == Duration.zero ? d : const Duration(milliseconds: 1)) : d;
}

const String kFont = 'PlusJakartaSans';
const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

/// Type scale (Figma: Display … Overline). Letter-spacing is given in em like the design file.
abstract final class Tx {
  static TextStyle _s(double size, FontWeight w, {double ls = 0, double? lh, Color? color, bool tab = false}) => TextStyle(
        fontFamily: kFont, fontSize: size, fontWeight: w, letterSpacing: ls * size, height: lh == null ? null : lh / size, color: color,
        fontFeatures: tab ? kTabular : null, leadingDistribution: TextLeadingDistribution.even,
      );

  static const w4 = FontWeight.w400, w5 = FontWeight.w500, w6 = FontWeight.w600, w7 = FontWeight.w700, w8 = FontWeight.w800;

  static TextStyle display([Color? c]) => _s(48, w8, ls: -0.04, lh: 52, color: c);
  static TextStyle h1([Color? c]) => _s(34, w8, ls: -0.03, lh: 40, color: c);
  static TextStyle h2([Color? c]) => _s(28, w8, ls: -0.02, lh: 34, color: c);
  static TextStyle h3([Color? c]) => _s(24, w8, ls: -0.01, lh: 32, color: c);
  static TextStyle h4([Color? c]) => _s(18, w8, lh: 24, color: c);
  static TextStyle bodyL([Color? c]) => _s(17, w5, lh: 26, color: c);
  static TextStyle body([Color? c]) => _s(15, w5, lh: 22, color: c);
  static TextStyle bodyS([Color? c]) => _s(13, w5, lh: 19, color: c);
  static TextStyle caption([Color? c]) => _s(12, w6, lh: 16, color: c);
  static TextStyle overline([Color? c]) => _s(11, w7, ls: 0.06, lh: 16, color: c);
  static TextStyle label(double size, FontWeight w, [Color? c, double ls = 0]) => _s(size, w, ls: ls, color: c);
  static TextStyle num(double size, FontWeight w, [Color? c, double ls = 0, double? lh]) => _s(size, w, ls: ls, lh: lh, color: c, tab: true);
}

/// Spacing (base 4).
abstract final class S {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0, s24 = 24.0, s32 = 32.0;
}

ThemeData buildTheme(AcColors c) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: c.dark ? Brightness.dark : Brightness.light,
    fontFamily: kFont,
    scaffoldBackgroundColor: c.surface,
    canvasColor: c.surface,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(seedColor: P.p600, brightness: c.dark ? Brightness.dark : Brightness.light).copyWith(surface: c.surface, primary: c.accent, onSurface: c.ink),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent, selectionColor: P.p300.withValues(alpha: 0.45), selectionHandleColor: c.accent),
    extensions: [c],
  );
  return base;
}
