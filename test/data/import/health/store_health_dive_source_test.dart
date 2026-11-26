// T6.6, T6.7, T6.12: fetching dives from the platform store.
import 'package:divedown/data/import/health/store_health_dive_source.dart';
import 'package:divedown/domain/diagnostics/diagnostic_log.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/health_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/health_fixtures.dart';
import '../../../support/test_app.dart' show MemoryDiagnosticLog;

class _FakeStore implements HealthStore {
  _FakeStore(this.workouts);

  final List<HealthWorkout> workouts;
  HealthAvailability answer = HealthAvailability.available;
  Object? error;
  int accessRequests = 0;
  (DateTime, DateTime)? asked;

  @override
  Future<HealthAvailability> availability() async => answer;

  @override
  Future<void> requestReadAccess() async => accessRequests++;

  @override
  Future<List<HealthWorkout>> diveWorkouts(DateTime from, DateTime to) async {
    asked = (from, to);
    if (error case final e?) throw e;
    return workouts;
  }
}

Dive _dive(DiveSource source, DateTime start) => Dive(
  diverId: 'anna',
  source: source,
  sourceId: 'x',
  start: start,
  durationS: 2820,
  maxDepthM: 18,
);

void main() {
  final from = DateTime.utc(2025, 11, 26);
  final to = DateTime.utc(2026, 11, 26);

  test('T6.6 two diving workouts, one without depth', () async {
    final store = _FakeStore([
      elphinstoneWorkout(),
      elphinstoneWorkout(
        uuid: 'no-depth',
        start: DateTime.utc(2026, 11, 15, 8),
        withDepth: false,
      ),
    ]);
    final source = StoreHealthDiveSource(store);

    final result = await source.fetch(from: from, to: to);

    expect(store.asked, (from, to));
    expect([for (final d in result.dives) d.sourceId], [elphinstoneUuid]);
    expect(result.skippedWithoutDepth, 1);
  });

  test('T6.6 newest first', () async {
    final source = StoreHealthDiveSource(
      _FakeStore([
        elphinstoneWorkout(uuid: 'old'),
        elphinstoneWorkout(uuid: 'new', start: DateTime.utc(2026, 11, 20, 9)),
      ]),
    );

    final result = await source.fetch(from: from, to: to);

    expect([for (final d in result.dives) d.sourceId], ['new', 'old']);
  });

  test('T6.6 a failing store becomes HealthReadFailure', () async {
    final store = _FakeStore([])
      ..error = PlatformException(code: 'query_failed');
    final source = StoreHealthDiveSource(store);

    expect(source.fetch(from: from, to: to), throwsA(isA<HealthReadFailure>()));
  });

  test('T6.6 availability and permission go to the store', () async {
    final store = _FakeStore([])..answer = HealthAvailability.needsNewerIos;
    final source = StoreHealthDiveSource(store);

    expect(await source.availability(), HealthAvailability.needsNewerIos);
    await source.requestPermission();
    expect(store.accessRequests, 1);
  });

  group('T6.7 suggested period', () {
    final now = DateTime.utc(2026, 11, 26, 10);

    test('a day before the newest Apple Health dive', () {
      final period = healthImportFrom([
        _dive(DiveSource.appleHealth, DateTime.utc(2026, 11, 2, 9)),
        _dive(DiveSource.appleHealth, DateTime.utc(2026, 11, 14, 12, 42)),
        _dive(DiveSource.fit, DateTime.utc(2026, 11, 20, 8)),
      ], now);

      expect(period.from, DateTime.utc(2026, 11, 13, 12, 42));
      expect(period.since, DateTime.utc(2026, 11, 13, 12, 42));
    });

    test('without an earlier import: twelve months', () {
      final period = healthImportFrom([
        _dive(DiveSource.fit, DateTime.utc(2026, 11, 20, 8)),
      ], now);

      expect(period.from, DateTime.utc(2025, 11, 26, 10));
      expect(period.since, isNull);
    });
  });

  test('T6.12 the log holds counts, never values', () async {
    final log = MemoryDiagnosticLog();
    final source = StoreHealthDiveSource(
      _FakeStore([
        elphinstoneWorkout(),
        elphinstoneWorkout(uuid: 'no-depth', withDepth: false),
      ]),
      log: log,
    );

    await source.fetch(from: from, to: to);

    final lines = (await log.lines()).join('\n');
    expect(lines, contains(healthLogCategory));
    expect(lines, contains('2 workouts'));
    expect(lines, contains('1 dives'));
    expect(lines, contains('1 without depth'));
    for (final value in [
      '18.4',
      '18,4',
      '23.',
      '24.',
      'bpm',
      elphinstoneUuid,
    ]) {
      expect(lines, isNot(contains(value)), reason: 'value $value in the log');
    }
  });

  test('T6.12 a failure is logged without details from HealthKit', () async {
    final log = MemoryDiagnosticLog();
    final store = _FakeStore([])
      ..error = PlatformException(code: 'query_failed', message: 'secret');
    final source = StoreHealthDiveSource(store, log: log);

    await expectLater(
      source.fetch(from: from, to: to),
      throwsA(isA<HealthReadFailure>()),
    );

    final lines = (await log.lines()).join('\n');
    expect(lines, contains('query_failed'));
    expect(lines, isNot(contains('secret')));
    expect(
      (await log.lines()).any(
        (l) => l.contains(LogLevel.error.name.toUpperCase()),
      ),
      isTrue,
    );
  });
}
