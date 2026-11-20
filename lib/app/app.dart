import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/import/fit_import_screen.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class DiveDownApp extends ConsumerWidget {
  const DiveDownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // „Teilen → DiveDown“ opens the FIT preview from anywhere (ui-spec §2).
    ref.listen(sharedFileEventsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        ref.read(pendingImportFileProvider.notifier).set(value);
        ref.read(routerProvider).go(FitImportScreen.path);
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      // German only for now (constitution, rule 2).
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
