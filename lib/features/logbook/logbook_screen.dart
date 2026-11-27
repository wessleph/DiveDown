import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../import/import_screen.dart';
import 'dive_detail_screen.dart';
import 'dive_texts.dart';
import '../settings/backup_flows.dart';
import 'manual_dive_screen.dart';
import 'sparkline.dart';
import 'statistics_screen.dart';

/// Logbuch (ui-spec §5.2): dives of the active diver by month, newest first.
class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  static const path = '/logbook';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dives = ref.watch(logbookProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navLogbook,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(ManualDiveScreen.newPath),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.logbookManualEntry),
      ),
      body: switch (dives) {
        AsyncData(:final value) when value.isEmpty => const _EmptyLogbook(),
        AsyncData(:final value) => _DiveList(dives: value),
        AsyncError() => _LoadError(
          onRetry: () => ref.invalidate(logbookProvider),
        ),
        // Short loads show nothing, so nothing flickers (ui-spec §4).
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _EmptyLogbook extends StatelessWidget {
  const _EmptyLogbook();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.waves,
              size: 72,
              color: theme.extension<DiveColors>()!.depth,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.logbookEmptyTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.logbookEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.go(ImportScreen.path),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.navImport),
              ),
              FilledButton.icon(
                onPressed: () => context.go(ManualDiveScreen.newPath),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.logbookManualEntry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(l10n.logbookLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiveList extends ConsumerStatefulWidget {
  const _DiveList({required this.dives});

  /// Newest first, as the repository returns them.
  final List<Dive> dives;

  @override
  ConsumerState<_DiveList> createState() => _DiveListState();
}

/// Highlights the dives of the last import for 3 s once the list is on
/// screen (ui-spec §5.2, T32); leaving the tab ends it at once.
class _DiveListState extends ConsumerState<_DiveList> {
  static const _highlightFor = Duration(seconds: 3);

  Set<String> _highlight = const {};
  Timer? _timer;
  bool _visible = false;
  final _firstNewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _take(ref.read(recentlyImportedProvider));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
      _start();
    } else if (_timer != null) {
      // Gone to another tab: the next visit shows no mark (T32.2).
      _timer!.cancel();
      _timer = null;
      _highlight = const {};
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Copies the ids of a new import and empties the provider.
  void _take(Set<String> ids) {
    if (ids.isEmpty) return;
    _highlight = {...ids};
    _timer?.cancel();
    _timer = null;
    Future.microtask(() {
      if (mounted) ref.read(recentlyImportedProvider.notifier).clear();
    });
    if (_visible) _start();
  }

  void _start() {
    if (_highlight.isEmpty || _timer != null) return;
    _timer = Timer(_highlightFor, () {
      if (mounted) setState(() => _highlight = const {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _firstNewKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.2,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      recentlyImportedProvider,
      (_, next) => setState(() => _take(next)),
    );
    final dives = widget.dives;
    final firstNew = dives.where((d) => _highlight.contains(d.id)).firstOrNull;
    final items = <Object>[const _Header()];
    (int, int)? month;
    for (final dive in dives) {
      final m = (dive.start.year, dive.start.month);
      if (m != month) {
        items.add(dive.start);
        month = m;
      }
      items.add(dive);
    }

    return ListView.builder(
      // Room for the FAB below the last row.
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final Dive dive => _DiveRow(
          key: dive == firstNew ? _firstNewKey : null,
          dive: dive,
          highlighted: _highlight.contains(dive.id),
        ),
        final DateTime start => _MonthHeader(start: start),
        _Header() => Column(
          children: [
            const _BackupReminder(),
            _SummaryTiles(dives: dives),
          ],
        ),
        _ => throw StateError('unexpected item'),
      },
    );
  }
}

/// „Neu“ next to the number of a just imported dive.
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.start});

  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Text(
          monthFormat.format(start),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _DiveRow extends StatelessWidget {
  const _DiveRow({super.key, required this.dive, this.highlighted = false});

  final Dive dive;

  /// Just imported (ui-spec §5.2, T32).
  final bool highlighted;

  static const _units = UnitFormatter.metric();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final site = dive.siteName;
    final depth = _units.depth(dive.maxDepthM);

    // Read as one element (ui-spec §7).
    final label = [
      if (highlighted) l10n.importedNewSemantics,
      l10n.diveNumberSpoken(dive.number!),
      site ?? l10n.noSite,
      spokenDateFormat.format(dive.start),
      l10n.depthSpoken(depth.replaceFirst(' m', '')),
      l10n.durationSpoken((dive.durationS / 60).round()),
      sourceSpoken(l10n, dive.source),
    ].join(', ');

    void open() => context.go(DiveDetailScreen.pathFor(dive.id!));
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 13;

    return Semantics(
      label: label,
      button: true,
      onTap: open,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                color: highlighted
                    ? colors.surfaceTint
                    : colors.surfaceTint.withValues(alpha: 0),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: highlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    // Large text (ui-spec §4): depth moves below the text.
                    direction: stacked ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: stacked ? MainAxisSize.min : MainAxisSize.max,
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        fit: stacked ? FlexFit.loose : FlexFit.tight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.diveNumber(dive.number!),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                if (highlighted) ...[
                                  const SizedBox(width: 6),
                                  _NewBadge(text: l10n.importedNew),
                                ],
                              ],
                            ),
                            Text(
                              site ?? l10n.noSite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: site == null
                                    ? FontStyle.italic
                                    : null,
                                color: site == null
                                    ? colors.onSurfaceMuted
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  sourceIcon(dive.source),
                                  size: 15,
                                  color: colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${dateFormat.format(dive.start)} · '
                                    '${timeFormat.format(dive.start)} · '
                                    '${_units.duration(dive.durationS)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12.5,
                                      color: colors.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12, height: 4),
                      Text.rich(
                        TextSpan(
                          text: depth.replaceFirst(' m', ''),
                          children: [
                            TextSpan(
                              text: ' m',
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colors.depth,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DiveSparkline(dive: dive, color: colors.depth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header {
  const _Header();
}

/// Two tiles for the active diver (ui-spec §5.2): dives and time under water.
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.dives});

  final List<Dive> dives;

  static const _units = UnitFormatter.metric();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = dives.fold<int>(0, (sum, d) => sum + d.durationS);
    // Both tiles open the statistics (ui-spec §5.15, T39).
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Semantics(
        button: true,
        label: l10n.statsOpen,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(StatisticsScreen.path),
          child: Row(
            children: [
              Expanded(
                child: _Tile(
                  value: '${dives.length}',
                  label: l10n.logbookTileDives,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Tile(
                  value: _units.underwater(total),
                  label: l10n.logbookTileUnderwater,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceMuted,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// „Letzte Sicherung vor 34 Tagen.“ with „Jetzt sichern“ and ✕ for 7 days
/// (ui-spec §5.2, T11.15).
class _BackupReminder extends ConsumerWidget {
  const _BackupReminder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupReminderProvider).value;
    if (state == null || !state.due) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final last = state.lastBackup;
    final text = last == null
        ? l10n.reminderNever
        : l10n.reminderLast(DateTime.now().toUtc().difference(last).inDays);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.warning),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.save_alt, color: colors.warning),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              TextButton(
                onPressed: () => showCreateBackup(context, ref),
                child: Text(l10n.reminderAction),
              ),
              IconButton(
                tooltip: l10n.reminderDismiss,
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider)
                      .setBackupReminderSnoozedUntil(
                        DateTime.now().toUtc().add(const Duration(days: 7)),
                      );
                  ref.invalidate(backupReminderProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
