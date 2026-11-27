// T8.1-T8.6: dive log storage (tasks.md, ADR 0004).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/dive_repository.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Dive _dive(
  String diverId, {
  int? number,
  int sampleCount = 0,
  DateTime? start,
  String? siteName,
}) {
  return Dive(
    diverId: diverId,
    number: number,
    siteName: siteName,
    source: DiveSource.manual,
    start: start ?? DateTime.utc(2026, 11, 14, 10, 42),
    durationS: 2820,
    maxDepthM: 18.4,
    samples: [
      for (var i = 0; i < sampleCount; i++)
        DiveSample(timeS: i * 2, depthM: (i % 300) / 16.3),
    ],
  );
}

/// A dive with every field set, for the round trip.
Dive _fullDive(String diverId) {
  return Dive(
    diverId: diverId,
    number: 42,
    siteName: 'SS Thistlegorm',
    siteCatalogueId: 'osm_123',
    siteLat: 27.81361,
    siteLon: 33.92139,
    source: DiveSource.diveComputer,
    sourceId: 'eon-core-3F7A-2026-11-14T10:42',
    start: DateTime.utc(2026, 11, 14, 10, 42, 7),
    utcOffsetS: 7200,
    durationS: 3600,
    maxDepthM: 29.87,
    avgDepthM: 17.123456,
    minTemperatureC: 23.4,
    maxTemperatureC: 26.1,
    waterType: WaterType.salt,
    notes: 'Strömung von Nord, „Motorräder“ im Laderaum.',
    rating: 5,
    tanks: const [
      DiveTank(
        index: 0,
        volumeL: 12,
        startPressureBar: 200,
        endPressureBar: 50,
        gas: GasMix(o2: 0.32),
      ),
      DiveTank(index: 1, volumeL: 7, gas: GasMix(o2: 0.21, he: 0.35)),
    ],
    events: const [
      DiveEvent(timeS: 600, type: 'gaschange', value: '1'),
      DiveEvent(timeS: 3300, type: 'ascent'),
    ],
    samples: [
      for (var i = 0; i < 1800; i++)
        DiveSample(
          timeS: i * 2,
          depthM: 29.87 * (i < 900 ? i / 900 : (1800 - i) / 900) + 0.0000001,
          temperatureC: 26.1 - i / 1000,
          pressures: [
            TankPressure(tankIndex: 0, pressureBar: 200 - i / 12),
            if (i.isEven) TankPressure(tankIndex: 1, pressureBar: 180 - i / 20),
          ],
          heartRate: i.isEven ? 70 + i % 30 : null,
          ndlS: i < 1500 ? 3000 - i : null,
          decoCeilingM: i >= 1500 ? 3.0 : null,
          decoTimeS: i >= 1500 ? 120 : null,
          gasIndex: i < 300 ? 0 : 1,
        ),
    ],
  );
}

void _expectSameDive(Dive actual, Dive expected) {
  const eps = 1e-6;
  expect(actual.diverId, expected.diverId);
  expect(actual.number, expected.number);
  expect(actual.siteName, expected.siteName);
  expect(actual.siteCatalogueId, expected.siteCatalogueId);
  expect(actual.siteLat, closeTo(expected.siteLat!, eps));
  expect(actual.siteLon, closeTo(expected.siteLon!, eps));
  expect(actual.source, expected.source);
  expect(actual.sourceId, expected.sourceId);
  expect(actual.start, expected.start);
  expect(actual.utcOffsetS, expected.utcOffsetS);
  expect(actual.durationS, expected.durationS);
  expect(actual.maxDepthM, closeTo(expected.maxDepthM, eps));
  expect(actual.avgDepthM, closeTo(expected.avgDepthM!, eps));
  expect(actual.minTemperatureC, closeTo(expected.minTemperatureC!, eps));
  expect(actual.maxTemperatureC, closeTo(expected.maxTemperatureC!, eps));
  expect(actual.waterType, expected.waterType);
  expect(actual.notes, expected.notes);
  expect(actual.rating, expected.rating);

  expect(actual.tanks, hasLength(expected.tanks.length));
  for (var i = 0; i < expected.tanks.length; i++) {
    final a = actual.tanks[i], e = expected.tanks[i];
    expect(a.index, e.index);
    expect(a.volumeL, e.volumeL);
    expect(a.startPressureBar, e.startPressureBar);
    expect(a.endPressureBar, e.endPressureBar);
    expect(a.gas?.o2, e.gas?.o2);
    expect(a.gas?.he, e.gas?.he);
  }

  expect(actual.events.map((e) => (e.timeS, e.type, e.value)).toList(), [
    for (final e in expected.events) (e.timeS, e.type, e.value),
  ]);

  expect(actual.samples, hasLength(expected.samples.length));
  for (var i = 0; i < expected.samples.length; i++) {
    final a = actual.samples[i], e = expected.samples[i];
    expect(a.timeS, e.timeS, reason: 'sample $i');
    expect(a.depthM, closeTo(e.depthM, eps), reason: 'sample $i');
    expect(a.temperatureC, closeTo(e.temperatureC!, eps), reason: 'sample $i');
    expect(a.heartRate, e.heartRate, reason: 'sample $i');
    expect(a.ndlS, e.ndlS, reason: 'sample $i');
    expect(a.decoCeilingM, e.decoCeilingM, reason: 'sample $i');
    expect(a.decoTimeS, e.decoTimeS, reason: 'sample $i');
    expect(a.gasIndex, e.gasIndex, reason: 'sample $i');
    expect(
      a.pressures.map((p) => p.tankIndex).toList(),
      e.pressures.map((p) => p.tankIndex).toList(),
      reason: 'sample $i',
    );
    for (var j = 0; j < e.pressures.length; j++) {
      expect(
        a.pressures[j].pressureBar,
        closeTo(e.pressures[j].pressureBar, eps),
        reason: 'sample $i, tank $j',
      );
    }
  }
}

void main() {
  late AppDatabase db;
  late DiverRepository divers;
  late DiveRepository dives;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    divers = DriftDiverRepository(db);
    dives = DriftDiveRepository(db);
  });

  tearDown(() => db.close());

  test('T8.1 a dive with 1,800 samples survives a round trip', () async {
    final diver = await divers.create(const Diver(name: 'Anna'));
    final dive = _fullDive(diver.id!);

    final saved = await dives.save(dive);
    final loaded = await dives.findById(saved.dive.id!);

    expect(loaded, isNotNull);
    _expectSameDive(loaded!, dive);
  });

  test('T8.2 a deleted dive leaves the list and can be restored', () async {
    final diver = await divers.create(const Diver(name: 'Anna'));
    final saved = await dives.save(_dive(diver.id!));
    final id = saved.dive.id!;

    await dives.delete(id);
    expect(await dives.listForDiver(diver.id!), isEmpty);

    await dives.restore(id);
    final listed = await dives.listForDiver(diver.id!);
    expect(listed.map((d) => d.id), [id]);
  });

  test('T39.8 the list for the statistics has the tanks, no samples', () async {
    final diver = await divers.create(const Diver(name: 'Anna'));
    final a = await dives.save(_fullDive(diver.id!));
    final gone = await dives.save(_dive(diver.id!));
    await dives.delete(gone.dive.id!);

    final listed = await dives.listWithTanksForDiver(diver.id!);

    expect(listed.map((d) => d.id), [a.dive.id]);
    final original = _fullDive(diver.id!).tanks;
    final tanks = listed.single.tanks;
    expect(tanks.map((t) => t.index), original.map((t) => t.index));
    for (final (i, t) in tanks.indexed) {
      expect(t.volumeL, original[i].volumeL);
      expect(t.startPressureBar, original[i].startPressureBar);
      expect(t.endPressureBar, original[i].endPressureBar);
    }
    expect(listed.single.samples, isEmpty);
  });

  test('T8.3 new records get UUID v4 ids, never autoincrement', () async {
    final diver = await divers.create(const Diver(name: 'Anna'));
    final first = await dives.save(_dive(diver.id!));
    final second = await dives.save(_dive(diver.id!));

    expect(diver.id, matches(_uuidV4));
    expect(first.dive.id, matches(_uuidV4));
    expect(second.dive.id, matches(_uuidV4));
    expect(first.dive.id, isNot(second.dive.id));
  });

  test('T8.5 numbering starts at first_dive_number', () async {
    final diver = await divers.create(
      const Diver(name: 'Bruder', firstDiveNumber: 101),
    );

    final a = await dives.save(_dive(diver.id!));
    final b = await dives.save(
      _dive(diver.id!, start: DateTime.utc(2026, 11, 15, 9)),
    );

    expect(a.dive.number, 101);
    expect(b.dive.number, 102);
  });

  test('T8.6 a duplicate number is saved with a warning', () async {
    final diver = await divers.create(const Diver(name: 'Anna'));
    for (var n = 1; n <= 5; n++) {
      final r = await dives.save(_dive(diver.id!, number: n));
      expect(r.warnings, isEmpty, reason: 'dive #$n is unique');
    }

    final dup = await dives.save(_dive(diver.id!, number: 3));

    expect(dup.dive.number, 3);
    expect(dup.warnings, {DiveWarning.duplicateNumber});
    expect(await dives.listForDiver(diver.id!), hasLength(6));
  });

  test('T8.6 numbers are counted per diver', () async {
    final anna = await divers.create(const Diver(name: 'Anna'));
    final ben = await divers.create(const Diver(name: 'Ben'));
    await dives.save(_dive(anna.id!, number: 1));

    final r = await dives.save(_dive(ben.id!, number: 1));

    expect(r.warnings, isEmpty);
  });

  // T8.4 (migration v1 -> v2) is written together with schema v2; there is
  // no v2 yet. See tasks.md.
}
