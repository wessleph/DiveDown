// Statistics over the logbook (ui-spec §5.15, T39). Pure Dart, computed on
// demand from the dives on the device, never stored.

import '../dive/dive.dart';

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
LogbookStats logbookStats(List<Dive> dives) => throw UnimplementedError();
