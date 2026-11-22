// T23.6-T23.12: Einstellungen with one diver (ui-spec §5.11, 2026-11-22).
import 'package:divedown/app/providers.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/local/drift_dive_computer_repository.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/dive_computer_registry.dart';
import 'package:divedown/domain/settings/app_settings.dart';
import 'package:divedown/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

const _info = AppInfo(version: '1.0.0', build: '42', libdivecomputer: '0.9.0');

Future<void> _open(
  WidgetTester tester,
  AppDatabase db, {
  List<Uri>? opened,
}) async {
  await pumpTestApp(
    tester,
    db: db,
    size: const Size(400, 1600),
    location: SettingsScreen.path,
    overrides: [
      appInfoProvider.overrideWith((ref) async => _info),
      urlOpenerProvider.overrideWithValue((uri) async => opened?.add(uri)),
    ],
  );
}

Dive _dive(String diverId, int number, DateTime start) =>
    exampleDive(diverId, number: number, start: start);

void main() {
  testWidgets('T23.6 groups: Taucher, Geräte, Darstellung, Über DiveDown', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await _open(tester, db);

    expect(find.text('TAUCHER'), findsOneWidget);
    expect(find.text('GERÄTE'), findsOneWidget);
    expect(find.text('DARSTELLUNG'), findsOneWidget);
    expect(find.text('ÜBER DIVEDOWN'), findsOneWidget);
    // Not in v1.0 resp. not yet (ui-spec §5.11).
    expect(find.textContaining('Einheiten'), findsNothing);
    // „Logbuch sichern“ arrived with T11 (backup_test.dart).
    expect(find.textContaining('hinzufügen'), findsNothing);
  });

  group('T23.7 rename the diver', () {
    testWidgets('saves the new name', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await _open(tester, db);

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      expect(find.text('Name ändern'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Lena');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Lena'), findsOneWidget);
      final stored = await DriftDiverRepository(db).findById(anna.id!);
      expect(stored!.name, 'Lena');
    });

    testWidgets('an empty name cannot be saved', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await _open(tester, db);

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  ');
      await tester.pump();

      expect(find.text('Bitte gib einen Namen ein.'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Speichern'),
      );
      expect(save.onPressed, isNull);
    });
  });

  group('T23.8 start number', () {
    testWidgets('without dives it is set right away', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await _open(tester, db);

      await tester.tap(find.text('Nummerierung beginnt bei'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '101');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
      expect(find.textContaining('Nummern verschieben'), findsNothing);
      expect(await DriftDiveRepository(db).nextNumber(anna.id!), 101);
    });

    testWidgets('with dives it asks, then shifts every number', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, _dive(anna.id!, 1, DateTime.utc(2026, 3, 1)));
      await seedDive(db, _dive(anna.id!, 2, DateTime.utc(2026, 5, 1)));
      await _open(tester, db);

      await tester.tap(find.text('Nummerierung beginnt bei'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '101');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Nummern verschieben?'), findsOneWidget);
      expect(find.text('Aus #1–#2 werden #101–#102.'), findsOneWidget);
      await tester.tap(find.text('Verschieben'));
      await tester.pumpAndSettle();

      final numbers = [
        for (final d in await DriftDiveRepository(db).listForDiver(anna.id!))
          d.number,
      ];
      expect(numbers, [102, 101]); // newest first
      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('cancel keeps numbers and start number', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, _dive(anna.id!, 1, DateTime.utc(2026, 3, 1)));
      await _open(tester, db);

      await tester.tap(find.text('Nummerierung beginnt bei'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '101');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      final list = await DriftDiveRepository(db).listForDiver(anna.id!);
      expect(list.single.number, 1);
      expect(
        (await DriftDiverRepository(db).findById(anna.id!))!.firstDiveNumber,
        1,
      );
    });
  });

  group('T23.9 renumber by date', () {
    testWidgets('offered when out of order, renumbers after asking', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, _dive(anna.id!, 1, DateTime.utc(2026, 11, 13)));
      await seedDive(db, _dive(anna.id!, 2, DateTime.utc(2026, 3, 26)));
      await _open(tester, db);

      await tester.tap(find.text('Nummern nach Datum neu vergeben'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Alle Tauchgänge nach Datum neu nummerieren? '
          'Der älteste bekommt #1.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Neu nummerieren'));
      await tester.pumpAndSettle();

      expect(find.text('2 Tauchgänge neu nummeriert'), findsOneWidget);
      final list = await DriftDiveRepository(db).listForDiver(anna.id!);
      expect([for (final d in list) d.number], [2, 1]); // Nov #2, Mar #1
      expect(find.text('Nummern nach Datum neu vergeben'), findsNothing);
    });

    testWidgets('hidden when the numbers already follow the dates', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      await seedDive(db, _dive(anna.id!, 1, DateTime.utc(2026, 3, 26)));
      await seedDive(db, _dive(anna.id!, 2, DateTime.utc(2026, 11, 13)));
      await _open(tester, db);

      expect(find.text('Nummern nach Datum neu vergeben'), findsNothing);
    });
  });

  group('T23.10 dive computers', () {
    testWidgets('listed with short id and last dive, can be forgotten', (
      tester,
    ) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      final anna = await seedActiveDiver(db);
      final eon = await DriftDiveComputerRepository(db).create(
        const KnownDiveComputer(
          id: '',
          vendor: 'Suunto',
          product: 'EON Core',
          address: 'D4:22:CD:00:3F:7A',
        ),
      );
      final dive = await seedDive(
        db,
        _dive(
          anna.id!,
          1,
          DateTime.utc(2026, 11, 13, 7, 54),
        ).copyWith(diveComputerId: eon.id),
      );
      await _open(tester, db);

      expect(find.text('Suunto EON Core ••3F7A'), findsOneWidget);
      expect(find.text('Zuletzt: 13.11.2026'), findsOneWidget);

      await tester.tap(find.byTooltip('EON Core vergessen'));
      await tester.pumpAndSettle();
      expect(find.text('EON Core vergessen?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Vergessen'));
      await tester.pumpAndSettle();

      expect(find.text('Noch kein Tauchcomputer verbunden.'), findsOneWidget);
      expect(await DriftDiveRepository(db).findById(dive.id!), isNotNull);
    });

    testWidgets('without dives from it', (tester) async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedActiveDiver(db);
      await DriftDiveComputerRepository(db).create(
        const KnownDiveComputer(id: '', vendor: 'Suunto', product: 'EON Core'),
      );
      await _open(tester, db);

      expect(find.text('Suunto EON Core'), findsOneWidget);
      expect(find.text('Noch keine Tauchgänge'), findsOneWidget);
    });
  });

  testWidgets('T23.11 Darstellung switches the theme and remembers it', (
    tester,
  ) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    await _open(tester, db);

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    await tester.tap(find.text('Dunkel'));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.dark);
    expect(await DriftAppSettings(db).themeMode(), AppThemeMode.dark);

    await tester.tap(find.text('Hell'));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
  });

  testWidgets('T23.12 Über DiveDown: version, licence, links', (tester) async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await seedActiveDiver(db);
    final opened = <Uri>[];
    await _open(tester, db, opened: opened);

    expect(find.text('Version 1.0.0 (Build 42)'), findsOneWidget);
    expect(find.text('libdivecomputer 0.9.0'), findsOneWidget);
    expect(find.text('Lizenz: GPL-3.0-or-later'), findsOneWidget);
    expect(find.text('Open-Source-Lizenzen'), findsOneWidget);

    await tester.tap(find.text('Datenschutzerklärung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quellcode'));
    await tester.pumpAndSettle();
    expect(opened, [
      Uri.parse('https://wessleph.github.io/DiveDown/datenschutz/'),
      Uri.parse('https://github.com/wessleph/DiveDown'),
    ]);
  });
}
