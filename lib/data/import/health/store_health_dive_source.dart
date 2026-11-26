import 'package:flutter/services.dart' show PlatformException;

import '../../../domain/diagnostics/diagnostic_log.dart';
import '../../../domain/import/health_import.dart';
import '../../../domain/import/imported_dive.dart';
import 'health_dive_mapper.dart';

/// Log category for the Apple Health import. Only counts, never values
/// (security.md §3, T6.12).
const healthLogCategory = 'health';

/// [HealthDiveSource] on top of the platform [HealthStore] (T6.6).
class StoreHealthDiveSource implements HealthDiveSource {
  StoreHealthDiveSource(this._store, {DiagnosticLog? log})
    : _log = log ?? const DiscardingDiagnosticLog();

  final HealthStore _store;
  final DiagnosticLog _log;

  @override
  Future<HealthAvailability> availability() => _store.availability();

  @override
  Future<void> requestPermission() => _store.requestReadAccess();

  @override
  Future<HealthFetchResult> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<HealthWorkout> workouts;
    try {
      workouts = await _store.diveWorkouts(from, to);
    } catch (e) {
      // Only the code: a message from HealthKit could name data (T6.12).
      final code = switch (e) {
        HealthReadFailure(:final reason) => reason,
        PlatformException(:final code) => code,
        _ => e.runtimeType.toString(),
      };
      await _log.log(healthLogCategory, LogLevel.error, 'fetch failed: $code');
      throw HealthReadFailure(code);
    }
    final dives = <ImportedDive>[];
    var skipped = 0;
    for (final w in workouts) {
      final dive = mapHealthDive(w);
      dive == null ? skipped++ : dives.add(dive);
    }
    dives.sort((a, b) => b.start.compareTo(a.start));
    final samples = dives.fold(0, (n, d) => n + d.samples.length);
    await _log.log(
      healthLogCategory,
      LogLevel.info,
      'fetch: ${workouts.length} workouts, ${dives.length} dives, '
      '$skipped without depth, $samples samples',
    );
    return HealthFetchResult(dives, skippedWithoutDepth: skipped);
  }
}
