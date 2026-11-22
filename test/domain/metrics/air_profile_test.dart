// T22.1-T22.6: air at one moment of the dive (ui-spec §6).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/metrics/air_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive({
  required List<DiveSample> samples,
  List<DiveTank> tanks = const [
    DiveTank(index: 0, volumeL: 12, startPressureBar: 200, endPressureBar: 50),
  ],
}) => Dive(
  diverId: 'd',
  source: DiveSource.diveComputer,
  start: DateTime.utc(2026, 11, 13, 7, 54),
  durationS: samples.last.timeS,
  maxDepthM: samples.map((s) => s.depthM).reduce((a, b) => a > b ? a : b),
  waterType: WaterType.salt,
  samples: samples,
  tanks: tanks,
);

/// 60 min at a constant 10 m, a sample every minute.
List<DiveSample> _flat10m() => [
  for (var m = 0; m <= 60; m++) DiveSample(timeS: m * 60, depthM: 10),
];

/// 30 min at 20 m, then 30 min at 5 m.
List<DiveSample> _twoLevels() => [
  for (var m = 0; m <= 60; m++)
    DiveSample(timeS: m * 60, depthM: m <= 30 ? 20 : 5),
];

void main() {
  group('estimated from start and end pressure', () {
    test('T22.1 constant depth: linear between start and end', () {
      final air = AirProfile(_dive(samples: _flat10m()));
      final start = air.at(0);
      final half = air.at(1800);
      final end = air.at(3600);
      expect(half.source, AirSource.estimated);
      expect(start.pressureBar, closeTo(200, 0.01));
      expect(start.usedLitres, closeTo(0, 0.01));
      expect(half.pressureBar, closeTo(125, 0.5));
      expect(half.usedLitres, closeTo(900, 6)); // (200 − 50) × 12 / 2
      expect(end.pressureBar, closeTo(50, 0.01));
      expect(end.usedLitres, closeTo(1800, 0.01));
    });

    test('T22.2 deeper part uses more air (time × ambient pressure)', () {
      final air = AirProfile(_dive(samples: _twoLevels()));
      // Ambient pressure 1 + 20 × 0,1005 = 3,01 bar for the first half and
      // 1 + 5 × 0,1005 = 1,5025 bar for the second (salt water, as
      // SacCalculator): the first half takes 3,01 / 4,5125 of the gas.
      final used = air.at(1800).usedLitres!;
      expect(used, closeTo(1800 * 3.01 / 4.5125, 15));
      expect(air.at(3600).usedLitres, closeTo(1800, 0.01));
    });

    test('T22.3 air now = average SAC × ambient pressure at that depth', () {
      final air = AirProfile(_dive(samples: _twoLevels()));
      // Average SAC over the dive: 1800 l / (30 min × 3,01 + 30 min × 1,5025).
      const sac = 1800 / (30 * 3.01 + 30 * 1.5025);
      expect(air.at(600).litresPerMinuteNow, closeTo(sac * 3.01, 0.5));
      expect(air.at(2700).litresPerMinuteNow, closeTo(sac * 1.5025, 0.5));
    });

    test('T22.3 times outside the dive are clamped, not an error', () {
      final air = AirProfile(_dive(samples: _flat10m()));
      expect(air.at(-5).usedLitres, closeTo(0, 0.01));
      expect(air.at(99999).pressureBar, closeTo(50, 0.01));
    });
  });

  test('T22.4 measured when the samples carry tank pressure', () {
    final samples = [
      for (var m = 0; m <= 60; m++)
        DiveSample(
          timeS: m * 60,
          depthM: 10,
          pressures: [TankPressure(tankIndex: 0, pressureBar: 200 - m * 2.5)],
        ),
    ];
    final air = AirProfile(_dive(samples: samples));
    final at = air.at(1200); // 20 min: 200 − 50 = 150 bar
    expect(at.source, AirSource.measured);
    expect(at.pressureBar, closeTo(150, 0.01));
    expect(at.usedLitres, closeTo(600, 0.01)); // 50 bar × 12 l
    // 2,5 bar/min × 12 l = 30 l/min at 10 m.
    expect(at.litresPerMinuteNow, closeTo(30, 0.5));
  });

  test('T22.5 measured wins over start/end pressure of the tank', () {
    final samples = [
      for (var m = 0; m <= 10; m++)
        DiveSample(
          timeS: m * 60,
          depthM: 10,
          pressures: [TankPressure(tankIndex: 0, pressureBar: 210 - m * 3.0)],
        ),
    ];
    final air = AirProfile(_dive(samples: samples));
    expect(air.at(0).source, AirSource.measured);
    expect(air.at(0).pressureBar, closeTo(210, 0.01));
  });

  group('T22.6 missing data', () {
    test('no pressure at all', () {
      final air = AirProfile(
        _dive(
          samples: _flat10m(),
          tanks: const [DiveTank(index: 0, volumeL: 12)],
        ),
      );
      expect(air.at(600).missing, AirMissing.pressure);
      expect(air.at(600).pressureBar, isNull);
    });

    test('no tank at all', () {
      final air = AirProfile(_dive(samples: _flat10m(), tanks: const []));
      expect(air.at(600).missing, AirMissing.pressure);
    });

    test('pressure but no volume', () {
      final air = AirProfile(
        _dive(
          samples: _flat10m(),
          tanks: const [
            DiveTank(index: 0, startPressureBar: 200, endPressureBar: 50),
          ],
        ),
      );
      expect(air.at(600).missing, AirMissing.volume);
    });

    test('no samples: nothing to spread over', () {
      final dive = _dive(samples: _flat10m()).copyWith(samples: const []);
      expect(AirProfile(dive).at(600).missing, AirMissing.pressure);
    });
  });
}
