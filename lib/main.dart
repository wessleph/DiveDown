import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/licenses.dart';
import 'app/startup.dart';
import 'app/startup_gate.dart';
import 'data/diagnostics/file_diagnostic_log.dart';
import 'data/diagnostics/log_sanitizer.dart';
import 'data/local/database.dart';
import 'data/platform/backup_exclusion.dart';
import 'data/platform/share_folder.dart';
import 'domain/diagnostics/diagnostic_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCatalogueLicence();
  final log = await _openLog();
  runApp(AppStartupGate(openDatabase: _openDatabase, diagnosticLog: log));
}

/// The diagnostic log in the app cache (T10, design.md §9). Uncaught errors
/// go into it with their stack; nothing is sent anywhere.
Future<DiagnosticLog> _openLog() async {
  try {
    final cache = await getApplicationCacheDirectory();
    final log = FileDiagnosticLog(
      File(p.join(cache.path, 'logs', 'diagnostic.log')),
      release: kReleaseMode,
    );
    await log.prune();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      recordError(log, details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(log, error, stack);
      return false; // keep the default handling as well
    };
    await log.log(appLogCategory, LogLevel.info, 'App gestartet');
    return log;
  } on Exception {
    return const DiscardingDiagnosticLog();
  }
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
