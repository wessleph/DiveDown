import '../dive/dive.dart';
import 'profile_stats.dart';

/// Why no SAC value can be given (design.md §6).
enum SacMissing { pressure, volume, duration, depth }

/// SAC over one fixed minute of the dive (T7.3); the last one can be shorter.
class SacSegment {
  const SacSegment(this.startS, this.endS, this.litresPerMinute);

  final int startS;
  final int endS;

  /// l/min at surface pressure, never negative.
  final double litresPerMinute;
}

class SacResult {
  const SacResult.value(double this.litresPerMinute) : missing = null;
  const SacResult.missing(SacMissing this.missing) : litresPerMinute = null;

  /// Surface air consumption in l/min, null when [missing] is set.
  final double? litresPerMinute;
  final SacMissing? missing;
}

/// Surface air consumption (SAC), never stored (ADR 0004).
///
/// SAC = (Δp × V) / (duration × mean ambient pressure), with 1,0 bar at the
/// surface and 10,05 kPa/m in salt water or 9,81 kPa/m in fresh water.
class SacCalculator {
  const SacCalculator();

  /// Average SAC of one tank from its start and end pressure.
  /// The mean depth is [Dive.avgDepthM], else the mean of the samples.
  SacResult average(Dive dive, {int tankIndex = 0}) {
    final tank = dive.tanks.where((t) => t.index == tankIndex).firstOrNull;
    final start = tank?.startPressureBar;
    final end = tank?.endPressureBar;
    if (tank == null || start == null || end == null) {
      return const SacResult.missing(SacMissing.pressure);
    }
    final volume = tank.volumeL;
    if (volume == null || volume <= 0) {
      return const SacResult.missing(SacMissing.volume);
    }
    if (dive.durationS <= 0) {
      return const SacResult.missing(SacMissing.duration);
    }
    final meanDepth = dive.avgDepthM ?? meanDepthFromSamples(dive.samples);
    if (meanDepth == null) return const SacResult.missing(SacMissing.depth);

    final ambient = ambientPressureBar(meanDepth, dive.waterType);
    final minutes = dive.durationS / 60;
    return SacResult.value((start - end) * volume / (minutes * ambient));
  }

  /// The SAC curve of one tank from its pressure samples, in fixed
  /// one-minute segments (ui-spec §6: step line). Empty without pressure
  /// samples or tank size.
  List<SacSegment> segments(Dive dive, {int tankIndex = 0}) {
    final volume = dive.tanks
        .where((t) => t.index == tankIndex)
        .firstOrNull
        ?.volumeL;
    if (volume == null || volume <= 0) return const [];
    final times = <int>[];
    final pressures = <double>[];
    for (final s in dive.samples) {
      for (final p in s.pressures) {
        if (p.tankIndex == tankIndex) {
          times.add(s.timeS);
          pressures.add(p.pressureBar);
        }
      }
    }
    if (times.length < 2) return const [];

    /// Pressure at [t], linear between readings, clamped at the ends.
    double pressureAt(int t) {
      if (t <= times.first) return pressures.first;
      if (t >= times.last) return pressures.last;
      var i = 1;
      while (times[i] < t) {
        i++;
      }
      final span = times[i] - times[i - 1];
      final f = span > 0 ? (t - times[i - 1]) / span : 1.0;
      return pressures[i - 1] + (pressures[i] - pressures[i - 1]) * f;
    }

    /// Mean depth of the samples in [from, to); the sample nearest to
    /// [from] when the segment holds fewer than two.
    double depthIn(int from, int to) {
      final inside = [
        for (final s in dive.samples)
          if (s.timeS >= from && s.timeS < to) s,
      ];
      final mean = meanDepthFromSamples(inside);
      if (mean != null) return mean;
      if (inside.isNotEmpty) return inside.first.depthM;
      var best = dive.samples.first;
      for (final s in dive.samples) {
        if ((s.timeS - from).abs() < (best.timeS - from).abs()) best = s;
      }
      return best.depthM;
    }

    final out = <SacSegment>[];
    final end = times.last;
    for (var from = 0; from < end; from += 60) {
      final to = from + 60 < end ? from + 60 : end;
      final drop = pressureAt(from) - pressureAt(to);
      final minutes = (to - from) / 60;
      final ambient = ambientPressureBar(depthIn(from, to), dive.waterType);
      out.add(
        SacSegment(
          from,
          to,
          drop <= 0 ? 0 : drop * volume / (minutes * ambient),
        ),
      );
    }
    return out;
  }
}

/// Ambient pressure at [depthM]: 1,0 bar at the surface plus 10,05 kPa/m in
/// salt water (also when unknown) or 9,81 kPa/m in fresh water.
double ambientPressureBar(double depthM, WaterType? water) =>
    1.0 + depthM * (water == WaterType.fresh ? 0.0981 : 0.1005);
