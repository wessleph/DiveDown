import 'package:flutter/material.dart';

import '../data/local/database.dart';

/// Opens the database before the app starts. While opening it shows
/// nothing, on failure an error card with „Erneut versuchen“ (ui-spec §4).
class AppStartupGate extends StatelessWidget {
  const AppStartupGate({super.key, required this.openDatabase});

  /// Opens the database and loads the catalogue; may throw.
  final Future<AppDatabase> Function() openDatabase;

  @override
  Widget build(BuildContext context) =>
      throw UnimplementedError('T16.4: AppStartupGate');
}
