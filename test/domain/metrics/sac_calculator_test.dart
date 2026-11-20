// T7.1, T7.2, T7.4, T7.5, T7.7, T7.8: average SAC (tasks.md, design.md §6).
// T7.3 (curve) and T7.6 (gas switch) follow with the profile chart.
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/metrics/sac_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive({
  double? volumeL = 12,
  double? startBar = 200,
  double? endBar = 50,
  int durationS = 50 * 60,
  double? avgDepthM = 10,
  WaterType? waterType = WaterType.salt,
  List<DiveSample> samples = const [],
}) {
  return Dive(
    diverId: 'd',
    source: DiveSource.manual,
    start: DateTime.utc(2026, 11, 14, 10),
    durationS: durationS,
    maxDepthM: 18,
    avgDepthM: avgDepthM,
    waterType: waterType,
    samples: samples,
    tanks: [
      DiveTank(
        index: 0,
        volumeL: volumeL,
        startPressureBar: startBar,
        endPressureBar: endBar,
      ),
    ],
  );
}

void main() {
  const sac = SacCalculator();

  test('T7.1: 12 l, 200 -> 50 bar, 50 min at 10 m salt = 18,0 l/min', () {
    final r = sac.average(_dive());
    expect(r.missing, isNull);
    expect(r.litresPerMinute, closeTo(18.0, 0.1));
  });

  test('T7.2: fresh water uses 9,81 kPa/m', () {
    final r = sac.average(_dive(waterType: WaterType.fresh));
    // (150 × 12) / (50 × (1 + 10 × 0.0981)) = 18,17
    expect(r.litresPerMinute, closeTo(1800 / (50 * 1.981), 0.01));
    expect(
      r.litresPerMinute,
      greaterThan(sac.average(_dive()).litresPerMinute!),
    );
  });

  test('T7.2: unknown water type counts as salt water', () {
    expect(
      sac.average(_dive(waterType: null)).litresPerMinute,
      closeTo(1800 / (50 * 2.005), 0.01),
    );
  });

  test('T7.4: no pressure -> no value, reason pressure', () {
    final r = sac.average(_dive(startBar: null, endBar: null));
    expect(r.litresPerMinute, isNull);
    expect(r.missing, SacMissing.pressure);
  });

  test('T7.4: no tank at all -> reason pressure', () {
    final r = sac.average(_dive().copyWith(tanks: const []));
    expect(r.missing, SacMissing.pressure);
  });

  test('T7.5: pressure but no tank volume -> reason volume', () {
    final r = sac.average(_dive(volumeL: null));
    expect(r.litresPerMinute, isNull);
    expect(r.missing, SacMissing.volume);
  });

  test('T7.7: duration 0 -> no value, no division by zero', () {
    final r = sac.average(_dive(durationS: 0));
    expect(r.litresPerMinute, isNull);
    expect(r.missing, SacMissing.duration);
  });

  test('T7.8: no mean depth and no samples -> reason depth', () {
    final r = sac.average(_dive(avgDepthM: null));
    expect(r.missing, SacMissing.depth);
  });

  test('T7.8: no mean depth, but samples -> time-weighted sample mean', () {
    // 0..50 min at a constant 10 m, so the mean is 10 m as in T7.1.
    final r = sac.average(
      _dive(
        avgDepthM: null,
        samples: [
          for (var t = 0; t <= 3000; t += 60) DiveSample(timeS: t, depthM: 10),
        ],
      ),
    );
    expect(r.litresPerMinute, closeTo(18.0, 0.1));
  });
}
