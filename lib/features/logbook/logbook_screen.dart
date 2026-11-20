import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  static const path = '/logbook';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navLogbook)),
    );
  }
}
