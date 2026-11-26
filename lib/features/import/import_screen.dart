import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/import/health_import.dart';
import '../../l10n/app_localizations.dart';
import 'dive_computer_screen.dart';
import 'fit_import_screen.dart';
import 'health_import_screen.dart';
import 'last_used.dart';

/// Choose where dives come from (ui-spec §5.5).
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  static const path = '/import';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    Future<void> pickFit() async {
      final file = await ref.read(importFilePickerProvider).pick();
      if (file == null || !context.mounted) return;
      ref.read(pendingImportFileProvider.notifier).set(file);
      context.go(FitImportScreen.path);
    }

    // The known device with the newest dive (ui-spec §5.5, T28).
    final known = ref.watch(knownComputersProvider).value ?? const [];
    final newest = known
        .where((k) => k.lastDive != null)
        .fold<({String product, DateTime lastDive})?>(
          null,
          (best, k) => best == null || k.lastDive!.isAfter(best.lastDive)
              ? (product: k.computer.product, lastDive: k.lastDive!)
              : best,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navImport)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SourceCard(
            icon: Icons.watch_outlined,
            title: l10n.importSourceComputer,
            subtitle: l10n.importSourceComputerHint,
            note: newest == null
                ? null
                : lastUsedText(
                    l10n,
                    newest.product,
                    newest.lastDive,
                    DateTime.now(),
                  ),
            onTap: () => context.go(DiveComputerScreen.path),
          ),
          _SourceCard(
            icon: Icons.description_outlined,
            title: l10n.importSourceFit,
            subtitle: l10n.importSourceFitHint,
            onTap: pickFit,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showFitGuide(context),
              child: Text(l10n.fitGuideTitle),
            ),
          ),
          const SizedBox(height: 12),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            switch (ref.watch(healthAvailabilityProvider).value) {
              HealthAvailability.available => _SourceCard(
                icon: Icons.favorite_outline,
                title: l10n.importSourceHealth,
                subtitle: l10n.importSourceHealthHint,
                onTap: () => context.go(HealthImportScreen.path),
              ),
              // Depth and water temperature need iOS 16 (T6.10).
              HealthAvailability.needsNewerIos => _SourceCard(
                icon: Icons.favorite_outline,
                title: l10n.importSourceHealth,
                subtitle: l10n.importSourceHealthHint,
                note: l10n.healthNeedsIos16,
                onTap: null,
              ),
              HealthAvailability.unavailable || null => const SizedBox.shrink(),
            },
        ],
      ),
    );
  }
}

/// The three steps to export a FIT file from the Suunto app (ui-spec §5.8).
Future<void> showFitGuide(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.fitGuideTitle),
      content: Text(l10n.fitGuideSteps),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  },
);

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.note,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// A third, quieter line, e.g. „Zuletzt: EON Core, vor 3 Tagen“.
  final String? note;

  /// Null shows the card disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: onTap == null
                        ? theme.extension<DiveColors>()?.onSurfaceMuted
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                        if (note case final n?)
                          Text(
                            n,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .extension<DiveColors>()
                                  ?.onSurfaceMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
