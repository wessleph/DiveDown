import '../dive/dive.dart';
import 'sac_calculator.dart';

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
    required AirSource this.source,
    required double this.pressureBar,
    required double this.usedLitres,
    required double this.litresPerMinuteNow,
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
///
/// Measured: pressure from the samples of the tank. Estimated: the gas used
/// between start and end pressure is spread over the dive in proportion to
/// time × ambient pressure, which assumes one constant SAC for the dive.
class AirProfile {
  AirProfile(this.dive, {this.tankIndex = 0}) {
    _prepare();
  }

  final Dive dive;
  final int tankIndex;

  AirMissing? _missing;
  AirSource? _source;
  double _volume = 0;

  // Measured: (time, pressure) of the tank.
  final _times = <int>[];
  final _pressures = <double>[];

  // Estimated: cumulative time × ambient pressure (bar·s) per sample.
  final _weights = <double>[];
  double _startBar = 0;
  double _totalLitres = 0;
  double _sac = 0; // l/min at surface pressure

  List<DiveSample> get _samples => dive.samples;

  void _prepare() {
    final tank = dive.tanks.where((t) => t.index == tankIndex).firstOrNull;
    for (final s in _samples) {
      for (final p in s.pressures) {
        if (p.tankIndex == tankIndex) {
          _times.add(s.timeS);
          _pressures.add(p.pressureBar);
        }
      }
    }
    final volume = tank?.volumeL;
    if (_times.isNotEmpty) {
      if (volume == null || volume <= 0) {
        _missing = AirMissing.volume;
        return;
      }
      _volume = volume;
      _source = AirSource.measured;
      return;
    }

    final start = tank?.startPressureBar;
    final end = tank?.endPressureBar;
    if (tank == null || start == null || end == null || _samples.length < 2) {
      _missing = AirMissing.pressure;
      return;
    }
    if (volume == null || volume <= 0) {
      _missing = AirMissing.volume;
      return;
    }
    _volume = volume;
    _startBar = start;
    _totalLitres = (start - end) * volume;
    _weights.add(0);
    for (var i = 1; i < _samples.length; i++) {
      final a = _samples[i - 1];
      final b = _samples[i];
      final ambient = _ambient((a.depthM + b.depthM) / 2);
      _weights.add(_weights.last + ambient * (b.timeS - a.timeS));
    }
    final total = _weights.last;
    if (total <= 0) {
      _missing = AirMissing.pressure;
      return;
    }
    _sac = _totalLitres / (total / 60);
    _source = AirSource.estimated;
  }

  double _ambient(double depthM) => ambientPressureBar(depthM, dive.waterType);

  /// Values at [timeS] seconds after the start, clamped to the dive.
  AirAtTime at(int timeS) {
    final missing = _missing;
    if (missing != null) return AirAtTime.missing(missing);
    return _source == AirSource.measured
        ? _measuredAt(timeS)
        : _estimatedAt(timeS);
  }

  AirAtTime _measuredAt(int timeS) {
    // Last pressure reading at or before timeS.
    var i = 0;
    while (i + 1 < _times.length && _times[i + 1] <= timeS) {
      i++;
    }
    final pressure = _pressures[i];
    // Consumption over the minute before (or after, at the start).
    var j = i;
    while (j > 0 && _times[i] - _times[j] < 60) {
      j--;
    }
    var from = j, to = i;
    if (from == to) {
      to = i;
      while (to + 1 < _times.length && _times[to] - _times[i] < 60) {
        to++;
      }
    }
    final span = (_times[to] - _times[from]) / 60;
    final now = span > 0
        ? ((_pressures[from] - _pressures[to]) * _volume / span)
              .clamp(0, double.infinity)
              .toDouble()
        : 0.0;
    return AirAtTime(
      source: AirSource.measured,
      pressureBar: pressure,
      usedLitres: (_pressures.first - pressure) * _volume,
      litresPerMinuteNow: now,
    );
  }

  AirAtTime _estimatedAt(int timeS) {
    final first = _samples.first.timeS;
    final last = _samples.last.timeS;
    final t = timeS.clamp(first, last);
    var i = 1;
    while (i < _samples.length - 1 && _samples[i].timeS < t) {
      i++;
    }
    final a = _samples[i - 1];
    final b = _samples[i];
    final span = b.timeS - a.timeS;
    final f = span > 0 ? (t - a.timeS) / span : 1.0;
    final weight = _weights[i - 1] + (_weights[i] - _weights[i - 1]) * f;
    final used = _totalLitres * weight / _weights.last;
    final depth = a.depthM + (b.depthM - a.depthM) * f;
    return AirAtTime(
      source: AirSource.estimated,
      pressureBar: _startBar - used / _volume,
      usedLitres: used,
      litresPerMinuteNow: _sac * _ambient(depth),
    );
  }
}
