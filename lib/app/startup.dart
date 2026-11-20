import 'dart:io';

import 'package:flutter/services.dart';

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
}) => throw UnimplementedError('T16.1: openAppDatabase');

/// Loads the bundled site catalogue when its version changed (T16.3, T8.7).
Future<void> loadBundledCatalogue(AppDatabase db, AssetBundle bundle) =>
    throw UnimplementedError('T16.3: loadBundledCatalogue');
