import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/tokens.dart';
import 'neu.dart';

/// Age ring — Figma "AgeRing". `progress` (0–1) = share of the year already lived since the last birthday.
/// The centre is an inset disc holding the big number and its unit.
class AgeRing extends StatelessWidget {
  const AgeRing({super.key, required this.size, required this.progress, this.child, this.semanticLabel});
  final double size;
  final double progress;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = size;
    return Semantics(
      image: true, label: semanticLabel, container: true,
      child: SizedBox(
        width: s, height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: raisedShadows(c, (s * 0.04, s * 0.09))),
              child: SizedBox.square(dimension: s),
            ),
            CustomPaint(size: Size.square(s), painter: _RingPainter(progress.clamp(0.0, 1.0).toDouble(), c.ringTrack)),
            Padding(
              padding: EdgeInsets.all(s * 0.19),
              child: Neu(
                radius: 999, inset: (s * 0.02, s * 0.045),
                child: Center(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.p, this.track);
  final double p;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s, s);
    const outer = 42.5, thick = 0.14;
    const sw = outer * thick;
    const mid = outer * (1 - thick / 2);
    final rect = Rect.fromCircle(center: const Offset(50, 50), radius: mid);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..isAntiAlias = true;
    canvas.drawCircle(const Offset(50, 50), mid, base..color = track);
    if (p > 0) {
      final shader = P.gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100));
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..isAntiAlias = true..shader = shader);
      // glowing knob riding the tip of the arc while it draws
      if (p > 0.02) {
        final a = -math.pi / 2 + 2 * math.pi * p;
        final tip = Offset(50 + mid * math.cos(a), 50 + mid * math.sin(a));
        canvas.drawCircle(tip, sw * 0.95, Paint()..color = const Color(0x665B3BE0)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
        canvas.drawCircle(tip, sw * 0.34, Paint()..color = Colors.white);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.p != p || o.track != track;
}

/// One eased 0→1 factor that drives the ring, the big number, the Y/M/D wells and the tiles together
/// (900 ms, ease-out). Reduced motion → already 1. Replays when [runKey] changes.
class ResultMotion extends StatefulWidget {
  const ResultMotion({super.key, required this.builder, this.runKey = 0, this.delay = Duration.zero});
  final Widget Function(BuildContext context, double p) builder;
  final Object runKey;
  final Duration delay;
  @override
  State<ResultMotion> createState() => _ResultMotionState();
}

class _ResultMotionState extends State<ResultMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.draw);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: const Cubic(0.165, 0.84, 0.44, 1)); // ease-out quart
  bool _first = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_first) {
      _first = false;
      _play();
    }
  }

  @override
  void didUpdateWidget(ResultMotion old) {
    super.didUpdateWidget(old);
    if (old.runKey != widget.runKey) _play();
  }

  void _play() {
    if (context.reduceMotion) {
      _c.value = 1;
      return;
    }
    _c.value = 0;
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _a, builder: (ctx, _) => widget.builder(ctx, _a.value));
}
