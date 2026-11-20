import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/dive/diver.dart';
import '../../l10n/app_localizations.dart';
import '../logbook/logbook_screen.dart';

/// Erster Start: Taucher anlegen (ui-spec §5.1).
/// Colour and units follow with the settings screen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  static const path = '/welcome';

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    final diver = await ref
        .read(diverRepositoryProvider)
        .create(Diver(name: _name.text.trim()));
    await ref.read(appSettingsProvider).setActiveDiverId(diver.id!);
    ref.invalidate(activeDiverProvider);
    if (mounted) context.go(LogbookScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasName = _name.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Text(l10n.welcomeTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.welcomeBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => hasName && !_saving ? _start() : null,
              decoration: InputDecoration(
                labelText: l10n.welcomeName,
                helperText: hasName ? null : l10n.welcomeNameMissing,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: hasName && !_saving ? _start : null,
              child: Text(l10n.welcomeStart),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeLocalOnly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
