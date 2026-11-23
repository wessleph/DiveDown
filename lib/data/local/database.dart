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
  static const latestSchemaVersion = 2;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
