import 'site_suggestions.dart';

abstract interface class SiteRepository {
  /// All entries of the bundled catalogue.
  Future<List<CatalogueSite>> catalogue();

  /// Site names of all dives on this device that are not deleted, most
  /// recently used first, each name once (ADR 0006: own names first).
  Future<List<OwnSite>> ownSites();

  /// Countries of the catalogue sites this diver has dived at.
  Future<Set<String>> visitedCountries(String diverId);
}
