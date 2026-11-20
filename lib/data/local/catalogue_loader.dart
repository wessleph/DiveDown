import 'database.dart';

/// Fills `catalogue_sites` from the bundled `dive_sites.json.gz` (ADR 0006).
class CatalogueLoader {
  CatalogueLoader(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  /// Loads the catalogue when [version] differs from the one already loaded.
  /// [readGzip] is only called when a reload is needed.
  /// Returns whether the table was refilled.
  Future<bool> ensureLoaded({
    required String version,
    required Future<List<int>> Function() readGzip,
  }) => throw UnimplementedError();

  Future<int> count() => throw UnimplementedError();
}
