import 'dart:io';

import '../../../domain/import/file_import.dart';

/// Reads a file another app shared, which the share plugin copied into one
/// of [allowedDirs] (cache). The name is only shown; a path outside those
/// folders is refused and never touched (security.md A2, T5.9). The copy is
/// deleted after reading.
Future<PickResult> readSharedFile(
  String path, {
  required List<Directory> allowedDirs,
  int maxBytes = maxImportFileBytes,
}) => throw UnimplementedError('readSharedFile');
