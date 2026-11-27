import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/feedback/feedback_mail.dart';

import '../features/import/dive_computer_screen.dart';
import '../features/import/fit_import_screen.dart';
import '../features/import/health_import_screen.dart';
import '../features/import/import_screen.dart';
import '../features/logbook/dive_detail_screen.dart';
import '../features/logbook/logbook_screen.dart';
import '../features/logbook/manual_dive_screen.dart';
import '../features/logbook/profile_fullscreen_screen.dart';
import '../features/logbook/share_dive_screen.dart';
import '../features/logbook/statistics_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/settings/diagnostics_screen.dart';
import '../features/settings/equipment_edit_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/settings_screen.dart';
import 'home_shell.dart';
import 'providers.dart';

// Top-level navigation from ui-spec §2: Logbuch, Importieren, Einstellungen.
// Without an active diver everything leads to the welcome (§5.1).

/// Routes above the tab shell, without the tab bar.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final diverChanged = ValueNotifier(0);
  ref.listen(activeDiverProvider, (_, _) => diverChanged.value++);
  ref.onDispose(diverChanged.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      // Above the tab shell, reachable from settings and error states.
      GoRoute(
        path: DiagnosticsScreen.path,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: FeedbackScreen.bugPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const FeedbackScreen(kind: FeedbackKind.bug),
      ),
      GoRoute(
        path: FeedbackScreen.ideaPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const FeedbackScreen(kind: FeedbackKind.idea),
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
                    path: 'statistics',
                    builder: (context, state) => const StatisticsScreen(),
                  ),
                  GoRoute(
                    path: 'dive/:id',
                    builder: (context, state) =>
                        DiveDetailScreen(diveId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'profile',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ProfileFullscreenScreen(
                          diveId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'share',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ShareDiveScreen(
                          diveId: state.pathParameters['id']!,
                        ),
                      ),
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
                  // A flow of its own: no tab bar that could leave a running
                  // transfer, and the import tab is fresh afterwards.
                  GoRoute(
                    path: 'divecomputer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const DiveComputerScreen(),
                  ),
                  GoRoute(
                    path: 'fit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const FitImportScreen(),
                  ),
                  GoRoute(
                    path: 'health',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HealthImportScreen(),
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
                routes: [
                  GoRoute(
                    path: 'equipment/new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EquipmentEditScreen(),
                  ),
                  GoRoute(
                    path: 'equipment/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => EquipmentEditScreen(
                      equipmentId: state.pathParameters['id'],
                    ),
                  ),
                ],
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
