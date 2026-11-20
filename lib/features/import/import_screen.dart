import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'dive_computer_screen.dart';
import 'fit_import_screen.dart';

/// Choose where dives come from (ui-spec §5.5).
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  static const path = '/import';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void soon() =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.importComingSoon)));

    Future<void> pickFit() async {
      final file = await ref.read(importFilePickerProvider).pick();
      if (file == null || !context.mounted) return;
      ref.read(pendingImportFileProvider.notifier).set(file);
      context.go(FitImportScreen.path);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navImport)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ImportForLine(),
          const SizedBox(height: 16),
          _SourceCard(
            icon: Icons.watch_outlined,
            title: l10n.importSourceComputer,
            subtitle: l10n.importSourceComputerHint,
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
            _SourceCard(
              icon: Icons.favorite_outline,
              title: l10n.importSourceHealth,
              subtitle: l10n.importSourceHealthHint,
              onTap: soon,
            ),
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

/// „Importieren für: **Anna**“ (ui-spec §2).
class ImportForLine extends ConsumerWidget {
  const ImportForLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(activeDiverProvider).value?.name;
    if (name == null) return const SizedBox.shrink();
    final text = AppLocalizations.of(context).importFor(name);
    final at = text.lastIndexOf(name);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(at + name.length)),
        ],
      ),
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
