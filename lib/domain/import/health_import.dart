// Apple Health import (design.md §4.3, ui-spec §5.10, security.md G3, T6).
// Pure Dart: the platform side delivers raw workouts, the data layer turns
// them into [ImportedDive]s.

import '../dive/dive.dart';
import 'imported_dive.dart';

/// One reading of a HealthKit series.
class HealthPoint {
  const HealthPoint(this.at, this.value);

  /// The moment, in UTC.
  final DateTime at;

  /// Metres, degrees Celsius or beats per minute.
  final double value;
}

/// An underwater diving workout as the platform channel delivers it: no
/// merging, no rounding, nothing dropped.
class HealthWorkout {
  const HealthWorkout({
    required this.uuid,
    required this.start,
    required this.end,
    required this.utcOffsetS,
    this.depth = const [],
    this.temperature = const [],
    this.heartRate = const [],
  });

  /// The HealthKit workout UUID, used as `sourceId`.
  final String uuid;

  /// Start and end in UTC.
  final DateTime start;
  final DateTime end;

  /// Seconds east of UTC at [start]: the workout's own time zone when the
  /// watch stored one, else the phone's. Worked out on the platform side,
  /// which has the time zone database.
  final int utcOffsetS;
  final List<HealthPoint> depth;
  final List<HealthPoint> temperature;
  final List<HealthPoint> heartRate;
}

/// Whether this phone can import from Apple Health.
enum HealthAvailability {
  available,

  /// iOS 15 and 16: the diving workout type exists from iOS 17 (T6.10).
  needsNewerIos,

  /// Android, or a device without the Health app.
  unavailable,
}

/// The platform side (`ios/Runner/HealthDiveChannel.swift`).
abstract interface class HealthStore {
  Future<HealthAvailability> availability();

  /// Shows the system dialog the first time. iOS never says whether read
  /// access was granted, so there is no result (T6.9).
  Future<void> requestReadAccess();

  /// Underwater diving workouts that start in [from]..[to].
  Future<List<HealthWorkout>> diveWorkouts(DateTime from, DateTime to);
}

/// Apple Health could not be read; the screen offers „Erneut versuchen“.
class HealthReadFailure implements Exception {
  const HealthReadFailure(this.reason);

  final String reason;

  @override
  String toString() => 'HealthReadFailure: $reason';
}

class HealthFetchResult {
  const HealthFetchResult(this.dives, {this.skippedWithoutDepth = 0});

  /// Newest first.
  final List<ImportedDive> dives;

  /// Diving workouts without any depth reading (T6.5).
  final int skippedWithoutDepth;
}

/// Dives from Apple Health (design.md §3).
abstract interface class HealthDiveSource {
  Future<HealthAvailability> availability();
  Future<void> requestPermission();

  /// Throws [HealthReadFailure].
  Future<HealthFetchResult> fetch({
    required DateTime from,
    required DateTime to,
  });
}

/// Start of the search (ui-spec §5.10, T6.7): a day before the newest dive
/// imported from Apple Health, else twelve months back. Null `since` means
/// no earlier import.
({DateTime from, DateTime? since}) healthImportFrom(
  List<Dive> dives,
  DateTime now,
) {
  DateTime? newest;
  for (final d in dives) {
    if (d.source != DiveSource.appleHealth) continue;
    if (newest == null || d.start.isAfter(newest)) newest = d.start;
  }
  if (newest == null) {
    final n = now.toUtc();
    return (
      from: DateTime.utc(n.year - 1, n.month, n.day, n.hour, n.minute),
      since: null,
    );
  }
  // The start is the wall clock flagged UTC; the day covers any offset.
  final since = newest.subtract(const Duration(days: 1));
  return (from: since, since: since);
}
