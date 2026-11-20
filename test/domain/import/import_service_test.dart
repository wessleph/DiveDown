// T2.1-T2.9: duplicate detection and saving (ADR 0003, security A2).
import 'package:clock/clock.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/dive_repository.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:divedown/domain/import/import_service.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:divedown/domain/import/plausibility.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime.utc(2026, 11, 14, 10, 42);

ImportedDive _imported({
  String sourceId = 'EON Core:5576006a',
  DateTime? start,
  double maxDepthM = 18.4,
  int durationS = 2820,
  DiveSource source = DiveSource.diveComputer,
}) => ImportedDive(
  source: source,
  sourceId: sourceId,
  start: start ?? _start,
  durationS: durationS,
  maxDepthM: maxDepthM,
  avgDepthM: 10,
  minTemperatureC: 21,
  samples: const [
    DiveSample(timeS: 0, depthM: 0),
    DiveSample(timeS: 60, depthM: 10, temperatureC: 21),
  ],
  tanks: const [DiveTank(index: 0, volumeL: 12, gas: GasMix(o2: 0.32))],
  events: const [DiveEvent(timeS: 60, type: 'safetystop')],
);

/// Fails the save of dives whose max depth is [failDepth] (T2.8).
class _FailingRepository implements DiveRepository {
  _FailingRepository(this._inner, this.failDepth);

  final DiveRepository _inner;
  final double failDepth;

  @override
  Future<SaveDiveResult> save(Dive dive) => dive.maxDepthM == failDepth
      ? Future.error(StateError('disk I/O error'))
      : _inner.save(dive);

  @override
  Future<Dive?> findById(String id) => _inner.findById(id);
  @override
  Future<List<Dive>> listForDiver(String diverId) =>
      _inner.listForDiver(diverId);
  @override
  Future<int> nextNumber(String diverId) => _inner.nextNumber(diverId);
  @override
  Future<void> delete(String id) => _inner.delete(id);
  @override
  Future<void> restore(String id) => _inner.restore(id);
  @override
  Future<Dive?> findBySource(
    String diverId,
    DiveSource source,
    String sourceId,
  ) => _inner.findBySource(diverId, source, sourceId);
  @override
  Future<List<Dive>> listStartingBetween(
    String diverId,
    DateTime from,
    DateTime to,
  ) => _inner.listStartingBetween(diverId, from, to);
}

void main() {
  late AppDatabase db;
  late DriftDiveRepository dives;
  late ImportService service;
  late String anna;
  late String ben;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dives = DriftDiveRepository(db);
    service = ImportService(dives);
    final divers = DriftDiverRepository(db);
    anna = (await divers.create(const Diver(name: 'Anna'))).id!;
    ben = (await divers.create(const Diver(name: 'Ben'))).id!;
  });

  tearDown(() => db.close());

  Future<List<ImportResult>> import(
    List<ImportedDive> list, {
    String? diver,
    Set<int> confirmed = const {},
  }) => withClock(
    Clock.fixed(DateTime.utc(2026, 11, 20)),
    () => service.importDives(diver ?? anna, list, confirmed: confirmed),
  );

  test('T2.1 empty logbook: the dive is saved with all its data', () async {
    final results = await import([_imported()]);

    final saved = (results.single as Saved).saved;
    final stored = await dives.findById(saved.id!);
    expect(stored!.source, DiveSource.diveComputer);
    expect(stored.sourceId, 'EON Core:5576006a');
    expect(stored.maxDepthM, 18.4);
    expect(stored.samples, hasLength(2));
    expect(stored.tanks.single.gas!.o2, 0.32);
    expect(stored.events.single.type, 'safetystop');
    expect(stored.number, 1);
  });

  test('T2.2 same source, id and content again: skipped', () async {
    final first = (await import([_imported()])).single as Saved;
    final again = await import([_imported()]);

    expect(again.single, isA<SkippedDuplicate>());
    expect((again.single as SkippedDuplicate).existingId, first.saved.id);
    expect(await dives.listForDiver(anna), hasLength(1));
  });

  test('T2.2 the preview marks the duplicate without saving', () async {
    await import([_imported()]);
    final preview = await service.preview(anna, [
      _imported(),
      _imported(sourceId: 'EON Core:8da7f66a', start: DateTime.utc(2026, 6, 1)),
    ]);

    expect(preview[0], isA<SkippedDuplicate>());
    expect(preview[1], isA<Saved>(), reason: 'would be saved');
    expect(await dives.listForDiver(anna), hasLength(1));
  });

  test('T2.3 same id, other max depth: needs confirmation', () async {
    final first = (await import([_imported()])).single as Saved;
    final results = await import([_imported(maxDepthM: 19.9)]);

    final r = results.single as NeedsConfirmation;
    expect(r.reason, ConfirmReason.sameIdDifferentContent);
    expect(r.possibleMatchId, first.saved.id);
    expect(await dives.listForDiver(anna), hasLength(1));
  });

  test('T2.4 other id, start +90 s and depth +0,3 m: similar', () async {
    await import([_imported(source: DiveSource.fit, sourceId: 'fit-1')]);
    final results = await import([
      _imported(
        start: _start.add(const Duration(seconds: 90)),
        maxDepthM: 18.7,
      ),
    ]);

    expect((results.single as NeedsConfirmation).reason, ConfirmReason.similar);
  });

  test('T2.4 a confirmed dive is saved anyway', () async {
    await import([_imported(source: DiveSource.fit, sourceId: 'fit-1')]);
    final results = await import(
      [_imported(start: _start.add(const Duration(seconds: 90)))],
      confirmed: {0},
    );

    expect(results.single, isA<Saved>());
    expect(await dives.listForDiver(anna), hasLength(2));
  });

  test('T2.5 start +3 min: outside ±2 min, saved', () async {
    await import([_imported(sourceId: 'EON Core:1')]);
    final results = await import([
      _imported(
        sourceId: 'EON Core:2',
        start: _start.add(const Duration(minutes: 3)),
      ),
    ]);

    expect(results.single, isA<Saved>());
  });

  test('T2.5 same start, depth 1 m deeper: outside ±0,5 m, saved', () async {
    await import([_imported(sourceId: 'EON Core:1')]);
    final results = await import([
      _imported(sourceId: 'EON Core:2', maxDepthM: 19.4),
    ]);

    expect(results.single, isA<Saved>());
  });

  test('T2.6 the same dive of another diver is saved', () async {
    await import([_imported()], diver: ben);
    final results = await import([_imported()]);

    expect(results.single, isA<Saved>());
    expect(await dives.listForDiver(anna), hasLength(1));
  });

  test('T2.7 a soft-deleted similar dive does not block', () async {
    final first = (await import([_imported()])).single as Saved;
    await dives.delete(first.saved.id!);

    final results = await import([_imported()]);
    expect(results.single, isA<Saved>());
  });

  test('T2.8 one failing save: the others are saved, it is Failed', () async {
    service = ImportService(_FailingRepository(dives, 13));
    final list = [
      for (var i = 1; i <= 5; i++)
        _imported(
          sourceId: 'EON Core:$i',
          start: DateTime.utc(2026, 11, i, 9),
          maxDepthM: 10.0 + i,
        ),
    ];

    final results = await import(list);

    expect(results.map((r) => r.runtimeType), [
      Saved,
      Saved,
      Failed,
      Saved,
      Saved,
    ]);
    expect(identical(results[2].dive, list[2]), isTrue);
    final stored = await dives.listForDiver(anna);
    expect(stored.map((d) => d.maxDepthM).toSet(), {11.0, 12.0, 14.0, 15.0});
  });

  test('T2.9 an implausible dive is rejected, the others are saved', () async {
    final results = await import([
      _imported(sourceId: 'EON Core:1', maxDepthM: 400),
      _imported(sourceId: 'EON Core:2', start: DateTime.utc(2026, 6, 1)),
    ]);

    expect((results[0] as Rejected).reason, RejectReason.depthOutOfRange);
    expect(results[1], isA<Saved>());
    expect(await dives.listForDiver(anna), hasLength(1));
  });

  test('T2.9 duplicates in one batch: the second is skipped', () async {
    final results = await import([_imported(), _imported()]);

    expect(results[0], isA<Saved>());
    expect(results[1], isA<SkippedDuplicate>());
  });

  test('T2.10 the dive computer is linked to every saved dive', () async {
    final now = DateTime.utc(2026, 11, 20);
    await db
        .into(db.diveComputers)
        .insert(
          DiveComputersCompanion.insert(
            id: 'dc-1',
            vendor: 'Suunto',
            product: 'EON Core',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final results = await withClock(
      Clock.fixed(now),
      () => service.importDives(anna, [_imported()], diveComputerId: 'dc-1'),
    );

    final saved = (results.single as Saved).saved;
    expect((await dives.findById(saved.id!))!.diveComputerId, 'dc-1');
  });
}
