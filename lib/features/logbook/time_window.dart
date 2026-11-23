import 'dart:math' as math;

/// The visible part of the time axis in the full-screen profile
/// (ui-spec §6, T27): pinch zooms around the fingers, two fingers move it,
/// a double tap shows the whole dive again. Seconds since the start.
class TimeWindow {
  const TimeWindow._(this.startS, this.endS, this.totalS);

  /// The whole dive, 0 … [totalS].
  factory TimeWindow.full(int totalS) =>
      TimeWindow._(0, totalS.toDouble(), totalS);

  /// Never narrower than this, so the curve stays readable.
  static const minLengthS = 120;

  final double startS;
  final double endS;
  final int totalS;

  double get lengthS => endS - startS;

  bool get isFull => startS <= 0 && endS >= totalS;

  /// The moment at [fraction] (0 = left edge, 1 = right edge).
  double timeAt(double fraction) => startS + fraction * lengthS;

  /// [scale] > 1 zooms in; the moment at [focus] (0 … 1) stays in place.
  /// Kept between [minLengthS] and the whole dive, inside 0 … [totalS].
  TimeWindow zoom(double scale, double focus) {
    if (scale <= 0) return this;
    final shortest = math.min(minLengthS, totalS).toDouble();
    final length = (lengthS / scale).clamp(shortest, totalS.toDouble());
    final pivot = timeAt(focus);
    return _placed(pivot - focus * length, length);
  }

  /// Moves by [fraction] of the visible length; positive shows later
  /// moments. Stops at the start and the end of the dive.
  TimeWindow pan(double fraction) =>
      _placed(startS + fraction * lengthS, lengthS);

  /// [length] seconds from [start], moved back inside the dive.
  TimeWindow _placed(double start, double length) {
    final s = start.clamp(0.0, totalS - length);
    return TimeWindow._(s, s + length, totalS);
  }
}
