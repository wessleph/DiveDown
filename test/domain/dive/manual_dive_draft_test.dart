// T15.18, T15.19: manual entry form logic (ui-spec §5.4, security G1).
import 'package:clock/clock.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/manual_dive_draft.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 20, 12);

ManualDiveDraft _valid({
  String number = '6',
  DateTime? start,
  String duration = '47',
  String maxDepth = '18,4',
  String avgDepth = '',
  String temperature = '',
  String tankVolume = '',
  String startPressure = '',
  String endPressure = '',
  String o2 = '',
}) {
  return ManualDiveDraft(
    number: number,
    siteName: 'Walensee, Quinten',
    start: start ?? DateTime(2026, 11, 14, 10, 42),
    duration: duration,
    maxDepth: maxDepth,
    avgDepth: avgDepth,
    temperature: temperature,
    tankVolume: tankVolume,
    startPressure: startPressure,
    endPressure: endPressure,
    o2: o2,
  );
}

Map<ManualDiveField, ManualDiveError> _check(ManualDiveDraft d) =>
    withClock(Clock.fixed(_now), d.validate);

/// An imported dive with values the form shows rounded.
Dive _imported() => Dive(
  id: 'dive-1',
  diverId: 'diver-1',
  number: 42,
  siteName: 'SS Thistlegorm',
  siteCatalogueId: 'osm_123',
  siteLat: 27.81361,
  siteLon: 33.92139,
  diveComputerId: 'dc-1',
  source: DiveSource.diveComputer,
  sourceId: 'eon-3F7A-1',
  start: DateTime.utc(2026, 11, 14, 10, 42, 7),
  utcOffsetS: 7200,
  durationS: 2827,
  maxDepthM: 29.87,
  avgDepthM: 17.123456,
  minTemperatureC: 23.4,
  maxTemperatureC: 26.1,
  waterType: WaterType.salt,
  notes: 'Strömung von Nord',
  rating: 4,
  tanks: const [
    DiveTank(
      index: 0,
      volumeL: 12,
      startPressureBar: 200,
      endPressureBar: 50,
      gas: GasMix(o2: 0.32),
    ),
    DiveTank(index: 1, volumeL: 7, gas: GasMix(o2: 0.21, he: 0.35)),
  ],
  samples: const [
    DiveSample(timeS: 0, depthM: 0),
    DiveSample(timeS: 60, depthM: 12.5),
  ],
  events: const [DiveEvent(timeS: 600, type: 'gaschange', value: '1')],
);

void main() {
  group('T15.18 validate', () {
    test('a valid draft has no errors', () {
      expect(_check(_valid()), isEmpty);
    });

    test('duration and max depth are required', () {
      expect(_check(_valid(duration: '', maxDepth: '')), {
        ManualDiveField.duration: ManualDiveError.required,
        ManualDiveField.maxDepth: ManualDiveError.required,
      });
    });

    test('errors come in screen order, so the first gets the focus', () {
      final errors = _check(_valid(o2: '120', maxDepth: '400', duration: ''));
      expect(errors.keys.toList(), [
        ManualDiveField.duration,
        ManualDiveField.maxDepth,
        ManualDiveField.o2,
      ]);
    });

    test('decimal comma and point are both accepted', () {
      expect(_check(_valid(maxDepth: '18,4')), isEmpty);
      expect(_check(_valid(maxDepth: '18.4')), isEmpty);
      expect(_check(_valid(maxDepth: ' 18,4 ')), isEmpty);
    });

    test('text that is not a number', () {
      expect(_check(_valid(maxDepth: 'tief')), {
        ManualDiveField.maxDepth: ManualDiveError.notANumber,
      });
    });

    test('limits are inclusive: 0 and 350 m ok, 350,1 m not (T12.15)', () {
      expect(_check(_valid(maxDepth: '0')), isEmpty);
      expect(_check(_valid(maxDepth: '350')), isEmpty);
      expect(_check(_valid(maxDepth: '350,1')), {
        ManualDiveField.maxDepth: ManualDiveError.depthOutOfRange,
      });
      expect(_check(_valid(maxDepth: '400')), {
        ManualDiveField.maxDepth: ManualDiveError.depthOutOfRange,
      });
      expect(_check(_valid(maxDepth: '-1')), {
        ManualDiveField.maxDepth: ManualDiveError.depthOutOfRange,
      });
    });

    test('duration 1 to 1440 min (below 24 h + 1 s)', () {
      expect(_check(_valid(duration: '1')), isEmpty);
      expect(_check(_valid(duration: '1440')), isEmpty);
      expect(_check(_valid(duration: '0')), {
        ManualDiveField.duration: ManualDiveError.durationOutOfRange,
      });
      expect(_check(_valid(duration: '1441')), {
        ManualDiveField.duration: ManualDiveError.durationOutOfRange,
      });
    });

    test('mean depth within limits and not deeper than max depth', () {
      expect(_check(_valid(avgDepth: '10,2')), isEmpty);
      expect(_check(_valid(avgDepth: '20')), {
        ManualDiveField.avgDepth: ManualDiveError.avgDepthAboveMax,
      });
    });

    test('temperature -5 to 45 °C', () {
      expect(_check(_valid(temperature: '-5')), isEmpty);
      expect(_check(_valid(temperature: '45')), isEmpty);
      expect(_check(_valid(temperature: '46')), {
        ManualDiveField.temperature: ManualDiveError.temperatureOutOfRange,
      });
    });

    test('pressure 0 to 400 bar, end below start', () {
      expect(_check(_valid(startPressure: '200', endPressure: '50')), isEmpty);
      expect(_check(_valid(startPressure: '401', endPressure: '50')), {
        ManualDiveField.startPressure: ManualDiveError.pressureOutOfRange,
      });
      expect(_check(_valid(startPressure: '200', endPressure: '200')), {
        ManualDiveField.endPressure: ManualDiveError.endPressureNotBelowStart,
      });
      expect(_check(_valid(startPressure: '50', endPressure: '200')), {
        ManualDiveField.endPressure: ManualDiveError.endPressureNotBelowStart,
      });
    });

    test('tank volume above 0 and at most 30 l, O₂ 1 to 100 %', () {
      expect(_check(_valid(tankVolume: '11,1', o2: '32')), isEmpty);
      expect(_check(_valid(tankVolume: '0')), {
        ManualDiveField.tankVolume: ManualDiveError.volumeOutOfRange,
      });
      expect(_check(_valid(o2: '0')), {
        ManualDiveField.o2: ManualDiveError.o2OutOfRange,
      });
      expect(_check(_valid(o2: '101')), {
        ManualDiveField.o2: ManualDiveError.o2OutOfRange,
      });
    });

    test('date must not be in the future (T1.5 rule)', () {
      expect(_check(_valid(start: _now)), isEmpty);
      expect(_check(_valid(start: _now.add(const Duration(minutes: 10)))), {
        ManualDiveField.start: ManualDiveError.dateInFuture,
      });
    });

    test('number: empty means automatic, otherwise a whole number >= 1', () {
      expect(_check(_valid(number: '')), isEmpty);
      expect(_check(_valid(number: '0')), {
        ManualDiveField.number: ManualDiveError.numberInvalid,
      });
      expect(_check(_valid(number: '4,5')), {
        ManualDiveField.number: ManualDiveError.numberInvalid,
      });
    });
  });

  group('T15.19 toDive', () {
    test('new dive: manual source, SI values, wall-clock start', () {
      final dive = _valid(
        avgDepth: '10,5',
        temperature: '21',
        tankVolume: '12',
        startPressure: '200',
        endPressure: '50',
        o2: '32',
      ).toDive(diverId: 'diver-1');

      expect(dive.id, isNull);
      expect(dive.diverId, 'diver-1');
      expect(dive.number, 6);
      expect(dive.siteName, 'Walensee, Quinten');
      expect(dive.source, DiveSource.manual);
      expect(dive.sourceId, isNull);
      expect(dive.start, DateTime(2026, 11, 14, 10, 42));
      expect(dive.durationS, 2820);
      expect(dive.maxDepthM, 18.4);
      expect(dive.avgDepthM, 10.5);
      expect(dive.minTemperatureC, 21);
      expect(dive.samples, isEmpty);
      expect(dive.tanks, hasLength(1));
      final tank = dive.tanks.single;
      expect(tank.index, 0);
      expect(tank.volumeL, 12);
      expect(tank.startPressureBar, 200);
      expect(tank.endPressureBar, 50);
      expect(tank.gas!.o2, closeTo(0.32, 1e-9));
    });

    test('new dive: empty optional fields stay null, no empty tank', () {
      final dive = _valid(number: '').toDive(diverId: 'diver-1');
      expect(dive.number, isNull);
      expect(dive.avgDepthM, isNull);
      expect(dive.minTemperatureC, isNull);
      expect(dive.notes, isNull);
      expect(dive.tanks, isEmpty);
    });

    test('blank site name is stored as null', () {
      final dive = ManualDiveDraft(
        siteName: '   ',
        start: DateTime(2026, 11, 14, 10, 42),
        duration: '47',
        maxDepth: '18,4',
      ).toDive(diverId: 'diver-1');
      expect(dive.siteName, isNull);
    });

    test('fromDive prefills the form with rounded, German values', () {
      final d = ManualDiveDraft.fromDive(_imported());
      expect(d.number, '42');
      expect(d.siteName, 'SS Thistlegorm');
      expect(d.start, DateTime.utc(2026, 11, 14, 10, 42, 7));
      expect(d.duration, '47');
      expect(d.maxDepth, '29,9');
      expect(d.avgDepth, '17,1');
      expect(d.temperature, '23,4');
      expect(d.tankVolume, '12');
      expect(d.startPressure, '200');
      expect(d.endPressure, '50');
      expect(d.o2, '32');
      expect(d.waterType, WaterType.salt);
      expect(d.notes, 'Strömung von Nord');
      expect(d.rating, 4);
    });

    test('editing keeps samples, events, source and unshown data', () {
      final original = _imported();
      final saved = ManualDiveDraft.fromDive(original)
          .toDive(diverId: original.diverId, original: original);

      expect(saved.id, original.id);
      expect(saved.source, DiveSource.diveComputer);
      expect(saved.sourceId, original.sourceId);
      expect(saved.diveComputerId, original.diveComputerId);
      expect(saved.siteCatalogueId, original.siteCatalogueId);
      expect(saved.siteLat, original.siteLat);
      expect(saved.utcOffsetS, original.utcOffsetS);
      expect(saved.maxTemperatureC, original.maxTemperatureC);
      expect(saved.samples, hasLength(2));
      expect(saved.events, hasLength(1));
      expect(saved.tanks, hasLength(2), reason: 'second tank is not in form');
      expect(saved.tanks[1].gas!.he, 0.35);
    });

    test('unchanged fields keep their exact value, not the rounded one', () {
      final original = _imported();
      final saved = ManualDiveDraft.fromDive(original)
          .toDive(diverId: original.diverId, original: original);
      expect(saved.durationS, 2827);
      expect(saved.maxDepthM, 29.87);
      expect(saved.avgDepthM, 17.123456);
      expect(saved.minTemperatureC, 23.4);
      expect(saved.start, original.start);
    });

    test('changed fields are taken, cleared fields become null', () {
      final original = _imported();
      final draft = ManualDiveDraft.fromDive(original);
      final saved = ManualDiveDraft(
        number: draft.number,
        siteName: draft.siteName,
        start: draft.start,
        duration: draft.duration,
        maxDepth: '30,5',
        avgDepth: '',
        temperature: draft.temperature,
        tankVolume: '15',
        startPressure: draft.startPressure,
        endPressure: draft.endPressure,
        o2: draft.o2,
        waterType: draft.waterType,
        notes: '',
        rating: draft.rating,
      ).toDive(diverId: original.diverId, original: original);

      expect(saved.maxDepthM, 30.5);
      expect(saved.avgDepthM, isNull);
      expect(saved.notes, isNull);
      expect(saved.tanks.first.volumeL, 15);
      expect(saved.tanks.first.gas!.o2, 0.32);
      expect(saved.durationS, 2827);
    });
  });
}
