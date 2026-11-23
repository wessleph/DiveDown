// T30.1-T30.3, T31.2: schema v2 with equipment and lead (ADR 0007).
import 'dart:io';

import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/data/local/drift_equipment_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/equipment/equipment.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_app.dart';

/// A database file in schema v1 with one diver and one dive.
File _v1File() {
  final dir = Directory.systemTemp.createTempSync('divedown_v1_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/logbook.sqlite');
  final raw = sqlite3.open(file.path);
  raw.execute(File('test/fixtures/db/schema_v1.sql').readAsStringSync());
  raw.execute('''
    INSERT INTO divers (id, created_at, updated_at, name, first_dive_number)
      VALUES ('anna', 0, 0, 'Anna', 1);
    INSERT INTO dives (id, created_at, updated_at, diver_id, dive_number,
        site_name, source, start_local, duration_s, max_depth_m)
      VALUES ('d1', 0, 0, 'anna', 7, 'Elphinstone', 'manual', 1763116920,
        2820, 18.4);
    PRAGMA user_version = 1;
  ''');
  raw.close();
  return file;
}

Equipment _item(
  String diverId,
  String name, {
  EquipmentKind kind = EquipmentKind.other,
  bool isDefault = false,
}) => Equipment(diverId: diverId, kind: kind, name: name, isDefault: isDefault);

void main() {
  group('T30.1 migration v1 → v2', () {
    test('keeps the dive, adds lead and the equipment tables', () async {
      final db = AppDatabase(NativeDatabase(_v1File()));
      addTearDown(db.close);

      final dive = await DriftDiveRepository(db).findById('d1');
      expect(dive, isNotNull);
      expect(dive!.number, 7);
      expect(dive.siteName, 'Elphinstone');
      expect(dive.weightKg, isNull);
      expect(dive.equipmentIds, isEmpty);

      final equipment = DriftEquipmentRepository(db);
      final bcd = await equipment.save(
        _item('anna', 'Hydros Pro', kind: EquipmentKind.bcd),
      );
      expect((await equipment.list('anna')).single.id, bcd.id);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 2);
    });
  });

  group('equipment repository', () {
    late AppDatabase db;
    late DriftEquipmentRepository equipment;
    late DriftDiveRepository dives;
    late String anna;

    setUp(() async {
      db = newTestDatabase();
      equipment = DriftEquipmentRepository(db);
      dives = DriftDiveRepository(db);
      anna = (await seedActiveDiver(db)).id!;
    });
    tearDown(() => db.close());

    test('T30.2 save, update, list by kind then name, delete hides', () async {
      final lamp = await equipment.save(
        _item(anna, 'Tovatec', kind: EquipmentKind.light),
      );
      await equipment.save(
        _item(anna, 'apeks XTX50', kind: EquipmentKind.regulator),
      );
      await equipment.save(_item(anna, 'Hydros Pro', kind: EquipmentKind.bcd));
      await equipment.save(_item(anna, 'Bare 5 mm', kind: EquipmentKind.suit));
      await equipment.save(
        _item(anna, 'Mares', kind: EquipmentKind.regulator),
      );
      expect(lamp.id, isNotNull);

      // Regulators by name ignoring case: apeks before Mares (with case,
      // „M“ would come first).
      expect(
        [for (final e in await equipment.list(anna)) e.name],
        ['Bare 5 mm', 'Hydros Pro', 'apeks XTX50', 'Mares', 'Tovatec'],
      );

      await equipment.save(
        lamp.copyWith(name: 'Tovatec Fusion', isDefault: true),
      );
      final updated = (await equipment.list(anna)).last;
      expect(updated.name, 'Tovatec Fusion');
      expect(updated.isDefault, isTrue);

      await equipment.delete(lamp.id!);
      expect([
        for (final e in await equipment.list(anna)) e.name,
      ], isNot(contains('Tovatec Fusion')));
    });

    test(
      'T30.3 a new dive gets the standard set, deleted pieces not',
      () async {
        final suit = await equipment.save(
          _item(anna, 'Bare', kind: EquipmentKind.suit, isDefault: true),
        );
        final bcd = await equipment.save(
          _item(anna, 'Hydros', kind: EquipmentKind.bcd, isDefault: true),
        );
        final old = await equipment.save(
          _item(anna, 'Alt', kind: EquipmentKind.bcd, isDefault: true),
        );
        await equipment.save(_item(anna, 'Lampe', kind: EquipmentKind.light));
        await equipment.delete(old.id!);

        final saved = (await dives.save(exampleDive(anna))).dive;
        final loaded = await dives.findById(saved.id!);
        expect(loaded!.equipmentIds, unorderedEquals([suit.id, bcd.id]));
      },
    );

    test('T30.3 an explicit selection is stored exactly, also empty', () async {
      await equipment.save(_item(anna, 'Bare', isDefault: true));
      final lamp = await equipment.save(_item(anna, 'Lampe'));

      final a = (await dives.save(
        exampleDive(anna, number: 1).copyWith(equipmentIds: [lamp.id!]),
      )).dive;
      final b = (await dives.save(
        exampleDive(anna, number: 2).copyWith(equipmentIds: const []),
      )).dive;

      expect((await dives.findById(a.id!))!.equipmentIds, [lamp.id]);
      expect((await dives.findById(b.id!))!.equipmentIds, isEmpty);
    });

    test('T30.3 updating without a selection keeps the links; a later '
        'standard piece is not added', () async {
      final suit = await equipment.save(_item(anna, 'Bare', isDefault: true));
      final saved = (await dives.save(exampleDive(anna))).dive;
      await equipment.save(_item(anna, 'Neu', isDefault: true));

      // As the import does when it replaces a dive (same id, new content).
      final replaced = (await dives.findById(saved.id!))!;
      await dives.save(
        Dive(
          id: replaced.id,
          diverId: anna,
          number: replaced.number,
          source: replaced.source,
          sourceId: replaced.sourceId,
          start: replaced.start,
          durationS: 3000,
          maxDepthM: 19,
        ),
      );

      expect((await dives.findById(saved.id!))!.equipmentIds, [suit.id]);
    });

    test('T30.3 forDive keeps deleted pieces of old dives', () async {
      final suit = await equipment.save(
        _item(anna, 'Bare', kind: EquipmentKind.suit, isDefault: true),
      );
      final saved = (await dives.save(exampleDive(anna))).dive;
      await equipment.delete(suit.id!);

      final used = await equipment.forDive(saved.id!);
      expect(used.single.name, 'Bare');
      expect(used.single.deleted, isTrue);
    });

    test('lead is stored with the dive', () async {
      final saved = (await dives.save(
        exampleDive(anna).copyWith(weightKg: 6.5),
      )).dive;
      expect((await dives.findById(saved.id!))!.weightKg, 6.5);
    });

    group('T31.2 lastWeightAt', () {
      Future<Dive> dive(
        int number,
        DateTime start, {
        String? site,
        String? catalogueId,
        double? kg,
      }) async => (await dives.save(
        Dive(
          diverId: anna,
          number: number,
          siteName: site,
          siteCatalogueId: catalogueId,
          source: DiveSource.manual,
          start: start,
          durationS: 2400,
          maxDepthM: 20,
          weightKg: kg,
        ),
      )).dive;

      test('newest dive at the same name, ignoring case and spaces', () async {
        await dive(1, DateTime.utc(2026, 3, 1), site: 'Elphinstone', kg: 5);
        await dive(2, DateTime.utc(2026, 3, 5), site: ' elphinstone ', kg: 6);
        await dive(3, DateTime.utc(2026, 3, 9), site: 'Elphinstone');
        await dive(4, DateTime.utc(2026, 3, 10), site: 'Daedalus', kg: 8);

        final last = await dives.lastWeightAt(anna, siteName: 'ELPHINSTONE');
        expect(last?.weightKg, 6);
        expect(last?.siteName, ' elphinstone '.trim());
      });

      test('the same catalogue id counts even with another name', () async {
        await dive(
          1,
          DateTime.utc(2026, 3, 1),
          site: 'Elphinstone Reef',
          catalogueId: 'osm:42',
          kg: 7,
        );
        final last = await dives.lastWeightAt(
          anna,
          siteName: 'Elphinstone',
          siteCatalogueId: 'osm:42',
        );
        expect(last?.weightKg, 7);
        expect(last?.siteName, 'Elphinstone Reef');
      });

      test('ignores the edited dive and deleted dives', () async {
        final a = await dive(
          1,
          DateTime.utc(2026, 3, 1),
          site: 'Walensee',
          kg: 10,
        );
        final b = await dive(
          2,
          DateTime.utc(2026, 3, 5),
          site: 'Walensee',
          kg: 12,
        );
        final c = await dive(
          3,
          DateTime.utc(2026, 3, 9),
          site: 'Walensee',
          kg: 14,
        );
        await dives.delete(c.id!);

        expect(
          (await dives.lastWeightAt(
            anna,
            siteName: 'Walensee',
            excludeDiveId: b.id,
          ))?.weightKg,
          10,
        );
        expect(a.id, isNotNull);
      });

      test('null without site or without an earlier dive with lead', () async {
        await dive(1, DateTime.utc(2026, 3, 1), site: 'Walensee');
        expect(await dives.lastWeightAt(anna, siteName: 'Walensee'), isNull);
        expect(await dives.lastWeightAt(anna, siteName: 'Quinten'), isNull);
        expect(await dives.lastWeightAt(anna), isNull);
      });
    });
  });
}
