import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/tokens.dart';

enum LogoVariant { tile, purple, mono }

/// Age Calculate mark — a birthday candle inside an age ring.
/// ring = time (opens top-left: the year still to come) · candle = birthday · flame = the moment being counted.
/// Geometry is the Figma logo in a 100×100 box.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 44, this.variant = LogoVariant.tile, this.color, this.semanticLabel});
  final double size;
  final LogoVariant variant;
  final Color? color; // for mono
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final w = CustomPaint(size: Size.square(size), painter: _LogoPainter(variant, color ?? context.ac.ink));
    return semanticLabel == null ? ExcludeSemantics(child: w) : Semantics(image: true, label: semanticLabel, child: w);
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.variant, this.mono);
  final LogoVariant variant;
  final Color mono;

  static const double _r = 34, _t = 0.17 * _r;
  static final double _mid = _r - _t / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s, s);
    final box = const Rect.fromLTWH(0, 0, 100, 100);
    final grad = P.gradient.createShader(box);
    final tile = variant == LogoVariant.tile;

    if (tile) canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(28)), Paint()..shader = grad);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _t
      ..isAntiAlias = true;
    if (tile) {
      ringPaint.color = Colors.white;
    } else if (variant == LogoVariant.purple) {
      ringPaint.shader = grad;
    } else {
      ringPaint.color = mono;
    }
    canvas.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: _mid), -math.pi / 2, 290 * math.pi / 180, false, ringPaint);

    final candle = Paint()..color = tile ? P.p200 : (variant == LogoVariant.purple ? P.p300 : mono);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43.75, 50, 12.5, 20), const Radius.circular(6.25)), candle);

    final flame = Path()
      ..moveTo(50, 30)
      ..cubicTo(56.6, 37.14, 56.27, 43.26, 50, 47)
      ..cubicTo(43.73, 43.26, 43.4, 37.14, 50, 30)
      ..close();
    final fp = Paint()..isAntiAlias = true;
    if (tile) {
      fp.color = Colors.white;
    } else if (variant == LogoVariant.purple) {
      fp.shader = grad;
    } else {
      fp.color = mono;
    }
    canvas.drawPath(flame, fp);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter o) => o.variant != variant || o.mono != mono;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 21});
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Age ', style: Tx.label(size, Tx.w8, c.ink, -0.03)),
        TextSpan(text: 'Calculate', style: Tx.label(size, Tx.w8, c.accent, -0.03)),
      ]),
      maxLines: 1,
    );
  }
}
