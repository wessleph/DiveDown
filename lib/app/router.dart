import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import/import_screen.dart';
import '../features/logbook/logbook_screen.dart';
import '../features/settings/settings_screen.dart';
import 'home_shell.dart';

// Top-level navigation from ui-spec §2: Logbuch, Importieren, Einstellungen.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: LogbookScreen.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LogbookScreen.path,
                builder: (context, state) => const LogbookScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ImportScreen.path,
                builder: (context, state) => const ImportScreen(),
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
