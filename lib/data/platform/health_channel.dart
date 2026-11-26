import 'package:flutter/services.dart';

import '../../domain/import/health_import.dart';

/// Apple Health on iOS (`ios/Runner/HealthDiveChannel.swift`), read only
/// (security.md G3). Elsewhere [availability] says
/// [HealthAvailability.unavailable].
///
/// Contract of `diveWorkouts` (arguments `from`, `to` in ms since the
/// epoch): a list of maps with `uuid`, `start`, `end` (ms), `utcOffsetS`,
/// and `depth`, `temperature`, `heartRate` as lists of `[ms, value]`.
class ChannelHealthStore implements HealthStore {
  const ChannelHealthStore([this._channel = const MethodChannel(channelName)]);

  static const channelName = 'io.github.wessleph.divedown/health';

  // ignore: unused_field
  final MethodChannel _channel;

  @override
  Future<HealthAvailability> availability() => throw UnimplementedError();

  @override
  Future<void> requestReadAccess() => throw UnimplementedError();

  @override
  Future<List<HealthWorkout>> diveWorkouts(DateTime from, DateTime to) =>
      throw UnimplementedError();
}
