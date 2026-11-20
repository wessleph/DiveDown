import 'package:clock/clock.dart';

import '../dive/dive.dart';
import 'imported_dive.dart';

// Plausibility limits for every import source (security.md G1/A1). All
// limits are inclusive (T1.10).
const maxDepthLimitM = 350.0;
const maxDurationS = 24 * 60 * 60;
const minTemperatureLimitC = -5.0;
const maxTemperatureLimitC = 45.0;
const maxPressureLimitBar = 400.0;
const maxSamplesPerDive = 100000;

/// Without a UTC instant the wall clock may be up to this far ahead of UTC
/// (largest time zone, UTC+14) before a dive counts as in the future.
const _maxClockAhead = Duration(hours: 14);

enum RejectReason {
  depthOutOfRange,
  durationOutOfRange,
  startInFuture,
  tooManySamples,
}

/// What was changed to make an accepted dive plausible.
class PlausibilityWarnings {
  const PlausibilityWarnings({
    this.samplesDropped = 0,
    this.pressuresDropped = 0,
    this.samplesReordered = false,
  });

  /// Samples removed for depth or temperature out of range, or duplicates.
  final int samplesDropped;

  /// Pressure values removed; their samples stay.
  final int pressuresDropped;

  /// Samples were not in rising time order and got sorted.
  final bool samplesReordered;

  bool get isEmpty =>
      samplesDropped == 0 && pressuresDropped == 0 && !samplesReordered;
}

sealed class PlausibilityResult {
  const PlausibilityResult();
}

class Plausible extends PlausibilityResult {
  const Plausible(this.dive, {this.warnings = const PlausibilityWarnings()});

  /// The dive with implausible samples and values removed.
  final ImportedDive dive;
  final PlausibilityWarnings warnings;
}

class Implausible extends PlausibilityResult {
  const Implausible(this.reason);

  final RejectReason reason;
}

/// Checks a dive against the limits; uses `clock` for „not in the future“.
PlausibilityResult checkPlausibility(ImportedDive dive) {
  if (!_depthOk(dive.maxDepthM)) {
    return const Implausible(RejectReason.depthOutOfRange);
  }
  if (dive.durationS < 0 || dive.durationS > maxDurationS) {
    return const Implausible(RejectReason.durationOutOfRange);
  }
  if (_inFuture(dive)) return const Implausible(RejectReason.startInFuture);
  if (dive.samples.length > maxSamplesPerDive) {
    return const Implausible(RejectReason.tooManySamples);
  }

  final original = dive.samples;
  var reordered = false;
  for (var i = 1; i < original.length; i++) {
    if (original[i].timeS < original[i - 1].timeS) reordered = true;
  }
  // Stable sort keeps the first of two samples with the same time.
  final sorted = [...original]..sort((a, b) => a.timeS.compareTo(b.timeS));

  var dropped = 0;
  var pressuresDropped = 0;
  final kept = <DiveSample>[];
  for (final s in sorted) {
    final duplicate = kept.isNotEmpty && kept.last.timeS == s.timeS;
    final temp = s.temperatureC;
    final badTemp =
        temp != null &&
        (temp < minTemperatureLimitC || temp > maxTemperatureLimitC);
    if (duplicate || !_depthOk(s.depthM) || badTemp) {
      dropped++;
      continue;
    }
    final pressures = [
      for (final p in s.pressures)
        if (p.pressureBar >= 0 && p.pressureBar <= maxPressureLimitBar) p,
    ];
    pressuresDropped += s.pressures.length - pressures.length;
    kept.add(
      pressures.length == s.pressures.length
          ? s
          : DiveSample(
              timeS: s.timeS,
              depthM: s.depthM,
              temperatureC: s.temperatureC,
              pressures: pressures,
              heartRate: s.heartRate,
              ndlS: s.ndlS,
              decoCeilingM: s.decoCeilingM,
              decoTimeS: s.decoTimeS,
              gasIndex: s.gasIndex,
            ),
    );
  }

  return Plausible(
    dive.copyWith(samples: kept),
    warnings: PlausibilityWarnings(
      samplesDropped: dropped,
      pressuresDropped: pressuresDropped,
      samplesReordered: reordered,
    ),
  );
}

bool _depthOk(double m) => m >= 0 && m <= maxDepthLimitM;

bool _inFuture(ImportedDive dive) {
  final now = clock.now().toUtc();
  if (dive.startInstant case final instant?) return instant.isAfter(now);
  final s = dive.start;
  final wall = DateTime.utc(s.year, s.month, s.day, s.hour, s.minute, s.second);
  return wall.isAfter(now.add(_maxClockAhead));
}
