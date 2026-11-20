import '../../domain/sites/site_repository.dart';
import '../../domain/sites/site_suggestions.dart';
import 'database.dart';

class DriftSiteRepository implements SiteRepository {
  DriftSiteRepository(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<List<CatalogueSite>> catalogue() =>
      throw UnimplementedError('T9.10: SiteRepository.catalogue');

  @override
  Future<List<OwnSite>> ownSites() =>
      throw UnimplementedError('T9.8: SiteRepository.ownSites');

  @override
  Future<Set<String>> visitedCountries(String diverId) =>
      throw UnimplementedError('T9.9: SiteRepository.visitedCountries');
}
