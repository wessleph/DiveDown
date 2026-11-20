import 'dart:typed_data';

import 'imported_dive.dart';

/// Largest file the app reads (security.md A2, ui-spec §5.8).
const maxImportFileBytes = 10 * 1024 * 1024;

/// A file to import, already in memory. [displayName] is only ever shown,
/// never used as a path (security.md A2).
class ImportFile {
  const ImportFile(this.displayName, this.bytes);

  final String displayName;
  final Uint8List bytes;
}

/// Why a file brought no dives (ui-spec §5.8).
enum FileImportFailure {
  /// Larger than [maxImportFileBytes].
  tooLarge,

  /// No FIT header.
  notFit,

  /// Header fine, but checksum or content broken.
  corrupt,

  /// A valid FIT file of another sport.
  noDive,

  /// Parsing took longer than allowed.
  timeout,

  /// The file could not be opened at all.
  unreadable,
}

sealed class FileParseResult {
  const FileParseResult();
}

class FileDives extends FileParseResult {
  const FileDives(this.dives);

  final List<ImportedDive> dives;
}

class FileFailed extends FileParseResult {
  const FileFailed(this.reason);

  final FileImportFailure reason;
}

/// Turns file content into dives (design.md §3).
abstract interface class FileDiveSource {
  Future<FileParseResult> parse(Uint8List bytes);
}

/// What the system file dialog returned.
sealed class PickResult {
  const PickResult();
}

class Picked extends PickResult {
  const Picked(this.file);

  final ImportFile file;
}

class PickFailed extends PickResult {
  const PickFailed(this.displayName, this.reason);

  final String displayName;
  final FileImportFailure reason;
}

/// The system dialog „Datei wählen“ (ui-spec §5.8).
abstract interface class ImportFilePicker {
  /// Null when the user closed the dialog without a file.
  Future<PickResult?> pick();
}

/// Files other apps share with DiveDown („Teilen → DiveDown“, ui-spec §2).
abstract interface class SharedFiles {
  /// One result per shared file, including one the app was started with.
  Stream<PickResult> get incoming;
}
