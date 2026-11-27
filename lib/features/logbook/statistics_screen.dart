import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/metrics/logbook_stats.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import 'dive_detail_screen.dart';

const _units = UnitFormatter.metric();

/// „Statistik“ (ui-spec §5.15, T39): computed from the dives on the device
/// each time it opens, nothing stored.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const path = '/logbook/statistics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dives = ref.watch(statisticsDivesProvider);
    final countries = ref.watch(visitedCountriesProvider).value;
    final stats = dives.value == null ? null : logbookStats(dives.value!);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: switch (stats) {
        // A read error (ui-spec §4, review W2); while loading nothing, the
        // local query is quick and nothing should flicker.
        null when dives.hasError => _LoadError(
          onRetry: () => ref.invalidate(statisticsDivesProvider),
        ),
        null => const SizedBox.shrink(),
        LogbookStats(isEmpty: true) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.statsEmpty, textAlign: TextAlign.center),
          ),
        ),
        final s => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Title(l10n.statsOverview),
            _Row(label: l10n.statsDives, value: '${s.count}'),
            _Row(
              label: l10n.statsUnderwater,
              value: _units.underwater(s.totalDurationS),
            ),
            if (s.deepest case final d?)
              _Record(
                label: l10n.statsDeepest,
                value: _units.depth(d.maxDepthM),
                dive: d,
              ),
            if (s.longest case final d?)
              _Record(
                label: l10n.statsLongest,
                value: _units.duration(d.durationS),
                dive: d,
              ),
            if (s.coldest case final d?)
              _Record(
                label: l10n.statsColdest,
                value: _units.temperature(d.minTemperatureC!),
                dive: d,
              ),
            if (countries != null)
              _Row(label: l10n.statsCountries, value: '${countries.length}'),
            const SizedBox(height: 16),
            _Title(l10n.statsPerYear),
            _Years(s.perYear),
            if (s.topSites.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Title(l10n.statsSites),
              for (final site in s.topSites)
                _Row(label: site.name, value: l10n.statsTimes(site.count)),
            ],
            const SizedBox(height: 16),
            _Title(l10n.statsAir),
            _AirTrend(s.sacTrend),
          ],
        ),
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(l10n.statsLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: theme.extension<DiveColors>()!.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A record with the dive it belongs to; opens that dive.
class _Record extends StatelessWidget {
  const _Record({required this.label, required this.value, required this.dive});

  final String label;
  final String value;
  final Dive dive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      title: Text(label, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        l10n.statsDiveRef('${dive.number ?? ''}', dive.siteName ?? l10n.noSite),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.extension<DiveColors>()!.onSurfaceMuted,
        ),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: () => context.go(DiveDetailScreen.pathFor(dive.id!)),
    );
  }
}

/// Horizontal bars per year; the numbers are text, not only length.
class _Years extends StatelessWidget {
  const _Years(this.perYear);

  final Map<int, int> perYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final most = perYear.values.fold(1, math.max);
    return Column(
      children: [
        for (final MapEntry(key: year, value: count) in perYear.entries)
          Semantics(
            container: true,
            label: l10n.statsYearSpoken('$year', count),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 52, child: Text('$year')),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 14,
                          width: math.max(4, c.maxWidth * count / most),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Average SAC of the last dives with air data, oldest left (ui-spec §5.15).
class _AirTrend extends StatelessWidget {
  const _AirTrend(this.points);

  final List<SacPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (points.length < 2) return Text(l10n.statsAirNone);
    final values = [for (final p in points) p.litresPerMinute];
    final average = values.reduce((a, b) => a + b) / values.length;
    final line = l10n.statsAirLine(
      _units.sac(average),
      _units.sac(values.last),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                values,
                theme.extension<DiveColors>()!.sac,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(line, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = math.max(hi - lo, 1.0);
    final path = Path();
    for (final (i, v) in values.indexed) {
      final x = size.width * i / (values.length - 1);
      final y = 4 + (hi - v) / span * (size.height - 8);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.color != color;
}
