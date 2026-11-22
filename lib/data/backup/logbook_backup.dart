import 'dart:io';
import 'dart:typed_data';

import '../local/database.dart';

/// File extension of a backup: a ZIP with `manifest.json` and
/// `divedown.sqlite` (security.md O1 a), ui-spec §5.12).
const backupFileExtension = 'divedown';

/// Larger files are rejected before they are read (T11.7).
const maxBackupBytes = 200 * 1024 * 1024;

/// Format of `manifest.json`; a newer format is not read.
const backupFormat = 1;

/// What `manifest.json` says about a backup.
class BackupManifest {
  const BackupManifest({
    required this.format,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.sha256,
    required this.diveCount,
  });

  final int format;
  final String appVersion;

  /// `AppDatabase.schemaVersion` of the copied database.
  final int schemaVersion;

  /// UTC.
  final DateTime createdAt;

  /// Hex SHA-256 of `divedown.sqlite` in the archive.
  final String sha256;

  /// Dives that are not deleted, for the summary (ui-spec §5.12).
  final int diveCount;
}

/// Why a file cannot be restored (ui-spec §5.12 texts).
enum BackupProblem {
  /// Larger than [maxBackupBytes].
  tooLarge,

  /// Not a ZIP, unexpected entries (e.g. `../evil`), no or broken manifest.
  invalid,

  /// Checksum or database header does not match.
  corrupt,

  /// Written by a newer schema than this app knows.
  newerVersion,
}

sealed class BackupCheck {
  const BackupCheck();
}

class BackupReadable extends BackupCheck {
  const BackupReadable(this.manifest);

  final BackupManifest manifest;
}

class BackupRejected extends BackupCheck {
  const BackupRejected(this.problem);

  final BackupProblem problem;
}

sealed class RestoreResult {
  const RestoreResult();
}

class Restored extends RestoreResult {
  const Restored(this.manifest);

  final BackupManifest manifest;
}

class RestoreRejected extends RestoreResult {
  const RestoreRejected(this.problem);

  final BackupProblem problem;
}

/// Replacing the database failed; the previous logbook was put back.
class RestoreFailed extends RestoreResult {
  const RestoreFailed(this.error);

  final Object error;
}

/// Writes the restored database file; replaceable to simulate a failure
/// in the middle of writing (T11.6).
typedef DatabaseWriter = Future<void> Function(File target, Uint8List bytes);

/// Creates, checks and restores `.divedown` backups of the database in
/// [folder] (`<support>/db/`, T16.1). Archive entries are only read into
/// memory by their exact names, never extracted to a path (security A2).
class LogbookBackup {
  LogbookBackup({
    required this.folder,
    required this.appVersion,
    this.maxBytes = maxBackupBytes,
    DatabaseWriter? writeDatabase,
  }) : writeDatabase = writeDatabase ?? _write;

  /// Folder of the live database file [databaseFileName].
  final Directory folder;
  final String appVersion;
  final int maxBytes;
  final DatabaseWriter writeDatabase;

  static Future<void> _write(File target, Uint8List bytes) =>
      target.writeAsBytes(bytes, flush: true);

  /// The archive of the open database [db] (consistent copy).
  Future<Uint8List> create(AppDatabase db) =>
      throw UnimplementedError('LogbookBackup.create');

  /// Checks [bytes] without touching the live database.
  BackupCheck inspect(Uint8List bytes) =>
      throw UnimplementedError('LogbookBackup.inspect');

  /// Replaces the live database with the backup in [bytes]. Calls
  /// [closeDatabase] before touching the file; keeps a copy of the previous
  /// database next to it and puts it back if writing fails.
  Future<RestoreResult> restore(
    Uint8List bytes, {
    required Future<void> Function() closeDatabase,
  }) => throw UnimplementedError('LogbookBackup.restore');
}

/// Whether the logbook shows the backup reminder (ui-spec §5.2, T11.8):
/// more than 30 days since the last backup, or since [baseline] (first
/// start of the app) when there never was one; not while snoozed.
bool backupReminderDue({
  required DateTime now,
  DateTime? lastBackup,
  DateTime? baseline,
  DateTime? snoozedUntil,
  bool hasDives = true,
}) => throw UnimplementedError('backupReminderDue');

/// A backup ready to share: file name and content (ui-spec §5.12).
class BackupFile {
  const BackupFile(this.name, this.bytes);

  /// `DiveDown-Sicherung-2026-11-22.divedown`
  final String name;
  final Uint8List bytes;
}

/// What the settings and the logbook reminder do with backups; the app
/// wires it to [LogbookBackup] and the open database.
abstract interface class BackupActions {
  Future<BackupFile> create();
  BackupCheck inspect(Uint8List bytes);

  /// Replaces the logbook; the app reopens the database afterwards.
  Future<RestoreResult> restore(Uint8List bytes);
}
