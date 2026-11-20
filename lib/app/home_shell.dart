import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Width from which navigation moves into a side rail (ui-spec §8).
const double tabletBreakpoint = 840;

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// The import tab keeps no state of its own: its flows run above the
  /// shell, so it always opens at the source choice (ui-spec §5.5).
  static const _importBranch = 1;

  void _select(int index) => shell.goBranch(
    index,
    initialLocation: index == shell.currentIndex || index == _importBranch,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.menu_book_outlined, Icons.menu_book, l10n.navLogbook),
      (Icons.add_circle_outline, Icons.add_circle, l10n.navImport),
      (Icons.settings_outlined, Icons.settings, l10n.navSettings),
    ];

    final wide = MediaQuery.sizeOf(context).width >= tabletBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
