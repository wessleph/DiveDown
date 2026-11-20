// T4.1-T4.4, T4.6-T4.10: ParsedDive → ImportedDive (ADR 0003).
// T4.5 (real EON Core dumps) runs on the phone, see integration_test/.
import 'package:divedown/data/import/divecomputer/parsed_dive_adapter.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/units/unit_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

dc.ParsedDive _parsed({
  int? tzOffset,
  double avgDepth = 10,
  double? minTemp = 21,
  double? maxTemp = 23,
  List<dc.ProfileSample>? samples,
  List<dc.TankInfo> tanks = const [],
  List<dc.GasMix> gasMixes = const [],
  List<dc.DiveEvent> events = const [],
}) => dc.ParsedDive(
  fingerprint: '5576006a',
  dateTimeYear: 2026,
  dateTimeMonth: 11,
  dateTimeDay: 14,
  dateTimeHour: 10,
  dateTimeMinute: 42,
  dateTimeSecond: 7,
  dateTimeTimezoneOffset: tzOffset,
  maxDepthMeters: 18.4,
  avgDepthMeters: avgDepth,
  durationSeconds: 2820,
  minTemperatureCelsius: minTemp,
  maxTemperatureCelsius: maxTemp,
  samples:
      samples ??
      [
        dc.ProfileSample(timeSeconds: 0, depthMeters: 0),
        dc.ProfileSample(timeSeconds: 60, depthMeters: 18.4),
      ],
  tanks: tanks,
  gasMixes: gasMixes,
  events: events,
);

void main() {
  test('T4.1 with time zone: wall clock as shown, instant in UTC', () {
    final d = importedFromParsedDive(
      _parsed(tzOffset: 7200),
      product: 'EON Core',
    );

    expect(d.start.hour, 10);
    expect(d.start.minute, 42);
    expect(d.start.second, 7);
    expect(d.startInstant, DateTime.utc(2026, 11, 14, 8, 42, 7));
    expect(d.utcOffsetS, 7200);
  });

  test('T4.2 without time zone: device time, no instant', () {
    final d = importedFromParsedDive(_parsed(), product: 'EON Core');

    expect(
      [d.start.year, d.start.month, d.start.day, d.start.hour, d.start.minute],
      [2026, 11, 14, 10, 42],
    );
    expect(d.startInstant, isNull);
    expect(d.utcOffsetS, isNull);
  });

  test('T4.3 per-tank pressures with gaps keep their tank index', () {
    final d = importedFromParsedDive(
      _parsed(
        samples: [
          dc.ProfileSample(
            timeSeconds: 60,
            depthMeters: 10,
            tankPressuresBar: [200.0, null, 180.0],
          ),
        ],
      ),
      product: 'EON Core',
    );

    final p = d.samples.single.pressures;
    expect(p.map((x) => x.tankIndex), [0, 2]);
    expect(p.map((x) => x.pressureBar), [200.0, 180.0]);
  });

  test('T4.3 a single pressure with tank index is used without the list', () {
    final d = importedFromParsedDive(
      _parsed(
        samples: [
          dc.ProfileSample(
            timeSeconds: 60,
            depthMeters: 10,
            pressureBar: 150,
            tankIndex: 1,
          ),
        ],
      ),
      product: 'EON Core',
    );

    final p = d.samples.single.pressures.single;
    expect(p.tankIndex, 1);
    expect(p.pressureBar, 150);
  });

  test('T4.4 gas O₂ 32 % / He 0 % becomes EAN32 on its tank', () {
    final d = importedFromParsedDive(
      _parsed(
        gasMixes: [dc.GasMix(index: 0, o2Percent: 32, hePercent: 0)],
        tanks: [
          dc.TankInfo(
            index: 0,
            gasMixIndex: 0,
            volumeLiters: 12,
            startPressureBar: 200,
            endPressureBar: 50,
          ),
        ],
      ),
      product: 'EON Core',
    );

    final tank = d.tanks.single;
    expect(tank.index, 0);
    expect(tank.volumeL, 12);
    expect(tank.startPressureBar, 200);
    expect(tank.endPressureBar, 50);
    expect(tank.gas!.o2, closeTo(0.32, 1e-9));
    expect(tank.gas!.he, 0);
    expect(const UnitFormatter.metric().gas(tank.gas!), 'EAN32');
  });

  test('T4.4 a gas mix without tank becomes a tank without volume', () {
    final d = importedFromParsedDive(
      _parsed(gasMixes: [dc.GasMix(index: 0, o2Percent: 21, hePercent: 35)]),
      product: 'EON Core',
    );

    expect(d.tanks.single.volumeL, isNull);
    expect(d.tanks.single.gas!.he, closeTo(0.35, 1e-9));
  });

  test('T4.6 mean depth 0 from the device is computed from the samples', () {
    final d = importedFromParsedDive(
      _parsed(
        avgDepth: 0,
        samples: [
          dc.ProfileSample(timeSeconds: 0, depthMeters: 10),
          dc.ProfileSample(timeSeconds: 600, depthMeters: 10),
          dc.ProfileSample(timeSeconds: 1200, depthMeters: 20),
        ],
      ),
      product: 'EON Core',
    );

    // Trapezoids: (10 × 600 + 15 × 600) / 1200 = 12,5 m
    expect(d.avgDepthM, closeTo(12.5, 1e-9));
  });

  test('T4.6 mean depth 0 without samples stays unknown, not 0', () {
    final d = importedFromParsedDive(
      _parsed(avgDepth: 0, samples: const []),
      product: 'EON Core',
    );
    expect(d.avgDepthM, isNull);
  });

  test('T4.7 missing temperatures come from the samples', () {
    final d = importedFromParsedDive(
      _parsed(
        minTemp: null,
        maxTemp: null,
        samples: [
          dc.ProfileSample(
            timeSeconds: 0,
            depthMeters: 0,
            temperatureCelsius: 24,
          ),
          dc.ProfileSample(
            timeSeconds: 60,
            depthMeters: 10,
            temperatureCelsius: 21.5,
          ),
          dc.ProfileSample(timeSeconds: 120, depthMeters: 5),
        ],
      ),
      product: 'EON Core',
    );

    expect(d.minTemperatureC, 21.5);
    expect(d.maxTemperatureC, 24);
  });

  test('T4.8 source and id: dive computer, product and fingerprint', () {
    final d = importedFromParsedDive(_parsed(), product: 'EON Core');

    expect(d.source, DiveSource.diveComputer);
    expect(d.sourceId, 'EON Core:5576006a');
    expect(d.fingerprint, [0x55, 0x76, 0x00, 0x6a]);
    expect(d.maxDepthM, 18.4);
    expect(d.durationS, 2820);
  });

  test('T4.9 events keep time, type and their data as text', () {
    final d = importedFromParsedDive(
      _parsed(
        events: [
          dc.DiveEvent(timeSeconds: 600, type: 'gaschange', data: {'mix': '1'}),
          dc.DiveEvent(timeSeconds: 2400, type: 'safetystop'),
        ],
      ),
      product: 'EON Core',
    );

    expect(d.events.map((e) => (e.timeS, e.type)), [
      (600, 'gaschange'),
      (2400, 'safetystop'),
    ]);
    expect(d.events[0].value, 'mix=1');
    expect(d.events[1].value, isNull);
  });

  test('T4.11 split samples with the same time are merged (EON Core)', () {
    // Seen in the real dumps: depth first, temperature in a second sample.
    final d = importedFromParsedDive(
      _parsed(
        samples: [
          dc.ProfileSample(timeSeconds: 0, depthMeters: 1.24),
          dc.ProfileSample(
            timeSeconds: 0,
            depthMeters: 1.24,
            temperatureCelsius: 20.8,
          ),
          dc.ProfileSample(
            timeSeconds: 10,
            depthMeters: 2.6,
            tankPressuresBar: [200.0],
          ),
          dc.ProfileSample(
            timeSeconds: 10,
            depthMeters: 2.63,
            temperatureCelsius: 20.9,
            tankPressuresBar: [null, 180.0],
          ),
        ],
      ),
      product: 'EON Core',
    );

    expect(d.samples, hasLength(2));
    expect(d.samples[0].depthM, 1.24);
    expect(d.samples[0].temperatureC, 20.8);
    final s = d.samples[1];
    expect(s.depthM, 2.63, reason: 'the later value wins');
    expect(s.temperatureC, 20.9);
    expect(s.pressures.map((p) => (p.tankIndex, p.pressureBar)), [
      (0, 200.0),
      (1, 180.0),
    ]);
  });

  test('T4.10 samples: temperature, heart rate, NDL and deco', () {
    final d = importedFromParsedDive(
      _parsed(
        samples: [
          // libdivecomputer: decoType 0 = NDL, 2 = deco stop.
          dc.ProfileSample(
            timeSeconds: 60,
            depthMeters: 12,
            temperatureCelsius: 21,
            heartRate: 80,
            decoType: 0,
            decoTime: 1500,
            gasMixIndex: 0,
          ),
          dc.ProfileSample(
            timeSeconds: 120,
            depthMeters: 30,
            decoType: 2,
            decoTime: 180,
            decoDepth: 3,
          ),
        ],
      ),
      product: 'EON Core',
    );

    final ndl = d.samples[0];
    expect(ndl.depthM, 12);
    expect(ndl.temperatureC, 21);
    expect(ndl.heartRate, 80);
    expect(ndl.ndlS, 1500);
    expect(ndl.decoCeilingM, isNull);
    expect(ndl.gasIndex, 0);
    final deco = d.samples[1];
    expect(deco.ndlS, isNull);
    expect(deco.decoCeilingM, 3);
    expect(deco.decoTimeS, 180);
  });
}
