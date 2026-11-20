// T9.1-T9.7, T9.15-T9.19: dive site suggestions (tasks.md, ADR 0006).
import 'dart:convert';
import 'dart:io';

import 'package:divedown/domain/sites/site_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogueSite _site(
  String id,
  String name, {
  String? region = 'South Sinai',
  String? country = 'EG',
  double lat = 27.81,
  double lon = 33.92,
}) => CatalogueSite(
  id: id,
  name: name,
  region: region,
  countryCode: country,
  lat: lat,
  lon: lon,
);

final _catalogue = [
  _site('osm_1', 'SS Thistlegorm', lat: 27.81409, lon: 33.92005),
  _site('osm_2', 'Walchensee', region: 'Bayern', country: 'DE'),
  _site('osm_3', 'Sha’ab El Erg', region: 'Red Sea', lat: 27.38, lon: 33.88),
  _site('osm_4', 'Zürichsee', region: null, country: 'CH'),
  _site('osm_5', 'Wrack ohne Land', region: null, country: null),
];

List<String> _names(List<SiteSuggestion> s) => s.map((x) => x.name).toList();

void main() {
  test('T9.1 own names come before catalogue hits', () {
    final s = SiteSuggester(_catalogue)
        .suggest('wal', own: const [OwnSite(name: 'Walensee, Quinten')]);

    expect(s.first, isA<OwnSiteSuggestion>());
    expect(s.first.name, 'Walensee, Quinten');
    expect(s[1], isA<CatalogueSiteSuggestion>());
    expect(s[1].name, 'Walchensee');
  });

  test('T9.2 catalogue hit with region and German country name', () {
    final s = SiteSuggester(_catalogue).suggest('thistle');

    final hit = s.whereType<CatalogueSiteSuggestion>().single;
    expect(hit.name, 'SS Thistlegorm');
    expect(hit.place, 'South Sinai, Ägypten');
    expect(hit.site.id, 'osm_1');
  });

  test('T9.2 place without region or country', () {
    final s = SiteSuggester(_catalogue);
    String? place(String q) =>
        s.suggest(q).whereType<CatalogueSiteSuggestion>().single.place;

    expect(place('zürich'), 'Schweiz');
    expect(place('wrack'), isNull);
  });

  test('T9.3 ignores accents, case and apostrophe variants', () {
    final s = SiteSuggester(_catalogue);

    expect(_names(s.suggest("sha'ab el erg")), contains('Sha’ab El Erg'));
    expect(_names(s.suggest('SHAAB')), contains('Sha’ab El Erg'));
    expect(_names(s.suggest('zurich')), contains('Zürichsee'));
    expect(normalizeSiteName('  Sha’ab   El  Érg '), 'shaab el erg');
    expect(normalizeSiteName("Sha'ab"), normalizeSiteName('Sha`ab'));
  });

  test('T9.3 matches the start of the name or of a word only', () {
    final s = SiteSuggester(_catalogue);

    expect(_names(s.suggest('erg')), contains('Sha’ab El Erg'));
    expect(_names(s.suggest('gorm')), isNot(contains('SS Thistlegorm')));
  });

  test('T9.4 at most 8 suggestions, own and catalogue together', () {
    final catalogue = [
      for (var i = 0; i < 20; i++) _site('osm_r$i', 'Reef $i'),
    ];
    final s = SiteSuggester(catalogue)
        .suggest('reef', own: const [OwnSite(name: 'Reef Eigen')]);

    final hits = s.where((x) => x is! NewSiteSuggestion).toList();
    expect(hits, hasLength(8));
    expect(hits.first.name, 'Reef Eigen');
  });

  test('T9.5 with a position, nearer catalogue hits come first', () {
    final catalogue = [
      _site('far', 'Far Reef', lat: 10, lon: 100),
      _site('near', 'Near Reef', lat: 27.80, lon: 33.93),
      _site('mid', 'Mid Reef', lat: 25, lon: 35),
    ];
    final s = SiteSuggester(catalogue)
        .suggest('reef', near: const GeoPoint(27.81, 33.92));

    expect(_names(s.whereType<CatalogueSiteSuggestion>().toList()), [
      'Near Reef',
      'Mid Reef',
      'Far Reef',
    ]);
  });

  test('T9.6 the last row always offers the typed text as a new site', () {
    final suggester = SiteSuggester(_catalogue);
    for (final q in ['thistle', 'Walensee, Quinten', 'xyz']) {
      final s = suggester.suggest(q);
      expect(s.last, isA<NewSiteSuggestion>(), reason: q);
      expect(s.last.name, q);
    }
  });

  test('T9.6 the new row keeps the text as typed, trimmed', () {
    final s = SiteSuggester(_catalogue).suggest('  Walensee, Quinten ');
    expect(s.last.name, 'Walensee, Quinten');
  });

  test('T9.7 names over 120 characters are cut, shown as text', () {
    final long = '<b>${'x' * 200}</b>';
    final s = SiteSuggester([_site('osm_l', long)]).suggest('<b>');

    final hit = s.whereType<CatalogueSiteSuggestion>().single;
    expect(hit.name.length, maxSiteNameLength);
    expect(hit.name, startsWith('<b>xxx'), reason: 'plain text, no markup');
  });

  test('T9.15 an own name linked to a catalogue site is shown once', () {
    final s = SiteSuggester(_catalogue).suggest(
      'thistle',
      own: const [
        OwnSite(
          name: 'SS Thistlegorm',
          catalogueId: 'osm_1',
          lat: 27.81409,
          lon: 33.92005,
        ),
      ],
    );

    expect(s.where((x) => x.name == 'SS Thistlegorm'), hasLength(1));
    expect(s.first, isA<OwnSiteSuggestion>());
    expect((s.first as OwnSiteSuggestion).site.catalogueId, 'osm_1');
  });

  test('T9.15 an own name equal to the typed text gives no extra new row', () {
    final s = SiteSuggester(_catalogue).suggest(
      'walensee, quinten',
      own: const [OwnSite(name: 'Walensee, Quinten')],
    );

    expect(_names(s), ['Walensee, Quinten']);
  });

  test('T9.16 empty query: most recent own names only, no new row', () {
    final own = [for (var i = 0; i < 10; i++) OwnSite(name: 'Platz $i')];
    final s = SiteSuggester(_catalogue).suggest('  ', own: own);

    expect(_names(s), [for (var i = 0; i < 8; i++) 'Platz $i']);
    expect(s.whereType<NewSiteSuggestion>(), isEmpty);
  });

  test('T9.17 without a position, visited countries come first', () {
    final catalogue = [
      _site('a', 'Blue Hole', country: 'BZ'),
      _site('b', 'Blue Hole Dahab', country: 'EG'),
    ];
    final s = SiteSuggester(catalogue)
        .suggest('blue', visitedCountries: const {'EG'});

    expect(_names(s.whereType<CatalogueSiteSuggestion>().toList()), [
      'Blue Hole Dahab',
      'Blue Hole',
    ]);
  });

  test('T9.18 name start ranks before word start', () {
    final catalogue = [
      _site('a', 'Big Brother Reef'),
      _site('b', 'Brother Islands'),
    ];
    final s = SiteSuggester(catalogue).suggest('brother');

    expect(_names(s.whereType<CatalogueSiteSuggestion>().toList()), [
      'Brother Islands',
      'Big Brother Reef',
    ]);
  });

  test('T9.19 German country names', () {
    expect(countryNameDe('EG'), 'Ägypten');
    expect(countryNameDe('CH'), 'Schweiz');
    expect(countryNameDe('DE'), 'Deutschland');
    expect(countryNameDe('HR'), 'Kroatien');
    expect(countryNameDe('ID'), 'Indonesien');
    expect(countryNameDe('US'), 'Vereinigte Staaten');
    expect(countryNameDe('XX'), 'XX');
  });

  test('T9.19 every country in the bundled catalogue has a German name', () {
    final json = jsonDecode(
      utf8.decode(
        gzip.decode(File('assets/data/dive_sites.json.gz').readAsBytesSync()),
      ),
    ) as Map<String, Object?>;
    final codes = {
      for (final s in (json['sites'] as List).cast<Map<String, Object?>>())
        if (s['country_code'] case final String code) code,
    };

    expect(codes, isNotEmpty);
    for (final code in codes) {
      expect(countryNameDe(code), isNot(code), reason: code);
    }
  });
}
