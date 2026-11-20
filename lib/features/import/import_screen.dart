import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  static const path = '/import';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navImport)),
    );
  }
}
