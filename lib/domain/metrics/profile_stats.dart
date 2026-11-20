import '../dive/dive.dart';

/// Time-weighted mean depth of a profile (trapezoids between samples);
/// null with fewer than two samples or no time span.
double? meanDepthFromSamples(List<DiveSample> samples) {
  if (samples.length < 2) return null;
  var area = 0.0;
  for (var i = 1; i < samples.length; i++) {
    final a = samples[i - 1];
    final b = samples[i];
    area += (b.timeS - a.timeS) * (a.depthM + b.depthM) / 2;
  }
  final span = samples.last.timeS - samples.first.timeS;
  return span > 0 ? area / span : null;
}
