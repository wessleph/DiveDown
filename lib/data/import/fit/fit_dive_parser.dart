import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';
// ignore: implementation_imports
import 'package:fit_tool/src/utils/logger.dart' as fit_log;
import 'package:logger/logger.dart' show Level, Logger;

import '../../../domain/dive/dive.dart';
import '../../../domain/import/file_import.dart';
import '../../../domain/import/imported_dive.dart';
import '../../../domain/metrics/profile_stats.dart';
import 'fit_gas_extractor.dart';
import 'fit_profile_extractor.dart';
import 'fit_tank_extractor.dart';
import 'fit_time_resolver.dart';

/// A parse running somewhere it can be stopped (an isolate in the app).
/// [result] is null when the file holds no dive; it throws on broken files.
typedef FitRun = ({Future<List<ImportedDive>?> result, void Function() kill});

/// Reads FIT files from the Suunto app or Garmin (ui-spec §5.8,
/// security.md A2): size, header and CRC first, then the parser in an
/// isolate with a time limit. Never throws.
class FitDiveParser implements FileDiveSource {
  FitDiveParser({this.timeout = const Duration(seconds: 30), this._run});

  final Duration timeout;
  final FitRun Function(Uint8List bytes)? _run;

  @override
  Future<FileParseResult> parse(Uint8List bytes) async {
    final problem = checkFitFile(bytes);
    if (problem != null) return FileFailed(problem);

    final run = (_run ?? _runInIsolate)(bytes);
    try {
      final dives = await run.result.timeout(timeout);
      return dives == null || dives.isEmpty
          ? const FileFailed(FileImportFailure.noDive)
          : FileDives(dives);
    } on TimeoutException {
      run.kill();
      return const FileFailed(FileImportFailure.timeout);
    } on Object {
      return const FileFailed(FileImportFailure.corrupt);
    }
  }
}

/// Size, `.FIT` header and file CRC, before any parsing (security.md A2).
/// Null when the file looks sound.
FileImportFailure? checkFitFile(Uint8List bytes) {
  if (bytes.length > maxImportFileBytes) return FileImportFailure.tooLarge;
  if (bytes.length < 14) return FileImportFailure.notFit;
  final headerSize = bytes[0];
  final signature = String.fromCharCodes(bytes.sublist(8, 12));
  if ((headerSize != 12 && headerSize != 14) || signature != '.FIT') {
    return FileImportFailure.notFit;
  }
  final dataSize = ByteData.sublistView(
    bytes,
    4,
    8,
  ).getUint32(0, Endian.little);
  final end = headerSize + dataSize;
  if (bytes.length < end + 2) return FileImportFailure.corrupt;
  final stored = bytes[end] | (bytes[end + 1] << 8);
  return _crc(bytes, end) == stored ? null : FileImportFailure.corrupt;
}

/// FIT CRC-16 over the first [length] bytes (FIT SDK).
int _crc(Uint8List bytes, int length) {
  const table = [
    0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401, //
    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
  ];
  var crc = 0;
  for (var i = 0; i < length; i++) {
    final byte = bytes[i];
    var tmp = table[crc & 0xF];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ table[byte & 0xF];
    tmp = table[crc & 0xF];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ table[(byte >> 4) & 0xF];
  }
  return crc;
}

/// Parses in its own isolate, so a hanging or crashing fit_tool cannot take
/// the app down; [FitRun.kill] ends it.
FitRun _runInIsolate(Uint8List bytes) {
  final port = ReceivePort();
  final result = Completer<List<ImportedDive>?>();
  Isolate? isolate;
  var killed = false;

  void finish() {
    port.close();
    isolate?.kill(priority: Isolate.immediate);
  }

  port.listen((message) {
    if (result.isCompleted) return;
    switch (message) {
      case (true, final List<ImportedDive>? dives):
        result.complete(dives);
      case _:
        // An error from inside, or the isolate exited without an answer.
        result.completeError(StateError('FIT parser failed: $message'));
    }
    finish();
  });

  Isolate.spawn<(SendPort, Uint8List)>(
        _isolateMain,
        (port.sendPort, bytes),
        onError: port.sendPort,
        onExit: port.sendPort,
      )
      .then((spawned) {
        isolate = spawned;
        if (killed) spawned.kill(priority: Isolate.immediate);
      })
      .catchError((Object e) {
        if (!result.isCompleted) result.completeError(e);
        port.close();
      });

  return (
    result: result.future,
    kill: () {
      killed = true;
      finish();
    },
  );
}

void _isolateMain((SendPort, Uint8List) args) {
  final (reply, bytes) = args;
  try {
    reply.send((true, importedFromFit(bytes)));
  } on Object catch (e) {
    reply.send((false, '$e'));
  }
}

/// Translates a FIT activity into dives, in the current isolate. Null when
/// the activity is no dive. Throws on content fit_tool cannot read.
///
/// Follows Submersion's `FitParserService` (commit e78a87cb): profile with
/// the recorded deco values, air-integration pressures, gas mixes, entry
/// position. Only translates: no checks, no saving (design.md §2).
List<ImportedDive>? importedFromFit(Uint8List bytes) {
  // fit_tool warns about its outdated FIT profile on every unknown field.
  fit_log.logger = Logger(level: Level.error);

  final messages = FitFile.fromBytes(bytes).records
      .map((r) => r.message)
      .whereType<Message>()
      .toList();
  T? first<T extends Message>() => messages.whereType<T>().firstOrNull;

  final session = first<SessionMessage>();
  if (session == null || session.sport != Sport.diving) return null;
  final startMs = session.startTime;
  if (startMs == null) return null;

  final fileId = first<FileIdMessage>();
  final activity = first<ActivityMessage>();
  final summary = messages.whereType<DiveSummaryMessage>().firstOrNull;
  final records = messages.whereType<RecordMessage>().toList();

  // Wall clock at the dive site; the activity's local timestamp gives the
  // offset. Without it, only the UTC instant is known.
  final hasLocal =
      activity?.timestamp != null && activity?.localTimestamp != null;
  final start = FitTimeResolver.wallClockStart(
    utcStartMs: startMs,
    localStartMs: null,
    utcTimestampMs: activity?.timestamp,
    localTimestampMs: activity?.localTimestamp,
  );
  final instant = DateTime.fromMillisecondsSinceEpoch(
    startMs ~/ 1000 * 1000,
    isUtc: true,
  );

  final elapsed = session.totalElapsedTime;
  final durationS = elapsed != null
      ? elapsed.round()
      : ((session.timestamp ?? startMs) - startMs) ~/ 1000;

  final tankData = FitTankExtractor.extract(messages);
  // A configured but unused transmitter reports all-zero start and end.
  final tanks = tankData.tanks
      .where(
        (t) => (t.startPressureBar ?? 0) > 0 || (t.endPressureBar ?? 0) > 0,
      )
      .toList();
  final gases = FitGasExtractor.extract(messages);

  final orderBySensor = {for (final (i, t) in tanks.indexed) t.sensorId: i};
  final pressuresAt = <int, List<TankPressure>>{};
  for (final p in tankData.pressures) {
    final order = orderBySensor[p.sensorId];
    if (order == null) continue;
    final t = ((p.timestampMs - startMs) / 1000).round();
    (pressuresAt[t] ??= []).add(
      TankPressure(tankIndex: order, pressureBar: p.pressureBar),
    );
  }

  final samples = [
    for (final s in FitProfileExtractor.extract(records))
      if (((s.timestampMs - startMs) / 1000).round() case final t)
        DiveSample(
          timeS: t < 0 ? 0 : t,
          depthM: s.depth,
          temperatureC: s.temperature,
          heartRate: s.heartRate,
          ndlS: s.ndlSeconds != null && s.ndlSeconds! > 0 ? s.ndlSeconds : null,
          decoCeilingM: (s.ceiling ?? 0) > 0 ? s.ceiling : null,
          decoTimeS: (s.ceiling ?? 0) > 0 ? s.ttsSeconds : null,
          pressures: pressuresAt[t] ?? const [],
        ),
  ];

  final temps = [for (final s in samples) ?s.temperatureC];
  final count = tanks.length > gases.length ? tanks.length : gases.length;

  var lat = session.startPositionLat;
  var lon = session.startPositionLong;
  if (lat == null || lon == null) {
    final fix = records
        .where((r) => r.positionLat != null && r.positionLong != null)
        .firstOrNull;
    lat = fix?.positionLat;
    lon = fix?.positionLong;
  }

  return [
    ImportedDive(
      source: DiveSource.fit,
      sourceId:
          '${fileId?.serialNumber ?? 0}:'
          '${(fileId?.timeCreated ?? startMs) ~/ 1000}',
      start: start,
      startInstant: instant,
      utcOffsetS: hasLocal ? start.difference(instant).inSeconds : null,
      durationS: durationS,
      maxDepthM: samples.isEmpty
          ? (summary?.maxDepth ?? 0)
          : samples.map((s) => s.depthM).reduce((a, b) => a > b ? a : b),
      avgDepthM: meanDepthFromSamples(samples) ?? summary?.avgDepth,
      minTemperatureC: temps.isEmpty
          ? null
          : temps.reduce((a, b) => a < b ? a : b),
      maxTemperatureC: temps.isEmpty
          ? null
          : temps.reduce((a, b) => a > b ? a : b),
      samples: samples,
      tanks: [
        for (var i = 0; i < count; i++)
          DiveTank(
            index: i,
            volumeL: i < tanks.length ? tanks[i].cylinderVolumeLiters : null,
            startPressureBar: i < tanks.length
                ? tanks[i].startPressureBar
                : null,
            endPressureBar: i < tanks.length ? tanks[i].endPressureBar : null,
            gas: i < gases.length
                ? GasMix(
                    o2: gases[i].o2Percent / 100,
                    he: gases[i].hePercent / 100,
                  )
                : null,
          ),
      ],
      siteLat: lat,
      siteLon: lon,
    ),
  ];
}
