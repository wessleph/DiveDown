// Dive log domain model (ADR 0004). Pure Dart, no Flutter or Drift imports
// (design.md §2). All values in SI units: metres, bar, degrees Celsius,
// seconds, litres.

/// Where a dive came from (design.md §5).
enum DiveSource { diveComputer, fit, appleHealth, manual }

enum WaterType { salt, fresh }

/// Breathing gas as fractions, e.g. EAN32 = `GasMix(o2: 0.32)`.
class GasMix {
  const GasMix({required this.o2, this.he = 0});

  final double o2;
  final double he;
}

class DiveTank {
  const DiveTank({
    required this.index,
    this.volumeL,
    this.startPressureBar,
    this.endPressureBar,
    this.gas,
  });

  final int index;
  final double? volumeL;
  final double? startPressureBar;
  final double? endPressureBar;
  final GasMix? gas;
}

/// Pressure of one tank at one sample time.
class TankPressure {
  const TankPressure({required this.tankIndex, required this.pressureBar});

  final int tankIndex;
  final double pressureBar;
}

class DiveSample {
  const DiveSample({
    required this.timeS,
    required this.depthM,
    this.temperatureC,
    this.pressures = const [],
    this.heartRate,
    this.ndlS,
    this.decoCeilingM,
    this.decoTimeS,
    this.gasIndex,
  });

  /// Seconds since the start of the dive.
  final int timeS;
  final double depthM;
  final double? temperatureC;
  final List<TankPressure> pressures;
  final int? heartRate;
  final int? ndlS;
  final double? decoCeilingM;
  final int? decoTimeS;
  final int? gasIndex;
}

class DiveEvent {
  const DiveEvent({required this.timeS, required this.type, this.value});

  final int timeS;

  /// libdivecomputer event name, e.g. `gaschange`, `ascent`.
  final String type;
  final String? value;
}

class Dive {
  const Dive({
    this.id,
    required this.diverId,
    this.number,
    this.siteName,
    this.siteCatalogueId,
    this.siteLat,
    this.siteLon,
    this.diveComputerId,
    required this.source,
    this.sourceId,
    required this.start,
    this.utcOffsetS,
    required this.durationS,
    required this.maxDepthM,
    this.avgDepthM,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.waterType,
    this.notes,
    this.rating,
    this.samples = const [],
    this.tanks = const [],
    this.events = const [],
  });

  /// UUID v4, assigned by the repository on first save.
  final String? id;
  final String diverId;

  /// Per-diver dive number; assigned on save when null (ADR 0004 addendum).
  final int? number;
  final String? siteName;
  final String? siteCatalogueId;
  final double? siteLat;
  final double? siteLon;
  final String? diveComputerId;
  final DiveSource source;
  final String? sourceId;

  /// Wall-clock start time as shown on the dive computer, to the second.
  /// Repositories return it UTC-flagged so the phone's time zone never
  /// shifts it; read the fields, not the instant.
  final DateTime start;

  /// Seconds east of UTC, null if the source does not know it.
  final int? utcOffsetS;
  final int durationS;
  final double maxDepthM;
  final double? avgDepthM;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final WaterType? waterType;
  final String? notes;
  final int? rating;
  final List<DiveSample> samples;
  final List<DiveTank> tanks;
  final List<DiveEvent> events;

  Dive copyWith({
    String? id,
    String? diverId,
    int? number,
    String? siteName,
    String? siteCatalogueId,
    double? siteLat,
    double? siteLon,
    String? diveComputerId,
    DiveSource? source,
    String? sourceId,
    DateTime? start,
    int? utcOffsetS,
    int? durationS,
    double? maxDepthM,
    double? avgDepthM,
    double? minTemperatureC,
    double? maxTemperatureC,
    WaterType? waterType,
    String? notes,
    int? rating,
    List<DiveSample>? samples,
    List<DiveTank>? tanks,
    List<DiveEvent>? events,
  }) => Dive(
    id: id ?? this.id,
    diverId: diverId ?? this.diverId,
    number: number ?? this.number,
    siteName: siteName ?? this.siteName,
    siteCatalogueId: siteCatalogueId ?? this.siteCatalogueId,
    siteLat: siteLat ?? this.siteLat,
    siteLon: siteLon ?? this.siteLon,
    diveComputerId: diveComputerId ?? this.diveComputerId,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    start: start ?? this.start,
    utcOffsetS: utcOffsetS ?? this.utcOffsetS,
    durationS: durationS ?? this.durationS,
    maxDepthM: maxDepthM ?? this.maxDepthM,
    avgDepthM: avgDepthM ?? this.avgDepthM,
    minTemperatureC: minTemperatureC ?? this.minTemperatureC,
    maxTemperatureC: maxTemperatureC ?? this.maxTemperatureC,
    waterType: waterType ?? this.waterType,
    notes: notes ?? this.notes,
    rating: rating ?? this.rating,
    samples: samples ?? this.samples,
    tanks: tanks ?? this.tanks,
    events: events ?? this.events,
  );
}
