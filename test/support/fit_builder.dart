// Derived from Submersion (https://github.com/submersion-app/submersion), commit e78a87cb, GPL-3.0. Modified for DiveDown.
//
// Builds small FIT files for tests with fit_tool's encoder.
import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';

/// A FIT activity: a dive by default, any other [sport] for T5.6.
Uint8List buildFitFile({
  required DateTime startUtc,
  required int durationS,
  required List<double> depths,
  List<int>? temperatures,
  Sport sport = Sport.diving,
  int serialNumber = 12345,
  int manufacturer = 23, // Suunto
}) {
  final builder = FitFileBuilder(autoDefine: true, minStringSize: 50);
  builder.add(
    FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = manufacturer
      ..serialNumber = serialNumber
      ..timeCreated = startUtc.millisecondsSinceEpoch,
  );
  final interval = durationS ~/ depths.length;
  for (var i = 0; i < depths.length; i++) {
    final record = RecordMessage()
      ..timestamp = startUtc
          .add(Duration(seconds: i * interval))
          .millisecondsSinceEpoch
      ..depth = depths[i];
    if (temperatures != null && i < temperatures.length) {
      record.temperature = temperatures[i];
    }
    builder.add(record);
  }
  final end = startUtc.add(Duration(seconds: durationS));
  builder.add(
    SessionMessage()
      ..sport = sport
      ..timestamp = end.millisecondsSinceEpoch
      ..startTime = startUtc.millisecondsSinceEpoch
      ..totalElapsedTime = durationS.toDouble()
      ..totalTimerTime = durationS.toDouble(),
  );
  return builder.build().toBytes();
}

/// FIT CRC-16 (FIT SDK), to give a changed file a valid checksum again.
int fitCrc(Uint8List bytes, int start, int end) {
  const table = [
    0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401, //
    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
  ];
  var crc = 0;
  for (var i = start; i < end; i++) {
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

/// Writes a matching file CRC into the last two bytes.
Uint8List withFileCrc(Uint8List bytes) {
  final out = Uint8List.fromList(bytes);
  final crc = fitCrc(out, 0, out.length - 2);
  out[out.length - 2] = crc & 0xFF;
  out[out.length - 1] = crc >> 8;
  return out;
}
