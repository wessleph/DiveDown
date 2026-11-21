import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/import/file_import.dart';
import '../import/fit/shared_file_reader.dart';

/// Files other apps share with DiveDown. Android: `MainActivity.kt` reads
/// the content into memory and sends it here, never a path (T5.9).
/// iOS: `SharedFileInbox.swift` sends `{name, path}` for a copy in
/// Documents/Inbox, read here through `readSharedFile` within [inboxDirs].
class ChannelSharedFiles implements SharedFiles {
  ChannelSharedFiles([
    this._channel = const MethodChannel(channelName),
    this.inboxDirs,
  ]);

  /// Folders a `{path}` message may point into (iOS: Documents/Inbox).
  final Future<List<Directory>> Function()? inboxDirs;

  static const channelName = 'io.github.wessleph.divedown/share';

  final MethodChannel _channel;

  @override
  late final Stream<PickResult> incoming = _listen();

  Stream<PickResult> _listen() {
    late final StreamController<PickResult> files;
    files = StreamController<PickResult>.broadcast(
      onListen: () async {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'shared') files.add(await _read(call.arguments));
        });
        try {
          final initial = await _channel.invokeMethod<Object?>('initial');
          if (initial != null) files.add(await _read(initial));
        } on MissingPluginException {
          // No share support on this platform (yet).
        } on PlatformException {
          // Nothing to add.
        }
      },
    );
    return files.stream;
  }

  /// `{name, path}` (iOS): read through [readSharedFile], only inside
  /// [inboxDirs]; without them every path is refused. Anything else goes
  /// to [decode].
  Future<PickResult> _read(Object? arguments) async {
    final map = (arguments as Map).cast<String, Object?>();
    final path = map['path'];
    if (path is! String) return decode(map);
    final dirs = await inboxDirs?.call() ?? const <Directory>[];
    final result = await readSharedFile(path, allowedDirs: dirs);
    final name = map['name'] as String?;
    // The name from the platform side wins for display; it is never a path.
    return switch (result) {
      Picked(:final file) when name != null => Picked(
        ImportFile(name, file.bytes),
      ),
      PickFailed(:final reason) when name != null => PickFailed(name, reason),
      _ => result,
    };
  }

  /// `{name, bytes}` or `{name, error}` from the platform side.
  static PickResult decode(Object? arguments) {
    final map = (arguments as Map).cast<String, Object?>();
    final name = map['name'] as String? ?? '';
    final bytes = map['bytes'];
    if (bytes is Uint8List) return Picked(ImportFile(name, bytes));
    final error = FileImportFailure.values.asNameMap()[map['error']];
    return PickFailed(name, error ?? FileImportFailure.unreadable);
  }
}
