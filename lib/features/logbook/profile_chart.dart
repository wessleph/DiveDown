import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/metrics/air_profile.dart';
import '../../domain/metrics/sac_calculator.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';

const _units = UnitFormatter.metric();
final _litres = NumberFormat('#,##0', 'de');

/// `m:ss` from seconds, e.g. „23:00“.
String clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

enum _Layer { temperature, air, ndl, sac }

/// Profile with layer chips, a plot that follows taps and drags, and the
/// value panel for the chosen moment (ui-spec §6).
///
/// The plot (`ValueKey('profile-plot')`) maps 0 … the last sample time onto
/// its full width; the panel has `ValueKey('profile-values')`.
class ProfileChart extends StatefulWidget {
  const ProfileChart({super.key, required this.dive, required this.onEdit});

  final Dive dive;

  /// Opens the form, for „Start- und Enddruck eintragen“.
  final VoidCallback onEdit;

  @override
  State<ProfileChart> createState() => _ProfileChartState();
}

class _ProfileChartState extends State<ProfileChart> {
  static const _plotKey = ValueKey('profile-plot');
  static const _plotHeight = 210.0;
  static const _leftAxis = 34.0;
  static const _rightAxis = 34.0;

  late AirProfile _air;
  late List<DiveSample> _samples;
  late int _index;

  /// Right-axis layers in the order they were switched on (max. two).
  final _rightLayers = <_Layer>[_Layer.temperature, _Layer.air];
  bool _ndl = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(ProfileChart old) {
    super.didUpdateWidget(old);
    if (old.dive != widget.dive) _prepare();
  }

  void _prepare() {
    _samples = widget.dive.samples;
    _air = AirProfile(widget.dive);
    _index = 0;
    for (var i = 1; i < _samples.length; i++) {
      if (_samples[i].depthM > _samples[_index].depthM) _index = i;
    }
  }

  int get _endS =>
      _samples.isEmpty ? widget.dive.durationS : _samples.last.timeS;

  bool get _measured => _air.at(0).source == AirSource.measured;

  void _pick(double dx, double width) {
    if (_samples.isEmpty || width <= 0) return;
    final t = (dx / width).clamp(0.0, 1.0) * _endS;
    var best = 0;
    for (var i = 1; i < _samples.length; i++) {
      if ((_samples[i].timeS - t).abs() < (_samples[best].timeS - t).abs()) {
        best = i;
      }
    }
    if (best != _index) setState(() => _index = best);
  }

  void _toggle(_Layer layer, AppLocalizations l10n) {
    setState(() {
      if (layer == _Layer.ndl) {
        _ndl = !_ndl;
        return;
      }
      if (_rightLayers.remove(layer)) return;
      _rightLayers.add(layer);
      if (_rightLayers.length > 2) {
        final dropped = _rightLayers.removeAt(0);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.profileAxesLimit(_label(dropped, l10n)))),
        );
      }
    });
  }

  String _label(_Layer layer, AppLocalizations l10n) => switch (layer) {
    _Layer.temperature => l10n.chipTemperature,
    _Layer.air => _measured ? l10n.chipAir : l10n.chipAirEstimated,
    _Layer.ndl => l10n.chipNdl,
    _Layer.sac => l10n.chipSac,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final estimatedProfile = _samples.length < 2;
    final air = _samples.isEmpty ? null : _air.at(_samples[_index].timeS);
    final hasAir = air != null && air.missing == null;
    final layers = [
      _Layer.temperature,
      // Without any pressure the chip would switch nothing on.
      if (_air.at(0).missing == null) _Layer.air,
      _Layer.ndl,
      if (_measured) _Layer.sac,
    ];
    final deepest = _samples.isEmpty ? null : _samples[_deepestIndex()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!estimatedProfile)
          Semantics(
            label: l10n.chipLayersSpoken,
            container: true,
            child: Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                for (final layer in layers)
                  FilterChip(
                    label: Text(_label(layer, l10n)),
                    selected: layer == _Layer.ndl
                        ? _ndl
                        : _rightLayers.contains(layer),
                    onSelected: (_) => _toggle(layer, l10n),
                    showCheckmark: false,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Semantics(
          label: l10n.profileSemantics(
            _units.depth(widget.dive.maxDepthM),
            _units.duration(deepest?.timeS ?? 0),
            _units.duration(widget.dive.durationS),
          ),
          excludeSemantics: true,
          container: true,
          child: SizedBox(
            height: _plotHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final plotWidth = constraints.maxWidth - _leftAxis - _rightAxis;
                void pick(Offset local) =>
                    _pick(local.dx - _leftAxis, plotWidth);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => pick(d.localPosition),
                  onHorizontalDragStart: (d) => pick(d.localPosition),
                  onHorizontalDragUpdate: (d) => pick(d.localPosition),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ProfilePainter(
                            dive: widget.dive,
                            air: _air,
                            colors: colors,
                            grid: colors.outline,
                            labels: theme.textTheme.labelSmall!.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                            left: _leftAxis,
                            right: _rightAxis,
                            cursor: estimatedProfile ? null : _index,
                            temperature: _rightLayers.contains(
                              _Layer.temperature,
                            ),
                            airLayer: _rightLayers.contains(_Layer.air),
                            sac: _rightLayers.contains(_Layer.sac),
                            ndl: _ndl,
                            cursorColor: theme.colorScheme.onSurface,
                            background: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      Positioned(
                        left: _leftAxis,
                        right: _rightAxis,
                        top: 0,
                        bottom: 0,
                        child: const SizedBox.expand(key: _plotKey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (estimatedProfile)
          Text(
            l10n.estimatedProfile,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          )
        else ...[
          const SizedBox(height: 8),
          _ValuePanel(
            sample: _samples[_index],
            dive: widget.dive,
            air: air!,
            onEdit: widget.onEdit,
          ),
          const SizedBox(height: 6),
          Text(
            hasAir && air.source == AirSource.estimated
                ? l10n.profileDisclaimerEstimated
                : l10n.profileDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _showTable(context),
              child: Text(l10n.profileShowTable),
            ),
          ),
        ],
      ],
    );
  }

  int _deepestIndex() {
    var best = 0;
    for (var i = 1; i < _samples.length; i++) {
      if (_samples[i].depthM > _samples[best].depthM) best = i;
    }
    return best;
  }

  void _showTable(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      for (final s in _samples)
        if (s.timeS % 60 == 0) s,
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        // All rows at once: at most a few hundred minutes.
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileTableTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final s in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(clockText(s.timeS))),
                      Expanded(child: Text(_units.depth(s.depthM))),
                      Expanded(
                        child: Text(
                          s.temperatureC == null
                              ? ''
                              : _units.temperature(s.temperatureC!),
                        ),
                      ),
                      Expanded(
                        child: Text(switch (_air.at(s.timeS)) {
                          AirAtTime(:final double pressureBar) =>
                            _units.pressure(pressureBar),
                          _ => '',
                        }),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The values of the chosen moment (ui-spec §6). Missing values are left
/// out instead of showing „—“.
class _ValuePanel extends StatelessWidget {
  const _ValuePanel({
    required this.sample,
    required this.dive,
    required this.air,
    required this.onEdit,
  });

  final DiveSample sample;
  final Dive dive;
  final AirAtTime air;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final ambient = ambientPressureBar(sample.depthM, dive.waterType);
    final estimated = air.source == AirSource.estimated;
    String about(String v) => estimated ? l10n.valueAbout(v) : v;

    final cells = <(String, String)>[
      (l10n.valueTime, clockText(sample.timeS)),
      (l10n.valueDepth, _units.depth(sample.depthM)),
      if (sample.temperatureC case final t?)
        (
          l10n.valueTemperature,
          '${t.toStringAsFixed(1).replaceAll('.', ',')} °C',
        ),
      if (sample.ndlS case final n?) (l10n.valueNdl, _units.duration(n)),
      (
        l10n.valueAmbient,
        '${ambient.toStringAsFixed(1).replaceAll('.', ',')} bar',
      ),
      if (air.litresPerMinuteNow case final now?)
        (l10n.valueAirNow, about(_units.sac(now))),
    ];

    final tank = dive.tanks.where((t) => t.index == 0).firstOrNull;
    final label = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceMuted,
      letterSpacing: 0.5,
    );
    final value = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        key: const ValueKey('profile-values'),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final columns = scale > 1.5 ? 2 : 3;
                  final width =
                      (constraints.maxWidth - 10 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final (l, v) in cells)
                        SizedBox(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l, style: label),
                              Text(v, style: value),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: colors.outline),
              const SizedBox(height: 6),
              ...switch (air) {
                AirAtTime(missing: AirMissing.pressure) => [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onEdit,
                      child: Text(l10n.airEnterPressure),
                    ),
                  ),
                ],
                AirAtTime(missing: AirMissing.volume) => [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onEdit,
                      child: Text(l10n.sacAddTankSize),
                    ),
                  ),
                ],
                AirAtTime(
                  :final double pressureBar,
                  :final double usedLitres,
                ) =>
                  [
                    _AirLine(
                      label: l10n.valueTankLeft,
                      value: about(_units.pressure(pressureBar)),
                      color: colors.accent,
                    ),
                    _AirLine(
                      label: l10n.valueUsed,
                      value: about('${_litres.format(usedLitres.round())} l'),
                      color: colors.accent,
                    ),
                    if (estimated &&
                        tank?.startPressureBar != null &&
                        tank?.endPressureBar != null &&
                        tank?.volumeL != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.airEstimateNote(
                            '${tank!.startPressureBar!.round()} → '
                            '${_units.pressure(tank.endPressureBar!)}',
                            _units.volume(tank.volumeL!),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                      ),
                  ],
                _ => const <Widget>[],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _AirLine extends StatelessWidget {
  const _AirLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.extension<DiveColors>()!.onSurfaceMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.dive,
    required this.air,
    required this.colors,
    required this.grid,
    required this.labels,
    required this.left,
    required this.right,
    required this.cursor,
    required this.temperature,
    required this.airLayer,
    required this.sac,
    required this.ndl,
    required this.cursorColor,
    required this.background,
  });

  final Dive dive;
  final AirProfile air;
  final DiveColors colors;
  final Color grid;
  final TextStyle labels;
  final double left;
  final double right;
  final int? cursor;
  final bool temperature;
  final bool airLayer;
  final bool sac;
  final bool ndl;
  final Color cursorColor;
  final Color background;

  static const _top = 8.0;
  static const _bottom = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final samples = dive.samples;
    final estimated = samples.length < 2;
    final end = estimated ? dive.durationS : samples.last.timeS;
    if (end <= 0) return;
    final w = size.width - left - right;
    final h = size.height - _top - _bottom;
    final maxDepth = math.max(5.0, dive.maxDepthM);
    final step = maxDepth <= 15 ? 5.0 : 10.0;
    final scaleDepth = (maxDepth / step).ceil() * step;
    double x(num t) => left + t / end * w;
    double y(num d) => _top + d / scaleDepth * h;

    // Grid and depth labels.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var d = 0.0; d <= scaleDepth + 0.01; d += step) {
      canvas.drawLine(Offset(left, y(d)), Offset(left + w, y(d)), gridPaint);
      _text(canvas, '${d.round()} m', Offset(left - 4, y(d)), right: true);
    }
    final minutes = end / 60;
    final tick = minutes <= 20 ? 5 : (minutes <= 60 ? 15 : 30);
    // Start at the first tick, so „0 min“ does not touch the depth labels.
    for (var m = tick; m <= minutes; m += tick) {
      _text(
        canvas,
        '$m min',
        Offset(x(m * 60), size.height - _bottom / 2 + 2),
        center: true,
      );
    }

    // Depth.
    final points = estimated
        ? [
            Offset(x(0), y(0)),
            Offset(x(end * 0.05), y(dive.maxDepthM)),
            Offset(x(end * 0.95), y(dive.maxDepthM)),
            Offset(x(end), y(0)),
          ]
        : [for (final s in samples) Offset(x(s.timeS), y(s.depthM))];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, y(0))
      ..lineTo(points.first.dx, y(0))
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.depth.withValues(alpha: 0.05),
            colors.depth.withValues(alpha: 0.42),
          ],
        ).createShader(Rect.fromLTWH(left, _top, w, h)),
    );
    final depthPaint = Paint()
      ..color = colors.depth
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (estimated) {
      _dashed(canvas, line, depthPaint);
      return;
    }
    canvas.drawPath(line, depthPaint);

    // NDL band at the bottom (up to 99 min fills a third of the height).
    if (ndl) {
      final path = Path();
      var started = false;
      for (final s in samples) {
        final n = s.ndlS;
        if (n == null) continue;
        final v = math.min(n / 60, 99) / 99;
        final p = Offset(x(s.timeS), _top + h - v * h / 3);
        started ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
        started = true;
      }
      _dashed(
        canvas,
        path,
        Paint()
          ..color = colors.ndl
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Right axes: temperature, air, SAC (at most two are on).
    if (temperature) {
      final temps = [
        for (final s in samples)
          if (s.temperatureC case final t?) (s.timeS, t),
      ];
      if (temps.isNotEmpty) {
        final lo = temps.map((e) => e.$2).reduce(math.min).floorToDouble() - 1;
        final hi = temps.map((e) => e.$2).reduce(math.max).ceilToDouble() + 1;
        double ty(double t) => _top + (hi - t) / (hi - lo) * h * 0.5;
        final path = Path();
        for (final (i, (t, v)) in temps.indexed) {
          i == 0 ? path.moveTo(x(t), ty(v)) : path.lineTo(x(t), ty(v));
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = colors.temperature
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        _text(
          canvas,
          '${hi.round()}°',
          Offset(left + w + 4, _top + 6),
          color: colors.temperature,
        );
        _text(
          canvas,
          '${lo.round()}°',
          Offset(left + w + 4, _top + h * 0.5),
          color: colors.temperature,
        );
      }
    }
    final start = air.at(0);
    if (airLayer && start.pressureBar != null) {
      final top = math.max(start.pressureBar!, 1.0);
      double py(double p) => _top + (1 - p / top) * h;
      final path = Path();
      for (final (i, s) in samples.indexed) {
        final p = air.at(s.timeS).pressureBar!;
        i == 0
            ? path.moveTo(x(s.timeS), py(p))
            : path.lineTo(x(s.timeS), py(p));
      }
      final paint = Paint()
        ..color = colors.pressure
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      start.source == AirSource.estimated
          ? _dashed(canvas, path, paint)
          : canvas.drawPath(path, paint);
      _text(
        canvas,
        '0 bar',
        Offset(left + w + 4, _top + h - 4),
        color: colors.pressure,
      );
    }
    if (sac && start.source == AirSource.measured) {
      final rates = [
        for (final s in samples)
          (
            s.timeS,
            (air.at(s.timeS).litresPerMinuteNow ?? 0) /
                ambientPressureBar(s.depthM, dive.waterType),
          ),
      ];
      final hi = math.max(1.0, rates.map((e) => e.$2).reduce(math.max));
      final path = Path();
      for (final (i, (t, r)) in rates.indexed) {
        final py = _top + (1 - r / hi) * h * 0.6 + h * 0.4;
        i == 0 ? path.moveTo(x(t), py) : path.lineTo(x(t), py);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.sac
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Event markers.
    for (final e in dive.events) {
      final s = samples.lastWhere(
        (s) => s.timeS <= e.timeS,
        orElse: () => samples.first,
      );
      canvas.drawCircle(
        Offset(x(e.timeS), y(s.depthM)),
        3.5,
        Paint()..color = colors.depth,
      );
    }

    // Cursor.
    final c = cursor;
    if (c != null) {
      final s = samples[c];
      final cx = x(s.timeS);
      canvas.drawLine(
        Offset(cx, _top),
        Offset(cx, _top + h),
        Paint()
          ..color = cursorColor.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(cx, y(s.depthM)),
        6,
        Paint()..color = background,
      );
      canvas.drawCircle(
        Offset(cx, y(s.depthM)),
        4.5,
        Paint()..color = colors.depth,
      );
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    bool right = false,
    bool center = false,
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: labels.copyWith(color: color ?? labels.color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right
        ? at.dx - painter.width
        : (center ? at.dx - painter.width / 2 : at.dx);
    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.dive != dive ||
      old.cursor != cursor ||
      old.temperature != temperature ||
      old.airLayer != airLayer ||
      old.sac != sac ||
      old.ndl != ndl ||
      old.colors != colors;
}
