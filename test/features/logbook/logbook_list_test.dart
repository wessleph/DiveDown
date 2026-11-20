// T12.1-T12.3, T12.13, T12.14, T15.2-T15.4: logbook list (ui-spec §5.2).
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/features/import/import_screen.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

Finder _inLogbook(Finder f) =>
    find.descendant(of: find.byType(LogbookScreen), matching: f);

void main() {
  group('T12.1 empty logbook', () {
    testWidgets('shows the empty state with both actions', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await pumpTestApp(tester, db: db);

      expect(find.text('Noch keine Tauchgänge'), findsOneWidget);
      expect(
        find.text(
          'Importiere vom Tauchcomputer oder trage einen Tauchgang von Hand ein.',
        ),
        findsOneWidget,
      );
      expect(_inLogbook(find.text('Importieren')), findsOneWidget);
      expect(_inLogbook(find.text('Manuell eintragen')), findsWidgets);
    });

    testWidgets('„Importieren“ opens the import tab', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await pumpTestApp(tester, db: db);

      await tester.tap(_inLogbook(find.text('Importieren')));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), ImportScreen.path);
    });

    testWidgets('„Manuell eintragen“ opens the form', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await pumpTestApp(tester, db: db);

      await tester.tap(_inLogbook(find.text('Manuell eintragen')).first);
      await tester.pumpAndSettle();

      expect(currentLocation(tester), ManualDiveScreen.newPath);
    });
  });

  testWidgets('T12.2 dive without site shows „Ohne Tauchplatz“', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await seedDive(db, exampleDive(anna.id!, siteName: null));
    await pumpTestApp(tester, db: db);

    expect(find.text('Ohne Tauchplatz'), findsOneWidget);
  });

  testWidgets('T12.3 + T15.3 row content and screen reader label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await seedDive(db, exampleDive(anna.id!));
    await pumpTestApp(tester, db: db);

    expect(find.text('#42'), findsOneWidget);
    expect(find.text('SS Thistlegorm'), findsOneWidget);
    expect(find.text('18,4 m'), findsOneWidget);
    expect(find.textContaining('14.11.2026'), findsOneWidget);
    expect(find.textContaining('47 min'), findsOneWidget);

    // Read as one element (ui-spec §7).
    expect(find.bySemanticsLabel(RegExp(r'^Tauchgang 42')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tauchgang 42, SS Thistlegorm, 14. November, 18,4 Meter, '
        '47 Minuten, vom Tauchcomputer',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('T15.2 grouped by month, newest first', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await seedDive(
      db,
      exampleDive(anna.id!, number: 1, start: DateTime.utc(2026, 10, 20, 9)),
    );
    await seedDive(
      db,
      exampleDive(anna.id!, number: 2, start: DateTime.utc(2026, 11, 2, 9)),
    );
    await seedDive(
      db,
      exampleDive(anna.id!, number: 3, start: DateTime.utc(2026, 11, 14, 9)),
    );
    await pumpTestApp(tester, db: db);

    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('November 2026'), lessThan(y('#3')));
    expect(y('#3'), lessThan(y('#2')));
    expect(y('#2'), lessThan(y('Oktober 2026')));
    expect(y('Oktober 2026'), lessThan(y('#1')));
  });

  testWidgets('T15.2 shows only dives of the active diver', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final ben = await DriftDiverRepository(db).create(const Diver(name: 'Ben'));
    await seedDive(db, exampleDive(ben.id!, number: 7));
    final anna = await seedActiveDiver(db);
    await seedDive(db, exampleDive(anna.id!, number: 42));
    await pumpTestApp(tester, db: db);

    expect(find.text('#42'), findsOneWidget);
    expect(find.text('#7'), findsNothing);
  });

  testWidgets('T15.4 tapping a row opens the detail', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    final dive = await seedDive(db, exampleDive(anna.id!));
    await pumpTestApp(tester, db: db);

    await tester.tap(find.text('#42'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), DiveDetailScreen.pathFor(dive.id!));
  });

  testWidgets('T12.13 no overflow at 200 % text size', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await seedDive(db, exampleDive(anna.id!, number: 42, siteName: null));
    // Same start, so #43 is the first row and visible at 200 %.
    await seedDive(
      db,
      exampleDive(
        anna.id!,
        number: 43,
        siteName: 'Ein sehr langer Tauchplatzname am Walensee bei Quinten',
      ),
    );
    await pumpTestApp(tester, db: db, size: const Size(360, 740), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('#43'), findsOneWidget);
  });

  testWidgets('T12.13 empty state: no overflow at 200 %', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await pumpTestApp(tester, db: db, size: const Size(360, 740), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Noch keine Tauchgänge'), findsOneWidget);
  });

  for (final withDives in [false, true]) {
    testWidgets('T12.14 tap targets and contrast, '
        '${withDives ? 'list' : 'empty state'}', (tester) async {
      final handle = tester.ensureSemantics();
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      if (withDives) {
        await seedDive(db, exampleDive(anna.id!));
        await seedDive(
          db,
          exampleDive(anna.id!, number: 43, source: DiveSource.manual),
        );
      }
      await pumpTestApp(tester, db: db);

      expect(
        find.text(withDives ? '#42' : 'Noch keine Tauchgänge'),
        findsOneWidget,
        reason: 'the screen must have content to check',
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
