import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../l10n/app_localizations.dart';
import 'app.dart';
import 'providers.dart';
import 'theme.dart';

/// Opens the database before the app starts. While opening it shows
/// nothing, on failure an error card with „Erneut versuchen“ (ui-spec §4).
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key, required this.openDatabase});

  /// Opens the database and loads the catalogue; may throw.
  final Future<AppDatabase> Function() openDatabase;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late Future<AppDatabase> _opening = widget.openDatabase();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _opening,
      builder: (context, snapshot) {
        if (snapshot.data case final db?) {
          return ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: const DiveDownApp(),
          );
        }
        if (!snapshot.hasError) return const SizedBox.shrink();
        return _StartupError(
          onRetry: () => setState(() {
            _opening = widget.openDatabase();
          }),
        );
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
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
                        Text(l10n.startupError, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onRetry,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
