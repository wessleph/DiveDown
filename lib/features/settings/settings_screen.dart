import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Einstellungen (ui-spec §5.11). For now only „Über DiveDown“ with the
/// open source licences; the other groups follow with their features.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsLicences),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
            ),
          ),
        ],
      ),
    );
  }
}
