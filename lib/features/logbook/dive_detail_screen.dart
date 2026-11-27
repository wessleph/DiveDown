import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/metrics/air_profile.dart';
import '../../domain/metrics/sac_calculator.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../settings/equipment_texts.dart';
import 'dive_texts.dart';
import 'logbook_screen.dart';
import 'manual_dive_screen.dart';
import 'profile_chart.dart';
import 'profile_fullscreen_screen.dart';

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
          computerLabel: d.computerLabel,
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
    required this.computerLabel,
    required this.onEdit,
  });

  final Dive dive;
  final String? diverName;
  final String? computerLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      color: colors.onSurfaceMuted,
    );
    const side = EdgeInsets.symmetric(horizontal: 16);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header on the tint gradient (ui-spec §5.3).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.surfaceTint, theme.colorScheme.surface],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: l10n.diveNumberSpoken(dive.number!),
                  header: true,
                  excludeSemantics: true,
                  child: Text(
                    l10n.diveNumber(dive.number!),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 44,
                      height: 1.05,
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
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(l10n.detailAddSite),
                  ),
                const SizedBox(height: 2),
                Text(
                  [
                    dateFormat.format(dive.start),
                    timeFormat.format(dive.start),
                    ?diverName,
                    computerLabel ?? sourceLabel(l10n, dive.source),
                  ].join(' · '),
                  style: muted,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: side,
          child: _Metrics(dive: dive),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ProfileChart(
            dive: dive,
            onEdit: onEdit,
            onFullscreen: () =>
                context.push(ProfileFullscreenScreen.pathFor(dive.id!)),
          ),
        ),
        if (dive.tanks.length > 1) ...[
          const SizedBox(height: 16),
          Padding(padding: side, child: _SectionTitle(l10n.tanksTitle)),
          for (final t in dive.tanks)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
          Padding(padding: side, child: _SectionTitle(l10n.eventsTitle)),
          Padding(
            padding: side,
            child: Column(
              children: [
                for (final g in groupEvents(dive.events)) _EventRow(group: g),
              ],
            ),
          ),
        ],
        _ConditionsSection(dive: dive),
        _EquipmentSection(dive: dive),
        if (dive.notes case final notes?) ...[
          const SizedBox(height: 16),
          Padding(padding: side, child: _SectionTitle(l10n.notesTitle)),
          Padding(padding: side, child: Text(notes)),
        ],
        if (dive.rating case final stars?) ...[
          const SizedBox(height: 16),
          Padding(
            padding: side,
            child: Semantics(
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
          ),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.group});

  final EventGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final warning = isWarningEvent(group.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  clockText(group.timeS),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsetsDirectional.only(end: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: warning ? theme.colorScheme.error : colors.depth,
                ),
              ),
              Expanded(child: Text(eventLabel(l10n, group.type))),
              if (group.count > 1)
                Text(
                  '${group.count}×',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `200 → 50 bar`, null without both pressures.
String? _pressureText(DiveTank? tank) {
  final start = tank?.startPressureBar;
  final end = tank?.endPressureBar;
  if (start == null || end == null) return null;
  return '${start.round()} → ${_units.pressure(end)}';
}

/// Lead and the pieces used (ui-spec §5.3 item 5, T31.5); hidden when the
/// dive has neither.
/// „BEDINGUNGEN“: visibility, current and kinds (ui-spec §5.3, T40); left
/// out when none is noted.
class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({required this.dive});

  final Dive dive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final first = [
      if (dive.visibility case final v?)
        l10n.visibilityDetail(visibilityLabel(l10n, v)),
      if (dive.current case final c?) currentShort(l10n, c),
    ].join(' · ');
    final kinds = diveKindsText(l10n, dive.kinds);
    if (first.isEmpty && kinds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l10n.detailConditions),
          if (first.isNotEmpty) Text(first),
          if (kinds.isNotEmpty) Text(kinds),
        ],
      ),
    );
  }
}

class _EquipmentSection extends ConsumerWidget {
  const _EquipmentSection({required this.dive});

  final Dive dive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final items = ref.watch(diveEquipmentProvider(dive.id!)).value ?? const [];
    final kg = dive.weightKg;
    if (kg == null && items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l10n.settingsSectionEquipment),
          if (kg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 18, color: colors.depth),
                  const SizedBox(width: 8),
                  Text(l10n.detailWeight),
                  const SizedBox(width: 6),
                  Text(
                    l10n.weightKg(formatKg(kg)),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in items)
                Chip(
                  avatar: Icon(
                    equipmentKindIcon(e.kind),
                    size: 18,
                    color: e.deleted ? colors.onSurfaceMuted : colors.depth,
                  ),
                  label: Text(
                    e.name,
                    style: e.deleted
                        ? TextStyle(color: colors.onSurfaceMuted)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
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

/// Key figures in three columns of equal height, SAC across the full width
/// (ui-spec §5.3); fewer columns with large text (§4).
class _Metrics extends StatelessWidget {
  const _Metrics({required this.dive});

  final Dive dive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tank = dive.tanks.where((t) => t.index == 0).firstOrNull;
    final sac = const SacCalculator().average(dive);
    final missing = l10n.valueMissing;
    final pressure = _pressureText(tank);
    final measured = AirProfile(dive).at(0).source == AirSource.measured;

    final tiles = <Widget>[
      _Metric(l10n.metricMaxDepth, _units.depth(dive.maxDepthM)),
      _Metric(l10n.metricDuration, _units.duration(dive.durationS)),
      if (dive.avgDepthM case final d?)
        _Metric(l10n.metricAvgDepth, _units.depth(d)),
      if (dive.minTemperatureC case final t?)
        _Metric(
          l10n.metricWater,
          _units.temperature(t),
          note: switch (dive.waterType) {
            final w? => waterTypeLabel(l10n, w),
            null => null,
          },
        ),
      if (tank?.gas case final g?) _Metric(l10n.metricGas, _units.gas(g)),
      if (tank != null)
        if (tank.volumeL case final v?)
          _Metric(l10n.metricTank, _units.volume(v), note: pressure ?? missing)
        else
          _Metric(l10n.metricTank, pressure ?? missing),
    ];

    final sacTile = _Metric(
      l10n.metricSac,
      sac.litresPerMinute == null ? missing : _units.sac(sac.litresPerMinute!),
      note: sac.litresPerMinute == null
          ? null
          : measured
          ? l10n.sacMeasured
          : (pressure == null ? null : l10n.sacEstimatedFrom(pressure)),
      extra: sac.missing == SacMissing.pressure
          ? IconButton(
              tooltip: l10n.sacNeedsPressure,
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            )
          : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = scale > 1.5 ? 1 : (constraints.maxWidth < 300 ? 2 : 3);
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += columns) {
          final row = tiles.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (j, t) in row.indexed) ...[
                    if (j > 0) const SizedBox(width: gap),
                    SizedBox(width: width, child: t),
                  ],
                ],
              ),
            ),
          );
          rows.add(const SizedBox(height: gap));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...rows, sacTile],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.note, this.extra});

  final String label;
  final String value;

  /// Small second line, e.g. „200 → 50 bar“ or „gemessen“.
  final String? note;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ?extra,
              ],
            ),
            if (note case final n?)
              Text(
                n,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
