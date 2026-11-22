import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../app/startup.dart' show databaseFileName;
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

  static const _manifestName = 'manifest.json';
  static const _databaseName = 'divedown.sqlite';
  static const _snapshotName = 'backup-snapshot.sqlite';

  /// Copy of the database before the last restore, next to the live one.
  static const previousDatabaseName = 'before-restore.sqlite';
  static final _sqliteHeader = ascii.encode('SQLite format 3\u0000');

  /// The archive of the open database [db] (consistent copy).
  Future<Uint8List> create(AppDatabase db) async {
    final snapshot = File(p.join(folder.path, _snapshotName));
    if (snapshot.existsSync()) snapshot.deleteSync();
    try {
      // VACUUM INTO writes a consistent copy, also with a WAL in use.
      final quoted = snapshot.path.replaceAll("'", "''");
      await db.customStatement("VACUUM INTO '$quoted'");
      final data = await snapshot.readAsBytes();
      final count = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM dives WHERE deleted_at IS NULL',
          )
          .getSingle();
      final manifest = {
        'format': backupFormat,
        'appVersion': appVersion,
        'schemaVersion': db.schemaVersion,
        'createdAt': clock.now().toUtc().toIso8601String(),
        'sha256': sha256.convert(data).toString(),
        'diveCount': count.read<int>('n'),
      };
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(_manifestName, utf8.encode(jsonEncode(manifest))),
        )
        ..addFile(ArchiveFile.bytes(_databaseName, data));
      return Uint8List.fromList(ZipEncoder().encode(archive));
    } finally {
      if (snapshot.existsSync()) snapshot.deleteSync();
    }
  }

  /// Checks [bytes] without touching the live database.
  BackupCheck inspect(Uint8List bytes) => switch (_read(bytes)) {
    final BackupRejected r => r,
    (final BackupManifest m, _) => BackupReadable(m),
    _ => const BackupRejected(BackupProblem.invalid),
  };

  /// [BackupRejected] or (manifest, database bytes).
  Object _read(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      return const BackupRejected(BackupProblem.tooLarge);
    }
    const invalid = BackupRejected(BackupProblem.invalid);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      return invalid;
    }
    // Exactly the two known names: nothing else, no paths (security A2).
    final names = [for (final f in archive.files) f.name];
    if (names.length != 2 ||
        !names.contains(_manifestName) ||
        !names.contains(_databaseName) ||
        archive.files.any((f) => !f.isFile)) {
      return invalid;
    }
    final BackupManifest manifest;
    try {
      final json = jsonDecode(
        utf8.decode(archive.findFile(_manifestName)!.content),
      ) as Map<String, Object?>;
      manifest = BackupManifest(
        format: json['format']! as int,
        appVersion: json['appVersion']! as String,
        schemaVersion: json['schemaVersion']! as int,
        createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
        sha256: json['sha256']! as String,
        diveCount: json['diveCount']! as int,
      );
    } on Object {
      return invalid;
    }
    if (manifest.format != backupFormat) return invalid;
    final data = Uint8List.fromList(archive.findFile(_databaseName)!.content);
    if (sha256.convert(data).toString() != manifest.sha256 ||
        data.length < _sqliteHeader.length ||
        !_startsWith(data, _sqliteHeader)) {
      return const BackupRejected(BackupProblem.corrupt);
    }
    if (manifest.schemaVersion > AppDatabase.latestSchemaVersion) {
      return const BackupRejected(BackupProblem.newerVersion);
    }
    return (manifest, data);
  }

  static bool _startsWith(List<int> data, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Replaces the live database with the backup in [bytes]. Calls
  /// [closeDatabase] before touching the file; keeps a copy of the previous
  /// database next to it and puts it back if writing fails.
  Future<RestoreResult> restore(
    Uint8List bytes, {
    required Future<void> Function() closeDatabase,
  }) async {
    final read = _read(bytes);
    if (read is BackupRejected) return RestoreRejected(read.problem);
    final (manifest, data) = read as (BackupManifest, Uint8List);

    await closeDatabase();
    final live = File(p.join(folder.path, databaseFileName));
    final previous = File(p.join(folder.path, previousDatabaseName));
    final hadLive = live.existsSync();
    if (hadLive) await live.copy(previous.path);
    // Leftovers of the closed database must not be applied to the new one.
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final side = File('${live.path}$suffix');
      if (side.existsSync()) side.deleteSync();
    }
    try {
      await writeDatabase(live, data);
      return Restored(manifest);
    } on Object catch (error) {
      if (hadLive) {
        await previous.copy(live.path);
      } else if (live.existsSync()) {
        live.deleteSync();
      }
      return RestoreFailed(error);
    }
  }
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
}) {
  if (!hasDives) return false;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
  final since = lastBackup ?? baseline;
  if (since == null) return false;
  return now.difference(since) > const Duration(days: 30);
}

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
