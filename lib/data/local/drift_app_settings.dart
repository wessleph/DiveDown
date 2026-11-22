import '../../domain/settings/app_settings.dart';
import 'database.dart';

/// Key in `app_meta` for [AppSettings.activeDiverId].
const activeDiverKey = 'active_diver_id';
const themeModeKey = 'theme_mode';

class DriftAppSettings implements AppSettings {
  DriftAppSettings(this._db);

  final AppDatabase _db;

  @override
  Future<String?> activeDiverId() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(activeDiverKey))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setActiveDiverId(String id) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(key: activeDiverKey, value: id),
      );

  @override
  Future<AppThemeMode> themeMode() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(themeModeKey))).getSingleOrNull();
    return AppThemeMode.values.asNameMap()[row?.value] ?? AppThemeMode.system;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(key: themeModeKey, value: mode.name),
      );
}
