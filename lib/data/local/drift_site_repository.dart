import 'package:drift/drift.dart';

import '../../domain/sites/site_repository.dart';
import '../../domain/sites/site_suggestions.dart';
import 'database.dart';

class DriftSiteRepository implements SiteRepository {
  DriftSiteRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<CatalogueSite>> catalogue() async {
    final rows = await _db.select(_db.catalogueSites).get();
    return [
      for (final r in rows)
        CatalogueSite(
          id: r.id,
          name: r.name,
          region: r.region,
          countryCode: r.countryCode,
          lat: r.lat,
          lon: r.lon,
        ),
    ];
  }

  @override
  Future<List<OwnSite>> ownSites() async {
    final rows =
        await (_db.select(_db.dives)
              ..where((t) => t.deletedAt.isNull() & t.siteName.isNotNull())
              ..orderBy([(t) => OrderingTerm.desc(t.startLocal)]))
            .get();
    // Newest first, so the first row of a name is its latest use.
    final byName = <String, OwnSite>{};
    for (final r in rows) {
      final name = r.siteName!.trim();
      if (name.isEmpty || byName.containsKey(name)) continue;
      byName[name] = OwnSite(
        name: name,
        catalogueId: r.siteCatalogueId,
        lat: r.siteLat,
        lon: r.siteLon,
      );
    }
    return byName.values.toList();
  }

  @override
  Future<Set<String>> visitedCountries(String diverId) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT c.country_code AS code FROM dives d '
          'JOIN catalogue_sites c ON c.id = d.site_catalogue_id '
          'WHERE d.diver_id = ? AND d.deleted_at IS NULL '
          'AND c.country_code IS NOT NULL',
          variables: [Variable.withString(diverId)],
          readsFrom: {_db.dives, _db.catalogueSites},
        )
        .get();
    return {for (final r in rows) r.read<String>('code')};
  }
}
