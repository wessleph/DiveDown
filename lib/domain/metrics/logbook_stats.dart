// Statistics over the logbook (ui-spec §5.15, T39). Pure Dart, computed on
// demand from the dives on the device, never stored.

import '../dive/dive.dart';
import 'sac_calculator.dart';

/// A dive site and how often it was dived.
class SiteCount {
  const SiteCount(this.name, this.count);

  /// As written in the newest dive there.
  final String name;
  final int count;
}

/// The average SAC of one dive, for the trend line.
class SacPoint {
  const SacPoint(this.dive, this.litresPerMinute);

  final Dive dive;
  final double litresPerMinute;
}

class LogbookStats {
  const LogbookStats({
    this.count = 0,
    this.totalDurationS = 0,
    this.deepest,
    this.longest,
    this.coldest,
    this.perYear = const {},
    this.topSites = const [],
    this.sacTrend = const [],
  });

  final int count;
  final int totalDurationS;
  final Dive? deepest;
  final Dive? longest;

  /// Lowest water temperature; only dives that have one.
  final Dive? coldest;

  /// Dives per year, oldest year first.
  final Map<int, int> perYear;

  /// At most [maxSites], most visited first.
  final List<SiteCount> topSites;

  /// The last [maxSacPoints] dives with a SAC value, oldest first.
  final List<SacPoint> sacTrend;

  bool get isEmpty => count == 0;

  static const maxSites = 5;
  static const maxSacPoints = 10;
}

/// Statistics of [dives] (not deleted, one diver).
LogbookStats logbookStats(List<Dive> dives) {
  if (dives.isEmpty) return const LogbookStats();
  // Oldest first: on a tie the earlier dive keeps the record.
  final sorted = [...dives]..sort((a, b) => a.start.compareTo(b.start));

  Dive? best(
    bool Function(Dive d, Dive current) better, {
    bool Function(Dive d)? only,
  }) {
    Dive? result;
    for (final d in sorted) {
      if (only != null && !only(d)) continue;
      if (result == null || better(d, result)) result = d;
    }
    return result;
  }

  final years = <int, int>{};
  for (final d in sorted) {
    years.update(d.start.year, (n) => n + 1, ifAbsent: () => 1);
  }

  // Sites: same name ignoring case and outer spaces; newest spelling.
  final sites = <String, ({String name, int count, DateTime last})>{};
  for (final d in sorted) {
    final name = d.siteName?.trim() ?? '';
    if (name.isEmpty) continue;
    final key = name.toLowerCase();
    final known = sites[key];
    sites[key] = (name: name, count: (known?.count ?? 0) + 1, last: d.start);
  }
  final ranked = sites.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.last.compareTo(a.last);
    });

  const sac = SacCalculator();
  final trend = [
    for (final d in sorted)
      if (sac.average(d).litresPerMinute case final v?) SacPoint(d, v),
  ];

  return LogbookStats(
    count: dives.length,
    totalDurationS: dives.fold(0, (n, d) => n + d.durationS),
    deepest: best((d, c) => d.maxDepthM > c.maxDepthM),
    longest: best((d, c) => d.durationS > c.durationS),
    coldest: best(
      (d, c) => d.minTemperatureC! < c.minTemperatureC!,
      only: (d) => d.minTemperatureC != null,
    ),
    perYear: Map.fromEntries(
      years.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    topSites: [
      for (final s in ranked.take(LogbookStats.maxSites))
        SiteCount(s.name, s.count),
    ],
    sacTrend: trend.length > LogbookStats.maxSacPoints
        ? trend.sublist(trend.length - LogbookStats.maxSacPoints)
        : trend,
  );
}
