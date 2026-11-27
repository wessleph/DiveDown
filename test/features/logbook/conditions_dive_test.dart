// T40.6-T40.8: visibility, current and kinds of dive in the form and the
// detail (ui-spec §5.3, §5.4).
import 'package:clock/clock.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _now = DateTime(2026, 11, 20, 12, 30);

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

/// A choice (visibility, current) or filter chip (kinds) with [text].
Finder _chip(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate((w) => w is ChoiceChip || w is FilterChip),
);

bool _selected(WidgetTester tester, String text) =>
    switch (tester.widget(_chip(text))) {
      ChoiceChip(:final selected) || FilterChip(:final selected) => selected,
      _ => false,
    };

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

/// Types the site and closes the keyboard; a focused field keeps scrolling
/// itself back into view.
Future<void> _site(WidgetTester tester, String name) async {
  await _enter(tester, 'Tauchplatz', name);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  // Closing the keyboard may still be scrolling the form.
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<(AppDatabase, String)> _seed({bool earlier = false}) async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = (await seedActiveDiver(db)).id!;
  if (earlier) {
    await seedDive(
      db,
      exampleDive(
        anna,
        number: 1,
        siteName: 'Elphinstone',
        source: DiveSource.manual,
        start: DateTime.utc(2026, 3, 26, 9, 30),
      ).copyWith(
        visibility: WaterVisibility.good,
        current: WaterCurrent.light,
        kinds: {DiveKind.reef},
      ),
    );
  }
  return (db, anna);
}

Future<void> _openNewForm(WidgetTester tester, AppDatabase db) async {
  await pumpTestApp(tester, db: db, size: const Size(400, 2400));
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T40.6 form: choose visibility, current and kinds; saved', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, anna) = await _seed();
      await _openNewForm(tester, db);

      for (final label in ['Sichtweite', 'Strömung', 'Tauchgangsart']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final chip in [
        'schlecht (< 5 m)',
        'mittel (5–10 m)',
        'gut (10–20 m)',
        'sehr gut (> 20 m)',
        'keine',
        'leicht',
        'mittel',
        'stark',
        'Riff',
        'Wrack',
        'Steilwand',
        'Höhle',
        'Nacht',
        'See',
        'Ausbildung',
        'Drift',
      ]) {
        expect(_chip(chip), findsOneWidget, reason: chip);
      }

      await _enter(tester, 'Dauer', '47');
      await _enter(tester, 'Max. Tiefe', '18');
      await _tap(tester, _chip('mittel (5–10 m)'));
      await _tap(tester, _chip('gut (10–20 m)')); // one step only
      await _tap(tester, _chip('stark'));
      await _tap(tester, _chip('stark')); // tapped again: cleared
      await _tap(tester, _chip('leicht'));
      await _tap(tester, _chip('Wrack'));
      await _tap(tester, _chip('Nacht'));
      expect(_selected(tester, 'mittel (5–10 m)'), isFalse);
      expect(_selected(tester, 'gut (10–20 m)'), isTrue);
      await _tap(tester, find.text('Speichern'));

      final repo = DriftDiveRepository(db);
      final saved = (await repo.findById(
        (await repo.listForDiver(anna)).first.id!,
      ))!;
      expect(saved.visibility, WaterVisibility.good);
      expect(saved.current, WaterCurrent.light);
      expect(saved.kinds, {DiveKind.wreck, DiveKind.night});
    });
  });

  testWidgets('T40.7 hint from the last dive at the site; „Übernehmen“', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, _) = await _seed(earlier: true);
      await _openNewForm(tester, db);
      expect(find.textContaining('Zuletzt bei'), findsNothing);

      await _site(tester, 'Elphinstone');
      expect(
        find.text(
          'Zuletzt bei Elphinstone: Sicht gut · Strömung leicht · Riff',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Übernehmen'));
      expect(_selected(tester, 'gut (10–20 m)'), isTrue);
      expect(_selected(tester, 'leicht'), isTrue);
      expect(_selected(tester, 'Riff'), isTrue);
      expect(find.textContaining('Zuletzt bei'), findsNothing);

      await _site(tester, 'Daedalus');
      await _tap(tester, _chip('gut (10–20 m)'));
      await _tap(tester, _chip('leicht'));
      await _tap(tester, _chip('Riff'));
      expect(find.textContaining('Zuletzt bei'), findsNothing);
    });
  });

  testWidgets('T40.7 something chosen already: no hint', (tester) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, _) = await _seed(earlier: true);
      await _openNewForm(tester, db);

      await _site(tester, 'Elphinstone');
      expect(find.textContaining('Zuletzt bei'), findsOneWidget);
      await _tap(tester, _chip('Nacht'));
      expect(find.textContaining('Zuletzt bei'), findsNothing);
    });
  });

  testWidgets('T40.8 detail: section „BEDINGUNGEN“; without any none', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = (await seedActiveDiver(db)).id!;
    final full = await seedDive(
      db,
      exampleDive(anna, number: 1).copyWith(
        visibility: WaterVisibility.excellent,
        current: WaterCurrent.none,
        kinds: {DiveKind.wreck, DiveKind.night},
      ),
    );
    final plain = await seedDive(db, exampleDive(anna, number: 2));
    await pumpTestApp(
      tester,
      db: db,
      size: const Size(400, 2400),
      location: DiveDetailScreen.pathFor(full.id!),
    );

    expect(find.text('BEDINGUNGEN'), findsOneWidget);
    expect(
      find.text('Sicht sehr gut (> 20 m) · keine Strömung'),
      findsOneWidget,
    );
    expect(find.text('Wrack · Nacht'), findsOneWidget);

    router(tester).go(DiveDetailScreen.pathFor(plain.id!));
    await tester.pumpAndSettle();
    expect(find.text('BEDINGUNGEN'), findsNothing);
  });
}
