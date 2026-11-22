import 'package:flutter/material.dart';

import '../../domain/dive/dive.dart';

/// Mini depth profile for a logbook card (ui-spec §5.2): filled area in
/// [color], depth growing downwards. Dives without samples get the
/// estimated rectangle profile, dashed.
class DiveSparkline extends StatelessWidget {
  const DiveSparkline({
    super.key = const ValueKey('sparkline'),
    required this.dive,
    required this.color,
    this.height = 34,
    this.depthScaleM = 40,
  });

  final Dive dive;
  final Color color;
  final double height;

  /// Depth that fills the full height, so cards can be compared.
  final double depthScaleM;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          dive: dive,
          color: color,
          depthScaleM: depthScaleM,
        ),
      ),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.dive,
    required this.color,
    required this.depthScaleM,
  });

  final Dive dive;
  final Color color;
  final double depthScaleM;

  @override
  void paint(Canvas canvas, Size size) {
    if (dive.durationS <= 0) return;
    final scale = depthScaleM < dive.maxDepthM ? dive.maxDepthM : depthScaleM;
    double x(num t) => t / dive.durationS * size.width;
    double y(num d) => d / scale * (size.height - 2);

    final points = <Offset>[];
    final estimated = dive.samples.length < 2;
    if (estimated) {
      // Rectangle profile from depth and duration (ui-spec §5.3).
      final edge = dive.durationS * 0.08;
      points.addAll([
        Offset(x(0), 0),
        Offset(x(edge), y(dive.maxDepthM)),
        Offset(x(dive.durationS - edge), y(dive.maxDepthM)),
        Offset(x(dive.durationS), 0),
      ]);
    } else {
      // At most ~120 points, enough for 34 dp.
      final step = (dive.samples.length / 120).ceil().clamp(1, 1 << 20);
      for (var i = 0; i < dive.samples.length; i += step) {
        final s = dive.samples[i];
        points.add(Offset(x(s.timeS), y(s.depthM)));
      }
      final last = dive.samples.last;
      points.add(Offset(x(last.timeS), y(last.depthM)));
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, 0)
      ..lineTo(points.first.dx, 0)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.18));
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (!estimated) {
      canvas.drawPath(line, stroke);
      return;
    }
    for (final metric in line.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.dive != dive || old.color != color;
}
