// T39.1-T39.4: statistics over the logbook (ui-spec §5.15).
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/metrics/logbook_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Dive _dive(
  int number,
  DateTime start, {
  double depth = 15,
  int minutes = 45,
  double? temperature,
  String? site,
  bool withAir = false,
  double endBar = 60,
}) => Dive(
  id: 'd$number',
  diverId: 'anna',
  number: number,
  source: DiveSource.manual,
  start: start,
  durationS: minutes * 60,
  maxDepthM: depth,
  avgDepthM: depth / 2,
  minTemperatureC: temperature,
  siteName: site,
  tanks: withAir
      ? [
          DiveTank(
            index: 0,
            volumeL: 12,
            startPressureBar: 200,
            endPressureBar: endBar,
          ),
        ]
      : const [],
);

DateTime _day(int y, int m, int d) => DateTime.utc(y, m, d, 10);

void main() {
  test('T39.1 counts, records with ties, per year', () {
    final stats = logbookStats([
      _dive(1, _day(2025, 6, 1), depth: 30, minutes: 50, temperature: 18),
      _dive(2, _day(2025, 8, 1), depth: 22, minutes: 61, temperature: 14),
      _dive(3, _day(2026, 2, 1), depth: 30, minutes: 61),
      _dive(4, _day(2026, 5, 1), depth: 12, minutes: 30, temperature: 14),
      _dive(5, _day(2026, 9, 1), depth: 8, minutes: 20, temperature: 25),
    ]);

    expect(stats.count, 5);
    expect(stats.totalDurationS, (50 + 61 + 61 + 30 + 20) * 60);
    expect(stats.deepest?.number, 1); // 30 m twice: the earlier one
    expect(stats.longest?.number, 2); // 61 min twice: the earlier one
    expect(stats.coldest?.number, 2); // 14 °C twice; #3 has none
    expect(stats.perYear, {2025: 2, 2026: 3});
    expect(stats.perYear.keys, [2025, 2026]);
  });

  test('T39.2 top five sites, names merged, newest spelling, ties', () {
    final stats = logbookStats([
      _dive(1, _day(2026, 1, 1), site: 'Elphinstone'),
      _dive(2, _day(2026, 1, 2), site: 'Elphinstone'),
      _dive(3, _day(2026, 1, 3), site: 'Elphinstone'),
      _dive(4, _day(2026, 1, 4), site: ' elphinstone '),
      _dive(5, _day(2026, 2, 1), site: 'Walensee'),
      _dive(6, _day(2026, 2, 2), site: 'Walensee'),
      _dive(7, _day(2026, 3, 1), site: 'Daedalus'),
      _dive(8, _day(2026, 3, 2), site: 'Daedalus'),
      _dive(9, _day(2026, 4, 1), site: 'Brother Islands'),
      _dive(10, _day(2026, 4, 2), site: 'Zürichsee'),
      _dive(11, _day(2026, 4, 3), site: 'Thistlegorm'),
      _dive(12, _day(2026, 4, 4), site: 'Abu Nuhas'),
      _dive(13, _day(2026, 5, 1)),
      _dive(14, _day(2026, 5, 2), site: '  '),
    ]);

    expect(
      [for (final s in stats.topSites) s.name],
      [
        'elphinstone', // 4×, spelling of the newest (#4, trimmed)
        'Daedalus', // 2×, visited after Walensee
        'Walensee', // 2×
        'Abu Nuhas', // 1×, the most recent of the single ones
        'Thistlegorm',
      ],
    );
    expect([for (final s in stats.topSites) s.count], [4, 2, 2, 1, 1]);
  });

  test('T39.3 SAC trend: last ten dives with a value, oldest first', () {
    final stats = logbookStats([
      for (var i = 1; i <= 12; i++)
        _dive(i, _day(2026, 1, i), withAir: true, endBar: 50.0 + i),
      _dive(13, _day(2026, 2, 1)), // no air data
      _dive(14, _day(2026, 2, 2)),
    ]);

    expect(
      [for (final p in stats.sacTrend) p.dive.number],
      [
        3, 4, 5, 6, 7, 8, 9, 10, 11, 12, //
      ],
    );
    // Less gas used each time: the values fall.
    for (var i = 1; i < stats.sacTrend.length; i++) {
      expect(
        stats.sacTrend[i].litresPerMinute,
        lessThan(stats.sacTrend[i - 1].litresPerMinute),
      );
    }
  });

  test('T39.4 no dives: empty', () {
    final stats = logbookStats(const []);

    expect(stats.isEmpty, isTrue);
    expect(stats.deepest, isNull);
    expect(stats.perYear, isEmpty);
    expect(stats.topSites, isEmpty);
    expect(stats.sacTrend, isEmpty);
  });
}
