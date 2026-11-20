import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/metrics/sac_calculator.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import 'dive_texts.dart';
import 'logbook_screen.dart';
import 'manual_dive_screen.dart';

const _units = UnitFormatter.metric();

/// Tauchgang-Detail (ui-spec §5.3).
class DiveDetailScreen extends ConsumerWidget {
  const DiveDetailScreen({super.key, required this.diveId});

  static String pathFor(String diveId) => '/logbook/dive/$diveId';

  final String diveId;

  void _edit(BuildContext context) =>
      context.go(ManualDiveScreen.editPathFor(diveId));

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final repository = ref.read(diveRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    // The snackbar outlives this screen, so it must not use [ref].
    final container = ProviderScope.containerOf(context, listen: false);
    await repository.delete(diveId);
    ref.refreshDives();
    if (!context.mounted) return;
    context.go(LogbookScreen.path);
    // Soft delete makes the undo possible (ADR 0004).
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.diveDeleted),
        duration: const Duration(seconds: 5),
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await repository.restore(diveId);
            refreshDivesIn(container, diveId: diveId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(diveDetailProvider(diveId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (detail.value != null) ...[
            IconButton(
              tooltip: l10n.detailEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
            PopupMenuButton<void>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _delete(context, ref),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ],
        ],
      ),
      body: switch (detail) {
        AsyncData(value: final d?) => _DiveDetail(
          dive: d.dive,
          diverName: d.diverName,
          onEdit: () => _edit(context),
        ),
        AsyncData() => Center(child: Text(l10n.detailNotFound)),
        AsyncError() => Center(child: Text(l10n.detailNotFound)),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _DiveDetail extends StatelessWidget {
  const _DiveDetail({
    required this.dive,
    required this.diverName,
    required this.onEdit,
  });

  final Dive dive;
  final String? diverName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceMuted,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Semantics(
          label: l10n.diveNumberSpoken(dive.number!),
          header: true,
          excludeSemantics: true,
          child: Text(
            l10n.diveNumber(dive.number!),
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (dive.siteName case final site?)
          Text(
            site,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l10n.detailAddSite),
            ),
          ),
        Text(
          [
            dateFormat.format(dive.start),
            timeFormat.format(dive.start),
            ?diverName,
            sourceLabel(l10n, dive.source),
          ].join(' · '),
          style: muted,
        ),
        const SizedBox(height: 16),
        _Metrics(dive: dive, onEdit: onEdit),
        const SizedBox(height: 16),
        _Profile(dive: dive),
        if (dive.tanks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle(l10n.tanksTitle),
          for (final t in dive.tanks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                [
                  l10n.tankNumber(t.index + 1),
                  if (t.volumeL case final v?) _units.volume(v),
                  ?_pressureText(t),
                  if (t.gas case final g?) _units.gas(g),
                ].join(' · '),
              ),
            ),
        ],
        if (dive.events.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle(l10n.eventsTitle),
          for (final e in dive.events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${_clock(e.timeS)} · ${eventLabel(l10n, e.type)}'),
            ),
        ],
        if (dive.notes case final notes?) ...[
          const SizedBox(height: 16),
          _SectionTitle(l10n.notesTitle),
          Text(notes),
        ],
        if (dive.rating case final stars?) ...[
          const SizedBox(height: 16),
          Semantics(
            label: l10n.ratingSpoken(stars),
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= stars ? Icons.star : Icons.star_border,
                    color: colors.warning,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// `200 → 50 bar`, null without both pressures.
String? _pressureText(DiveTank? tank) {
  final start = tank?.startPressureBar;
  final end = tank?.endPressureBar;
  if (start == null || end == null) return null;
  return '${start.round()} → ${_units.pressure(end)}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// Key figures in two columns, one column on small screens or with large
/// text (ui-spec §4, §8).
class _Metrics extends StatelessWidget {
  const _Metrics({required this.dive, required this.onEdit});

  final Dive dive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tank = dive.tanks.where((t) => t.index == 0).firstOrNull;
    final sac = const SacCalculator().average(dive);
    final missing = l10n.valueMissing;

    final tiles = <Widget>[
      _Metric(l10n.metricMaxDepth, _units.depth(dive.maxDepthM)),
      _Metric(l10n.metricDuration, _units.duration(dive.durationS)),
      if (dive.avgDepthM case final d?)
        _Metric(l10n.metricAvgDepth, _units.depth(d)),
      if (dive.minTemperatureC case final t?)
        _Metric(l10n.metricMinTemperature, _units.temperature(t)),
      _Metric(l10n.metricPressure, _pressureText(tank) ?? missing),
      _Metric(
        l10n.metricSac,
        sac.litresPerMinute == null
            ? missing
            : _units.sac(sac.litresPerMinute!),
        extra: switch (sac.missing) {
          SacMissing.pressure => IconButton(
            tooltip: l10n.sacNeedsPressure,
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
          SacMissing.volume => TextButton(
            onPressed: onEdit,
            child: Text(l10n.sacAddTankSize),
          ),
          _ => null,
        },
      ),
      if (tank?.gas case final g?) _Metric(l10n.metricGas, _units.gas(g)),
      if (dive.waterType case final w?)
        _Metric(l10n.metricWaterType, waterTypeLabel(l10n, w)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth < 328 || scale > 1.5 ? 1 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.extra});

  final String label;
  final String value;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ?extra,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple depth line until the full chart arrives (ui-spec §6, KW 49).
/// Without samples a dashed estimate from depth and duration (§5.3).
class _Profile extends StatelessWidget {
  const _Profile({required this.dive});

  final Dive dive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final estimated = dive.samples.length < 2;
    final points = estimated
        ? [
            (0.0, 0.0),
            (0.05, dive.maxDepthM),
            (0.95, dive.maxDepthM),
            (1.0, 0.0),
          ]
        : [
            for (final s in dive.samples)
              (s.timeS / math.max(1, dive.samples.last.timeS), s.depthM),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: l10n.profileSemantics(
            _units.depth(dive.maxDepthM),
            _units.duration(dive.durationS),
          ),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _ProfilePainter(
                points: points,
                maxDepth: math.max(1, dive.maxDepthM),
                color: theme.extension<DiveColors>()!.depth,
                dashed: estimated,
              ),
            ),
          ),
        ),
        if (estimated)
          Text(
            l10n.estimatedProfile,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.points,
    required this.maxDepth,
    required this.color,
    required this.dashed,
  });

  /// (time 0..1, depth in m)
  final List<(double, double)> points;
  final double maxDepth;
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final (i, (t, d)) in points.indexed) {
      // Depth grows downwards (ui-spec §6).
      final o = Offset(t * size.width, d / maxDepth * size.height);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.points != points || old.color != color || old.dashed != dashed;
}
