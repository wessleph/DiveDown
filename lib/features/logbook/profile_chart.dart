import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/metrics/air_profile.dart';
import '../../domain/metrics/sac_calculator.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import 'time_window.dart';

const _units = UnitFormatter.metric();
final _litres = NumberFormat('#,##0', 'de');

/// `m:ss` from seconds, e.g. „23:00“.
String clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

enum _Layer { temperature, air, ndl, sac, pulse }

/// Profile with layer chips, a plot that follows taps and drags, and the
/// value panel for the chosen moment (ui-spec §6).
///
/// The plot (`ValueKey('profile-plot')`) maps the visible time range (the
/// whole dive unless zoomed) onto its full width; the panel has
/// `ValueKey('profile-values')`.
class ProfileChart extends StatefulWidget {
  const ProfileChart({
    super.key,
    required this.dive,
    required this.onEdit,
    this.onFullscreen,
    this.fullscreen = false,
  });

  final Dive dive;

  /// Opens the form, for „Start- und Enddruck eintragen“.
  final VoidCallback onEdit;

  /// Shows „Vollbild“ next to „Als Tabelle anzeigen“ (T27).
  final VoidCallback? onFullscreen;

  /// Full-screen layout: plot over the full height, values beside it,
  /// two fingers zoom and move the time axis, double tap resets (T27).
  final bool fullscreen;

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

  /// The visible time range; the whole dive unless zoomed (T27).
  late TimeWindow _window;
  TimeWindow? _gestureStart;
  double _gestureFocus = 0;

  /// Fingers on the full-screen plot.
  int _pointers = 0;

  /// Right-axis layers in the order they were switched on (max. two).
  final _rightLayers = <_Layer>[_Layer.temperature, _Layer.air];
  bool _ndl = false;
  bool _hasPulse = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(ProfileChart old) {
    super.didUpdateWidget(old);
    if (old.dive != widget.dive) {
      _prepare(resetLayers: old.dive.id != widget.dive.id);
    }
  }

  void _prepare({bool resetLayers = true}) {
    _samples = widget.dive.samples;
    _air = AirProfile(widget.dive);
    _hasPulse = _samples.any((s) => s.heartRate != null);
    // Apple Watch dives have no air curve; the pulse takes its place (T6.11).
    // A reload of the same dive keeps the layers the diver chose.
    if (resetLayers) _setDefaultLayers();
    _index = 0;
    for (var i = 1; i < _samples.length; i++) {
      if (_samples[i].depthM > _samples[_index].depthM) _index = i;
    }
    _window = TimeWindow.full(math.max(1, _endS));
  }

  void _setDefaultLayers() {
    _rightLayers
      ..clear()
      ..addAll([
        _Layer.temperature,
        if (_air.at(0).missing == null || !_hasPulse)
          _Layer.air
        else
          _Layer.pulse,
      ]);
  }

  int get _endS =>
      _samples.isEmpty ? widget.dive.durationS : _samples.last.timeS;

  bool get _measured => _air.at(0).source == AirSource.measured;

  void _pick(double dx, double width) {
    if (_samples.isEmpty || width <= 0) return;
    final t = _window.timeAt((dx / width).clamp(0.0, 1.0));
    var best = 0;
    for (var i = 1; i < _samples.length; i++) {
      if ((_samples[i].timeS - t).abs() < (_samples[best].timeS - t).abs()) {
        best = i;
      }
    }
    if (best != _index) setState(() => _index = best);
  }

  void _scaleStart(ScaleStartDetails d, double width) {
    _gestureStart = _window;
    _gestureFocus = width <= 0 ? 0 : (d.localFocalPoint.dx - _leftAxis) / width;
  }

  void _scaleUpdate(ScaleUpdateDetails d, double width) {
    final start = _gestureStart;
    if (start == null || width <= 0) return;
    if (d.pointerCount < 2) {
      _pick(d.localFocalPoint.dx - _leftAxis, width);
      return;
    }
    // Keep the moment that was under the fingers under them now.
    final focus = (d.localFocalPoint.dx - _leftAxis) / width;
    final next = start
        .zoom(d.horizontalScale, _gestureFocus)
        .pan(_gestureFocus - focus);
    setState(() => _window = next);
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
    _Layer.pulse => l10n.chipPulse,
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
      if (_hasPulse) _Layer.pulse,
    ];
    final deepest = _samples.isEmpty ? null : _samples[_deepestIndex()];

    final chips = Semantics(
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
    );

    final plot = Semantics(
      label: l10n.profileSemantics(
        _units.depth(widget.dive.maxDepthM),
        _units.duration(deepest?.timeS ?? 0),
        _units.duration(widget.dive.durationS),
      ),
      excludeSemantics: true,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = constraints.maxWidth - _leftAxis - _rightAxis;
          void pick(Offset local) => _pick(local.dx - _leftAxis, plotWidth);
          final painted = Stack(
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
                    from: _window.startS,
                    to: _window.endS,
                    cursor: estimatedProfile ? null : _index,
                    temperature: _rightLayers.contains(_Layer.temperature),
                    airLayer: _rightLayers.contains(_Layer.air),
                    sac: _rightLayers.contains(_Layer.sac),
                    pulse: _rightLayers.contains(_Layer.pulse),
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
          );
          return widget.fullscreen
              // A tap would wait for the double tap to lose; the first
              // finger going down picks the moment right away.
              ? Listener(
                  onPointerDown: (e) {
                    if (++_pointers == 1) pick(e.localPosition);
                  },
                  onPointerUp: (_) => _pointers--,
                  onPointerCancel: (_) => _pointers--,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () => setState(
                      () => _window = TimeWindow.full(math.max(1, _endS)),
                    ),
                    onScaleStart: (d) => _scaleStart(d, plotWidth),
                    onScaleUpdate: (d) => _scaleUpdate(d, plotWidth),
                    onScaleEnd: (_) => _gestureStart = null,
                    child: painted,
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => pick(d.localPosition),
                  onHorizontalDragStart: (d) => pick(d.localPosition),
                  onHorizontalDragUpdate: (d) => pick(d.localPosition),
                  child: painted,
                );
        },
      ),
    );

    final values = estimatedProfile
        ? <Widget>[
            Text(
              l10n.estimatedProfile,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ]
        : <Widget>[
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
          ];

    if (widget.fullscreen) {
      final range = _window.isFull
          ? null
          : Text(
              l10n.profileRange(
                clockText(_window.startS.round()),
                clockText(_window.endS.round()),
              ),
              key: const ValueKey('profile-range'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            );
      final graph = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!estimatedProfile) chips,
          ?range,
          Expanded(child: plot),
        ],
      );
      final panel = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: values,
        ),
      );
      return LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth > constraints.maxHeight
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: graph),
                  const SizedBox(width: 12),
                  SizedBox(width: 300, child: panel),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: graph),
                  const SizedBox(height: 8),
                  Expanded(flex: 2, child: panel),
                ],
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!estimatedProfile) chips,
        const SizedBox(height: 4),
        SizedBox(height: _plotHeight, child: plot),
        if (!estimatedProfile) const SizedBox(height: 8),
        ...values,
        if (!estimatedProfile)
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _showTable(context),
                child: Text(l10n.profileShowTable),
              ),
              if (widget.onFullscreen case final open?)
                TextButton.icon(
                  onPressed: open,
                  icon: const Icon(Icons.open_in_full),
                  label: Text(l10n.profileFullscreen),
                ),
            ],
          ),
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
      if (sample.heartRate case final r?) (l10n.valuePulse, '$r /min'),
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
    required this.from,
    required this.to,
    required this.cursor,
    required this.temperature,
    required this.airLayer,
    required this.sac,
    required this.pulse,
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

  /// The visible time range in seconds (T27).
  final double from;
  final double to;
  final int? cursor;
  final bool temperature;
  final bool airLayer;
  final bool sac;
  final bool pulse;
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
    if (end <= 0 || to <= from) return;
    final w = size.width - left - right;
    final h = size.height - _top - _bottom;
    final maxDepth = math.max(5.0, dive.maxDepthM);
    final step = maxDepth <= 15 ? 5.0 : 10.0;
    final scaleDepth = (maxDepth / step).ceil() * step;
    double x(num t) => left + (t - from) / (to - from) * w;
    double y(num d) => _top + d / scaleDepth * h;

    // Grid and depth labels.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var d = 0.0; d <= scaleDepth + 0.01; d += step) {
      canvas.drawLine(Offset(left, y(d)), Offset(left + w, y(d)), gridPaint);
      _text(canvas, '${d.round()} m', Offset(left - 4, y(d)), right: true);
    }
    final minutes = (to - from) / 60;
    final tick = minutes <= 6
        ? 1
        : minutes <= 12
        ? 2
        : minutes <= 20
        ? 5
        : (minutes <= 60 ? 15 : 30);
    // Start after the left edge, so „0 min“ does not touch the depth labels.
    for (
      var m = (from / 60 / tick).floor() * tick + tick;
      m * 60 <= to;
      m += tick
    ) {
      _text(
        canvas,
        '$m min',
        Offset(x(m * 60), size.height - _bottom / 2 + 2),
        center: true,
      );
    }

    // Curves only over the plot and the right axis when zoomed.
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(left - 6, 0, w + right + 6, size.height));

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
      canvas.restore();
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
      // Step line over fixed one-minute segments (ui-spec §6, T7.3).
      final segments = const SacCalculator().segments(dive);
      if (segments.isNotEmpty) {
        final hi = math.max(
          1.0,
          segments.map((e) => e.litresPerMinute).reduce(math.max),
        );
        double py(double r) => _top + (1 - r / hi) * h * 0.6 + h * 0.4;
        final path = Path();
        for (final (i, seg) in segments.indexed) {
          final y = py(seg.litresPerMinute);
          i == 0
              ? path.moveTo(x(seg.startS), y)
              : path.lineTo(x(seg.startS), y);
          path.lineTo(x(seg.endS), y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = colors.sac
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Heart rate in the lower half (Apple Watch, T6.11).
    if (pulse) {
      final rates = [
        for (final s in samples)
          if (s.heartRate case final r?) (s.timeS, r.toDouble()),
      ];
      if (rates.isNotEmpty) {
        final lo = (rates.map((e) => e.$2).reduce(math.min) / 10).floor() * 10;
        final hi = (rates.map((e) => e.$2).reduce(math.max) / 10).ceil() * 10;
        final span = math.max(10, hi - lo);
        double py(double r) => _top + h * 0.5 + (hi - r) / span * h * 0.5;
        final path = Path();
        for (final (i, (t, r)) in rates.indexed) {
          i == 0 ? path.moveTo(x(t), py(r)) : path.lineTo(x(t), py(r));
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = colors.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        _text(
          canvas,
          '$hi',
          Offset(left + w + 4, _top + h * 0.5 + 6),
          color: colors.accent,
        );
        _text(
          canvas,
          '$lo',
          Offset(left + w + 4, _top + h - 4),
          color: colors.accent,
        );
      }
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
    canvas.restore();
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
      old.from != from ||
      old.to != to ||
      old.temperature != temperature ||
      old.airLayer != airLayer ||
      old.sac != sac ||
      old.pulse != pulse ||
      old.ndl != ndl ||
      old.colors != colors;
}
