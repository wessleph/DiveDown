import '../../domain/settings/app_settings.dart';
import 'database.dart';

/// Key in `app_meta` for [AppSettings.activeDiverId].
const activeDiverKey = 'active_diver_id';

class DriftAppSettings implements AppSettings {
  DriftAppSettings(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<String?> activeDiverId() =>
      throw UnimplementedError('T15.25: activeDiverId');

  @override
  Future<void> setActiveDiverId(String id) =>
      throw UnimplementedError('T15.25: setActiveDiverId');
}
