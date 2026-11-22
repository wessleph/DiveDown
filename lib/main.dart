import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app/licenses.dart';
import 'app/startup.dart';
import 'app/startup_gate.dart';
import 'data/local/database.dart';
import 'data/platform/backup_exclusion.dart';
import 'data/platform/share_folder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerCatalogueLicence();
  runApp(const AppStartupGate(openDatabase: _openDatabase));
}

Future<AppDatabase> _openDatabase() async {
  final db = await openAppDatabase(
    supportDirectory: await getApplicationSupportDirectory(),
    backupExclusion: BackupExclusion(),
  );
  try {
    // Files shared last time are not needed any more (T11.16).
    await clearShareFolder(await getTemporaryDirectory());
  } on Exception {
    // A leftover file is harmless; the next share clears it.
  }
  try {
    await loadBundledCatalogue(db, rootBundle);
  } on Exception {
    // Only the site suggestions need the catalogue; the logbook opens
    // anyway and the next start tries again.
  }
  return db;
}
