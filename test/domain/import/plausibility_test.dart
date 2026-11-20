// T1.1-T1.10: plausibility check for every import source (security G1/A1).
import 'package:clock/clock.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:divedown/domain/import/plausibility.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 20, 12);

ImportedDive _dive({
  double maxDepthM = 18.4,
  int durationS = 47 * 60,
  DateTime? start,
  DateTime? startInstant,
  List<DiveSample>? samples,
}) => ImportedDive(
  source: DiveSource.diveComputer,
  sourceId: 'EON Core:5576006a',
  start: start ?? DateTime.utc(2026, 11, 14, 10, 42),
  startInstant: startInstant,
  durationS: durationS,
  maxDepthM: maxDepthM,
  minTemperatureC: 21,
  samples:
      samples ??
      [
        for (var t = 0; t <= 2820; t += 60)
          DiveSample(timeS: t, depthM: 10, temperatureC: 21),
      ],
);

PlausibilityResult _check(ImportedDive d) =>
    withClock(Clock.fixed(_now), () => checkPlausibility(d));

RejectReason? _reason(PlausibilityResult r) =>
    r is Implausible ? r.reason : null;

void main() {
  test('T1.1 18,4 m, 47 min, 21 °C is valid without warnings', () {
    final r = _check(_dive());
    expect(r, isA<Plausible>());
    r as Plausible;
    expect(r.warnings.isEmpty, isTrue);
    expect(r.dive.samples, hasLength(48));
  });

  test('T1.2 max depth 351 m is rejected', () {
    expect(
      _reason(_check(_dive(maxDepthM: 351))),
      RejectReason.depthOutOfRange,
    );
  });

  test('T1.3 max depth -1 m is rejected', () {
    expect(_reason(_check(_dive(maxDepthM: -1))), RejectReason.depthOutOfRange);
  });

  test('T1.4 duration 24 h + 1 s is rejected', () {
    expect(
      _reason(_check(_dive(durationS: 24 * 3600 + 1))),
      RejectReason.durationOutOfRange,
    );
  });

  test('T1.4 a negative duration is rejected', () {
    expect(
      _reason(_check(_dive(durationS: -1))),
      RejectReason.durationOutOfRange,
    );
  });

  test('T1.5 start 10 min in the future is rejected', () {
    final future = _now.add(const Duration(minutes: 10));
    expect(
      _reason(_check(_dive(start: future, startInstant: future))),
      RejectReason.startInFuture,
    );
  });

  test('T1.5 without UTC instant the wall clock is compared, with a day '
      'of slack for unknown time zones', () {
    // Device clock in UTC+14 shows a time 10 h ahead of UTC: still fine.
    expect(
      _check(_dive(start: _now.add(const Duration(hours: 10)))),
      isA<Plausible>(),
    );
    expect(
      _reason(_check(_dive(start: _now.add(const Duration(hours: 15))))),
      RejectReason.startInFuture,
    );
  });

  test('T1.6 three samples at 80 °C are dropped, the dive stays', () {
    final samples = [
      for (var t = 0; t <= 600; t += 60)
        DiveSample(
          timeS: t,
          depthM: 10,
          temperatureC: t >= 120 && t <= 240 ? 80 : 21,
        ),
    ];
    final r = _check(_dive(samples: samples));

    expect(r, isA<Plausible>());
    r as Plausible;
    expect(r.warnings.samplesDropped, 3);
    expect(r.dive.samples, hasLength(samples.length - 3));
    expect(r.dive.samples.map((s) => s.timeS), isNot(contains(180)));
  });

  test('T1.6 samples with depth out of range are dropped too', () {
    final r = _check(
      _dive(
        samples: const [
          DiveSample(timeS: 0, depthM: 0),
          DiveSample(timeS: 60, depthM: 400),
          DiveSample(timeS: 120, depthM: 12),
        ],
      ),
    );
    r as Plausible;
    expect(r.warnings.samplesDropped, 1);
    expect(r.dive.samples.map((s) => s.timeS), [0, 120]);
  });

  test('T1.7 a pressure of 450 bar is dropped, the sample stays', () {
    final r = _check(
      _dive(
        samples: const [
          DiveSample(
            timeS: 0,
            depthM: 0,
            pressures: [TankPressure(tankIndex: 0, pressureBar: 200)],
          ),
          DiveSample(
            timeS: 60,
            depthM: 10,
            pressures: [
              TankPressure(tankIndex: 0, pressureBar: 450),
              TankPressure(tankIndex: 1, pressureBar: 180),
            ],
          ),
        ],
      ),
    );
    r as Plausible;
    expect(r.warnings.pressuresDropped, 1);
    expect(r.warnings.samplesDropped, 0);
    expect(r.dive.samples, hasLength(2));
    expect(r.dive.samples[1].pressures.map((p) => p.tankIndex), [1]);
  });

  test('T1.8 100.001 samples are rejected', () {
    final r = _check(
      _dive(
        samples: [
          for (var i = 0; i < maxSamplesPerDive + 1; i++)
            DiveSample(timeS: i, depthM: 5),
        ],
      ),
    );
    expect(_reason(r), RejectReason.tooManySamples);
  });

  test('T1.9 samples out of order are sorted, duplicates removed', () {
    final r = _check(
      _dive(
        samples: const [
          DiveSample(timeS: 10, depthM: 3),
          DiveSample(timeS: 10, depthM: 3),
          DiveSample(timeS: 5, depthM: 1),
        ],
      ),
    );
    r as Plausible;
    expect(r.dive.samples.map((s) => s.timeS), [5, 10]);
    expect(r.warnings.samplesReordered, isTrue);
    expect(r.warnings.samplesDropped, 1);
  });

  test('T1.10 limits are inclusive', () {
    final r = _check(
      _dive(
        maxDepthM: 350,
        durationS: 24 * 3600,
        samples: const [
          DiveSample(
            timeS: 0,
            depthM: 0,
            temperatureC: -5,
            pressures: [TankPressure(tankIndex: 0, pressureBar: 400)],
          ),
          DiveSample(
            timeS: 60,
            depthM: 350,
            temperatureC: 45,
            pressures: [TankPressure(tankIndex: 0, pressureBar: 0)],
          ),
        ],
      ),
    );
    expect(r, isA<Plausible>());
    expect((r as Plausible).warnings.isEmpty, isTrue);
    expect(_check(_dive(maxDepthM: 0)), isA<Plausible>());
  });
}
