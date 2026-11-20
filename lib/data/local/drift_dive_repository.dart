import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/dive/dive.dart';
import '../../domain/dive/dive_repository.dart';
import '../../domain/dive/diver.dart';
import 'database.dart';

const _uuid = Uuid();

class DriftDiverRepository implements DiverRepository {
  DriftDiverRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Diver> create(Diver diver) async {
    final now = clock.now().toUtc();
    final stored = diver.copyWith(id: _uuid.v4());
    await _db
        .into(_db.divers)
        .insert(
          DiversCompanion.insert(
            id: stored.id!,
            name: stored.name,
            firstDiveNumber: Value(stored.firstDiveNumber),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return stored;
  }

  @override
  Future<Diver?> findById(String id) async {
    final row = await (_db.select(
      _db.divers,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return null;
    return Diver(
      id: row.id,
      name: row.name,
      firstDiveNumber: row.firstDiveNumber,
    );
  }

  @override
  Future<List<Diver>> list() =>
      throw UnimplementedError('T15.24: DiverRepository.list');
}

class DriftDiveRepository implements DiveRepository {
  DriftDiveRepository(this._db);

  final AppDatabase _db;

  @override
  Future<SaveDiveResult> save(Dive dive) {
    return _db.transaction(() async {
      final now = clock.now().toUtc();
      final id = dive.id ?? _uuid.v4();
      final number = dive.number ?? await _nextNumber(dive.diverId);
      final stored = dive.copyWith(id: id, number: number);

      final existing = await (_db.select(
        _db.dives,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      await _db
          .into(_db.dives)
          .insertOnConflictUpdate(
            _toRow(stored, createdAt: existing?.createdAt ?? now, now: now),
          );
      await _replaceChildren(stored);

      final warnings = <DiveWarning>{
        if (await _numberTaken(stored)) DiveWarning.duplicateNumber,
      };
      return SaveDiveResult(stored, warnings: warnings);
    });
  }

  @override
  Future<Dive?> findById(String id) async {
    final row = await (_db.select(
      _db.dives,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return null;
    return _fromRow(row).copyWith(
      samples: await _loadSamples(id),
      tanks: await _loadTanks(id),
      events: await _loadEvents(id),
    );
  }

  @override
  Future<List<Dive>> listForDiver(String diverId) async {
    final rows =
        await (_db.select(_db.dives)
              ..where((t) => t.diverId.equals(diverId) & t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.desc(t.startLocal),
                (t) => OrderingTerm.desc(t.diveNumber),
              ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> nextNumber(String diverId) =>
      throw UnimplementedError('T15.23: DiveRepository.nextNumber');

  @override
  Future<void> delete(String id) => _setDeleted(id, clock.now().toUtc());

  @override
  Future<void> restore(String id) => _setDeleted(id, null);

  Future<void> _setDeleted(String id, DateTime? deletedAt) {
    return (_db.update(_db.dives)..where((t) => t.id.equals(id))).write(
      DivesCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(clock.now().toUtc()),
      ),
    );
  }

  /// Highest number of the diver + 1, starting at `first_dive_number`.
  Future<int> _nextNumber(String diverId) async {
    final max = _db.dives.diveNumber.max();
    final highest =
        await (_db.selectOnly(_db.dives)
              ..addColumns([max])
              ..where(
                _db.dives.diverId.equals(diverId) &
                    _db.dives.deletedAt.isNull(),
              ))
            .map((r) => r.read(max))
            .getSingle();
    if (highest != null) return highest + 1;
    final diver = await (_db.select(
      _db.divers,
    )..where((t) => t.id.equals(diverId))).getSingle();
    return diver.firstDiveNumber;
  }

  Future<bool> _numberTaken(Dive dive) async {
    final other =
        await (_db.select(_db.dives)
              ..where(
                (t) =>
                    t.diverId.equals(dive.diverId) &
                    t.diveNumber.equals(dive.number!) &
                    t.id.equals(dive.id!).not() &
                    t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return other != null;
  }

  Future<void> _replaceChildren(Dive dive) async {
    final id = dive.id!;
    for (final table in <TableInfo<Table, Object?>>[
      _db.diveSamples,
      _db.diveTankPressures,
      _db.diveTanks,
      _db.diveEvents,
    ]) {
      await _db.customStatement(
        'DELETE FROM ${table.actualTableName} WHERE dive_id = ?',
        [id],
      );
    }

    await _db.batch((b) {
      b.insertAll(_db.diveSamples, [
        for (final s in dive.samples)
          DiveSamplesCompanion.insert(
            diveId: id,
            timeS: s.timeS,
            depthM: s.depthM,
            temperatureC: Value(s.temperatureC),
            heartRate: Value(s.heartRate),
            ndlS: Value(s.ndlS),
            decoCeilingM: Value(s.decoCeilingM),
            decoTimeS: Value(s.decoTimeS),
            gasIndex: Value(s.gasIndex),
          ),
      ]);
      b.insertAll(_db.diveTankPressures, [
        for (final s in dive.samples)
          for (final p in s.pressures)
            DiveTankPressuresCompanion.insert(
              diveId: id,
              timeS: s.timeS,
              tankIndex: p.tankIndex,
              pressureBar: p.pressureBar,
            ),
      ]);
      b.insertAll(_db.diveTanks, [
        for (final t in dive.tanks)
          DiveTanksCompanion.insert(
            diveId: id,
            tankIndex: t.index,
            volumeL: Value(t.volumeL),
            startPressureBar: Value(t.startPressureBar),
            endPressureBar: Value(t.endPressureBar),
            o2: Value(t.gas?.o2),
            he: Value(t.gas?.he),
          ),
      ]);
      b.insertAll(_db.diveEvents, [
        for (final e in dive.events)
          DiveEventsCompanion.insert(
            id: _uuid.v4(),
            diveId: id,
            timeS: e.timeS,
            type: e.type,
            value: Value(e.value),
          ),
      ]);
    });
  }

  Future<List<DiveSample>> _loadSamples(String diveId) async {
    final pressureRows =
        await (_db.select(_db.diveTankPressures)
              ..where((t) => t.diveId.equals(diveId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.timeS),
                (t) => OrderingTerm.asc(t.tankIndex),
              ]))
            .get();
    final pressures = <int, List<TankPressure>>{};
    for (final p in pressureRows) {
      (pressures[p.timeS] ??= []).add(
        TankPressure(tankIndex: p.tankIndex, pressureBar: p.pressureBar),
      );
    }

    final rows =
        await (_db.select(_db.diveSamples)
              ..where((t) => t.diveId.equals(diveId))
              ..orderBy([(t) => OrderingTerm.asc(t.timeS)]))
            .get();
    return [
      for (final r in rows)
        DiveSample(
          timeS: r.timeS,
          depthM: r.depthM,
          temperatureC: r.temperatureC,
          pressures: pressures[r.timeS] ?? const [],
          heartRate: r.heartRate,
          ndlS: r.ndlS,
          decoCeilingM: r.decoCeilingM,
          decoTimeS: r.decoTimeS,
          gasIndex: r.gasIndex,
        ),
    ];
  }

  Future<List<DiveTank>> _loadTanks(String diveId) async {
    final rows =
        await (_db.select(_db.diveTanks)
              ..where((t) => t.diveId.equals(diveId))
              ..orderBy([(t) => OrderingTerm.asc(t.tankIndex)]))
            .get();
    return [
      for (final r in rows)
        DiveTank(
          index: r.tankIndex,
          volumeL: r.volumeL,
          startPressureBar: r.startPressureBar,
          endPressureBar: r.endPressureBar,
          gas: r.o2 == null ? null : GasMix(o2: r.o2!, he: r.he ?? 0),
        ),
    ];
  }

  Future<List<DiveEvent>> _loadEvents(String diveId) async {
    final rows =
        await (_db.select(_db.diveEvents)
              ..where((t) => t.diveId.equals(diveId))
              ..orderBy([(t) => OrderingTerm.asc(t.timeS)]))
            .get();
    return [
      for (final r in rows)
        DiveEvent(timeS: r.timeS, type: r.type, value: r.value),
    ];
  }
}

// Stored names from design.md §5.
const _sourceNames = {
  DiveSource.diveComputer: 'dive_computer',
  DiveSource.fit: 'fit',
  DiveSource.appleHealth: 'apple_health',
  DiveSource.manual: 'manual',
};

/// The wall-clock start is stored as if it were UTC, so it never shifts with
/// the time zone of the phone (ADR 0004, T4.1).
DateTime _wallClockAsUtc(DateTime t) => DateTime.utc(
  t.year,
  t.month,
  t.day,
  t.hour,
  t.minute,
  t.second,
  t.millisecond,
);

DivesCompanion _toRow(
  Dive d, {
  required DateTime createdAt,
  required DateTime now,
}) {
  return DivesCompanion.insert(
    id: d.id!,
    diverId: d.diverId,
    diveNumber: d.number!,
    siteName: Value(d.siteName),
    siteCatalogueId: Value(d.siteCatalogueId),
    siteLat: Value(d.siteLat),
    siteLon: Value(d.siteLon),
    diveComputerId: Value(d.diveComputerId),
    source: _sourceNames[d.source]!,
    sourceId: Value(d.sourceId),
    startLocal: _wallClockAsUtc(d.start),
    utcOffsetS: Value(d.utcOffsetS),
    durationS: d.durationS,
    maxDepthM: d.maxDepthM,
    avgDepthM: Value(d.avgDepthM),
    minTemperatureC: Value(d.minTemperatureC),
    maxTemperatureC: Value(d.maxTemperatureC),
    waterType: Value(d.waterType?.name),
    notes: Value(d.notes),
    rating: Value(d.rating),
    createdAt: createdAt,
    updatedAt: now,
  );
}

Dive _fromRow(DiveRow r) {
  return Dive(
    id: r.id,
    diverId: r.diverId,
    number: r.diveNumber,
    siteName: r.siteName,
    siteCatalogueId: r.siteCatalogueId,
    siteLat: r.siteLat,
    siteLon: r.siteLon,
    diveComputerId: r.diveComputerId,
    source: _sourceNames.entries.firstWhere((e) => e.value == r.source).key,
    sourceId: r.sourceId,
    start: r.startLocal.toUtc(),
    utcOffsetS: r.utcOffsetS,
    durationS: r.durationS,
    maxDepthM: r.maxDepthM,
    avgDepthM: r.avgDepthM,
    minTemperatureC: r.minTemperatureC,
    maxTemperatureC: r.maxTemperatureC,
    waterType: r.waterType == null
        ? null
        : WaterType.values.byName(r.waterType!),
    notes: r.notes,
    rating: r.rating,
  );
}
