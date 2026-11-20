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
import 'manual_dive_screen.dart';

/// Logbuch (ui-spec §5.2): dives of the active diver by month, newest first.
class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  static const path = '/logbook';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dives = ref.watch(logbookProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLogbook)),
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

class _DiveList extends StatelessWidget {
  const _DiveList({required this.dives});

  /// Newest first, as the repository returns them.
  final List<Dive> dives;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[];
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
        final Dive dive => _DiveRow(dive: dive),
        final DateTime start => _MonthHeader(start: start),
        _ => throw StateError('unexpected item'),
      },
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          monthFormat.format(start),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DiveRow extends StatelessWidget {
  const _DiveRow({required this.dive});

  final Dive dive;

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
      l10n.diveNumberSpoken(dive.number!),
      site ?? l10n.noSite,
      spokenDateFormat.format(dive.start),
      l10n.depthSpoken(depth.replaceFirst(' m', '')),
      l10n.durationSpoken((dive.durationS / 60).round()),
      sourceSpoken(l10n, dive.source),
    ].join(', ');

    void open() => context.go(DiveDetailScreen.pathFor(dive.id!));

    return Semantics(
      label: label,
      button: true,
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.diveNumber(dive.number!),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      site ?? l10n.noSite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: site == null ? colors.onSurfaceMuted : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          sourceIcon(dive.source),
                          size: 16,
                          color: colors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${dateFormat.format(dive.start)} · '
                            '${_units.duration(dive.durationS)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                depth,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.depth,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
