// T5.1-T5.8: FIT files from the Suunto app or Garmin (security A2, R3).
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:divedown/data/import/fit/fit_dive_parser.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:divedown/domain/import/imported_dive.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fit_builder.dart';

/// Garmin Descent, trimix with two deco gases, from Submersion's tests
/// (README in the folder). Values read with fit_tool from the file itself.
final _fixture = File('test/fixtures/fit/005_oc-trimix-two-deco-gases.fit')
    .readAsBytesSync();

FileFailed _failed(FileParseResult r) => r as FileFailed;

void main() {
  final parser = FitDiveParser();

  group('T5.1 valid dive file', () {
    late ImportedDive dive;

    setUpAll(() async {
      final result = await parser.parse(_fixture);
      dive = (result as FileDives).dives.single;
    });

    test('source and id from file_id (serial + creation time)', () {
      expect(dive.source, DiveSource.fit);
      expect(dive.sourceId, '1234567890:1774519371');
    });

    test('start as wall clock, instant in UTC, duration', () {
      expect(dive.start, DateTime.utc(2026, 3, 26, 11, 2, 51));
      expect(dive.startInstant, DateTime.utc(2026, 3, 26, 10, 2, 51));
      expect(dive.utcOffsetS, 3600);
      expect(dive.durationS, 4475);
    });

    test('profile, depth and temperature', () {
      expect(dive.samples, hasLength(3921));
      expect(dive.samples.first.timeS, 0);
      expect(dive.maxDepthM, closeTo(58.909, 0.001));
      expect(dive.avgDepthM, isNotNull);
      expect(dive.minTemperatureC, 16);
      expect(dive.maxTemperatureC, 17);
      expect(dive.samples.where((s) => s.temperatureC != null), isNotEmpty);
    });

    test('trimix gases are kept, one tank per mix', () {
      final gases = {
        for (final t in dive.tanks)
          if (t.gas case final g?) (g.o2, g.he),
      };
      expect(gases.where((g) => g.$2 > 0), isNotEmpty);
      expect(gases.length, greaterThanOrEqualTo(3));
    });
  });

  test('T5.1b synthetic Suunto dive: one dive, Suunto serial in the id', () async {
    final bytes = buildFitFile(
      startUtc: DateTime.utc(2026, 11, 14, 9, 42),
      durationS: 2820,
      depths: [0, 10, 18.4, 12, 0],
      temperatures: [24, 22, 21, 22, 24],
      serialNumber: 777,
    );

    final dive = ((await parser.parse(bytes)) as FileDives).dives.single;

    expect(
      dive.sourceId,
      '777:${DateTime.utc(2026, 11, 14, 9, 42).millisecondsSinceEpoch ~/ 1000}',
    );
    expect(dive.maxDepthM, closeTo(18.4, 0.01));
    expect(dive.minTemperatureC, 21);
    expect(dive.durationS, 2820);
  });

  test('T5.2 larger than 10 MB: tooLarge, the parser never runs', () async {
    var ran = false;
    final p = FitDiveParser(
      run: (_) {
        ran = true;
        return (result: Future.value(null), kill: () {});
      },
    );

    final result = await p.parse(Uint8List(maxImportFileBytes + 1));

    expect(_failed(result).reason, FileImportFailure.tooLarge);
    expect(ran, isFalse);
  });

  test('T5.3 no .FIT signature: notFit, the parser never runs', () async {
    var ran = false;
    final p = FitDiveParser(
      run: (_) {
        ran = true;
        return (result: Future.value(null), kill: () {});
      },
    );
    final bytes = Uint8List.fromList(_fixture);
    bytes[8] = 0x58; // „.FIT“ → „XFIT“

    expect(_failed(await p.parse(bytes)).reason, FileImportFailure.notFit);
    expect(ran, isFalse);
    expect(
      _failed(await p.parse(Uint8List.fromList('hello'.codeUnits))).reason,
      FileImportFailure.notFit,
    );
  });

  test('T5.4 header fine, file CRC wrong: corrupt', () async {
    final bytes = Uint8List.fromList(_fixture);
    bytes[bytes.length - 1] ^= 0xFF;

    expect(
      _failed(await parser.parse(bytes)).reason,
      FileImportFailure.corrupt,
    );
  });

  test('T5.5 cut off after half: corrupt, no crash', () async {
    final half = Uint8List.sublistView(_fixture, 0, _fixture.length ~/ 2);

    expect(_failed(await parser.parse(half)).reason, FileImportFailure.corrupt);
  });

  test('T5.6 a running activity: noDive', () async {
    final bytes = buildFitFile(
      startUtc: DateTime.utc(2026, 11, 1, 7),
      durationS: 1800,
      depths: [0, 0, 0],
      sport: Sport.running,
    );

    expect(_failed(await parser.parse(bytes)).reason, FileImportFailure.noDive);
  });

  test('T5.7 hanging parser: timeout after 30 s, the run is killed', () {
    fakeAsync((async) {
      var killed = false;
      final p = FitDiveParser(
        run: (_) => (
          result: Completer<List<ImportedDive>?>().future,
          kill: () => killed = true,
        ),
      );
      FileParseResult? result;
      p.parse(_fixture).then((r) => result = r);

      async.elapse(const Duration(seconds: 29));
      expect(result, isNull);
      async.elapse(const Duration(seconds: 2));

      expect(_failed(result!).reason, FileImportFailure.timeout);
      expect(killed, isTrue);
    });
  });

  test('T5.7b the parser throws: corrupt, not an exception', () async {
    final p = FitDiveParser(
      run: (_) => (
        result: Future<List<ImportedDive>?>.error(StateError('boom')),
        kill: () {},
      ),
    );

    expect(_failed(await p.parse(_fixture)).reason, FileImportFailure.corrupt);
  });

  test(
    'T5.8 fuzz: 200 changed variants, each a result or a defined failure',
    () async {
      final random = Random(20261120);
      final small = buildFitFile(
        startUtc: DateTime.utc(2026, 11, 14, 9, 42),
        durationS: 600,
        depths: [0, 5, 10, 5, 0],
        temperatures: [20, 19, 18, 19, 20],
      );
      for (var i = 0; i < 200; i++) {
        var bytes = Uint8List.fromList(small);
        final changes = 1 + random.nextInt(8);
        for (var c = 0; c < changes; c++) {
          // Leave the 14-byte header alone in half of the cases, so the parser
          // itself sees broken records.
          final from = i.isEven ? 14 : 0;
          bytes[from + random.nextInt(bytes.length - from)] = random.nextInt(
            256,
          );
        }
        if (i % 3 == 0) bytes = withFileCrc(bytes);

        final result = await parser.parse(bytes);
        expect(
          result,
          anyOf(isA<FileDives>(), isA<FileFailed>()),
          reason: 'variant $i',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
