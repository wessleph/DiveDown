import '../dive/dive.dart';

/// Where the air values at one moment come from (ui-spec §6).
enum AirSource {
  /// Pressure samples from the dive computer.
  measured,

  /// Only start and end pressure: consumption spread by time × ambient
  /// pressure.
  estimated,
}

/// Why no air values can be shown.
enum AirMissing { pressure, volume }

/// Air in one tank at one moment of the dive.
class AirAtTime {
  const AirAtTime({
    required this.source,
    required this.pressureBar,
    required this.usedLitres,
    required this.litresPerMinuteNow,
  }) : missing = null;

  const AirAtTime.missing(AirMissing this.missing)
    : source = null,
      pressureBar = null,
      usedLitres = null,
      litresPerMinuteNow = null;

  final AirSource? source;
  final AirMissing? missing;

  /// Pressure left in the tank.
  final double? pressureBar;

  /// Gas used since the start, in litres at surface pressure.
  final double? usedLitres;

  /// Consumption at this depth in l/min (SAC × ambient pressure).
  final double? litresPerMinuteNow;
}

/// Air values over the course of a dive for the value panel under the
/// profile (ui-spec §6). Never stored (ADR 0004).
class AirProfile {
  AirProfile(this.dive, {this.tankIndex = 0});

  final Dive dive;
  final int tankIndex;

  /// Values at [timeS] seconds after the start.
  AirAtTime at(int timeS) => throw UnimplementedError('AirProfile.at');
}
