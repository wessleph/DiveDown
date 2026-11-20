import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the database out of iCloud backups (security.md O1 a), T11.9).
///
/// iOS: sets `NSURLIsExcludedFromBackupKey` on the folder through
/// [channelName], implemented in `ios/Runner/AppDelegate.swift`.
/// Android: nothing to do at runtime, `dataExtractionRules` and
/// `fullBackupContent` in the manifest exclude the folder (T11.10).
class BackupExclusion {
  BackupExclusion({MethodChannel? channel, TargetPlatform? platform})
    : _channel = channel ?? const MethodChannel(channelName),
      _platform = platform ?? defaultTargetPlatform;

  static const channelName = 'io.github.wessleph.divedown/backup';
  static const excludeMethod = 'excludeFromBackup';

  // ignore: unused_field
  final MethodChannel _channel;
  // ignore: unused_field
  final TargetPlatform _platform;

  /// Excludes the folder at [path] and everything in it.
  Future<void> excludeDirectory(String path) =>
      throw UnimplementedError('T11.9: BackupExclusion.excludeDirectory');
}
