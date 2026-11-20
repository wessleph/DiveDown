/// Small app-wide settings kept in the local database.
abstract interface class AppSettings {
  /// The diver that logbook and import work for (ui-spec §2), null on the
  /// very first start.
  Future<String?> activeDiverId();
  Future<void> setActiveDiverId(String id);
}
