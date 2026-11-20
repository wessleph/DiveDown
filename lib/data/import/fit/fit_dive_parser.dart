import 'dart:typed_data';

import '../../../domain/import/file_import.dart';
import '../../../domain/import/imported_dive.dart';

/// A parse running somewhere it can be stopped (an isolate in the app).
/// [result] is null when the file holds no dive; it throws on broken files.
typedef FitRun = ({Future<List<ImportedDive>?> result, void Function() kill});

/// Reads FIT files from the Suunto app or Garmin (ui-spec §5.8,
/// security.md A2): size, header and CRC first, then the parser in an
/// isolate with a time limit. Never throws.
class FitDiveParser implements FileDiveSource {
  FitDiveParser({
    this.timeout = const Duration(seconds: 30),
    this._run,
  });

  final Duration timeout;
  // ignore: unused_field
  final FitRun Function(Uint8List bytes)? _run;

  @override
  Future<FileParseResult> parse(Uint8List bytes) =>
      throw UnimplementedError('FitDiveParser.parse');
}

/// Translates a FIT activity into dives, in the current isolate. Null when
/// the activity is no dive. Throws on content fit_tool cannot read.
List<ImportedDive>? importedFromFit(Uint8List bytes) =>
    throw UnimplementedError('importedFromFit');
