// Dive site suggestions for the „Tauchplatz“ field (ADR 0006, ui-spec §5.4).
// Pure Dart: own names first, then the bundled catalogue, then free text.

/// Names longer than this are cut for display (ADR 0006, security).
const maxSiteNameLength = 120;

/// At most this many own and catalogue suggestions together (T9.4).
const maxSiteSuggestions = 8;

/// One entry of the bundled catalogue (`catalogue_sites`).
class CatalogueSite {
  const CatalogueSite({
    required this.id,
    required this.name,
    this.region,
    this.countryCode,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final String? region;

  /// ISO 3166-1 alpha-2, e.g. `EG`.
  final String? countryCode;
  final double lat;
  final double lon;
}

/// A site name already used in the logbook, with the catalogue link and
/// position of its most recent use.
class OwnSite {
  const OwnSite({required this.name, this.catalogueId, this.lat, this.lon});

  final String name;
  final String? catalogueId;
  final double? lat;
  final double? lon;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lon);

  final double lat;
  final double lon;
}

sealed class SiteSuggestion {
  const SiteSuggestion();

  /// The text that goes into the field, at most [maxSiteNameLength].
  String get name;
}

class OwnSiteSuggestion extends SiteSuggestion {
  const OwnSiteSuggestion(this.site);

  final OwnSite site;

  @override
  String get name => throw UnimplementedError('T9: OwnSiteSuggestion.name');
}

class CatalogueSiteSuggestion extends SiteSuggestion {
  const CatalogueSiteSuggestion(this.site);

  final CatalogueSite site;

  @override
  String get name =>
      throw UnimplementedError('T9.7: CatalogueSiteSuggestion.name');

  /// `South Sinai, Ägypten`; null without region and country.
  String? get place =>
      throw UnimplementedError('T9.2: CatalogueSiteSuggestion.place');
}

/// The last row: „‚…‘ als neuen Tauchplatz verwenden“ (T9.6).
class NewSiteSuggestion extends SiteSuggestion {
  const NewSiteSuggestion(this.name);

  @override
  final String name;
}

/// Lower case, without accents, apostrophe variants removed and spaces
/// collapsed, so `Sha’ab El Erg` and `sha'ab el erg` compare equal.
String normalizeSiteName(String text) =>
    throw UnimplementedError('T9.3: normalizeSiteName');

/// German country name for an ISO code, the code itself if unknown.
String countryNameDe(String code) =>
    throw UnimplementedError('T9.19: countryNameDe');

/// Searches own names and the catalogue. Build once per catalogue version
/// and reuse it for every keystroke.
class SiteSuggester {
  SiteSuggester(List<CatalogueSite> catalogue);

  /// Suggestions for [query]: own names (most recent first), then catalogue
  /// hits on name or word start, together at most [maxSiteSuggestions],
  /// then always [NewSiteSuggestion]. With [near], nearer catalogue hits
  /// come first; without it, sites in [visitedCountries] do.
  /// An empty query lists the most recent own names only.
  List<SiteSuggestion> suggest(
    String query, {
    List<OwnSite> own = const [],
    GeoPoint? near,
    Set<String> visitedCountries = const {},
  }) => throw UnimplementedError('T9: SiteSuggester.suggest');
}
