// T30.4-T30.6: equipment in the settings (ui-spec §5.11, ADR 0007).
import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/data/local/drift_equipment_repository.dart';
import 'package:divedown/domain/equipment/equipment.dart';
import 'package:divedown/features/logbook/dive_detail_screen.dart';
import 'package:divedown/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

const _info = AppInfo(version: '1.0.0', build: '42', libdivecomputer: '0.9.0');

Future<void> _open(WidgetTester tester, AppDatabase db) => pumpTestApp(
  tester,
  db: db,
  size: const Size(400, 1800),
  location: SettingsScreen.path,
  overrides: [appInfoProvider.overrideWith((ref) async => _info)],
);

Finder _field(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField && (w.decoration?.labelText?.startsWith(label) ?? false),
  description: 'TextField „$label“',
);

Finder _row(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ListTile));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T30.4 section after Taucher, sorted by kind, with „Standard“', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = (await seedActiveDiver(db)).id!;
    final repo = DriftEquipmentRepository(db);
    await repo.save(
      Equipment(
        diverId: anna,
        kind: EquipmentKind.light,
        name: 'Tovatec Fusion 1000',
      ),
    );
    await repo.save(
      Equipment(
        diverId: anna,
        kind: EquipmentKind.bcd,
        name: 'Scubapro Hydros Pro',
        isDefault: true,
      ),
    );
    await repo.save(
      Equipment(
        diverId: anna,
        kind: EquipmentKind.suit,
        name: 'Bare Velocity 5 mm',
        isDefault: true,
      ),
    );
    await _open(tester, db);

    final y = {
      for (final t in [
        'TAUCHER',
        'AUSRÜSTUNG',
        'Bare Velocity 5 mm',
        'Scubapro Hydros Pro',
        'Tovatec Fusion 1000',
        'Ausrüstung hinzufügen',
        'GERÄTE',
      ])
        t: tester.getTopLeft(find.text(t)).dy,
    };
    final order = y.keys.toList()..sort((a, b) => y[a]!.compareTo(y[b]!));
    expect(order, y.keys.toList());

    for (final (name, kind) in [
      ('Bare Velocity 5 mm', 'Anzug'),
      ('Scubapro Hydros Pro', 'Jacket'),
      ('Tovatec Fusion 1000', 'Lampe'),
    ]) {
      expect(
        find.descendant(of: _row(name), matching: find.textContaining(kind)),
        findsOneWidget,
        reason: name,
      );
    }
    expect(
      find.descendant(
        of: _row('Scubapro Hydros Pro'),
        matching: find.text('Standard'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _row('Tovatec Fusion 1000'),
        matching: find.text('Standard'),
      ),
      findsNothing,
    );
  });

  testWidgets('T30.4 without equipment: hint text', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await _open(tester, db);

    expect(find.text('AUSRÜSTUNG'), findsOneWidget);
    expect(
      find.text(
        'Noch keine Ausrüstung. Standard-Teile werden neuen Tauchgängen '
        'automatisch zugeordnet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('T30.5 add: name required, saved with kind and Standard', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = (await seedActiveDiver(db)).id!;
    await _open(tester, db);

    await _tap(tester, find.text('Ausrüstung hinzufügen'));
    expect(find.text('Ausrüstung hinzufügen'), findsWidgets); // page title

    await _tap(tester, find.byType(DropdownButtonFormField<EquipmentKind>));
    await _tap(tester, find.text('Jacket').last);
    await _tap(tester, find.text('Speichern'));
    expect(find.text('Bitte eine Bezeichnung eingeben.'), findsOneWidget);
    expect(await DriftEquipmentRepository(db).list(anna), isEmpty);

    await tester.enterText(_field('Bezeichnung'), 'Scubapro Hydros Pro');
    await tester.enterText(_field('Notiz'), 'Größe M');
    await _tap(tester, find.text('Standard'));
    await _tap(tester, find.text('Speichern'));

    expect(currentLocation(tester), SettingsScreen.path);
    final saved = (await DriftEquipmentRepository(db).list(anna)).single;
    expect(saved.name, 'Scubapro Hydros Pro');
    expect(saved.kind, EquipmentKind.bcd);
    expect(saved.notes, 'Größe M');
    expect(saved.isDefault, isTrue);
    expect(find.text('Scubapro Hydros Pro'), findsOneWidget);
  });

  testWidgets('T30.5 add: a kind must be chosen', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await _open(tester, db);

    await _tap(tester, find.text('Ausrüstung hinzufügen'));
    await tester.enterText(_field('Bezeichnung'), 'Irgendwas');
    await _tap(tester, find.text('Speichern'));
    expect(find.text('Bitte eine Art wählen.'), findsOneWidget);
  });

  testWidgets('T30.6 edit and delete; old dives keep the piece', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final anna = (await seedActiveDiver(db)).id!;
    final repo = DriftEquipmentRepository(db);
    final bcd = await repo.save(
      Equipment(
        diverId: anna,
        kind: EquipmentKind.bcd,
        name: 'Hydros Pro',
        isDefault: true,
      ),
    );
    final dive = await seedDive(db, exampleDive(anna));
    await _open(tester, db);

    await _tap(tester, find.text('Hydros Pro'));
    expect(find.text('Ausrüstung bearbeiten'), findsOneWidget);
    await tester.enterText(_field('Bezeichnung'), 'Scubapro Hydros Pro');
    await _tap(tester, find.text('Speichern'));
    expect(find.text('Scubapro Hydros Pro'), findsOneWidget);

    await _tap(tester, find.text('Scubapro Hydros Pro'));
    await _tap(tester, find.byTooltip('Menü anzeigen'));
    await _tap(tester, find.text('Löschen'));
    expect(
      find.text(
        'Scubapro Hydros Pro löschen? Bei bisherigen Tauchgängen bleibt es '
        'eingetragen.',
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text('Löschen').last);

    expect(currentLocation(tester), SettingsScreen.path);
    expect(find.text('Scubapro Hydros Pro'), findsNothing);
    expect(await repo.list(anna), isEmpty);
    expect((await DriftDiveRepository(db).findById(dive.id!))!.equipmentIds, [
      bcd.id,
    ]);

    router(tester).go(DiveDetailScreen.pathFor(dive.id!));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Scubapro Hydros Pro'), 200);
    expect(find.text('Scubapro Hydros Pro'), findsOneWidget);
  });
}
