import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../domain/import/file_import.dart';

/// Reads a file another app shared, which the share plugin copied into one
/// of [allowedDirs] (cache). The name is only shown; a path outside those
/// folders is refused and never touched (security.md A2, T5.9). The copy is
/// deleted after reading.
Future<PickResult> readSharedFile(
  String path, {
  required List<Directory> allowedDirs,
  int maxBytes = maxImportFileBytes,
}) async {
  // Shown only; a name like „../../databases/x.fit“ becomes „x.fit“.
  final displayName = p.basename(path.replaceAll(r'\', '/'));
  final String real;
  try {
    real = await File(p.normalize(p.absolute(path))).resolveSymbolicLinks();
  } on FileSystemException {
    return PickFailed(displayName, FileImportFailure.unreadable);
  }
  final inside = allowedDirs.any((dir) {
    try {
      return p.isWithin(dir.resolveSymbolicLinksSync(), real);
    } on FileSystemException {
      return false;
    }
  });
  if (!inside) return PickFailed(displayName, FileImportFailure.unreadable);

  final file = File(real);
  try {
    if (await file.length() > maxBytes) {
      return PickFailed(displayName, FileImportFailure.tooLarge);
    }
    return Picked(ImportFile(displayName, await file.readAsBytes()));
  } on FileSystemException {
    return PickFailed(displayName, FileImportFailure.unreadable);
  } finally {
    // The copy in the cache is not needed any more (security.md: caches).
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
