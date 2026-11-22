// T15.23-T15.25: queries the logbook needs (tasks.md, ui-spec §5.1, §5.4).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_app_settings.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive(String diverId, {int? number}) => Dive(
  diverId: diverId,
  number: number,
  source: DiveSource.manual,
  start: DateTime.utc(2026, 11, 14, 10, 42),
  durationS: 2820,
  maxDepthM: 18.4,
);

void main() {
  late AppDatabase db;
  late DriftDiverRepository divers;
  late DriftDiveRepository dives;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    divers = DriftDiverRepository(db);
    dives = DriftDiveRepository(db);
  });

  tearDown(() => db.close());

  group('T15.23 nextNumber', () {
    test('without dives it is first_dive_number', () async {
      final anna = await divers.create(
        const Diver(name: 'Anna', firstDiveNumber: 101),
      );
      expect(await dives.nextNumber(anna.id!), 101);
    });

    test('after #1-#5 it is 6, and save gives the same number', () async {
      final anna = await divers.create(const Diver(name: 'Anna'));
      for (var i = 0; i < 5; i++) {
        await dives.save(_dive(anna.id!));
      }
      expect(await dives.nextNumber(anna.id!), 6);
      final saved = await dives.save(_dive(anna.id!));
      expect(saved.dive.number, 6);
    });

    test('counts per diver and ignores deleted dives', () async {
      final anna = await divers.create(const Diver(name: 'Anna'));
      final ben = await divers.create(const Diver(name: 'Ben'));
      await dives.save(_dive(anna.id!, number: 7));
      final last = await dives.save(_dive(anna.id!, number: 8));
      await dives.delete(last.dive.id!);

      expect(await dives.nextNumber(anna.id!), 8);
      expect(await dives.nextNumber(ben.id!), 1);
    });
  });

  test('T15.24 list returns all divers in creation order', () async {
    expect(await divers.list(), isEmpty);
    await divers.create(const Diver(name: 'Anna'));
    await divers.create(const Diver(name: 'Ben'));
    expect((await divers.list()).map((d) => d.name), ['Anna', 'Ben']);
  });

  test('T15.25 active diver: null at first, then stored', () async {
    final settings = DriftAppSettings(db);
    expect(await settings.activeDiverId(), isNull);

    final anna = await divers.create(const Diver(name: 'Anna'));
    await settings.setActiveDiverId(anna.id!);
    expect(await settings.activeDiverId(), anna.id);

    // A fresh instance reads it from the database, not from memory.
    expect(await DriftAppSettings(db).activeDiverId(), anna.id);
  });

  test('T21.14 the list carries the depth profile for the sparkline', () async {
    final anna = await divers.create(const Diver(name: 'Anna'));
    await dives.save(
      _dive(anna.id!).copyWith(
        samples: [
          for (var t = 0; t <= 600; t += 60)
            DiveSample(timeS: t, depthM: t / 60, temperatureC: 21),
        ],
      ),
    );
    await dives.save(_dive(anna.id!)); // manual, no samples

    final listed = await dives.listForDiver(anna.id!);
    final withProfile = listed.firstWhere((d) => d.samples.isNotEmpty);
    expect(withProfile.samples.map((s) => s.timeS), [
      for (var t = 0; t <= 600; t += 60) t,
    ]);
    expect(withProfile.samples.last.depthM, 10);
    expect(listed.where((d) => d.samples.isEmpty), hasLength(1));
  });
}
