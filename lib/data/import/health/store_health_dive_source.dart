import '../../../domain/diagnostics/diagnostic_log.dart';
import '../../../domain/import/health_import.dart';

/// Log category for the Apple Health import. Only counts, never values
/// (security.md §3, T6.12).
const healthLogCategory = 'health';

/// [HealthDiveSource] on top of the platform [HealthStore] (T6.6).
class StoreHealthDiveSource implements HealthDiveSource {
  StoreHealthDiveSource(this._store, {DiagnosticLog? log})
    : _log = log ?? const DiscardingDiagnosticLog();

  // ignore: unused_field
  final HealthStore _store;
  // ignore: unused_field
  final DiagnosticLog _log;

  @override
  Future<HealthAvailability> availability() => throw UnimplementedError();

  @override
  Future<void> requestPermission() => throw UnimplementedError();

  @override
  Future<HealthFetchResult> fetch({
    required DateTime from,
    required DateTime to,
  }) => throw UnimplementedError();
}
