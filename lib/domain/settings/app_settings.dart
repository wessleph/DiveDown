/// „Darstellung“ in the settings (ui-spec §5.11).
enum AppThemeMode { system, light, dark }

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
}
