import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import 'database.dart';

const _versionKey = 'catalogue_version';

/// Fills `catalogue_sites` from the bundled `dive_sites.json.gz` (ADR 0006).
class CatalogueLoader {
  CatalogueLoader(this._db);

  final AppDatabase _db;

  /// Loads the catalogue when [version] differs from the one already loaded.
  /// [readGzip] is only called when a reload is needed.
  /// Returns whether the table was refilled.
  Future<bool> ensureLoaded({
    required String version,
    required Future<List<int>> Function() readGzip,
  }) async {
    final loaded = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_versionKey))).getSingleOrNull();
    if (loaded?.value == version) return false;

    final json = jsonDecode(
      utf8.decode(gzip.decode(await readGzip())),
    ) as Map<String, Object?>;
    final sites = (json['sites'] as List).cast<Map<String, Object?>>();

    await _db.transaction(() async {
      await _db.delete(_db.catalogueSites).go();
      await _db.batch((b) {
        b.insertAll(_db.catalogueSites, [
          for (final s in sites)
            CatalogueSitesCompanion.insert(
              id: s['id'] as String,
              name: s['name'] as String,
              region: Value(s['region'] as String?),
              countryCode: Value(s['country_code'] as String?),
              lat: (s['lat'] as num).toDouble(),
              lon: (s['lon'] as num).toDouble(),
              maxDepthM: Value((s['max_depth_m'] as num?)?.toDouble()),
              types: Value(((s['types'] as List?) ?? const []).join(',')),
            ),
        ]);
      });
      await _db
          .into(_db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(key: _versionKey, value: version),
          );
    });
    return true;
  }

  Future<int> count() {
    final n = _db.catalogueSites.id.count();
    return (_db.selectOnly(
      _db.catalogueSites,
    )..addColumns([n])).map((r) => r.read(n)!).getSingle();
  }
}
