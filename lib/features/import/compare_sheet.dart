import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../logbook/dive_texts.dart';

/// „Tauchgänge vergleichen“ (ui-spec §5.9, T26): the new dive next to the
/// similar one in the logbook. Pops true for „Importieren“, false for
/// „Nicht importieren“, null when dismissed.
class CompareSheet extends StatelessWidget {
  const CompareSheet({super.key, required this.fresh, required this.stored});

  final Dive fresh;
  final Dive stored;

  static const _units = UnitFormatter.metric();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    String? temp(Dive d) => switch (d.minTemperatureC) {
      final t? => _units.temperature(t),
      null => null,
    };
    String? avg(Dive d) => switch (d.avgDepthM) {
      final a? => _units.depth(a),
      null => null,
    };
    final rows = <(String, String?, String?)>[
      (
        l10n.fieldDate,
        dateFormat.format(fresh.start),
        dateFormat.format(stored.start),
      ),
      (
        l10n.fieldStartTime,
        timeFormat.format(fresh.start),
        timeFormat.format(stored.start),
      ),
      (
        l10n.compareSource,
        sourceLabel(l10n, fresh.source),
        sourceLabel(l10n, stored.source),
      ),
      (
        l10n.metricMaxDepth,
        _units.depth(fresh.maxDepthM),
        _units.depth(stored.maxDepthM),
      ),
      (
        l10n.metricDuration,
        _units.duration(fresh.durationS),
        _units.duration(stored.durationS),
      ),
      (l10n.metricAvgDepth, avg(fresh), avg(stored)),
      (l10n.metricMinTemperature, temp(fresh), temp(stored)),
    ];

    Widget cell(String? text, {bool bold = false, Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text ?? '–',
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : null,
          color: color,
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.compareTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    // The headers carry the curve colours: the legend of the
                    // chart below.
                    _Legend(color: colors.depth, text: l10n.compareNew),
                    _Legend(
                      color: colors.accent,
                      text: l10n.compareStored,
                      line: true,
                    ),
                  ],
                ),
                for (final (label, a, b) in rows)
                  TableRow(
                    children: [
                      cell(label, color: colors.onSurfaceMuted),
                      cell(a, bold: a != b),
                      cell(b, bold: a != b),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: const ValueKey('compare-chart'),
              height: 150,
              child: CustomPaint(
                painter: _ComparePainter(
                  fresh: fresh,
                  stored: stored,
                  freshColor: colors.depth,
                  storedColor: colors.accent,
                  gridColor: colors.outline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.compareImport),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.compareSkip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text, this.line = false});

  final Color color;
  final String text;
  final bool line;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 16,
          height: line ? 3 : 12,
          decoration: BoxDecoration(
            color: line ? color : color.withValues(alpha: 0.35),
            border: line
                ? null
                : Border(top: BorderSide(color: color, width: 2)),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

/// Both profiles on shared axes: the new one as area, the stored one as
/// line. Dives without samples get their rectangle estimate.
class _ComparePainter extends CustomPainter {
  _ComparePainter({
    required this.fresh,
    required this.stored,
    required this.freshColor,
    required this.storedColor,
    required this.gridColor,
  });

  final Dive fresh;
  final Dive stored;
  final Color freshColor;
  final Color storedColor;
  final Color gridColor;

  List<Offset> _points(Dive d) => d.samples.length >= 2
      ? [for (final s in d.samples) Offset(s.timeS.toDouble(), s.depthM)]
      : [
          Offset.zero,
          Offset(math.min(60, d.durationS / 10), d.maxDepthM),
          Offset(d.durationS - math.min(180, d.durationS / 5), d.maxDepthM),
          Offset(d.durationS.toDouble(), 0),
        ];

  @override
  void paint(Canvas canvas, Size size) {
    final maxT = math.max(fresh.durationS, stored.durationS).toDouble();
    final maxD = math.max(fresh.maxDepthM, stored.maxDepthM) * 1.1;
    if (maxT <= 0 || maxD <= 0) return;
    Offset map(Offset p) =>
        Offset(p.dx / maxT * size.width, p.dy / maxD * size.height);

    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    final a = _points(fresh).map(map).toList();
    final area = Path()..moveTo(a.first.dx, 0);
    for (final p in a) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(a.last.dx, 0)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = freshColor.withValues(alpha: 0.3))
      ..drawPoints(
        PointMode.polygon,
        a,
        Paint()
          ..color = freshColor
          ..strokeWidth = 2,
      );

    canvas.drawPoints(
      PointMode.polygon,
      _points(stored).map(map).toList(),
      Paint()
        ..color = storedColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ComparePainter old) =>
      old.fresh != fresh || old.stored != stored;
}
