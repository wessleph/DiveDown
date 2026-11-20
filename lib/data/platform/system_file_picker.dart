import 'package:file_picker/file_picker.dart';

import '../../domain/import/file_import.dart';

/// The system dialog „Datei wählen“ (file_picker, ui-spec §5.8). On Android
/// the plugin copies the file into its own cache folder (path traversal
/// checked there); it is read into memory and the copy removed
/// (security.md: caches).
class SystemFilePicker implements ImportFilePicker {
  const SystemFilePicker();

  @override
  Future<PickResult?> pick() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    final file = files.first;
    try {
      final size = file.lengthSync() ?? await file.length();
      if (size == null) {
        return PickFailed(file.name, FileImportFailure.unreadable);
      }
      if (size > maxImportFileBytes) {
        return PickFailed(file.name, FileImportFailure.tooLarge);
      }
      return Picked(ImportFile(file.name, await file.readAsBytes()));
    } on Exception {
      return PickFailed(file.name, FileImportFailure.unreadable);
    } finally {
      await FilePicker.clearTemporaryFiles();
    }
  }
}
