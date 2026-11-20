import 'imported_dive.dart';

// Plausibility limits for every import source (security.md G1/A1). All
// limits are inclusive (T1.10).
const maxDepthLimitM = 350.0;
const maxDurationS = 24 * 60 * 60;
const minTemperatureLimitC = -5.0;
const maxTemperatureLimitC = 45.0;
const maxPressureLimitBar = 400.0;
const maxSamplesPerDive = 100000;

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
PlausibilityResult checkPlausibility(ImportedDive dive) =>
    throw UnimplementedError('T1: checkPlausibility');
