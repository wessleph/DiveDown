import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Divers,
    DiveComputers,
    Dives,
    DiveSamples,
    DiveTankPressures,
    DiveTanks,
    DiveEvents,
    Equipment,
    DiveEquipment,
    CatalogueSites,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Schema of this app version; backups from a newer one are refused
  /// (T11.4).
  static const latestSchemaVersion = 3;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Equipment and lead (ADR 0007).
        await m.addColumn(dives, dives.weightKg);
        await m.createTable(equipment);
        await m.createTable(diveEquipment);
      }
      if (from < 3) {
        // Visibility, current and kinds of dive (T40).
        await m.addColumn(dives, dives.visibility);
        await m.addColumn(dives, dives.currentStrength);
        await m.addColumn(dives, dives.kinds);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
