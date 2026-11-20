// Fakes for the FIT import: file dialog, shared files, parser.
import 'dart:async';
import 'dart:typed_data';

import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/file_import.dart';
import 'package:divedown/domain/import/imported_dive.dart';

/// A dive as the FIT parser delivers it: Nov [day], 09:00, 18,4 m, 47 min.
ImportedDive fitDive(int day, {String serial = '777'}) => ImportedDive(
  source: DiveSource.fit,
  sourceId: '$serial:$day',
  start: DateTime.utc(2026, 11, day, 9),
  durationS: 2820,
  maxDepthM: 18.4,
  samples: const [
    DiveSample(timeS: 0, depthM: 0),
    DiveSample(timeS: 1410, depthM: 18.4),
    DiveSample(timeS: 2820, depthM: 0),
  ],
);

ImportFile fitFile([String name = 'Tauchgang.fit']) =>
    ImportFile(name, Uint8List.fromList([1, 2, 3]));

class FakeFilePicker implements ImportFilePicker {
  /// What the next [pick] returns; null = dialog closed.
  PickResult? next = Picked(fitFile());
  int calls = 0;

  @override
  Future<PickResult?> pick() async {
    calls++;
    return next;
  }
}

class FakeSharedFiles implements SharedFiles {
  final _controller = StreamController<PickResult>.broadcast();

  void share(PickResult file) => _controller.add(file);

  @override
  Stream<PickResult> get incoming => _controller.stream;
}

/// Answers every file with [result]; [pending] keeps it waiting.
class FakeFileDiveSource implements FileDiveSource {
  FileParseResult result = FileDives([fitDive(14)]);
  Completer<void>? pending;
  final parsed = <Uint8List>[];

  @override
  Future<FileParseResult> parse(Uint8List bytes) async {
    parsed.add(bytes);
    await pending?.future;
    return result;
  }
}
