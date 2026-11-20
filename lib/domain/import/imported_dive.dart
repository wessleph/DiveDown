import 'dart:typed_data';

import '../dive/dive.dart';

/// One dive from an import source, before checks and saving (ADR 0003).
/// Values in SI units like [Dive].
class ImportedDive {
  const ImportedDive({
    required this.source,
    required this.sourceId,
    required this.start,
    this.startInstant,
    this.utcOffsetS,
    required this.durationS,
    required this.maxDepthM,
    this.avgDepthM,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.samples = const [],
    this.tanks = const [],
    this.events = const [],
    this.fingerprint,
    this.siteLat,
    this.siteLon,
  });

  final DiveSource source;

  /// Unique per source: `<product>:<fingerprint>` for dive computers, the
  /// FIT file id or the HealthKit workout UUID.
  final String sourceId;

  /// Wall-clock start as shown on the device.
  final DateTime start;

  /// The same moment in UTC; null when the device does not know its time
  /// zone (T4.2).
  final DateTime? startInstant;
  final int? utcOffsetS;
  final int durationS;
  final double maxDepthM;
  final double? avgDepthM;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final List<DiveSample> samples;
  final List<DiveTank> tanks;
  final List<DiveEvent> events;

  /// Raw libdivecomputer fingerprint, dive computers only (T3).
  final Uint8List? fingerprint;
  final double? siteLat;
  final double? siteLon;

  ImportedDive copyWith({
    int? durationS,
    double? maxDepthM,
    DateTime? start,
    List<DiveSample>? samples,
  }) => ImportedDive(
    source: source,
    sourceId: sourceId,
    start: start ?? this.start,
    startInstant: startInstant,
    utcOffsetS: utcOffsetS,
    durationS: durationS ?? this.durationS,
    maxDepthM: maxDepthM ?? this.maxDepthM,
    avgDepthM: avgDepthM,
    minTemperatureC: minTemperatureC,
    maxTemperatureC: maxTemperatureC,
    samples: samples ?? this.samples,
    tanks: tanks,
    events: events,
    fingerprint: fingerprint,
    siteLat: siteLat,
    siteLon: siteLon,
  );

  /// The dive to store for [diverId]; the number is assigned on save.
  Dive toDive({required String diverId, String? diveComputerId}) => Dive(
    diverId: diverId,
    diveComputerId: diveComputerId,
    source: source,
    sourceId: sourceId,
    start: start,
    utcOffsetS: utcOffsetS,
    durationS: durationS,
    maxDepthM: maxDepthM,
    avgDepthM: avgDepthM,
    minTemperatureC: minTemperatureC,
    maxTemperatureC: maxTemperatureC,
    siteLat: siteLat,
    siteLon: siteLon,
    samples: samples,
    tanks: tanks,
    events: events,
  );
}
