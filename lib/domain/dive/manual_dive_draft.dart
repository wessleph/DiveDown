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
}

/// What the user typed in the manual entry form. Numbers are kept as text
/// (German decimal comma) until [validate] and [toDive].
class ManualDiveDraft {
  const ManualDiveDraft({
    this.number = '',
    this.siteName = '',
    required this.start,
    this.duration = '',
    this.maxDepth = '',
    this.avgDepth = '',
    this.temperature = '',
    this.tankVolume = '',
    this.startPressure = '',
    this.endPressure = '',
    this.o2 = '',
    this.waterType,
    this.notes = '',
    this.rating,
  });

  /// Prefills the form for editing [dive].
  factory ManualDiveDraft.fromDive(Dive dive) =>
      throw UnimplementedError('T15.19: ManualDiveDraft.fromDive');

  final String number;
  final String siteName;

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
  final WaterType? waterType;
  final String notes;
  final int? rating;

  /// Errors per field; empty when the draft can be saved.
  /// Ordered like [ManualDiveField], so the first entry gets the focus.
  Map<ManualDiveField, ManualDiveError> validate() =>
      throw UnimplementedError('T15.18: ManualDiveDraft.validate');

  /// Builds the dive to save. With [original] (editing), everything the form
  /// does not show is kept, and unchanged fields keep their exact value.
  Dive toDive({required String diverId, Dive? original}) =>
      throw UnimplementedError('T15.19: ManualDiveDraft.toDive');
}
