import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/bottom_action.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/import/health/store_health_dive_source.dart'
    show healthLogCategory;
import '../../domain/diagnostics/diagnostic_log.dart';
import '../../domain/import/health_import.dart';
import '../../domain/import/import_service.dart';
import '../../domain/import/imported_dive.dart';
import '../../l10n/app_localizations.dart';
import 'import_preview.dart';

/// Dives of the Apple Watch from Apple Health (ui-spec §5.10, T6.8, T6.9):
/// explanation, period, the system permission, search, preview §5.9.
class HealthImportScreen extends ConsumerStatefulWidget {
  const HealthImportScreen({super.key});

  static const path = '/import/health';

  /// Shorter searches show nothing, so nothing flickers (ui-spec §4).
  static const quietLoad = Duration(milliseconds: 300);

  @override
  ConsumerState<HealthImportScreen> createState() => _HealthImportScreenState();
}

enum _Period { sinceLast, year }

class _HealthImportScreenState extends ConsumerState<HealthImportScreen> {
  _Period? _period;
  bool _searching = false;
  bool _slowSearch = false;
  bool _failed = false;
  Timer? _slow;
  HealthFetchResult? _result;
  List<ImportResult> _checks = const [];
  int _run = 0;

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  Future<void> _search(({DateTime from, DateTime? since}) suggested) async {
    final run = ++_run;
    final now = clock.now().toUtc();
    final from = _chosen(suggested) == _Period.sinceLast
        ? suggested.since!
        : healthImportFrom(const [], now).from;
    setState(() {
      _searching = true;
      _slowSearch = false;
      _failed = false;
    });
    _slow?.cancel();
    _slow = Timer(HealthImportScreen.quietLoad, () {
      if (mounted && run == _run) setState(() => _slowSearch = true);
    });
    final source = ref.read(healthDiveSourceProvider);
    HealthFetchResult? result;
    var checks = const <ImportResult>[];
    try {
      await source.requestPermission();
      result = await source.fetch(from: from, to: now);
      if (result.dives.isNotEmpty) {
        final diver = (await ref.read(activeDiverProvider.future))!;
        checks = await ref
            .read(importServiceProvider)
            .preview(diver.id!, result.dives);
      }
    } on HealthReadFailure {
      result = null;
    } catch (e) {
      // Anything else (database, preview) must not leave the search hanging
      // (review W1). Only the type goes to the log, no data.
      result = null;
      await ref
          .read(diagnosticLogProvider)
          .log(
            healthLogCategory,
            LogLevel.error,
            'search failed: ${e.runtimeType}',
          );
    }
    _slow?.cancel();
    if (!mounted || run != _run) return;
    setState(() {
      _searching = false;
      _result = result;
      _checks = checks;
      _failed = result == null;
    });
  }

  _Period _chosen(({DateTime from, DateTime? since}) suggested) =>
      _period ?? (suggested.since != null ? _Period.sinceLast : _Period.year);

  /// Oldest first, so the numbers follow the dive order.
  Future<Set<String>> _save(
    Set<int> selected,
    Set<int> confirmed,
    List<ImportedDive> dives,
  ) async {
    final indices = selected.toList()
      ..sort((a, b) => dives[a].start.compareTo(dives[b].start));
    final diverId = (await ref.read(activeDiverProvider.future))!.id!;
    final results = await ref
        .read(importServiceProvider)
        .importDives(
          diverId,
          [for (final i in indices) dives[i]],
          confirmed: {
            for (final (pos, i) in indices.indexed)
              if (confirmed.contains(i)) pos,
          },
        );
    return {for (final r in results.whereType<Saved>()) r.saved.id!};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importSourceHealth)),
      body: SafeArea(
        child: result != null && result.dives.isNotEmpty
            ? ImportPreview(
                key: ValueKey(_run),
                source: l10n.previewSourceHealth,
                notes: [
                  if (result.skippedWithoutDepth > 0)
                    l10n.healthSkippedNoDepth(result.skippedWithoutDepth),
                ],
                dives: result.dives,
                checks: _checks,
                onSave: _save,
              )
            : _start(l10n, result),
      ),
    );
  }

  Widget _start(AppLocalizations l10n, HealthFetchResult? result) {
    final theme = Theme.of(context);
    final muted = theme.extension<DiveColors>()!.onSurfaceMuted;
    final dives = ref.watch(logbookProvider).value;
    if (dives == null) return const SizedBox.shrink();
    final suggested = healthImportFrom(dives, clock.now());
    final chosen = _chosen(suggested);
    final since = suggested.since;

    return BodyWithBottomAction(
      action: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: _searching ? null : () => _search(suggested),
        icon: const Icon(Icons.search),
        label: Text(_failed ? l10n.retry : l10n.healthSearch),
      ),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Icon(
            Icons.favorite_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(l10n.healthIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            l10n.healthDepthLimit,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.healthPeriodTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          RadioGroup<_Period>(
            groupValue: chosen,
            onChanged: (p) => setState(() => _period = p),
            child: Column(
              children: [
                if (since != null)
                  RadioListTile<_Period>(
                    contentPadding: EdgeInsets.zero,
                    enabled: !_searching,
                    value: _Period.sinceLast,
                    title: Text(
                      l10n.healthPeriodSince(
                        DateFormat('dd.MM.yyyy', 'de').format(since),
                      ),
                    ),
                  ),
                RadioListTile<_Period>(
                  contentPadding: EdgeInsets.zero,
                  enabled: !_searching,
                  value: _Period.year,
                  title: Text(l10n.healthPeriodYear),
                ),
              ],
            ),
          ),
          if (_searching && _slowSearch) ...[
            const SizedBox(height: 16),
            Text(l10n.healthSearching),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (!_searching && _failed) ...[
            const SizedBox(height: 16),
            _Notice(
              icon: Icons.error_outline,
              color: theme.colorScheme.error,
              lines: [l10n.healthFailed],
            ),
          ],
          if (!_searching && result != null && result.dives.isEmpty) ...[
            const SizedBox(height: 16),
            _Notice(
              icon: Icons.info_outline,
              color: theme.colorScheme.primary,
              lines: [
                l10n.healthNone,
                l10n.healthNoneHint,
                l10n.healthNoneAccess,
                if (result.skippedWithoutDepth > 0)
                  l10n.healthSkippedNoDepth(result.skippedWithoutDepth),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A message with an icon, so it does not depend on colour alone (§1).
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.lines});

  final IconData icon;
  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, line) in lines.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: Text(
                    line,
                    style: i == 0
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
