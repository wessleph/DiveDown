// Turns a raw Apple Health workout into an ImportedDive (T6.1-T6.5).
//
// Derived from Submersion (GPL-3.0),
// lib/features/dive_import/data/services/healthkit_service.dart,
// commit 4e638982:
// deepest reading per second, temperature and heart rate matched to the
// nearest depth point within 30 s, wall-clock start. Rewritten for
// DiveDown's model; see THIRD_PARTY.md.

import 'dart:math' as math;

import '../../../domain/dive/dive.dart';
import '../../../domain/import/health_import.dart';
import '../../../domain/import/imported_dive.dart';
import '../../../domain/metrics/profile_stats.dart';

/// Widest gap between a depth point and a temperature or heart rate reading
/// for the two to belong together.
const healthMatchWindow = Duration(seconds: 30);

/// The dive for [workout]; null without any depth reading (T6.5).
ImportedDive? mapHealthDive(HealthWorkout workout) {
  final start = workout.start.toUtc();
  final durationS = workout.end.toUtc().difference(start).inSeconds;

  // HealthKit can hold several readings of the same second from different
  // sources; the deepest one counts.
  final deepest = <int, double>{};
  for (final p in workout.depth) {
    final ms = p.at.toUtc().difference(start).inMilliseconds;
    if (ms < 0) continue;
    final second = ms ~/ 1000;
    final known = deepest[second];
    if (known == null || p.value > known) deepest[second] = p.value;
  }
  if (deepest.isEmpty) return null;

  final temperature = _sorted(workout.temperature);
  final heartRate = _sorted(workout.heartRate);
  final seconds = deepest.keys.toList()..sort();
  final samples = [
    for (final t in seconds)
      DiveSample(
        timeS: t,
        depthM: deepest[t]!,
        temperatureC: _nearest(temperature, start.add(Duration(seconds: t))),
        heartRate: _nearest(
          heartRate,
          start.add(Duration(seconds: t)),
        )?.round(),
      ),
  ];

  final end = workout.end.toUtc();
  final temps = [
    for (final p in temperature)
      if (!p.at.isBefore(start) && !p.at.isAfter(end)) p.value,
  ];

  return ImportedDive(
    source: DiveSource.appleHealth,
    sourceId: workout.uuid,
    // The wall clock the diver saw, flagged UTC like every other source.
    start: start.add(Duration(seconds: workout.utcOffsetS)),
    startInstant: start,
    utcOffsetS: workout.utcOffsetS,
    durationS: durationS,
    maxDepthM: samples.map((s) => s.depthM).reduce(math.max),
    avgDepthM: meanDepthFromSamples(samples),
    minTemperatureC: temps.isEmpty ? null : temps.reduce(math.min),
    maxTemperatureC: temps.isEmpty ? null : temps.reduce(math.max),
    samples: samples,
  );
}

List<HealthPoint> _sorted(List<HealthPoint> points) =>
    [...points]..sort((a, b) => a.at.compareTo(b.at));

/// Value of the reading nearest to [at] within [healthMatchWindow].
/// [series] is sorted by time.
double? _nearest(List<HealthPoint> series, DateTime at) {
  if (series.isEmpty) return null;
  var low = 0;
  var high = series.length;
  while (low < high) {
    final mid = (low + high) ~/ 2;
    if (series[mid].at.isBefore(at)) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  HealthPoint? best;
  var gap = healthMatchWindow + const Duration(microseconds: 1);
  for (final i in [low - 1, low]) {
    if (i < 0 || i >= series.length) continue;
    final d = series[i].at.difference(at).abs();
    if (d < gap) {
      best = series[i];
      gap = d;
    }
  }
  return best?.value;
}
