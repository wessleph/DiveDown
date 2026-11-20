import '../dive/dive.dart';

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

  /// Average SAC of one tank from its start and end pressure.
  /// The mean depth is [Dive.avgDepthM], else the mean of the samples.
  SacResult average(Dive dive, {int tankIndex = 0}) {
    throw UnimplementedError('T7: SacCalculator.average');
  }
}
