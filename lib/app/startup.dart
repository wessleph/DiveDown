import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../data/local/catalogue_loader.dart';
import '../data/local/database.dart';
import '../data/platform/backup_exclusion.dart';

/// Folder below Application Support that holds the database and its
/// `-wal`/`-journal` files, so one backup exclusion covers all of them.
const databaseFolderName = 'db';
const databaseFileName = 'divedown.sqlite';

const catalogueAsset = 'assets/data/dive_sites.json.gz';
const catalogueVersionAsset = 'assets/data/dive_sites.version';

/// Opens (or creates) `<supportDirectory>/db/divedown.sqlite` and excludes
/// the folder from backups on every start (T16.1, T11.9).
Future<AppDatabase> openAppDatabase({
  required Directory supportDirectory,
  required BackupExclusion backupExclusion,
}) async {
  final folder = Directory(p.join(supportDirectory.path, databaseFolderName));
  await folder.create(recursive: true);
  try {
    await backupExclusion.excludeDirectory(folder.path);
  } on Exception {
    // Offline-first wins: the logbook opens even if the flag cannot be set.
    // It is set again on the next start (T16.2).
  }
  return AppDatabase(
    NativeDatabase.createInBackground(
      File(p.join(folder.path, databaseFileName)),
    ),
  );
}

/// Loads the bundled site catalogue when its version changed (T16.3, T8.7).
Future<void> loadBundledCatalogue(AppDatabase db, AssetBundle bundle) async {
  final version = (await bundle.loadString(catalogueVersionAsset)).trim();
  await CatalogueLoader(db).ensureLoaded(
    version: version,
    readGzip: () async {
      final data = await bundle.load(catalogueAsset);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
  );
}
