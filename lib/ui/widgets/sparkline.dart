import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mini-courbe lissée sans axes, pour les cartes de sites.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 60,
    this.height = 26,
    this.strokeWidth = 2,
    this.fill = false,
  });

  final List<double> values;
  final Color color;
  final double width;
  final double height;
  final double strokeWidth;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkPainter(values, color, strokeWidth, fill),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.strokeWidth, this.fill);

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final pad = strokeWidth;
    final h = size.height - pad * 2;
    final n = values.length;

    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(
          i / (n - 1) * size.width,
          pad + h - (values[i] - minV) / range * h,
        ),
    ];

    final path = _smoothPath(pts);

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  /// Lissage Catmull-Rom → cubiques de Bézier.
  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      const t = 0.16;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) * t, p1.dy + (p2.dy - p0.dy) * t);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) * t, p2.dy - (p3.dy - p1.dy) * t);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}
