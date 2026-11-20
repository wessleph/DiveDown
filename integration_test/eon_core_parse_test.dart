// T4.5: real EON Core dives, parsed by libdivecomputer on the phone and
// translated by the adapter. Needs a device:
//
//   flutter test integration_test/eon_core_parse_test.dart
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:divedown/data/import/divecomputer/parsed_dive_adapter.dart';
import 'package:divedown/domain/import/plausibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

import 'eon_core_fixtures.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final host = dc.DiveComputerHostApi();

  for (final fixture in eonCoreFixtures) {
    group(fixture.name, () {
      final expected = jsonDecode(fixture.expectedJson) as Map<String, Object?>;
      late dc.ParsedDive parsed;

      setUpAll(() async {
        parsed = await host.parseRawDiveData(
          expected['vendor']! as String,
          expected['product']! as String,
          expected['model']! as int,
          base64Decode(fixture.rawBase64),
        );
      });

      test('T4.5 libdivecomputer reads depth, duration and samples', () {
        expect(
          parsed.maxDepthMeters,
          closeTo(expected['max_depth_m']! as double, 0.001),
        );
        expect(parsed.durationSeconds, expected['duration_s']);
        expect(parsed.samples, hasLength(expected['sample_count']! as int));
        expect(parsed.events, hasLength(expected['event_count']! as int));
      });

      test('T4.5 the adapter fills in what the EON Core leaves out', () {
        final dive = importedFromParsedDive(parsed, product: 'EON Core');

        expect(dive.maxDepthM, closeTo(parsed.maxDepthMeters, 1e-9));
        // One sample per time: split samples are merged (T4.11).
        expect(
          dive.samples,
          hasLength(parsed.samples.map((s) => s.timeSeconds).toSet().length),
        );
        // The device reports 0,0 m and no temperature (fixture README).
        expect(dive.avgDepthM, isNotNull);
        expect(dive.avgDepthM, inExclusiveRange(1, dive.maxDepthM));
        expect(dive.minTemperatureC, isNotNull);
        expect(dive.minTemperatureC, inInclusiveRange(-5, 45));
      });

      test('T4.5 the real dive passes the plausibility check unchanged', () {
        final dive = importedFromParsedDive(parsed, product: 'EON Core');
        final result = withClock(
          Clock.fixed(DateTime.utc(2026, 11, 20, 12)),
          () => checkPlausibility(dive),
        );

        expect(result, isA<Plausible>());
        final w = (result as Plausible).warnings;
        expect(
          w.isEmpty,
          isTrue,
          reason:
              'dropped ${w.samplesDropped}, pressures ${w.pressuresDropped}, '
              'reordered ${w.samplesReordered}',
        );
      });
    });
  }
}
