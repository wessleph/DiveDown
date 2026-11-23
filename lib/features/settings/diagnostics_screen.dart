import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// „Diagnose-Logs teilen“ (ui-spec §5.13, design.md §9): preview of what
/// would be sent, then the system share dialog. Nothing is sent by itself.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  static const path = '/diagnostics';

  /// Lines shown before „… 1.240 weitere Zeilen“.
  static const previewLines = 200;

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  late final Future<List<String>> _lines = ref
      .read(diagnosticLogProvider)
      .lines();

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final header = await ref.read(diagnosticHeaderProvider.future);
      final text = await ref.read(diagnosticLogProvider).export(header);
      final day = DateFormat('yyyy-MM-dd').format(clock.now());
      await ref.read(shareFileProvider)(
        'DiveDown-Diagnose-$day.txt',
        utf8.encode(text),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.diagnosticsFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle)),
      body: FutureBuilder<List<String>>(
        future: _lines,
        builder: (context, snapshot) {
          final lines = snapshot.data;
          if (lines == null) return const SizedBox.shrink();
          final shown = lines.take(DiagnosticsScreen.previewLines).toList();
          final more = lines.length - shown.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(l10n.diagnosticsInfo),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: lines.isEmpty
                      ? Text(
                          l10n.diagnosticsEmpty,
                          style: TextStyle(color: colors.onSurfaceMuted),
                        )
                      // Own scroll area, so „Teilen“ stays in reach.
                      // At most 320 dp, smaller with few lines; lines wrap.
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final line in shown)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        line,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  if (more > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        l10n.diagnosticsMore(
                                          NumberFormat.decimalPattern('de')
                                              .format(more),
                                        ),
                                        style: TextStyle(
                                          color: colors.onSurfaceMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: lines.isEmpty ? null : _share,
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.diagnosticsShare),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.diagnosticsHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
