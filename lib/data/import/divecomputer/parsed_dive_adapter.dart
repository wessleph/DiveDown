import 'dart:typed_data';

import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

import '../../../domain/dive/dive.dart';
import '../../../domain/import/imported_dive.dart';
import '../../../domain/metrics/profile_stats.dart';

/// libdivecomputer `DC_DECO_NDL`; other deco types are stops with a ceiling.
const _decoTypeNdl = 0;

/// Translates one dive from the plugin into [ImportedDive] (ADR 0003).
/// Only translates: no duplicate checks, no saving (design.md §2).
///
/// - Wall-clock start from the device; the UTC instant only when the device
///   knows its offset (T4.1, T4.2).
/// - Per-tank pressures, gas mixes as fractions (T4.3, T4.4).
/// - Mean depth and temperatures from the samples when the device reports
///   none; a mean depth of exactly 0 counts as none (EON Core, T4.6, T4.7).
/// - `sourceId` = `<product>:<fingerprint>` (T4.8).
/// - Split samples with the same time are merged into one (EON Core, T4.11).
ImportedDive importedFromParsedDive(
  dc.ParsedDive dive, {
  required String product,
}) {
  final start = DateTime.utc(
    dive.dateTimeYear,
    dive.dateTimeMonth,
    dive.dateTimeDay,
    dive.dateTimeHour,
    dive.dateTimeMinute,
    dive.dateTimeSecond,
  );
  final offset = dive.dateTimeTimezoneOffset;
  final samples = _mergeSameTime([for (final s in dive.samples) _sample(s)]);
  final temperatures = [for (final s in samples) ?s.temperatureC];

  return ImportedDive(
    source: DiveSource.diveComputer,
    sourceId: '$product:${dive.fingerprint}',
    start: start,
    startInstant: offset == null
        ? null
        : start.subtract(Duration(seconds: offset)),
    utcOffsetS: offset,
    durationS: dive.durationSeconds,
    maxDepthM: dive.maxDepthMeters,
    avgDepthM: dive.avgDepthMeters > 0
        ? dive.avgDepthMeters
        : meanDepthFromSamples(samples),
    minTemperatureC:
        dive.minTemperatureCelsius ??
        (temperatures.isEmpty ? null : temperatures.reduce(_min)),
    maxTemperatureC:
        dive.maxTemperatureCelsius ??
        (temperatures.isEmpty ? null : temperatures.reduce(_max)),
    samples: samples,
    tanks: _tanks(dive),
    events: [
      for (final e in dive.events)
        DiveEvent(
          timeS: e.timeSeconds,
          type: e.type,
          value: e.data == null || e.data!.isEmpty
              ? null
              : e.data!.entries.map((x) => '${x.key}=${x.value}').join(','),
        ),
    ],
    fingerprint: dive.rawFingerprint ?? _hexToBytes(dive.fingerprint),
    siteLat: dive.entryLatitude,
    siteLon: dive.entryLongitude,
  );
}

/// libdivecomputer reports some times twice, e.g. depth first and the
/// temperature in a second sample. Later values win, missing ones are kept.
List<DiveSample> _mergeSameTime(List<DiveSample> samples) {
  final merged = <DiveSample>[];
  for (final s in samples) {
    if (merged.isEmpty || merged.last.timeS != s.timeS) {
      merged.add(s);
      continue;
    }
    final a = merged.removeLast();
    final pressures = {
      for (final p in a.pressures) p.tankIndex: p,
      for (final p in s.pressures) p.tankIndex: p,
    };
    merged.add(
      DiveSample(
        timeS: s.timeS,
        depthM: s.depthM,
        temperatureC: s.temperatureC ?? a.temperatureC,
        pressures: [
          for (final i in pressures.keys.toList()..sort()) pressures[i]!,
        ],
        heartRate: s.heartRate ?? a.heartRate,
        ndlS: s.ndlS ?? a.ndlS,
        decoCeilingM: s.decoCeilingM ?? a.decoCeilingM,
        decoTimeS: s.decoTimeS ?? a.decoTimeS,
        gasIndex: s.gasIndex ?? a.gasIndex,
      ),
    );
  }
  return merged;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;

DiveSample _sample(dc.ProfileSample s) {
  final perTank = s.tankPressuresBar;
  final ndl = s.decoType == _decoTypeNdl;
  final stop = s.decoType != null && !ndl;
  return DiveSample(
    timeS: s.timeSeconds,
    depthM: s.depthMeters,
    temperatureC: s.temperatureCelsius,
    pressures: perTank != null
        ? [
            for (final (i, p) in perTank.indexed)
              if (p != null) TankPressure(tankIndex: i, pressureBar: p),
          ]
        : [
            if (s.pressureBar case final p?)
              TankPressure(tankIndex: s.tankIndex ?? 0, pressureBar: p),
          ],
    heartRate: s.heartRate,
    ndlS: ndl ? s.decoTime : null,
    decoCeilingM: stop ? s.decoDepth : null,
    decoTimeS: stop ? s.decoTime : null,
    gasIndex: s.gasMixIndex,
  );
}

List<DiveTank> _tanks(dc.ParsedDive dive) {
  GasMix? gas(int index) {
    final mix = dive.gasMixes.where((m) => m.index == index).firstOrNull;
    return mix == null
        ? null
        : GasMix(o2: mix.o2Percent / 100, he: mix.hePercent / 100);
  }

  if (dive.tanks.isEmpty) {
    // No tank data: one tank per gas so the gas is not lost (T4.4).
    return [
      for (final m in dive.gasMixes)
        DiveTank(index: m.index, gas: gas(m.index)),
    ];
  }
  return [
    for (final t in dive.tanks)
      DiveTank(
        index: t.index,
        volumeL: t.volumeLiters,
        startPressureBar: t.startPressureBar,
        endPressureBar: t.endPressureBar,
        gas: gas(t.gasMixIndex),
      ),
  ];
}

Uint8List? _hexToBytes(String hex) {
  if (hex.isEmpty || hex.length.isOdd) return null;
  return Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}
