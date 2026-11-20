// Dive site suggestions for the „Tauchplatz“ field (ADR 0006, ui-spec §5.4).
// Pure Dart: own names first, then the bundled catalogue, then free text.

import 'dart:math' as math;

import 'country_names_de.dart';

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
  String get name => _cut(site.name);
}

class CatalogueSiteSuggestion extends SiteSuggestion {
  const CatalogueSiteSuggestion(this.site);

  final CatalogueSite site;

  @override
  String get name => _cut(site.name);

  /// `South Sinai, Ägypten`; null without region and country.
  String? get place {
    final parts = [
      ?site.region,
      if (site.countryCode case final c?) countryNameDe(c),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// The last row: „‚…‘ als neuen Tauchplatz verwenden“ (T9.6).
class NewSiteSuggestion extends SiteSuggestion {
  const NewSiteSuggestion(this.name);

  @override
  final String name;
}

/// Lower case, without accents, apostrophe variants removed and spaces
/// collapsed, so `Sha’ab El Erg` and `sha'ab el erg` compare equal.
String normalizeSiteName(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    if (_apostrophes.contains(ch)) continue;
    out.write(_plain[ch] ?? ch);
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// German country name for an ISO code, the code itself if unknown.
String countryNameDe(String code) => countryNamesDe[code.toUpperCase()] ?? code;

const _apostrophes = {"'", '’', '‘', '`', '´', 'ʼ', 'ʻ'};

/// Letters with accents and their plain form, as far as dive site names
/// in the catalogue need them.
const _plain = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'æ': 'ae',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ď': 'd',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ı': 'i',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'ő': 'o',
  'œ': 'oe',
  'ř': 'r',
  'ś': 's',
  'š': 's',
  'ş': 's',
  'ș': 's',
  'ß': 'ss',
  'ť': 't',
  'ţ': 't',
  'ț': 't',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ů': 'u',
  'ű': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
};

String _cut(String name) => name.length <= maxSiteNameLength
    ? name
    : name.substring(0, maxSiteNameLength);

/// 0 = name starts with [query], 1 = a word starts with it, null = no match.
int? _matchRank(String normalizedName, String query) {
  if (normalizedName.startsWith(query)) return 0;
  for (final m in _wordStart.allMatches(normalizedName)) {
    if (normalizedName.startsWith(query, m.end)) return 1;
  }
  return null;
}

final _wordStart = RegExp(r'[\s\-/(),.]+');

/// Great-circle distance in km.
double _distanceKm(GeoPoint a, double lat, double lon) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat - a.lat);
  final dLon = rad(lon - a.lon);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(lat)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Searches own names and the catalogue. Build once per catalogue version
/// and reuse it for every keystroke.
class SiteSuggester {
  SiteSuggester(List<CatalogueSite> catalogue)
    : _catalogue = [
        for (final site in catalogue) (site, normalizeSiteName(site.name)),
      ];

  final List<(CatalogueSite, String)> _catalogue;

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
  }) {
    final q = normalizeSiteName(query);
    if (q.isEmpty) {
      return [
        for (final o in own.take(maxSiteSuggestions)) OwnSiteSuggestion(o),
      ];
    }

    final ownHits = [
      for (final o in own)
        if (_matchRank(normalizeSiteName(o.name), q) != null) o,
    ].take(maxSiteSuggestions).toList();
    final ownIds = {for (final o in ownHits) ?o.catalogueId};
    final ownNames = {for (final o in ownHits) normalizeSiteName(o.name)};

    final hits = <(CatalogueSite, int)>[
      for (final (site, name) in _catalogue)
        if (!ownIds.contains(site.id) && !ownNames.contains(name))
          if (_matchRank(name, q) case final rank?) (site, rank),
    ];
    if (near != null) {
      double d(CatalogueSite s) => _distanceKm(near, s.lat, s.lon);
      hits.sort((a, b) => d(a.$1).compareTo(d(b.$1)));
    } else {
      int visited(CatalogueSite s) =>
          visitedCountries.contains(s.countryCode) ? 0 : 1;
      hits.sort((a, b) {
        final byCountry = visited(a.$1).compareTo(visited(b.$1));
        if (byCountry != 0) return byCountry;
        final byRank = a.$2.compareTo(b.$2);
        if (byRank != 0) return byRank;
        return normalizeSiteName(a.$1.name)
            .compareTo(normalizeSiteName(b.$1.name));
      });
    }

    final suggestions = <SiteSuggestion>[
      for (final o in ownHits) OwnSiteSuggestion(o),
      for (final (site, _) in hits.take(maxSiteSuggestions - ownHits.length))
        CatalogueSiteSuggestion(site),
    ];
    final typed = _cut(query.trim());
    final known = suggestions.any((s) => normalizeSiteName(s.name) == q);
    return [...suggestions, if (!known) NewSiteSuggestion(typed)];
  }
}
