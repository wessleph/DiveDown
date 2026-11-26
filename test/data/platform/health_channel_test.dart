// T6.2: the contract of the Apple Health channel (HealthDiveChannel.swift).
import 'package:divedown/data/platform/health_channel.dart';
import 'package:divedown/domain/import/health_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelHealthStore.channelName);
  final calls = <MethodCall>[];
  Object? Function(MethodCall) answer = (_) => null;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final a = answer(call);
          if (a is Exception) throw a;
          return a;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  const store = ChannelHealthStore();
  final start = DateTime.utc(2026, 11, 14, 10, 42);
  final ms = start.millisecondsSinceEpoch;

  test('T6.2 availability', () async {
    for (final (wire, expected) in [
      ('available', HealthAvailability.available),
      ('needsNewerIos', HealthAvailability.needsNewerIos),
      ('unavailable', HealthAvailability.unavailable),
      ('something new', HealthAvailability.unavailable),
    ]) {
      answer = (_) => wire;
      expect(await store.availability(), expected, reason: wire);
    }
  });

  test('T6.2 no channel (Android): unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(await store.availability(), HealthAvailability.unavailable);
  });

  test('T6.2 read access', () async {
    await store.requestReadAccess();
    expect(calls.single.method, 'requestReadAccess');
  });

  test('T6.2 workouts decoded', () async {
    answer = (_) => [
      {
        'uuid': 'W-1',
        'start': ms,
        'end': ms + 2820000,
        'utcOffsetS': 7200,
        'depth': [
          [ms, 0.0],
          [ms + 1000, 0.4],
        ],
        'temperature': [
          [ms, 24],
        ],
        'heartRate': <Object>[],
      },
    ];

    final from = DateTime.utc(2025, 11, 26);
    final to = DateTime.utc(2026, 11, 26);
    final workouts = await store.diveWorkouts(from, to);

    expect(calls.single.method, 'diveWorkouts');
    expect(calls.single.arguments, {
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    final w = workouts.single;
    expect(w.uuid, 'W-1');
    expect(w.start, start);
    expect(w.start.isUtc, isTrue);
    expect(w.end, start.add(const Duration(minutes: 47)));
    expect(w.utcOffsetS, 7200);
    expect([for (final p in w.depth) p.value], [0.0, 0.4]);
    expect(w.depth[1].at, start.add(const Duration(seconds: 1)));
    expect(w.temperature.single.value, 24.0);
    expect(w.heartRate, isEmpty);
  });

  test('T6.2 broken data or a platform error: HealthReadFailure', () async {
    for (final bad in <Object?>[
      [
        {'start': ms, 'end': ms, 'utcOffsetS': 0}, // no uuid
      ],
      [
        {
          'uuid': 'W',
          'start': ms,
          'end': ms,
          'utcOffsetS': 0,
          'depth': [
            ['x', 1],
          ],
        },
      ],
      'not a list',
      PlatformException(code: 'query_failed'),
    ]) {
      answer = (_) => bad;
      await expectLater(
        store.diveWorkouts(start, start),
        throwsA(isA<HealthReadFailure>()),
        reason: '$bad',
      );
    }
  });
}
