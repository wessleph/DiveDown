import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import/dive_computer_screen.dart';
import '../features/import/import_screen.dart';
import '../features/logbook/dive_detail_screen.dart';
import '../features/logbook/logbook_screen.dart';
import '../features/logbook/manual_dive_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/settings/settings_screen.dart';
import 'home_shell.dart';
import 'providers.dart';

// Top-level navigation from ui-spec §2: Logbuch, Importieren, Einstellungen.
// Without an active diver everything leads to the welcome (§5.1).
final routerProvider = Provider<GoRouter>((ref) {
  final diverChanged = ValueNotifier(0);
  ref.listen(activeDiverProvider, (_, _) => diverChanged.value++);
  ref.onDispose(diverChanged.dispose);

  final router = GoRouter(
    initialLocation: LogbookScreen.path,
    refreshListenable: diverChanged,
    redirect: (context, state) {
      final diver = ref.read(activeDiverProvider);
      if (!diver.hasValue) return null;
      final welcome = state.matchedLocation == WelcomeScreen.path;
      if (diver.value == null) return welcome ? null : WelcomeScreen.path;
      return welcome ? LogbookScreen.path : null;
    },
    routes: [
      GoRoute(
        path: WelcomeScreen.path,
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LogbookScreen.path,
                builder: (context, state) => const LogbookScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ManualDiveScreen(),
                  ),
                  GoRoute(
                    path: 'dive/:id',
                    builder: (context, state) =>
                        DiveDetailScreen(diveId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => ManualDiveScreen(
                          diveId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ImportScreen.path,
                builder: (context, state) => const ImportScreen(),
                routes: [
                  GoRoute(
                    path: 'divecomputer',
                    builder: (context, state) => const DiveComputerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsScreen.path,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
