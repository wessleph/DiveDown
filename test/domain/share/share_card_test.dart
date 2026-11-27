// T43.1-T43.3: what the share card shows and where it sits (ui-spec §5.16,
// security.md G7).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/share/share_card.dart';
import 'package:flutter_test/flutter_test.dart';

/// #42 at Elphinstone with every field the database knows.
Dive _fullDive({String? site = 'Elphinstone', double? minTemp = 23}) => Dive(
  diverId: 'diver-philipp',
  number: 42,
  siteName: site,
  siteCatalogueId: 'osm-123',
  siteLat: 25.31417,
  siteLon: 34.86139,
  source: DiveSource.diveComputer,
  sourceId: 'EON Core:5576006a',
  start: DateTime.utc(2026, 11, 14, 12, 42),
  durationS: 2820,
  maxDepthM: 18.4,
  avgDepthM: 12.3,
  minTemperatureC: minTemp,
  maxTemperatureC: minTemp == null ? null : 24,
  waterType: WaterType.salt,
  notes: 'Mantas am Nordplateau, Philipps Lampe kaputt',
  rating: 5,
  weightKg: 6,
  visibility: WaterVisibility.good,
  current: WaterCurrent.light,
  kinds: const {DiveKind.reef},
  tanks: const [
    DiveTank(
      index: 0,
      volumeL: 12,
      startPressureBar: 200,
      endPressureBar: 50,
      gas: GasMix(o2: 0.32),
    ),
  ],
  samples: [
    for (var t = 0; t <= 2820; t += 60)
      DiveSample(
        timeS: t,
        depthM: t == 1380 ? 18.4 : (t < 1410 ? t / 1410 * 18 : 10),
        temperatureC: 23,
        heartRate: 137,
        ndlS: 4321,
        pressures: const [TankPressure(tankIndex: 0, pressureBar: 151)],
      ),
  ],
);

Dive _profile({required double maxDepth, required int durationS}) => Dive(
  diverId: 'd',
  number: 1,
  source: DiveSource.manual,
  start: DateTime.utc(2026, 11, 1, 9),
  durationS: durationS,
  maxDepthM: maxDepth,
  samples: [
    const DiveSample(timeS: 0, depthM: 0),
    DiveSample(timeS: durationS ~/ 2, depthM: maxDepth),
    DiveSample(timeS: durationS, depthM: 0),
  ],
);

void _expectLayout(
  ShareCardLayout l, {
  double scale = 1,
  double opacity = 0.95,
  double x = 0.5,
  double y = 1,
}) {
  expect(l.scale, closeTo(scale, 1e-9), reason: 'scale');
  expect(l.opacity, closeTo(opacity, 1e-9), reason: 'opacity');
  expect(l.x, closeTo(x, 1e-9), reason: 'x');
  expect(l.y, closeTo(y, 1e-9), reason: 'y');
}

void main() {
  group('T43.1 content', () {
    test('site, date with number, three figures', () {
      final c = shareCardContent(_fullDive());
      expect(c.siteName, 'Elphinstone');
      expect(c.number, 42);
      expect(c.date, '14.11.2026');
      expect(
        [for (final f in c.figures) (f.kind, f.value)],
        [
          (ShareFigureKind.depth, '18,4 m'),
          (ShareFigureKind.duration, '47 min'),
          (ShareFigureKind.water, '23 °C'),
        ],
      );
    });

    test('without site no name, without temperature two figures', () {
      final c = shareCardContent(_fullDive(site: null, minTemp: null));
      expect(c.siteName, isNull);
      expect(c.number, 42);
      expect(
        [for (final f in c.figures) f.kind],
        [ShareFigureKind.depth, ShareFigureKind.duration],
      );
    });

    test('a blank site counts as none', () {
      expect(shareCardContent(_fullDive(site: '  ')).siteName, isNull);
    });

    test('nothing outside the positive list reaches the card', () {
      final all = shareCardContent(_fullDive()).texts.join(' | ');
      for (final secret in [
        '25,3', '25.3', '34,8', '34.8', // coordinates
        'Mantas', 'Philipp', 'Lampe', // notes, diver
        '137', // heart rate
        '4321', '72 min', // NDL
        '151', '200', '50 bar', // pressure
        'EAN32', '5576006a', 'EON', // gas, computer
        'gut', 'leicht', 'Riff', // conditions
      ]) {
        expect(all, isNot(contains(secret)), reason: secret);
      }
    });
  });

  group('T43.2 axes and profile', () {
    List<String> labels(List<ShareTick> ticks) => [
      for (final t in ticks) t.label,
    ];

    test('12 m, 9 min: depth every 5 m, time every 2 min', () {
      final c = shareCardContent(_profile(maxDepth: 12, durationS: 540));
      expect(c.depthScaleM, 15);
      expect(labels(c.depthTicks), ['0 m', '5', '10', '15']);
      expect([for (final t in c.depthTicks) t.position], [0, 5, 10, 15]);
      expect(c.timeScaleS, 540);
      expect(labels(c.timeTicks), ['0', '2', '4', '6', '8 min']);
      expect(
        [for (final t in c.timeTicks) t.position],
        [0, 120, 240, 360, 480],
      );
    });

    test('18,4 m, 47 min: depth every 10 m, time every 10 min', () {
      final c = shareCardContent(_profile(maxDepth: 18.4, durationS: 2820));
      expect(c.depthScaleM, 20);
      expect(labels(c.depthTicks), ['0 m', '10', '20']);
      expect(labels(c.timeTicks), ['0', '10', '20', '30', '40 min']);
    });

    test('41 m, 75 min: depth to 50 m, time every 20 min', () {
      final c = shareCardContent(_profile(maxDepth: 41, durationS: 4500));
      expect(c.depthScaleM, 50);
      expect(labels(c.depthTicks), ['0 m', '10', '20', '30', '40', '50']);
      expect(labels(c.timeTicks), ['0', '20', '40', '60 min']);
    });

    test('very short and shallow: still 3 to 5 time marks', () {
      final c = shareCardContent(_profile(maxDepth: 2, durationS: 150));
      expect(c.depthScaleM, 5);
      expect(c.timeTicks.length, inInclusiveRange(3, 5));
      expect(c.timeTicks.last.label, endsWith(' min'));
    });

    test('review N4: under a minute or no duration: axis of 2 min', () {
      final short = shareCardContent(_profile(maxDepth: 3, durationS: 45));
      expect(short.timeScaleS, 120);
      expect(labels(short.timeTicks), ['0', '1', '2 min']);
      final none = shareCardContent(
        _profile(maxDepth: 3, durationS: 0).copyWith(samples: const []),
      );
      expect(none.timeScaleS, 120);
      expect(none.timeTicks.last.label, '2 min');
    });

    test('the curve follows the samples', () {
      final c = shareCardContent(_fullDive());
      expect(c.estimatedProfile, isFalse);
      expect(c.profile.length, _fullDive().samples.length);
      expect(
        c.profile.map((p) => p.depthM).reduce((a, b) => a > b ? a : b),
        18.4,
      );
    });

    test('without samples: a rectangle from depth and duration', () {
      final c = shareCardContent(_fullDive().copyWith(samples: const []));
      expect(c.estimatedProfile, isTrue);
      expect(c.profile.first.depthM, 0);
      expect(c.profile.last.depthM, 0);
      expect(c.profile.last.timeS, 2820);
      expect(
        c.profile.map((p) => p.depthM).reduce((a, b) => a > b ? a : b),
        18.4,
      );
    });
  });

  group('T43.3 layout', () {
    test('default: full size, 95 %, bottom centre; dark text', () {
      const l = ShareCardLayout();
      _expectLayout(l);
      expect(l.lightText, isFalse);
    });

    test('values are kept in range', () {
      const l = ShareCardLayout();
      expect(l.copyWith(scale: 0.2).scale, 0.5);
      expect(l.copyWith(scale: 1.5).scale, 1.0);
      expect(l.copyWith(opacity: -0.1).opacity, 0);
      expect(l.copyWith(opacity: 1.4).opacity, 1);
      expect(l.copyWith(x: -1).x, 0);
      expect(l.copyWith(y: 2).y, 1);
      _expectLayout(l.copyWith(scale: 0.7), scale: 0.7);
    });

    test('„Oben“, „Mitte“, „Unten“ centre the card, size stays', () {
      final l = const ShareCardLayout().copyWith(
        scale: 0.6,
        opacity: 0.3,
        x: 0.1,
        y: 0.8,
      );
      _expectLayout(
        l.anchoredAt(ShareCardAnchor.top),
        scale: 0.6,
        opacity: 0.3,
        x: 0.5,
        y: 0,
      );
      _expectLayout(
        l.anchoredAt(ShareCardAnchor.middle),
        scale: 0.6,
        opacity: 0.3,
        x: 0.5,
        y: 0.5,
      );
      _expectLayout(
        l.anchoredAt(ShareCardAnchor.bottom),
        scale: 0.6,
        opacity: 0.3,
        x: 0.5,
        y: 1,
      );
    });

    test('below 50 % opacity the text turns light', () {
      const l = ShareCardLayout();
      expect(l.copyWith(opacity: 0.49).lightText, isTrue);
      expect(l.copyWith(opacity: 0.5).lightText, isFalse);
      expect(l.copyWith(opacity: 0).lightText, isTrue);
    });

    test('stored and read back; anything broken gives the default', () {
      final l = const ShareCardLayout().copyWith(
        scale: 0.55,
        opacity: 0.2,
        x: 0.25,
        y: 0.125,
      );
      _expectLayout(
        ShareCardLayout.decode(l.encode()),
        scale: 0.55,
        opacity: 0.2,
        x: 0.25,
        y: 0.125,
      );
      for (final broken in [null, '', 'kaputt', '1,2', 'a,b,c,d']) {
        _expectLayout(ShareCardLayout.decode(broken));
      }
      // Stored by a hand-edited or newer app: still kept in range.
      _expectLayout(
        ShareCardLayout.decode('9,9,9,9'),
        scale: 1,
        opacity: 1,
        x: 1,
        y: 1,
      );
    });
  });
}
