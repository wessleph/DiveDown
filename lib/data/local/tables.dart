import 'package:drift/drift.dart';

// Schema v2 (ADR 0004, ADR 0006, ADR 0007). Values in SI units.
// Logbook tables use UUID text keys and soft delete; child rows of a dive
// (samples, tanks, pressures) are keyed by the dive and replaced with it.
// Row classes end in `Row` so they never clash with the domain model.

mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('DiverRow')
class Divers extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get firstDiveNumber => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DiveComputerRow')
class DiveComputers extends Table with SyncColumns {
  TextColumn get vendor => text()();
  TextColumn get product => text()();
  IntColumn get modelNumber => integer().nullable()();
  TextColumn get serial => text().nullable()();
  TextColumn get firmware => text().nullable()();
  TextColumn get address => text().nullable()();
  BlobColumn get lastFingerprint => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'dives_by_diver', columns: {#diverId, #startLocal})
@DataClassName('DiveRow')
class Dives extends Table with SyncColumns {
  TextColumn get diverId => text().references(Divers, #id)();
  IntColumn get diveNumber => integer()();
  TextColumn get siteName => text().nullable()();
  TextColumn get siteCatalogueId => text().nullable()();
  RealColumn get siteLat => real().nullable()();
  RealColumn get siteLon => real().nullable()();
  TextColumn get diveComputerId =>
      text().nullable().references(DiveComputers, #id)();
  TextColumn get source => text()();
  TextColumn get sourceId => text().nullable()();

  /// Wall-clock start, stored as if it were UTC so it never shifts.
  DateTimeColumn get startLocal => dateTime()();
  IntColumn get utcOffsetS => integer().nullable()();
  IntColumn get durationS => integer()();
  RealColumn get maxDepthM => real()();
  RealColumn get avgDepthM => real().nullable()();
  RealColumn get minTemperatureC => real().nullable()();
  RealColumn get maxTemperatureC => real().nullable()();
  TextColumn get waterType => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get rating => integer().nullable()();

  /// Lead in kg (schema v2, ADR 0007).
  RealColumn get weightKg => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A piece of the diver's equipment (schema v2, ADR 0007).
@DataClassName('EquipmentRow')
class Equipment extends Table with SyncColumns {
  TextColumn get diverId => text().references(Divers, #id)();

  /// `EquipmentKind.name`, e.g. `bcd`.
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Equipment used on a dive; child rows of the dive like its samples.
@DataClassName('DiveEquipmentRow')
class DiveEquipment extends Table {
  TextColumn get diveId =>
      text().references(Dives, #id, onDelete: KeyAction.cascade)();
  TextColumn get equipmentId => text().references(Equipment, #id)();

  @override
  Set<Column> get primaryKey => {diveId, equipmentId};
}

@DataClassName('DiveSampleRow')
class DiveSamples extends Table {
  TextColumn get diveId =>
      text().references(Dives, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeS => integer()();
  RealColumn get depthM => real()();
  RealColumn get temperatureC => real().nullable()();
  IntColumn get heartRate => integer().nullable()();
  IntColumn get ndlS => integer().nullable()();
  RealColumn get decoCeilingM => real().nullable()();
  IntColumn get decoTimeS => integer().nullable()();
  IntColumn get gasIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {diveId, timeS};
}

/// Tank pressure per sample time; a sample can carry several tanks.
@DataClassName('DiveTankPressureRow')
class DiveTankPressures extends Table {
  TextColumn get diveId =>
      text().references(Dives, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeS => integer()();
  IntColumn get tankIndex => integer()();
  RealColumn get pressureBar => real()();

  @override
  Set<Column> get primaryKey => {diveId, timeS, tankIndex};
}

@DataClassName('DiveTankRow')
class DiveTanks extends Table {
  TextColumn get diveId =>
      text().references(Dives, #id, onDelete: KeyAction.cascade)();
  IntColumn get tankIndex => integer()();
  RealColumn get volumeL => real().nullable()();
  RealColumn get startPressureBar => real().nullable()();
  RealColumn get endPressureBar => real().nullable()();
  RealColumn get o2 => real().nullable()();
  RealColumn get he => real().nullable()();

  @override
  Set<Column> get primaryKey => {diveId, tankIndex};
}

@DataClassName('DiveEventRow')
class DiveEvents extends Table {
  TextColumn get id => text()();
  TextColumn get diveId =>
      text().references(Dives, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeS => integer()();
  TextColumn get type => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Read-only copy of assets/data/dive_sites.json.gz (ADR 0006).
/// Not part of backups or sync.
@DataClassName('CatalogueSiteRow')
class CatalogueSites extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get region => text().nullable()();
  TextColumn get countryCode => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get maxDepthM => real().nullable()();

  /// Comma-separated, e.g. `reef,wreck`.
  TextColumn get types => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key-value store for app state such as the loaded catalogue version.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
