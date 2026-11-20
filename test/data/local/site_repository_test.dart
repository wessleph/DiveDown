// T9.8-T9.10: site queries behind the suggestions (tasks.md, ADR 0006).
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/data/local/drift_site_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive(
  String diverId,
  String? site,
  DateTime start, {
  String? catalogueId,
  double? lat,
  double? lon,
}) => Dive(
  diverId: diverId,
  siteName: site,
  siteCatalogueId: catalogueId,
  siteLat: lat,
  siteLon: lon,
  source: DiveSource.manual,
  start: start,
  durationS: 2820,
  maxDepthM: 18.4,
);

void main() {
  late AppDatabase db;
  late DriftDiveRepository dives;
  late DriftSiteRepository sites;
  late String anna;
  late String ben;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dives = DriftDiveRepository(db);
    sites = DriftSiteRepository(db);
    anna = (await DriftDiverRepository(db).create(const Diver(name: 'Anna')))
        .id!;
    ben = (await DriftDiverRepository(db).create(const Diver(name: 'Ben'))).id!;
    await db.batch((b) {
      b.insertAll(db.catalogueSites, [
        CatalogueSitesCompanion.insert(
          id: 'osm_1',
          name: 'SS Thistlegorm',
          region: const Value('South Sinai'),
          countryCode: const Value('EG'),
          lat: 27.81409,
          lon: 33.92005,
        ),
        CatalogueSitesCompanion.insert(
          id: 'osm_2',
          name: 'Walchensee',
          countryCode: const Value('DE'),
          lat: 47.59,
          lon: 11.33,
        ),
      ]);
    });
  });

  tearDown(() => db.close());

  test('T9.8 own sites: each name once, most recent use first', () async {
    await dives.save(
      _dive(anna, 'Walensee, Quinten', DateTime.utc(2026, 6, 1)),
    );
    await dives.save(_dive(anna, 'Hallwilersee', DateTime.utc(2026, 7, 1)));
    await dives.save(_dive(ben, 'Walensee, Quinten', DateTime.utc(2026, 8, 1)));
    await dives.save(_dive(anna, null, DateTime.utc(2026, 9, 1)));
    await dives.save(_dive(anna, '   ', DateTime.utc(2026, 9, 2)));

    final own = await sites.ownSites();
    expect(own.map((s) => s.name), ['Walensee, Quinten', 'Hallwilersee']);
  });

  test('T9.8 own sites carry link and position of the latest use', () async {
    await dives.save(_dive(anna, 'SS Thistlegorm', DateTime.utc(2026, 5, 1)));
    await dives.save(
      _dive(
        anna,
        'SS Thistlegorm',
        DateTime.utc(2026, 11, 14),
        catalogueId: 'osm_1',
        lat: 27.81409,
        lon: 33.92005,
      ),
    );

    final own = (await sites.ownSites()).single;
    expect(own.catalogueId, 'osm_1');
    expect(own.lat, 27.81409);
    expect(own.lon, 33.92005);
  });

  test('T9.8 deleted dives do not suggest their site', () async {
    final saved = await dives.save(
      _dive(anna, 'Geheimplatz', DateTime.utc(2026, 6, 1)),
    );
    await dives.delete(saved.dive.id!);

    expect(await sites.ownSites(), isEmpty);
  });

  test('T9.9 visited countries come from linked catalogue sites', () async {
    await dives.save(
      _dive(
        anna,
        'SS Thistlegorm',
        DateTime.utc(2026, 11, 14),
        catalogueId: 'osm_1',
      ),
    );
    await dives.save(
      _dive(anna, 'Walensee, Quinten', DateTime.utc(2026, 6, 1)),
    );
    await dives.save(
      _dive(ben, 'Walchensee', DateTime.utc(2026, 6, 1), catalogueId: 'osm_2'),
    );

    expect(await sites.visitedCountries(anna), {'EG'});
    expect(await sites.visitedCountries(ben), {'DE'});
  });

  test('T9.10 catalogue returns every entry with its fields', () async {
    final all = await sites.catalogue();

    expect(all, hasLength(2));
    final t = all.firstWhere((s) => s.id == 'osm_1');
    expect(t.name, 'SS Thistlegorm');
    expect(t.region, 'South Sinai');
    expect(t.countryCode, 'EG');
    expect(t.lat, 27.81409);
    expect(all.firstWhere((s) => s.id == 'osm_2').region, isNull);
  });
}
