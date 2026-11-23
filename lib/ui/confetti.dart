import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/tokens.dart';
import 'neu.dart';

/// One-shot confetti fan for the rare "birthday is today" moment (delight tier).
/// Particles are deterministic (seeded) and a pure function of time, so it is cheap and repeatable.
/// Reduced motion → nothing is drawn.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.origin = const Alignment(0, -0.3), this.delay = const Duration(milliseconds: 650)});
  final Alignment origin;
  final Duration delay;
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final List<_Piece> _pieces = _make();
  bool _started = false;

  static const _colors = [Color(0xFF5B3BE0), Color(0xFF8B6CF5), Color(0xFFC4B5FD), Color(0xFFFFC857), Color(0xFFFF7AA2), Color(0xFF5ED6C1)];

  List<_Piece> _make() {
    final r = math.Random(7);
    return List.generate(48, (i) {
      final angle = -math.pi * (0.08 + 0.84 * r.nextDouble()); // upward fan
      final speed = 380 + 520 * r.nextDouble();
      return _Piece(
        vx: math.cos(angle) * speed, vy: math.sin(angle) * speed,
        spin: (r.nextDouble() - 0.5) * 14, phase: r.nextDouble() * math.pi * 2,
        w: 6 + 6 * r.nextDouble(), h: 3 + 5 * r.nextDouble(), color: _colors[i % _colors.length], round: i % 5 == 0,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || context.reduceMotion) return;
    _started = true;
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      haptic(Haptic.medium);
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => _c.value == 0 ? const SizedBox.expand() : CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value * 2.2, widget.origin)),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({required this.vx, required this.vy, required this.spin, required this.phase, required this.w, required this.h, required this.color, required this.round});
  final double vx, vy, spin, phase, w, h;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t, this.origin);
  final List<_Piece> pieces;
  final double t; // seconds
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = origin.alongSize(size);
    const gravity = 1100.0, drag = 2.2;
    final fade = (1 - ((t - 1.5) / 0.7)).clamp(0.0, 1.0).toDouble();
    if (fade == 0) return;
    for (final p in pieces) {
      // velocity decays with air drag: x(t) = v/k * (1 - e^{-kt})
      final k = 1 - math.exp(-drag * t);
      final x = o.dx + p.vx / drag * k + math.sin(t * 5 + p.phase) * 6 * t;
      final y = o.dy + p.vy / drag * k + 0.5 * gravity * t * t * 0.55;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t + p.phase);
      // flutter in 3D: squash height with a cosine
      final squash = 0.35 + 0.65 * math.cos(t * 7 + p.phase).abs();
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.w * 0.4, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h * squash * 1.6), const Radius.circular(1.5)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}
