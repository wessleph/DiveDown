// T25.1-T25.2: one site for several imported dives (ui-spec §5.9).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:divedown/domain/sites/site_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

ImportedDive _dive({double? lat, double? lon}) => ImportedDive(
  source: DiveSource.fit,
  sourceId: 'fit-1',
  start: DateTime.utc(2026, 11, 14, 9),
  durationS: 2820,
  maxDepthM: 18.4,
  siteLat: lat,
  siteLon: lon,
);

void main() {
  group('T25.1 ImportedDive.withSite', () {
    const elphinstone = ChosenSite(
      name: 'Elphinstone',
      catalogueId: 'eg-elphinstone',
      lat: 25.31,
      lon: 34.86,
    );

    test('name, catalogue link and position go into the dive', () {
      final dive = _dive().withSite(elphinstone);

      expect(dive.siteName, 'Elphinstone');
      expect(dive.siteCatalogueId, 'eg-elphinstone');
      expect(dive.siteLat, 25.31);
      expect(dive.siteLon, 34.86);
      expect(dive.sourceId, 'fit-1', reason: 'everything else stays');
      expect(dive.maxDepthM, 18.4);

      final stored = dive.toDive(diverId: 'anna');
      expect(stored.siteName, 'Elphinstone');
      expect(stored.siteCatalogueId, 'eg-elphinstone');
      expect(stored.siteLat, 25.31);
    });

    test('a new name without position keeps the GPS of the device', () {
      final dive = _dive(
        lat: 27.1,
        lon: 33.9,
      ).withSite(const ChosenSite(name: 'Hausriff'));

      expect(dive.siteName, 'Hausriff');
      expect(dive.siteCatalogueId, isNull);
      expect(dive.siteLat, 27.1);
      expect(dive.siteLon, 33.9);
    });

    test('null removes the site again, the device position stays', () {
      final dive = _dive(
        lat: 27.1,
        lon: 33.9,
      ).withSite(elphinstone).withSite(null);

      expect(dive.siteName, isNull);
      expect(dive.siteCatalogueId, isNull);
      expect(dive.siteLat, 27.1);
      expect(dive.siteLon, 33.9);
    });
  });

  group('T25.2 ChosenSite', () {
    test('from an own site, a catalogue site and a new name', () {
      final own = ChosenSite.fromSuggestion(
        const OwnSiteSuggestion(
          OwnSite(name: 'Hausriff', catalogueId: 'x', lat: 1, lon: 2),
        ),
      );
      expect(
        (own.name, own.catalogueId, own.lat, own.lon),
        ('Hausriff', 'x', 1.0, 2.0),
      );

      final catalogue = ChosenSite.fromSuggestion(
        const CatalogueSiteSuggestion(
          CatalogueSite(
            id: 'eg-elphinstone',
            name: 'Elphinstone',
            countryCode: 'EG',
            lat: 25.31,
            lon: 34.86,
          ),
        ),
      );
      expect(
        (catalogue.name, catalogue.catalogueId, catalogue.lat),
        ('Elphinstone', 'eg-elphinstone', 25.31),
      );

      final fresh = ChosenSite.fromSuggestion(
        const NewSiteSuggestion('Blue Hole'),
      );
      expect(
        (fresh.name, fresh.catalogueId, fresh.lat),
        ('Blue Hole', null, null),
      );
    });

    test('typed text: trimmed, blank is no site, cut to the limit', () {
      expect(ChosenSite.typed('  Blue Hole ')!.name, 'Blue Hole');
      expect(ChosenSite.typed('   '), isNull);
      expect(ChosenSite.typed('x' * 200)!.name, hasLength(maxSiteNameLength));
    });
  });
}
