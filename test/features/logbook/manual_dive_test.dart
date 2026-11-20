// T12.13-T12.15, T15.11-T15.17: manual entry and editing (ui-spec §5.4).
import 'package:clock/clock.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/logbook/logbook_screen.dart';
import 'package:divedown/features/logbook/manual_dive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _now = DateTime(2026, 11, 20, 12, 30);

/// The text field whose label starts with [label].
Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

String _textOf(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller!.text;

bool _hasFocus(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(of: _field(label), matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Speichern'));
  await tester.pumpAndSettle();
}

/// Anna with dives #1-#5, form for a new dive open.
Future<(AppDatabase, Diver)> _openNewForm(
  WidgetTester tester, {
  int existing = 5,
  double textScale = 1,
  Size size = const Size(400, 800),
}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = await seedActiveDiver(db);
  for (var i = 1; i <= existing; i++) {
    await seedDive(
      db,
      exampleDive(anna.id!, number: i, source: DiveSource.manual),
    );
  }
  await pumpTestApp(tester, db: db, size: size, textScale: textScale);
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  return (db, anna);
}

void main() {
  testWidgets('T15.11 FAB opens the form, number prefilled with 6', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      await _openNewForm(tester);

      expect(currentLocation(tester), ManualDiveScreen.newPath);
      expect(_textOf(tester, 'Nr.'), '6');
      expect(find.textContaining('20.11.2026'), findsOneWidget); // Datum
      expect(find.textContaining('12:30'), findsOneWidget); // Startzeit
    });
  });

  testWidgets('T15.11 number fields use the number keyboard', (tester) async {
    await _openNewForm(tester);

    TextInputType keyboard(String label) =>
        tester.widget<TextField>(_field(label)).keyboardType;
    expect(keyboard('Nr.'), TextInputType.number);
    expect(keyboard('Dauer'), TextInputType.number);
    for (final label in ['Max. Tiefe', 'Ø-Tiefe', 'Wassertemp.', 'Flasche']) {
      expect(
        keyboard(label),
        const TextInputType.numberWithOptions(decimal: true, signed: false),
        reason: label,
      );
    }
  });

  testWidgets('T15.12 missing required fields: focus on the first', (
    tester,
  ) async {
    final (db, anna) = await _openNewForm(tester);

    await _save(tester);

    expect(currentLocation(tester), ManualDiveScreen.newPath);
    expect(find.text('Bitte ausfüllen.'), findsNWidgets(2));
    expect(_hasFocus(tester, 'Dauer'), isTrue);
    expect(await DriftDiveRepository(db).listForDiver(anna.id!), hasLength(5));
  });

  testWidgets('T12.15 depth 400: error text, focus jumps there', (
    tester,
  ) async {
    await _openNewForm(tester);
    await _enter(tester, 'Dauer', '47');
    await _enter(tester, 'Max. Tiefe', '400');

    await _save(tester);

    expect(
      find.text('Tiefe muss zwischen 0 und 350 m liegen.'),
      findsOneWidget,
    );
    expect(_hasFocus(tester, 'Max. Tiefe'), isTrue);
  });

  testWidgets('T15.13 end pressure not below start pressure', (tester) async {
    await _openNewForm(tester);
    await _enter(tester, 'Dauer', '47');
    await _enter(tester, 'Max. Tiefe', '18,4');
    await _enter(tester, 'Startdruck', '200');
    await _enter(tester, 'Enddruck', '210');

    await _save(tester);

    expect(
      find.text('Der Enddruck muss kleiner als der Startdruck sein.'),
      findsOneWidget,
    );
    expect(_hasFocus(tester, 'Enddruck'), isTrue);
  });

  testWidgets('T15.14 valid entry is saved and shown in the list', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, anna) = await _openNewForm(tester);
      await _enter(tester, 'Tauchplatz', 'Walensee, Quinten');
      await _enter(tester, 'Dauer', '47');
      await _enter(tester, 'Max. Tiefe', '18,4');
      await _enter(tester, 'Flasche', '12');
      await _enter(tester, 'Startdruck', '200');
      await _enter(tester, 'Enddruck', '50');

      await _save(tester);

      expect(currentLocation(tester), LogbookScreen.path);
      expect(find.text('#6'), findsOneWidget);
      expect(find.text('Walensee, Quinten'), findsOneWidget);

      final dives = await DriftDiveRepository(db).listForDiver(anna.id!);
      final saved = dives.firstWhere((d) => d.number == 6);
      expect(saved.source, DiveSource.manual);
      expect(saved.durationS, 2820);
      expect(saved.maxDepthM, 18.4);
      expect(saved.start.year, 2026);
      expect(saved.start.month, 11);
      expect(saved.start.day, 20);
      final full = await DriftDiveRepository(db).findById(saved.id!);
      expect(full!.tanks.single.volumeL, 12);
      expect(full.tanks.single.endPressureBar, 50);
    });
  });

  testWidgets('T15.15 editing an imported dive keeps its profile', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = await seedActiveDiver(db);
    final dive = await seedDive(db, exampleDive(anna.id!));
    await pumpTestApp(
      tester,
      db: db,
      location: ManualDiveScreen.editPathFor(dive.id!),
    );

    expect(_textOf(tester, 'Nr.'), '42');
    expect(_textOf(tester, 'Tauchplatz'), 'SS Thistlegorm');
    expect(_textOf(tester, 'Max. Tiefe'), '18,4');
    await _enter(tester, 'Max. Tiefe', '19,5');
    await _save(tester);

    expect(currentLocation(tester), DiveDetailScreen.pathFor(dive.id!));
    expect(find.text('19,5 m'), findsOneWidget);
    final saved = await DriftDiveRepository(db).findById(dive.id!);
    expect(saved!.maxDepthM, 19.5);
    expect(saved.samples, hasLength(dive.samples.length));
    expect(saved.source, DiveSource.diveComputer);
  });

  testWidgets('T15.16 leaving with changes asks first', (tester) async {
    final (db, anna) = await _openNewForm(tester);
    await _enter(tester, 'Dauer', '47');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Änderungen verwerfen?'), findsOneWidget);

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(currentLocation(tester), ManualDiveScreen.newPath);
    expect(_textOf(tester, 'Dauer'), '47');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();

    expect(currentLocation(tester), LogbookScreen.path);
    expect(await DriftDiveRepository(db).listForDiver(anna.id!), hasLength(5));
  });

  testWidgets('T15.16 leaving without changes does not ask', (tester) async {
    await _openNewForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Änderungen verwerfen?'), findsNothing);
    expect(currentLocation(tester), LogbookScreen.path);
  });

  testWidgets('T15.17 duplicate number: saved, with a hint', (tester) async {
    final (db, anna) = await _openNewForm(tester);
    await _enter(tester, 'Nr.', '3');
    await _enter(tester, 'Dauer', '47');
    await _enter(tester, 'Max. Tiefe', '18,4');

    await _save(tester);

    expect(currentLocation(tester), LogbookScreen.path);
    expect(
      find.text(
        'Die Nummer 3 gibt es schon. Der Tauchgang ist trotzdem gespeichert.',
      ),
      findsOneWidget,
    );
    final dives = await DriftDiveRepository(db).listForDiver(anna.id!);
    expect(dives.where((d) => d.number == 3), hasLength(2));
  });

  testWidgets('T12.13 form: no overflow at 200 % text size', (tester) async {
    await _openNewForm(tester, size: const Size(360, 740), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(_field('Dauer'), findsOneWidget);
  });

  testWidgets('T12.14 form: tap targets and contrast', (tester) async {
    final handle = tester.ensureSemantics();
    await _openNewForm(tester);

    expect(_field('Dauer'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
