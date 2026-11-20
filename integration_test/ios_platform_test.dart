// T20.12: the Swift side of T11.9 (database folder excluded from iCloud
// backup). Runs on the iOS simulator in CI (ci.yml, job `ios`); skipped on
// Android, where the manifest rules do this (T11.10).
//
//   flutter test integration_test/ios_platform_test.dart -d <iOS simulator>
import 'dart:io';

import 'package:divedown/app/startup.dart';
import 'package:divedown/data/platform/backup_exclusion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('T20.12 database folder carries NSURLIsExcludedFromBackupKey', (
    tester,
  ) async {
    final support = await getApplicationSupportDirectory();
    final db = await openAppDatabase(
      supportDirectory: support,
      backupExclusion: BackupExclusion(),
    );
    await db.close();

    const channel = MethodChannel(BackupExclusion.channelName);
    final excluded = await channel.invokeMethod<bool>('isExcludedFromBackup', {
      'path': p.join(support.path, databaseFolderName),
    });
    expect(excluded, isTrue);
  }, skip: !Platform.isIOS);
}
