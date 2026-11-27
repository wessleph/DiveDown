/// „Darstellung“ in the settings (ui-spec §5.11).
enum AppThemeMode { system, light, dark }

/// The layers of the profile chart with their own axis (ui-spec §6, T37).
enum ProfileLayer { temperature, pressure, consumption, pulse }

/// Small app-wide settings kept in the local database.
abstract interface class AppSettings {
  /// The diver that logbook and import work for (ui-spec §2), null on the
  /// very first start.
  Future<String?> activeDiverId();
  Future<void> setActiveDiverId(String id);

  /// System when never set.
  Future<AppThemeMode> themeMode();
  Future<void> setThemeMode(AppThemeMode mode);

  /// When the last backup was shared (ui-spec §5.12), null if never.
  Future<DateTime?> lastBackupAt();
  Future<void> setLastBackupAt(DateTime at);

  /// First start of the app; set on the first call (T11.8).
  Future<DateTime> backupBaseline();

  /// „✕“ on the reminder hides it until then (T11.8).
  Future<DateTime?> backupReminderSnoozedUntil();
  Future<void> setBackupReminderSnoozedUntil(DateTime until);

  /// The profile layers last switched on (ui-spec §6 „Zustand wird gemerkt“,
  /// T38); null until the diver changes them.
  Future<List<ProfileLayer>?> profileLayers();
  Future<void> setProfileLayers(List<ProfileLayer> layers);
}
