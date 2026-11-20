import '../dive/dive.dart';
import 'profile_stats.dart';

/// Why no SAC value can be given (design.md §6).
enum SacMissing { pressure, volume, duration, depth }

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

  static const _surfaceBar = 1.0;
  static const _saltBarPerM = 0.1005;
  static const _freshBarPerM = 0.0981;

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

    final perMetre = dive.waterType == WaterType.fresh
        ? _freshBarPerM
        : _saltBarPerM;
    final ambient = _surfaceBar + meanDepth * perMetre;
    final minutes = dive.durationS / 60;
    return SacResult.value((start - end) * volume / (minutes * ambient));
  }
}
