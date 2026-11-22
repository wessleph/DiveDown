import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Name of the folder in the app cache that holds files being shared.
const shareFolderName = 'share';

/// Writes [bytes] as [name] into `<cache>/share/` for the share dialog.
/// Older shared files are removed first. The new file stays: the receiving
/// app may read it after the dialog has closed (found on the phone,
/// T11.16). It goes with the next share or the next app start.
Future<File> prepareShareFile(
  Directory cache,
  String name,
  Uint8List bytes,
) async {
  await clearShareFolder(cache);
  final dir = Directory(p.join(cache.path, shareFolderName));
  await dir.create(recursive: true);
  // Only the last part: a name is never a path (security.md A2).
  final file = File(p.join(dir.path, p.basename(name.replaceAll(r'\', '/'))));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Removes everything in `<cache>/share/` (app start, security.md caches).
Future<void> clearShareFolder(Directory cache) async {
  final dir = Directory(p.join(cache.path, shareFolderName));
  if (dir.existsSync()) await dir.delete(recursive: true);
}
