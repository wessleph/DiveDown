import 'package:clock/clock.dart';

import '../../domain/settings/app_settings.dart';
import '../../domain/share/share_card.dart';
import 'database.dart';

/// Key in `app_meta` for [AppSettings.activeDiverId].
const activeDiverKey = 'active_diver_id';
const themeModeKey = 'theme_mode';
const lastBackupKey = 'last_backup_at';
const backupBaselineKey = 'backup_baseline';
const backupSnoozedKey = 'backup_snoozed_until';
const profileLayersKey = 'profile_layers';
const shareCardKey = 'share_card';

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

  Future<String?> _get(String key) async => (await (_db.select(
    _db.appMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));

  Future<DateTime?> _getTime(String key) async =>
      DateTime.tryParse(await _get(key) ?? '')?.toUtc();

  @override
  Future<DateTime?> lastBackupAt() => _getTime(lastBackupKey);

  @override
  Future<void> setLastBackupAt(DateTime at) =>
      _set(lastBackupKey, at.toUtc().toIso8601String());

  @override
  Future<DateTime> backupBaseline() async {
    final stored = await _getTime(backupBaselineKey);
    if (stored != null) return stored;
    final now = clock.now().toUtc();
    await _set(backupBaselineKey, now.toIso8601String());
    return now;
  }

  @override
  Future<DateTime?> backupReminderSnoozedUntil() => _getTime(backupSnoozedKey);

  @override
  Future<void> setBackupReminderSnoozedUntil(DateTime until) =>
      _set(backupSnoozedKey, until.toUtc().toIso8601String());

  @override
  Future<void> setThemeMode(AppThemeMode mode) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(key: themeModeKey, value: mode.name),
      );

  @override
  Future<List<ProfileLayer>?> profileLayers() async {
    final raw = await _get(profileLayersKey);
    if (raw == null) return null;
    final byName = ProfileLayer.values.asNameMap();
    // Names of other app versions (e.g. the removed `ndl`) are skipped.
    return [for (final name in raw.split(',')) ?byName[name.trim()]];
  }

  @override
  Future<void> setProfileLayers(List<ProfileLayer> layers) =>
      _set(profileLayersKey, layers.map((l) => l.name).join(','));

  @override
  Future<ShareCardLayout?> shareCardLayout() async {
    final raw = await _get(shareCardKey);
    return raw == null ? null : ShareCardLayout.decode(raw);
  }

  @override
  Future<void> setShareCardLayout(ShareCardLayout layout) =>
      _set(shareCardKey, layout.encode());
}
