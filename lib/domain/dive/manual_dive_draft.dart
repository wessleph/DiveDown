import 'package:clock/clock.dart';

import '../units/unit_formatter.dart';
import 'dive.dart';

/// Fields of the manual entry form (ui-spec §5.4), in screen order.
enum ManualDiveField {
  number,
  start,
  duration,
  maxDepth,
  avgDepth,
  temperature,
  tankVolume,
  startPressure,
  endPressure,
  o2,
  weight,
}

/// Validation errors, with the limits of the plausibility check (security G1).
enum ManualDiveError {
  required,
  notANumber,
  numberInvalid,
  dateInFuture,
  durationOutOfRange,
  depthOutOfRange,
  avgDepthAboveMax,
  temperatureOutOfRange,
  volumeOutOfRange,
  pressureOutOfRange,
  endPressureNotBelowStart,
  o2OutOfRange,
  weightOutOfRange,
}

/// What the user typed in the manual entry form. Numbers are kept as text
/// (German decimal comma) until [validate] and [toDive].
class ManualDiveDraft {
  const ManualDiveDraft({
    this.number = '',
    this.siteName = '',
    this.siteCatalogueId,
    this.siteLat,
    this.siteLon,
    required this.start,
    this.duration = '',
    this.maxDepth = '',
    this.avgDepth = '',
    this.temperature = '',
    this.tankVolume = '',
    this.startPressure = '',
    this.endPressure = '',
    this.o2 = '',
    this.weight = '',
    this.equipmentIds,
    this.waterType,
    this.notes = '',
    this.rating,
  });

  /// Prefills the form for editing [dive].
  factory ManualDiveDraft.fromDive(Dive dive) {
    final tank = _firstTank(dive);
    String num(double? v, int decimals) =>
        v == null ? '' : UnitFormatter.trimmed(v, decimals);
    return ManualDiveDraft(
      number: dive.number?.toString() ?? '',
      siteName: dive.siteName ?? '',
      siteCatalogueId: dive.siteCatalogueId,
      siteLat: dive.siteLat,
      siteLon: dive.siteLon,
      start: dive.start,
      duration: (dive.durationS / 60).round().toString(),
      maxDepth: num(dive.maxDepthM, 1),
      avgDepth: num(dive.avgDepthM, 1),
      temperature: num(dive.minTemperatureC, 1),
      tankVolume: num(tank?.volumeL, 1),
      startPressure: num(tank?.startPressureBar, 0),
      endPressure: num(tank?.endPressureBar, 0),
      o2: tank?.gas == null ? '' : (tank!.gas!.o2 * 100).round().toString(),
      waterType: dive.waterType,
      notes: dive.notes ?? '',
      rating: dive.rating,
    );
  }

  final String number;
  final String siteName;

  /// Set when a suggestion with a catalogue link or position was chosen
  /// (ADR 0006); the form clears them when the name is typed over.
  final String? siteCatalogueId;
  final double? siteLat;
  final double? siteLon;

  /// Wall-clock start, as on the dive computer.
  final DateTime start;

  /// Minutes.
  final String duration;
  final String maxDepth;
  final String avgDepth;
  final String temperature;
  final String tankVolume;
  final String startPressure;
  final String endPressure;

  /// Percent, e.g. `32`.
  final String o2;

  /// Lead in kg, e.g. `6,5` (ADR 0007).
  final String weight;

  /// Selected equipment; null until the form has loaded it (then the
  /// repository applies the standard set to a new dive, ADR 0007).
  final Set<String>? equipmentIds;
  final WaterType? waterType;
  final String notes;
  final int? rating;

  /// Errors per field; empty when the draft can be saved.
  /// Ordered like [ManualDiveField], so the first entry gets the focus.
  Map<ManualDiveField, ManualDiveError> validate() {
    final errors = <ManualDiveField, ManualDiveError>{};

    if (number.trim().isNotEmpty) {
      final n = int.tryParse(number.trim());
      if (n == null || n < 1) {
        errors[ManualDiveField.number] = ManualDiveError.numberInvalid;
      }
    }

    if (_wallClock(start).isAfter(_wallClock(clock.now()))) {
      errors[ManualDiveField.start] = ManualDiveError.dateInFuture;
    }

    /// Parses [text] and checks it against [min]..[max]; returns the value
    /// when it is valid, records the error otherwise.
    double? check(
      ManualDiveField field,
      String text,
      bool Function(double) inRange,
      ManualDiveError outOfRange, {
      bool required = false,
    }) {
      if (text.trim().isEmpty) {
        if (required) errors[field] = ManualDiveError.required;
        return null;
      }
      final v = _parse(text);
      if (v == null) {
        errors[field] = ManualDiveError.notANumber;
        return null;
      }
      if (!inRange(v)) {
        errors[field] = outOfRange;
        return null;
      }
      return v;
    }

    check(
      ManualDiveField.duration,
      duration,
      (v) => v >= 1 && v <= 1440,
      ManualDiveError.durationOutOfRange,
      required: true,
    );
    final max = check(
      ManualDiveField.maxDepth,
      maxDepth,
      _depthOk,
      ManualDiveError.depthOutOfRange,
      required: true,
    );
    final avg = check(
      ManualDiveField.avgDepth,
      avgDepth,
      _depthOk,
      ManualDiveError.depthOutOfRange,
    );
    if (avg != null && max != null && avg > max) {
      errors[ManualDiveField.avgDepth] = ManualDiveError.avgDepthAboveMax;
    }
    check(
      ManualDiveField.temperature,
      temperature,
      (v) => v >= -5 && v <= 45,
      ManualDiveError.temperatureOutOfRange,
    );
    check(
      ManualDiveField.tankVolume,
      tankVolume,
      (v) => v > 0 && v <= 30,
      ManualDiveError.volumeOutOfRange,
    );
    final startBar = check(
      ManualDiveField.startPressure,
      startPressure,
      _pressureOk,
      ManualDiveError.pressureOutOfRange,
    );
    final endBar = check(
      ManualDiveField.endPressure,
      endPressure,
      _pressureOk,
      ManualDiveError.pressureOutOfRange,
    );
    if (startBar != null && endBar != null && endBar >= startBar) {
      errors[ManualDiveField.endPressure] =
          ManualDiveError.endPressureNotBelowStart;
    }
    check(
      ManualDiveField.o2,
      o2,
      (v) => v >= 1 && v <= 100,
      ManualDiveError.o2OutOfRange,
    );

    return {
      for (final f in ManualDiveField.values)
        if (errors.containsKey(f)) f: errors[f]!,
    };
  }

  /// Builds the dive to save. With [original] (editing), everything the form
  /// does not show is kept, and unchanged fields keep their exact value.
  Dive toDive({required String diverId, Dive? original}) {
    final before = original == null ? null : ManualDiveDraft.fromDive(original);
    final oldTank = original == null ? null : _firstTank(original);

    /// The original value when [text] is what the form showed for it.
    double? value(String text, String? shown, double? originalValue) =>
        text == shown ? originalValue : _parse(text);

    final site = siteName.trim().isEmpty ? null : siteName.trim();

    final volume = value(tankVolume, before?.tankVolume, oldTank?.volumeL);
    final startBar = value(
      startPressure,
      before?.startPressure,
      oldTank?.startPressureBar,
    );
    final endBar = value(
      endPressure,
      before?.endPressure,
      oldTank?.endPressureBar,
    );
    final GasMix? gas = o2 == before?.o2
        ? oldTank?.gas
        : _parse(o2) == null
        ? null
        : GasMix(o2: _parse(o2)! / 100, he: oldTank?.gas?.he ?? 0);
    final hasTank =
        volume != null || startBar != null || endBar != null || gas != null;

    return Dive(
      id: original?.id,
      diverId: diverId,
      number: number.trim().isEmpty
          ? original?.number
          : int.parse(number.trim()),
      siteName: site,
      siteCatalogueId: site == null ? null : siteCatalogueId,
      siteLat: site == null ? null : siteLat,
      siteLon: site == null ? null : siteLon,
      diveComputerId: original?.diveComputerId,
      source: original?.source ?? DiveSource.manual,
      sourceId: original?.sourceId,
      start: start,
      utcOffsetS: original?.utcOffsetS,
      durationS: duration == before?.duration
          ? original!.durationS
          : (_parse(duration)! * 60).round(),
      maxDepthM: value(maxDepth, before?.maxDepth, original?.maxDepthM)!,
      avgDepthM: value(avgDepth, before?.avgDepth, original?.avgDepthM),
      minTemperatureC: value(
        temperature,
        before?.temperature,
        original?.minTemperatureC,
      ),
      maxTemperatureC: original?.maxTemperatureC,
      waterType: waterType,
      notes: notes.trim().isEmpty ? null : notes,
      rating: rating,
      samples: original?.samples ?? const [],
      events: original?.events ?? const [],
      tanks: [
        if (hasTank)
          DiveTank(
            index: 0,
            volumeL: volume,
            startPressureBar: startBar,
            endPressureBar: endBar,
            gas: gas,
          ),
        ...?original?.tanks.where((t) => t.index != 0),
      ],
    );
  }

  static DiveTank? _firstTank(Dive dive) =>
      dive.tanks.where((t) => t.index == 0).firstOrNull;

  static bool _depthOk(double v) => v >= 0 && v <= 350;
  static bool _pressureOk(double v) => v >= 0 && v <= 400;

  /// Accepts `18,4` and `18.4`; null for empty or invalid text.
  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// Compares wall-clock fields only, whatever the time zone flag says.
  static DateTime _wallClock(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
}
