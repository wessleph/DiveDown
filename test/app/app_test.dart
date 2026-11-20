import 'package:divedown/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: DiveDownApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts in the logbook with German navigation (ui-spec §2)', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Logbuch'), findsWidgets);
    expect(find.text('Importieren'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('switches tabs from the navigation bar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.widgetWithText(AppBar, 'Einstellungen'), findsOneWidget);
  });

  testWidgets('uses a side rail on tablets, >= 840 dp (ui-spec §8)', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1000, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('runs in German only (constitution, rule 2)', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('de'));
  });

  testWidgets('meets tap target and contrast guidelines (ui-spec §7)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
