// T31.3-T31.5: lead and equipment in the form and the detail (ui-spec §5.3,
// §5.4, ADR 0007).
import 'package:clock/clock.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/data/local/drift_equipment_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/equipment/equipment.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/settings/equipment_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

final _now = DateTime(2026, 11, 20, 12, 30);

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

Finder _chip(String name) => find.widgetWithText(FilterChip, name);

bool _selected(WidgetTester tester, String name) =>
    tester.widget<FilterChip>(_chip(name)).selected;

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Anna with a suit and a BCD in the standard set, a lamp, and an older
/// dive at Elphinstone with 6 kg.
Future<(AppDatabase, String, Map<String, Equipment>)> _seed() async {
  final db = newTestDatabase();
  addTearDown(db.close);
  final anna = (await seedActiveDiver(db)).id!;
  final repo = DriftEquipmentRepository(db);
  final items = {
    for (final e in [
      Equipment(
        diverId: anna,
        kind: EquipmentKind.suit,
        name: 'Bare Velocity 5 mm',
        isDefault: true,
      ),
      Equipment(
        diverId: anna,
        kind: EquipmentKind.bcd,
        name: 'Hydros Pro',
        isDefault: true,
      ),
      Equipment(diverId: anna, kind: EquipmentKind.light, name: 'Tovatec'),
    ])
      e.name: await repo.save(e),
  };
  await seedDive(
    db,
    exampleDive(
      anna,
      number: 1,
      siteName: 'Elphinstone',
      source: DiveSource.manual,
      start: DateTime.utc(2026, 3, 26, 9, 30),
    ).copyWith(weightKg: 6, equipmentIds: const []),
  );
  return (db, anna, items);
}

Future<void> _openNewForm(WidgetTester tester, AppDatabase db) async {
  await pumpTestApp(tester, db: db, size: const Size(400, 1400));
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T31.3 lead field with the number keyboard; hint from the '
      'last dive at the site, „Übernehmen“ fills it in', (tester) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, _, _) = await _seed();
      await _openNewForm(tester, db);

      expect(
        tester.widget<TextField>(_field('Blei (kg)')).keyboardType,
        const TextInputType.numberWithOptions(decimal: true, signed: false),
      );
      expect(find.textContaining('Zuletzt bei'), findsNothing);

      await _enter(tester, 'Tauchplatz', 'Elphinstone');
      expect(find.text('Zuletzt bei Elphinstone: 6 kg'), findsOneWidget);

      await _tap(tester, find.text('Übernehmen'));
      expect(
        tester.widget<TextField>(_field('Blei (kg)')).controller!.text,
        '6',
      );
      expect(find.textContaining('Zuletzt bei'), findsNothing);

      await _enter(tester, 'Tauchplatz', 'Daedalus');
      await _enter(tester, 'Blei (kg)', '');
      expect(find.textContaining('Zuletzt bei'), findsNothing);
    });
  });

  testWidgets('T31.3 lead out of range: error text', (tester) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, _, _) = await _seed();
      await _openNewForm(tester, db);

      await _enter(tester, 'Dauer', '47');
      await _enter(tester, 'Max. Tiefe', '18');
      await _enter(tester, 'Blei (kg)', '45');
      await _tap(tester, find.text('Speichern'));
      expect(
        find.text('Blei muss zwischen 0 und 40 kg liegen.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('T31.4 new dive: standard set preselected, saved as chosen', (
    tester,
  ) async {
    await withClock(Clock.fixed(_now), () async {
      final (db, anna, items) = await _seed();
      await _openNewForm(tester, db);

      await tester.ensureVisible(_chip('Tovatec'));
      expect(_selected(tester, 'Bare Velocity 5 mm'), isTrue);
      expect(_selected(tester, 'Hydros Pro'), isTrue);
      expect(_selected(tester, 'Tovatec'), isFalse);

      await _tap(tester, _chip('Hydros Pro'));
      await _tap(tester, _chip('Tovatec'));
      await _enter(tester, 'Dauer', '47');
      await _enter(tester, 'Max. Tiefe', '18');
      await _enter(tester, 'Blei (kg)', '6,5');
      await _tap(tester, find.text('Speichern'));

      final dives = DriftDiveRepository(db);
      final newest = (await dives.listForDiver(anna)).first;
      final saved = (await dives.findById(newest.id!))!;
      expect(saved.weightKg, 6.5);
      expect(
        saved.equipmentIds,
        unorderedEquals([
          items['Bare Velocity 5 mm']!.id,
          items['Tovatec']!.id,
        ]),
      );
    });
  });

  testWidgets('T31.4 editing shows the dive’s pieces, a deleted one too', (
    tester,
  ) async {
    final (db, anna, items) = await _seed();
    final dive = await seedDive(
      db,
      exampleDive(
        anna,
        number: 2,
      ).copyWith(equipmentIds: [items['Hydros Pro']!.id!]),
    );
    await DriftEquipmentRepository(db).delete(items['Hydros Pro']!.id!);
    await pumpTestApp(
      tester,
      db: db,
      size: const Size(400, 1400),
      location: '${DiveDetailScreen.pathFor(dive.id!)}/edit',
    );

    await tester.ensureVisible(_chip('Hydros Pro'));
    expect(_selected(tester, 'Hydros Pro'), isTrue);
    expect(_selected(tester, 'Bare Velocity 5 mm'), isFalse);
    expect(_selected(tester, 'Tovatec'), isFalse);
  });

  testWidgets('T31.4 without equipment: hint with link', (tester) async {
    await withClock(Clock.fixed(_now), () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await _openNewForm(tester, db);

      final hint = find.text(
        'Noch keine Ausrüstung. Lege sie in den Einstellungen an.',
      );
      await tester.ensureVisible(hint);
      expect(hint, findsOneWidget);
      await _tap(tester, find.text('Ausrüstung anlegen'));
      // Pushed over the form, so what was typed stays (T31.4).
      expect(find.byType(EquipmentEditScreen), findsOneWidget);
    });
  });

  testWidgets('T31.5 detail: section with lead and the pieces', (tester) async {
    final (db, anna, items) = await _seed();
    final dive = await seedDive(
      db,
      exampleDive(anna, number: 2).copyWith(
        weightKg: 6.5,
        equipmentIds: [items['Bare Velocity 5 mm']!.id!, items['Tovatec']!.id!],
      ),
    );
    await pumpTestApp(
      tester,
      db: db,
      size: const Size(400, 2400),
      location: DiveDetailScreen.pathFor(dive.id!),
    );

    expect(find.text('AUSRÜSTUNG'), findsOneWidget);
    expect(find.text('6,5 kg'), findsOneWidget);
    expect(find.text('Bare Velocity 5 mm'), findsOneWidget);
    expect(find.text('Tovatec'), findsOneWidget);
    expect(find.text('Hydros Pro'), findsNothing);
  });

  testWidgets('T31.5 detail: no lead and no pieces, no section', (
    tester,
  ) async {
    final (db, anna, _) = await _seed();
    final dive = await seedDive(
      db,
      exampleDive(anna, number: 2).copyWith(equipmentIds: const []),
    );
    await pumpTestApp(
      tester,
      db: db,
      size: const Size(400, 2400),
      location: DiveDetailScreen.pathFor(dive.id!),
    );

    expect(find.text('AUSRÜSTUNG'), findsNothing);
  });
}
