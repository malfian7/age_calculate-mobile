import 'package:flutter/material.dart';
import '../core/tokens.dart';
import '../ui/icons.dart';
import '../ui/logo.dart';
import '../ui/neu.dart';

/// Launch sequence (Figma → Interaction → "Launch timeline"), ~1.5 s:
///   orbs scale 0.6→1 · logo scale 0.8→1 · wordmark fades up 8 px · tagline fades · progress bar fills (linear).
/// Reduced motion → everything just fades and the whole thing takes 0.5 s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _setUp = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_setUp) return;
    _setUp = true;
    _c = AnimationController(vsync: this, duration: context.reduceMotion ? const Duration(milliseconds: 500) : Motion.splash)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _iv(int from, int to, Curve curve) {
    final total = _c.duration!.inMilliseconds.toDouble();
    final reduce = total < 1000;
    final a = reduce ? 0.0 : from / total;
    final b = reduce ? 1.0 : (to / total).clamp(0.0, 1.0).toDouble();
    return CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final reduce = context.reduceMotion;
    final orbOuter = _iv(80, 720, Motion.out), orbInner = _iv(160, 800, Motion.out), logo = _iv(200, 840, Motion.out);
    final word = _iv(420, 840, Motion.out), tag = _iv(560, 980, Motion.out);
    final bar = CurvedAnimation(parent: _c, curve: Interval(reduce ? 0.0 : 500 / 1500, 1.0, curve: Curves.linear));

    Widget scaleFade(Animation<double> a, double from, Widget child) => FadeTransition(
          opacity: a,
          child: reduce ? child : ScaleTransition(scale: Tween<double>(begin: from, end: 1).animate(a), child: child),
        );

    return Semantics(
      label: 'Loading Age Calculate', liveRegion: true,
      child: Material(
        color: c.surface,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              SizedBox(
                width: 300, height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    scaleFade(orbOuter, 0.6, Neu(radius: 999, raised: (16.0, 34.0), width: 300, height: 300)),
                    scaleFade(orbInner, 0.6, Neu(radius: 999, inset: Elev.iDeep, width: 220, height: 220)),
                    scaleFade(
                      logo, 0.8,
                      DecoratedBox(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), boxShadow: const [BoxShadow(color: Color(0x595B3BE0), offset: Offset(0, 14), blurRadius: 26)]),
                        child: const LogoMark(size: 140),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: word,
                child: AnimatedBuilder(animation: word, builder: (_, child) => Transform.translate(offset: Offset(0, reduce ? 0 : 8 * (1 - word.value)), child: child), child: const Wordmark(size: 34)),
              ),
              const SizedBox(height: 6),
              FadeTransition(opacity: tag, child: Text('Calculate age, precisely.', style: Tx.label(15, Tx.w5, c.ink3))),
              const Spacer(flex: 6),
              SizedBox(
                width: 180, height: 8,
                child: Neu(
                  radius: 4, inset: Elev.iXs, clip: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(animation: bar, builder: (_, __) => FractionallySizedBox(widthFactor: bar.value.clamp(0.0, 1.0).toDouble(), child: const DecoratedBox(decoration: BoxDecoration(gradient: P.gradient), child: SizedBox(height: 8)))),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('Loading…', style: Tx.label(12, Tx.w7, c.ink2)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================================================== onboarding
class _Page {
  const _Page(this.tag, this.title, this.body, this.coreIcon, this.big, this.unit);
  final String tag, title, body;
  final String? coreIcon, big, unit;
}

const _pages = [
  _Page('Age Calculate', 'Your age, calculated\nwith precision.', 'Years, months, days, even hours. Just enter your date of birth.', null, '28', 'YEARS'),
  _Page('More detail', 'More than just\na number of years.', 'Birthday countdown, totals from days to hours, and the age difference between two people.', 'gift', null, null),
  _Page('Privacy', 'Your data stays\non your device.', 'No account, no server, no trackers. History is stored only here.', 'lock', null, null),
];

/// First launch only. Swipe or tap "Next"; "Skip" jumps straight in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= _pages.length - 1) {
      widget.onDone();
      return;
    }
    _pc.nextPage(duration: Motion.of(context, Motion.moderate), curve: Motion.standard);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final last = _i == _pages.length - 1;
    return Material(
      color: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc, itemCount: _pages.length, onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (ctx, i) {
                  final p = _pages[i];
                  return LayoutBuilder(builder: (ctx, box) {
                    final s = (box.maxHeight * 0.46).clamp(220.0, 300.0).toDouble();
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Orb(size: s, page: p),
                            const SizedBox(height: 28),
                            Tag(p.tag),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Semantics(header: true, child: Text(p.title, textAlign: TextAlign.center, style: Tx.h1(c.ink).copyWith(height: 1.12))),
                            ),
                            const SizedBox(height: 10),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 36), child: Text(p.body, textAlign: TextAlign.center, style: Tx.body(c.ink2).copyWith(height: 1.5))),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: Motion.of(context, Motion.base), curve: Motion.out, margin: const EdgeInsets.symmetric(horizontal: 4), width: i == _i ? 28 : 8, height: 8,
                    decoration: BoxDecoration(gradient: i == _i ? P.gradient : null, color: i == _i ? null : (c.dark ? c.line : P.p200), borderRadius: BorderRadius.circular(4)),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: NeuButton(label: last ? 'Start Calculating' : 'Next', icon: 'arrowR', iconRight: true, size: BtnSize.lg, block: true, onPressed: _next),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1, duration: Motion.of(context, Motion.base),
                child: IgnorePointer(ignoring: last, child: NeuButton(label: 'Skip', kind: BtnKind.ghost, size: BtnSize.sm, onPressed: widget.onDone)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.page});
  final double size;
  final _Page page;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final core = size * 0.467;
    return ExcludeSemantics(
      child: SizedBox(
        width: size, height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Neu(radius: 999, raised: (size * 0.053, size * 0.113), width: size, height: size),
            Neu(radius: 999, inset: (size * 0.033, size * 0.073), width: size * 0.733, height: size * 0.733),
            Container(
              width: core, height: core, alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: P.gradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x805B3BE0), offset: Offset(0, 16), blurRadius: 30)]),
              child: page.coreIcon != null
                  ? AcIcon(page.coreIcon!, size: core * 0.42, color: Colors.white, strokeWidth: 1.8)
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(page.big!, style: Tx.num(core * 0.46, Tx.w8, Colors.white, -0.04, core * 0.42)),
                      Text(page.unit!, style: Tx.label(12, Tx.w7, P.p100, 0.12)),
                    ]),
            ),
            Positioned(top: size * 0.12, right: size * 0.1, child: Neu(radius: 999, raised: Elev.xs, width: 22, height: 22)),
            Positioned(bottom: size * 0.1, left: size * 0.15, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: P.p300, shape: BoxShape.circle, boxShadow: raisedShadows(c, Elev.xs)))),
          ],
        ),
      ),
    );
  }
}
