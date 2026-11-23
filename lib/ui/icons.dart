import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// 24 px grid, stroke 2, round caps/joins — the same paths as the Figma "Iconography" set and the web app.
const Map<String, String> kIconPaths = {
  'calendar': 'M5 4h14a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z M16 2v4 M8 2v4 M3 10h18',
  'home': 'M3 11l9-8 9 8 M5 10v10a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V10',
  'clock': 'M12 3a9 9 0 1 0 .01 0z M12 7v5l3 2',
  'users': 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2 M9 3a4 4 0 1 0 .01 0 M23 21v-2a4 4 0 0 0-3-3.87 M16 3.13a4 4 0 0 1 0 7.75',
  'sliders': 'M4 21v-7 M4 10V3 M12 21v-9 M12 8V3 M20 21v-5 M20 12V3 M1 14h6 M9 8h6 M17 16h6',
  'gift': 'M20 12v10H4V12 M2 7h20v5H2z M12 22V7 M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z',
  'share': 'M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8 M16 6l-4-4-4 4 M12 2v13',
  'chevR': 'M9 18l6-6-6-6',
  'chevL': 'M15 18l-6-6 6-6',
  'chevD': 'M6 9l6 6 6-6',
  'chevU': 'M18 15l-6-6-6 6',
  'plus': 'M12 5v14 M5 12h14',
  'check': 'M20 6L9 17l-5-5',
  'x': 'M18 6L6 18 M6 6l12 12',
  'trash': 'M3 6h18 M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6 M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2',
  'moon': 'M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z',
  'sun': 'M12 8a4 4 0 1 0 .01 0z M12 1v2 M12 21v2 M4.22 4.22l1.42 1.42 M18.36 18.36l1.42 1.42 M1 12h2 M21 12h2 M4.22 19.78l1.42-1.42 M18.36 5.64l1.42-1.42',
  'star': 'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z',
  'search': 'M11 3a8 8 0 1 0 .01 0z M21 21l-4.35-4.35',
  'bell': 'M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9 M13.73 21a2 2 0 0 1-3.46 0',
  'arrowR': 'M5 12h14 M12 5l7 7-7 7',
  'arrowL': 'M19 12H5 M12 19l-7-7 7-7',
  'refresh': 'M23 4v6h-6 M1 20v-6h6 M3.51 9a9 9 0 0 1 14.85-3.36L23 10 M1 14l4.64 4.36A9 9 0 0 0 20.49 15',
  'info': 'M12 3a9 9 0 1 0 .01 0z M12 16v-4 M12 8h.01',
  'user': 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 3a4 4 0 1 0 .01 0',
  'bookmark': 'M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z',
  'globe': 'M12 3a9 9 0 1 0 .01 0z M3 12h18 M12 3a14 14 0 0 1 0 18 M12 3a14 14 0 0 0 0 18',
  'zap': 'M13 2L3 14h9l-1 8 10-12h-9l1-8z',
  'heart': 'M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z',
  'lock': 'M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z M7 11V7a5 5 0 0 1 10 0v4',
  'copy': 'M9 9h11a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V10a1 1 0 0 1 1-1z M5 15H4a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1h11a1 1 0 0 1 1 1v1',
  'grid': 'M3 3h7v7H3z M14 3h7v7h-7z M14 14h7v7h-7z M3 14h7v7H3z',
  'layers': 'M12 2L2 7l10 5 10-5-10-5z M2 17l10 5 10-5 M2 12l10 5 10-5',
  'edit': 'M12 20h9 M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z',
  'eye': 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z M12 9a3 3 0 1 0 .01 0z',
  'target': 'M12 3a9 9 0 1 0 .01 0z M12 7a5 5 0 1 0 .01 0z M12 11a1 1 0 1 0 .01 0z',
  'flag': 'M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z M4 22v-7',
  'list': 'M8 6h13 M8 12h13 M8 18h13 M3 6h.01 M3 12h.01 M3 18h.01',
  'pen': 'M12 19l7-7 3 3-7 7-3-3z M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z M2 2l7.586 7.586',
  'smartphone': 'M7 2h10a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z M12 18h.01',
  'monitor': 'M4 3h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M8 21h8 M12 17v4',
};

final Map<String, Path> _cache = {};

class AcIcon extends StatelessWidget {
  const AcIcon(this.name, {super.key, this.size = 24, this.color, this.strokeWidth = 2});
  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final path = _cache.putIfAbsent(name, () {
      final d = kIconPaths[name];
      if (d == null) throw ArgumentError('Unknown icon $name');
      return parseSvgPathData(d);
    });
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox(
      width: size,
      height: size,
      child: ExcludeSemantics(child: CustomPaint(painter: _IconPainter(path, c, strokeWidth))),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.path, this.color, this.sw);
  final Path path;
  final Color color;
  final double sw;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s, s);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.color != color || o.path != path || o.sw != sw;
}
