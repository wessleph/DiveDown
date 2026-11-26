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

  final MethodChannel _channel;

  @override
  Future<HealthAvailability> availability() async {
    try {
      return switch (await _channel.invokeMethod<String>('availability')) {
        'available' => HealthAvailability.available,
        'needsNewerIos' => HealthAvailability.needsNewerIos,
        _ => HealthAvailability.unavailable,
      };
    } on MissingPluginException {
      return HealthAvailability.unavailable;
    } on PlatformException {
      return HealthAvailability.unavailable;
    }
  }

  @override
  Future<void> requestReadAccess() async {
    try {
      await _channel.invokeMethod<void>('requestReadAccess');
    } on PlatformException catch (e) {
      throw HealthReadFailure(e.code);
    }
  }

  @override
  Future<List<HealthWorkout>> diveWorkouts(DateTime from, DateTime to) async {
    final Object? raw;
    try {
      raw = await _channel.invokeMethod<Object?>('diveWorkouts', {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      throw HealthReadFailure(e.code);
    } on MissingPluginException {
      throw const HealthReadFailure('no_channel');
    }
    if (raw is! List) throw const HealthReadFailure('bad_data');
    try {
      return [for (final w in raw) _workout(w as Map)];
    } on TypeError {
      throw const HealthReadFailure('bad_data');
    }
  }

  static DateTime _time(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch((ms as num).toInt(), isUtc: true);

  static List<HealthPoint> _series(Object? raw) => [
    for (final p in (raw as List?) ?? const [])
      HealthPoint(_time((p as List)[0]), (p[1] as num).toDouble()),
  ];

  static HealthWorkout _workout(Map w) => HealthWorkout(
    uuid: w['uuid'] as String,
    start: _time(w['start']),
    end: _time(w['end']),
    utcOffsetS: (w['utcOffsetS'] as num).toInt(),
    depth: _series(w['depth']),
    temperature: _series(w['temperature']),
    heartRate: _series(w['heartRate']),
  );
}
