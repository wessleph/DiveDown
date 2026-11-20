// T9.12-T9.18 (UI), T12.14: suggestions in the „Tauchplatz“ field
// (ui-spec §5.4, ADR 0006).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

String _textOf(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller!.text;

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredAndSave(WidgetTester tester) async {
  await _enter(tester, 'Dauer', '47');
  await _enter(tester, 'Max. Tiefe', '18,4');
  await tester.tap(find.text('Speichern'));
  await tester.pumpAndSettle();
}

Future<void> _seedCatalogue(AppDatabase db) => db.batch((b) {
  b.insertAll(db.catalogueSites, [
    CatalogueSitesCompanion.insert(
      id: 'osm_1',
      name: 'SS Thistlegorm',
      region: const Value('South Sinai'),
      countryCode: const Value('EG'),
      lat: 27.81409,
      lon: 33.92005,
    ),
    CatalogueSitesCompanion.insert(
      id: 'osm_2',
      name: 'Walchensee',
      region: const Value('Bayern'),
      countryCode: const Value('DE'),
      lat: 47.59,
      lon: 11.33,
    ),
  ]);
});

/// Anna, catalogue loaded, optional earlier dives, new-dive form open.
Future<(AppDatabase, Diver)> _openForm(
  WidgetTester tester, {
  List<String> earlierSites = const [],
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  await _seedCatalogue(db);
  for (final (i, site) in earlierSites.indexed) {
    await seedDive(
      db,
      exampleDive(
        anna.id!,
        number: i + 1,
        siteName: site,
        start: DateTime.utc(2026, 10, 1 + i),
        source: DiveSource.manual,
      ),
    );
  }
  await pumpTestApp(tester, db: db, location: ManualDiveScreen.newPath);
  return (db, anna);
}

Future<Dive> _savedDive(AppDatabase db, Diver diver) async {
  final dives = await DriftDiveRepository(db).listForDiver(diver.id!);
  return dives.reduce((a, b) => a.number! > b.number! ? a : b);
}

void main() {
  testWidgets('T9.12 choosing a catalogue site saves name, id, position', (
    tester,
  ) async {
    final (db, anna) = await _openForm(tester);

    await _enter(tester, 'Tauchplatz', 'thistle');
    expect(find.text('SS Thistlegorm'), findsOneWidget);
    expect(find.text('South Sinai, Ägypten'), findsOneWidget);
    await tester.tap(find.text('SS Thistlegorm'));
    await tester.pumpAndSettle();

    expect(_textOf(tester, 'Tauchplatz'), 'SS Thistlegorm');
    expect(find.text('South Sinai, Ägypten'), findsNothing, reason: 'closed');
    await _fillRequiredAndSave(tester);

    final dive = await _savedDive(db, anna);
    expect(dive.siteName, 'SS Thistlegorm');
    expect(dive.siteCatalogueId, 'osm_1');
    expect(dive.siteLat, 27.81409);
    expect(dive.siteLon, 33.92005);
  });

  testWidgets('T9.13 a new name is offered and saved as free text', (
    tester,
  ) async {
    final (db, anna) = await _openForm(tester);

    await _enter(tester, 'Tauchplatz', 'Walensee, Quinten');
    final newRow = find.text(
      '‚Walensee, Quinten‘ als neuen Tauchplatz verwenden',
    );
    expect(newRow, findsOneWidget);
    await tester.tap(newRow);
    await tester.pumpAndSettle();
    await _fillRequiredAndSave(tester);

    final dive = await _savedDive(db, anna);
    expect(dive.siteName, 'Walensee, Quinten');
    expect(dive.siteCatalogueId, isNull);
  });

  testWidgets('T9.14 typing over a chosen site drops the link', (tester) async {
    final (db, anna) = await _openForm(tester);

    await _enter(tester, 'Tauchplatz', 'thistle');
    await tester.tap(find.text('SS Thistlegorm'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Tauchplatz', 'SS Thistlegorm Heck');
    await _fillRequiredAndSave(tester);

    final dive = await _savedDive(db, anna);
    expect(dive.siteName, 'SS Thistlegorm Heck');
    expect(dive.siteCatalogueId, isNull);
    expect(dive.siteLat, isNull);
  });

  testWidgets('T9.15 own names are listed above catalogue hits', (
    tester,
  ) async {
    await _openForm(tester, earlierSites: ['Walensee, Quinten']);

    await _enter(tester, 'Tauchplatz', 'wal');

    final own = find.text('Walensee, Quinten');
    final catalogue = find.text('Walchensee');
    expect(own, findsOneWidget);
    expect(catalogue, findsOneWidget);
    expect(
      tester.getTopLeft(own).dy,
      lessThan(tester.getTopLeft(catalogue).dy),
    );
  });

  testWidgets('T9.16 the empty field shows recent own names on focus', (
    tester,
  ) async {
    await _openForm(
      tester,
      earlierSites: ['Hallwilersee', 'Walensee, Quinten'],
    );

    await tester.tap(_field('Tauchplatz'));
    await tester.pumpAndSettle();

    final recent = find.text('Walensee, Quinten');
    final older = find.text('Hallwilersee');
    expect(recent, findsOneWidget);
    expect(older, findsOneWidget);
    expect(tester.getTopLeft(recent).dy, lessThan(tester.getTopLeft(older).dy));
    expect(find.textContaining('als neuen Tauchplatz'), findsNothing);
  });

  testWidgets('T9.17 editing other fields keeps the catalogue link', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await _seedCatalogue(db);
    final dive = await seedDive(
      db,
      exampleDive(anna.id!).copyWith(
        siteCatalogueId: 'osm_1',
        siteLat: 27.81409,
        siteLon: 33.92005,
      ),
    );
    await pumpTestApp(
      tester,
      db: db,
      location: ManualDiveScreen.editPathFor(dive.id!),
    );

    await _enter(tester, 'Max. Tiefe', '19,5');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final saved = await DriftDiveRepository(db).findById(dive.id!);
    expect(saved!.maxDepthM, 19.5);
    expect(saved.siteCatalogueId, 'osm_1');
    expect(saved.siteLat, 27.81409);
  });

  testWidgets('T9.18 an own site with a link brings the link along', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    await _seedCatalogue(db);
    await seedDive(
      db,
      exampleDive(anna.id!, number: 1, siteName: 'SS Thistlegorm').copyWith(
        siteCatalogueId: 'osm_1',
        siteLat: 27.81409,
        siteLon: 33.92005,
      ),
    );
    await pumpTestApp(tester, db: db, location: ManualDiveScreen.newPath);

    await _enter(tester, 'Tauchplatz', 'thistle');
    expect(find.text('SS Thistlegorm'), findsOneWidget, reason: 'once');
    await tester.tap(find.text('SS Thistlegorm'));
    await tester.pumpAndSettle();
    await _fillRequiredAndSave(tester);

    final saved = await _savedDive(db, anna);
    expect(saved.number, 2);
    expect(saved.siteCatalogueId, 'osm_1');
  });

  testWidgets('T12.14 open suggestion list: tap targets and contrast', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _openForm(tester, earlierSites: ['Walensee, Quinten']);
    await _enter(tester, 'Tauchplatz', 'wal');

    expect(find.text('Walchensee'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
