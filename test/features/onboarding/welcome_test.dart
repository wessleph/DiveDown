// T15.20-T15.22: first start, create a diver (ui-spec §5.1).
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:divedown/features/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

ButtonStyleButton _startButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Los geht’s'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

void main() {
  testWidgets('T15.20 without a diver the app starts with the welcome', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db);

    expect(currentLocation(tester), WelcomeScreen.path);
    expect(find.text('Willkommen bei DiveDown'), findsOneWidget);
    expect(
      find.text('Wer taucht? Du kannst später weitere Taucher hinzufügen.'),
      findsOneWidget,
    );
    expect(find.text('Alle Daten bleiben auf diesem Gerät.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('T15.20 empty or blank name: button disabled, with hint', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db);

    expect(_startButton(tester).onPressed, isNull);
    expect(find.text('Bitte gib einen Namen ein.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(_startButton(tester).onPressed, isNull);
  });

  testWidgets('T15.21 „Los geht’s“ creates the diver and opens the logbook', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db);

    await tester.enterText(find.byType(TextField), ' Anna ');
    await tester.pump();
    expect(_startButton(tester).onPressed, isNotNull);
    await tester.tap(find.text('Los geht’s'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), LogbookScreen.path);
    expect(find.text('Noch keine Tauchgänge'), findsOneWidget);
    final divers = await DriftDiverRepository(db).list();
    expect(divers.single.name, 'Anna');
    expect(await DriftAppSettings(db).activeDiverId(), divers.single.id);
  });

  testWidgets('T15.22 with an active diver the app opens the logbook', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await seedDive(db, exampleDive(anna.id!));
    await pumpTestApp(tester, db: db);

    expect(currentLocation(tester), LogbookScreen.path);
    expect(find.text('Willkommen bei DiveDown'), findsNothing);
    // The logbook of the active diver is loaded, not just the empty tab.
    expect(find.text('#42'), findsOneWidget);
  });
}
