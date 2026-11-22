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
}
