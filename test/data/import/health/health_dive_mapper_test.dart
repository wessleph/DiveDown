// T6.1, T6.3-T6.5: raw Apple Health workout → ImportedDive.
import 'package:divedown/data/import/health/health_dive_mapper.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/health_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/health_fixtures.dart';

void main() {
  test('T6.1 workout with depth, temperature and heart rate', () {
    final dive = mapHealthDive(elphinstoneWorkout())!;

    expect(dive.source, DiveSource.appleHealth);
    expect(dive.sourceId, elphinstoneUuid);
    // Wall clock in Cairo, stored UTC-flagged like every other source.
    expect(dive.start, DateTime.utc(2026, 11, 14, 12, 42));
    expect(dive.startInstant, elphinstoneStart);
    expect(dive.utcOffsetS, 7200);
    expect(dive.durationS, 2820);
    expect(dive.maxDepthM, closeTo(18.4, 0.001));
    expect(dive.avgDepthM, closeTo(12.3, 0.05)); // time-weighted
    expect(dive.minTemperatureC, closeTo(23, 0.01));
    expect(dive.maxTemperatureC, closeTo(24, 0.01));
    expect(dive.tanks, isEmpty);
    expect(dive.fingerprint, isNull);

    expect(dive.samples, hasLength(2821));
    final deepest = dive.samples[300];
    expect(deepest.timeS, 300);
    expect(deepest.depthM, closeTo(18.4, 0.001));
    expect(deepest.temperatureC, closeTo(24 - 300 / 2820, 0.001));
    expect(deepest.heartRate, 95); // 80 + 300 / 20
    expect(dive.samples.every((s) => s.pressures.isEmpty), isTrue);
  });

  test('T6.1 the offset from the platform decides the wall clock', () {
    // No time zone in the workout: the platform sends the phone's offset,
    // here Zurich in winter.
    final dive = mapHealthDive(elphinstoneWorkout(utcOffsetS: 3600))!;

    expect(dive.start, DateTime.utc(2026, 11, 14, 11, 42));
    expect(dive.utcOffsetS, 3600);
  });

  test('T6.3 unsorted depth, two readings in one second, one before start', () {
    final s = elphinstoneStart;
    DateTime at(int ms) => s.add(Duration(milliseconds: ms));
    final dive = mapHealthDive(
      HealthWorkout(
        uuid: 'u',
        start: s,
        end: at(3000),
        utcOffsetS: 0,
        depth: [
          HealthPoint(at(2000), 5),
          HealthPoint(at(1200), 12.0),
          HealthPoint(at(-1000), 1),
          HealthPoint(at(0), 0),
          HealthPoint(at(1700), 12.4),
        ],
      ),
    )!;

    expect([for (final x in dive.samples) x.timeS], [0, 1, 2]);
    expect([for (final x in dive.samples) x.depthM], [0, 12.4, 5]);
    expect(dive.maxDepthM, 12.4);
  });

  test('T6.3 readings after the end are dropped (review W3)', () {
    final s = elphinstoneStart;
    DateTime at(int t) => s.add(Duration(seconds: t));
    final dive = mapHealthDive(
      HealthWorkout(
        uuid: 'u',
        start: s,
        end: at(100),
        utcOffsetS: 0,
        depth: [
          HealthPoint(at(0), 0),
          HealthPoint(at(100), 3),
          HealthPoint(at(130), 25), // an overlapping series after the dive
        ],
      ),
    )!;

    expect([for (final x in dive.samples) x.timeS], [0, 100]);
    expect(dive.maxDepthM, 3);
  });

  test('T6.4 temperature and heart rate only within 30 s', () {
    final s = elphinstoneStart;
    DateTime at(int t) => s.add(Duration(seconds: t));
    final dive = mapHealthDive(
      HealthWorkout(
        uuid: 'u',
        start: s,
        end: at(200),
        utcOffsetS: 0,
        depth: [
          HealthPoint(at(0), 0),
          HealthPoint(at(100), 8),
          HealthPoint(at(200), 0),
        ],
        temperature: [HealthPoint(at(140), 21)], // 40 s to 100, 60 s to 200
        heartRate: [HealthPoint(at(120), 88)], // 20 s to 100
      ),
    )!;

    expect([for (final x in dive.samples) x.temperatureC], [null, null, null]);
    expect([for (final x in dive.samples) x.heartRate], [null, 88, null]);
    // The reading still counts for the dive's water temperature.
    expect(dive.minTemperatureC, 21);
  });

  test('T6.5 workout without depth readings is skipped', () {
    expect(mapHealthDive(elphinstoneWorkout(withDepth: false)), isNull);
  });
}
