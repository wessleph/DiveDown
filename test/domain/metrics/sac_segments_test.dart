// T7.3: SAC curve in fixed one-minute segments (design.md §6, ui-spec §6).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/metrics/sac_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Samples every 10 s at [depth] with the pressure of tank 0 from
/// [pressure] (null: no reading in that sample).
Dive _dive({
  required int endS,
  required double? Function(int t) pressure,
  double Function(int t)? depth,
  double? volumeL = 12,
}) => Dive(
  diverId: 'd',
  source: DiveSource.diveComputer,
  start: DateTime.utc(2026, 11, 14, 10),
  durationS: endS,
  maxDepthM: 10,
  waterType: WaterType.salt,
  tanks: [DiveTank(index: 0, volumeL: volumeL)],
  samples: [
    for (var t = 0; t <= endS; t += 10)
      DiveSample(
        timeS: t,
        depthM: depth?.call(t) ?? 10,
        pressures: [
          if (pressure(t) case final p?)
            TankPressure(tankIndex: 0, pressureBar: p),
        ],
      ),
  ],
);

void main() {
  const sac = SacCalculator();
  // 3 bar/min × 12 l at 10 m salt water (2,005 bar).
  const perMinute = 3 * 12 / 2.005;

  test('T7.3 steady 3 bar/min: 50 segments of one minute, same value', () {
    final segments = sac.segments(
      _dive(endS: 3000, pressure: (t) => 200 - t / 20),
    );

    expect(segments, hasLength(50));
    expect(segments.first.startS, 0);
    expect(segments.first.endS, 60);
    expect(segments.last.endS, 3000);
    for (final s in segments) {
      expect(s.litresPerMinute, closeTo(perMinute, 0.01));
    }
  });

  test('T7.3 a minute without pressure change is 0, a rise never negative', () {
    double p(int t) => switch (t) {
      < 120 => 200 - t / 20, // falls 3 bar/min
      < 180 => 194, // minute 3: no change
      < 240 => 194 + (t - 180) / 30, // minute 4: sensor rises 2 bar
      _ => 196 - (t - 240) / 20,
    };
    final segments = sac.segments(_dive(endS: 300, pressure: p));

    expect([for (final s in segments) s.startS], [0, 60, 120, 180, 240]);
    expect(segments[2].litresPerMinute, 0);
    expect(segments[3].litresPerMinute, 0);
    expect(segments[4].litresPerMinute, closeTo(perMinute, 0.01));
  });

  test('T7.3 the last, shorter segment is per minute too', () {
    final segments = sac.segments(
      _dive(endS: 150, pressure: (t) => 200 - t / 20),
    );

    expect(segments.last.startS, 120);
    expect(segments.last.endS, 150);
    expect(segments.last.litresPerMinute, closeTo(perMinute, 0.01));
  });

  test('T7.3 ambient pressure of the segment\'s own depth', () {
    // 20 m in the second minute: 3,01 bar.
    final segments = sac.segments(
      _dive(
        endS: 120,
        pressure: (t) => 200 - t / 20,
        depth: (t) => t < 60 ? 10 : 20,
      ),
    );

    expect(segments[0].litresPerMinute, closeTo(perMinute, 0.2));
    expect(segments[1].litresPerMinute, closeTo(3 * 12 / 3.01, 0.2));
  });

  test('T7.3 readings only every 30 s: interpolated at the boundaries', () {
    final segments = sac.segments(
      _dive(endS: 180, pressure: (t) => t % 30 == 0 ? 200 - t / 20 : null),
    );

    expect(segments, hasLength(3));
    for (final s in segments) {
      expect(s.litresPerMinute, closeTo(perMinute, 0.01));
    }
  });

  test('T7.3 no pressure samples or no tank size: no curve', () {
    expect(sac.segments(_dive(endS: 300, pressure: (_) => null)), isEmpty);
    expect(
      sac.segments(
        _dive(endS: 300, pressure: (t) => 200 - t / 20, volumeL: null),
      ),
      isEmpty,
    );
  });
}
