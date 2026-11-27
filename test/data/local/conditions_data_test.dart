// T40.1-T40.4: visibility, current and kinds of dive in the database.
import 'dart:io';

import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/import_service.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_app.dart';

/// A database file in schema v2 with one diver and one dive.
File _v2File() {
  final dir = Directory.systemTemp.createTempSync('divedown_v2_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/logbook.sqlite');
  final raw = sqlite3.open(file.path);
  raw.execute(File('test/fixtures/db/schema_v2.sql').readAsStringSync());
  raw.execute('''
    INSERT INTO divers (id, created_at, updated_at, name, first_dive_number)
      VALUES ('anna', 0, 0, 'Anna', 1);
    INSERT INTO dives (id, created_at, updated_at, diver_id, dive_number,
        site_name, source, start_local, duration_s, max_depth_m, weight_kg)
      VALUES ('d1', 0, 0, 'anna', 7, 'Elphinstone', 'manual', 1763116920,
        2820, 18.4, 6);
    PRAGMA user_version = 2;
  ''');
  raw.close();
  return file;
}

Dive _at(
  String diver,
  int number,
  DateTime start, {
  String? site = 'Elphinstone',
  String? catalogueId,
  WaterVisibility? visibility,
  WaterCurrent? current,
  Set<DiveKind> kinds = const {},
}) => Dive(
  diverId: diver,
  number: number,
  siteName: site,
  siteCatalogueId: catalogueId,
  source: DiveSource.manual,
  start: start,
  durationS: 2820,
  maxDepthM: 18,
  visibility: visibility,
  current: current,
  kinds: kinds,
);

void main() {
  test(
    'T40.1 migration v2 → v3 keeps the dive; conditions can be saved',
    () async {
      final db = AppDatabase(NativeDatabase(_v2File()));
      addTearDown(db.close);
      final repo = DriftDiveRepository(db);

      final dive = (await repo.findById('d1'))!;
      expect(dive.number, 7);
      expect(dive.weightKg, 6);
      expect(dive.visibility, isNull);
      expect(dive.current, isNull);
      expect(dive.kinds, isEmpty);

      await repo.save(
        dive.copyWith(visibility: WaterVisibility.good, kinds: {DiveKind.reef}),
      );
      final again = (await repo.findById('d1'))!;
      expect(again.visibility, WaterVisibility.good);
      expect(again.kinds, {DiveKind.reef});
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 3);
    },
  );

  group('with an empty database', () {
    late AppDatabase db;
    late DriftDiveRepository repo;
    late String anna;

    setUp(() async {
      db = newTestDatabase();
      repo = DriftDiveRepository(db);
      anna = (await seedActiveDiver(db)).id!;
    });
    tearDown(() => db.close());

    test('T40.2 saved and loaded, also in the list; cleared again', () async {
      final saved = (await repo.save(
        _at(
          anna,
          1,
          DateTime.utc(2026, 3, 1, 10),
          visibility: WaterVisibility.excellent,
          current: WaterCurrent.strong,
          kinds: {DiveKind.wreck, DiveKind.night},
        ),
      )).dive;

      final loaded = (await repo.findById(saved.id!))!;
      expect(loaded.visibility, WaterVisibility.excellent);
      expect(loaded.current, WaterCurrent.strong);
      expect(loaded.kinds, {DiveKind.wreck, DiveKind.night});
      final listed = (await repo.listForDiver(anna)).single;
      expect(listed.kinds, {DiveKind.wreck, DiveKind.night});

      await repo.save(
        Dive(
          id: saved.id,
          diverId: anna,
          number: 1,
          source: DiveSource.manual,
          start: saved.start,
          durationS: 2820,
          maxDepthM: 18,
        ),
      );
      final cleared = (await repo.findById(saved.id!))!;
      expect(cleared.visibility, isNull);
      expect(cleared.current, isNull);
      expect(cleared.kinds, isEmpty);
    });

    test(
      'T40.3 an import that replaces the dive keeps the conditions',
      () async {
        ImportedDive imported(double depth) => ImportedDive(
          source: DiveSource.diveComputer,
          sourceId: 'eon-1',
          start: DateTime.utc(2026, 3, 1, 10),
          durationS: 2820,
          maxDepthM: depth,
        );
        final service = ImportService(repo);
        final first = await service.importDives(anna, [imported(18)]);
        final id = (first.single as Saved).saved.id!;
        final dive = (await repo.findById(id))!;
        await repo.save(
          dive.copyWith(
            visibility: WaterVisibility.good,
            current: WaterCurrent.light,
            kinds: {DiveKind.reef},
          ),
        );

        // Same id, other data: replaced after confirmation.
        await service.importDives(anna, [imported(19)], confirmed: {0});

        final replaced = (await repo.findById(id))!;
        expect(replaced.maxDepthM, 19);
        expect(replaced.visibility, WaterVisibility.good);
        expect(replaced.current, WaterCurrent.light);
        expect(replaced.kinds, {DiveKind.reef});
      },
    );

    test('T40.4 last conditions at the site: newest with any, by name or '
        'catalogue id; excluded and deleted dives do not count', () async {
      await repo.save(
        _at(
          anna,
          1,
          DateTime.utc(2026, 3, 1, 10),
          visibility: WaterVisibility.moderate,
          kinds: {DiveKind.reef},
        ),
      );
      final newest = (await repo.save(
        _at(
          anna,
          2,
          DateTime.utc(2026, 3, 2, 10),
          site: ' elphinstone ',
          catalogueId: 'osm-1',
          current: WaterCurrent.light,
          kinds: {DiveKind.reef, DiveKind.drift},
        ),
      )).dive;
      // Newer, but without conditions.
      await repo.save(_at(anna, 3, DateTime.utc(2026, 3, 3, 10)));
      final gone = (await repo.save(
        _at(
          anna,
          4,
          DateTime.utc(2026, 3, 4, 10),
          visibility: WaterVisibility.poor,
        ),
      )).dive;
      await repo.delete(gone.id!);

      final last = await repo.lastConditionsAt(anna, siteName: 'Elphinstone');
      expect(last?.siteName, 'elphinstone');
      expect(last?.visibility, isNull);
      expect(last?.current, WaterCurrent.light);
      expect(last?.kinds, {DiveKind.reef, DiveKind.drift});

      final byCatalogue = await repo.lastConditionsAt(
        anna,
        siteCatalogueId: 'osm-1',
      );
      expect(byCatalogue?.current, WaterCurrent.light);

      final without = await repo.lastConditionsAt(
        anna,
        siteName: 'Elphinstone',
        excludeDiveId: newest.id,
      );
      expect(without?.visibility, WaterVisibility.moderate);

      expect(await repo.lastConditionsAt(anna, siteName: 'Daedalus'), isNull);
      expect(await repo.lastConditionsAt(anna), isNull);
    });
  });
}
