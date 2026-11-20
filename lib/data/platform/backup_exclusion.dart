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

  final MethodChannel _channel;
  final TargetPlatform _platform;

  /// Excludes the folder at [path] and everything in it.
  Future<void> excludeDirectory(String path) async {
    if (_platform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>(excludeMethod, {'path': path});
  }
}
