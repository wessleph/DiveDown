// Hand-built Apple Health workouts for T6 (no real export yet, see tasks.md).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/health_import.dart';
import 'package:divedown/domain/import/imported_dive.dart';

/// 14.11.2026, 10:42-11:29 UTC (12:42 in Cairo), 47 min.
final elphinstoneStart = DateTime.utc(2026, 11, 14, 10, 42);
const elphinstoneUuid = '7C1E5B2A-9F3D-4E61-8A7B-2C4D6E8F0A1B';

/// Depth in metres at second [t]: down to 18,4 m at 5 min, slowly up to
/// 10 m at 40 min, then to the surface.
double elphinstoneDepth(int t) => t < 300
    ? 18.4 * t / 300
    : t < 2400
    ? 18.4 - (t - 300) * 8.4 / 2100
    : 10 * (2820 - t) / 420;

/// Depth every second, water temperature every 10 s (24 → 23 °C), heart
/// rate every 5 s (80-100 /min). Seconds east of UTC: Cairo, +2 h.
HealthWorkout elphinstoneWorkout({
  String uuid = elphinstoneUuid,
  DateTime? start,
  int utcOffsetS = 7200,
  bool withDepth = true,
}) {
  final s = start ?? elphinstoneStart;
  DateTime at(int t) => s.add(Duration(seconds: t));
  return HealthWorkout(
    uuid: uuid,
    start: s,
    end: at(2820),
    utcOffsetS: utcOffsetS,
    depth: withDepth
        ? [
            for (var t = 0; t <= 2820; t++)
              HealthPoint(at(t), elphinstoneDepth(t)),
          ]
        : const [],
    temperature: [
      for (var t = 0; t <= 2820; t += 10) HealthPoint(at(t), 24 - t / 2820),
    ],
    heartRate: [
      for (var t = 0; t <= 2820; t += 5)
        HealthPoint(at(t), 80 + (t % 400) / 20),
    ],
  );
}

/// The same dive as the mapper should make it, built by hand so UI tests do
/// not depend on the mapper: one sample per minute, heart rate 95 at the
/// deepest point (5:00).
ImportedDive elphinstoneImported() => ImportedDive(
  source: DiveSource.appleHealth,
  sourceId: elphinstoneUuid,
  start: DateTime.utc(2026, 11, 14, 12, 42),
  startInstant: elphinstoneStart,
  utcOffsetS: 7200,
  durationS: 2820,
  maxDepthM: 18.4,
  avgDepthM: 12.3,
  minTemperatureC: 23,
  maxTemperatureC: 24,
  samples: [
    for (var t = 0; t <= 2820; t += 60)
      DiveSample(
        timeS: t,
        depthM: elphinstoneDepth(t),
        temperatureC: 24 - t / 2820,
        heartRate: (80 + (t % 400) / 20).round(),
      ),
  ],
);
