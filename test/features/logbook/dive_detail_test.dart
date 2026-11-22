// T12.12-T12.14, T15.5-T15.10: dive detail (ui-spec §5.3).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Seeds Anna with [dive] (built from her id) and opens its detail.
Future<(AppDatabase, Dive)> _openDetail(
  WidgetTester tester,
  Dive Function(String diverId) dive, {
  double textScale = 1,
  Size size = const Size(400, 800),
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  final saved = await seedDive(db, dive(anna.id!));
  await pumpTestApp(
    tester,
    db: db,
    size: size,
    textScale: textScale,
    location: DiveDetailScreen.pathFor(saved.id!),
  );
  return (db, saved);
}

const _noSacInfo =
    'Für den Luftverbrauch werden Flaschendruck und Flaschengröße benötigt.';

void main() {
  testWidgets('T15.5 header and key figures', (tester) async {
    final handle = tester.ensureSemantics();
    await _openDetail(tester, exampleDive);

    expect(find.text('#42'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Tauchgang 42')), findsWidgets);
    expect(find.text('SS Thistlegorm'), findsOneWidget);
    expect(find.textContaining('14.11.2026'), findsWidgets);
    expect(find.textContaining('10:42'), findsWidgets);
    expect(find.textContaining('Anna'), findsWidgets);

    expect(find.text('18,4 m'), findsOneWidget); // max. Tiefe
    expect(find.text('47 min'), findsOneWidget); // Dauer
    expect(find.text('10,0 m'), findsOneWidget); // Ø-Tiefe
    expect(find.text('21 °C'), findsOneWidget); // Wassertemp. min
    expect(find.text('200 → 50 bar'), findsOneWidget); // Druck
    // (150 bar × 12 l) / (47 min × 2,005 bar) = 19,1 l/min
    expect(find.text('19,1 l/min'), findsOneWidget); // Ø-SAC
    expect(find.text('EAN32'), findsWidgets); // Gas
    expect(find.text('Salzwasser'), findsOneWidget); // Wassertyp
    handle.dispose();
  });

  testWidgets('T15.6 no site: link „Tauchplatz hinzufügen“ opens the form', (
    tester,
  ) async {
    final (_, dive) = await _openDetail(
      tester,
      (id) => exampleDive(id, siteName: null),
    );

    await tester.tap(find.text('Tauchplatz hinzufügen'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), ManualDiveScreen.editPathFor(dive.id!));
  });

  testWidgets('T12.12 no pressure: pressure and SAC „—“ with info', (
    tester,
  ) async {
    await _openDetail(
      tester,
      (id) => exampleDive(id, tanks: const [DiveTank(index: 0, volumeL: 12)]),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.byTooltip(_noSacInfo), findsOneWidget);
  });

  testWidgets('T15.7 pressure but no tank size: link opens the form', (
    tester,
  ) async {
    final (_, dive) = await _openDetail(
      tester,
      (id) => exampleDive(
        id,
        tanks: const [
          DiveTank(index: 0, startPressureBar: 200, endPressureBar: 50),
        ],
      ),
    );

    expect(find.text('200 → 50 bar'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    // Since T22.12 the link sits in the value panel under the profile.
    await tester.ensureVisible(find.text('Flaschengröße eintragen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flaschengröße eintragen'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), ManualDiveScreen.editPathFor(dive.id!));
  });

  testWidgets('T15.8 no samples: estimated profile with hint', (tester) async {
    await _openDetail(
      tester,
      (id) => exampleDive(id, source: DiveSource.manual, samples: const []),
    );

    expect(find.text('Geschätztes Profil'), findsOneWidget);
  });

  testWidgets('T15.8 with samples: no estimate hint', (tester) async {
    await _openDetail(tester, exampleDive);

    expect(find.text('#42'), findsOneWidget);
    expect(find.text('Geschätztes Profil'), findsNothing);
  });

  testWidgets('„Bearbeiten“ opens the form for this dive', (tester) async {
    final (_, dive) = await _openDetail(tester, exampleDive);

    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), ManualDiveScreen.editPathFor(dive.id!));
  });

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menü anzeigen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
  }

  testWidgets('T15.9 delete, then undo from the snackbar', (tester) async {
    final (db, dive) = await _openDetail(tester, exampleDive);

    await openDeleteDialog(tester);
    expect(find.text('Tauchgang löschen?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Löschen'),
      ),
    );
    await tester.pumpAndSettle();

    expect(currentLocation(tester), LogbookScreen.path);
    expect(find.text('#42'), findsNothing);
    expect(await DriftDiveRepository(db).findById(dive.id!), isNull);

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();

    expect(find.text('#42'), findsOneWidget);
    expect(await DriftDiveRepository(db).findById(dive.id!), isNotNull);
  });

  testWidgets('T15.10 cancel keeps the dive', (tester) async {
    final (db, dive) = await _openDetail(tester, exampleDive);

    await openDeleteDialog(tester);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), DiveDetailScreen.pathFor(dive.id!));
    expect(await DriftDiveRepository(db).findById(dive.id!), isNotNull);
  });

  testWidgets('T12.13 no overflow at 200 % text size', (tester) async {
    await _openDetail(
      tester,
      exampleDive,
      size: const Size(360, 740),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('#42'), findsOneWidget);
  });

  testWidgets('T12.14 tap targets and contrast', (tester) async {
    final handle = tester.ensureSemantics();
    await _openDetail(tester, (id) => exampleDive(id, siteName: null));

    expect(find.text('#42'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
