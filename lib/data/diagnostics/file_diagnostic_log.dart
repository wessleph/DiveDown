import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';

import '../../domain/diagnostics/diagnostic_log.dart';
import 'log_sanitizer.dart';

/// Default size limit of the log file (security.md G5).
const maxDiagnosticLogBytes = 5 * 1024 * 1024;

/// Entries older than this are removed on start (security.md G5).
const maxDiagnosticLogAge = Duration(days: 7);

/// Ring buffer in one text file in the app cache (not in any backup),
/// one entry per line: `2026-11-23T10:00:00.000Z INFO BLE message`.
class FileDiagnosticLog implements DiagnosticLog {
  FileDiagnosticLog(
    this.file, {
    required this.release,
    this.maxBytes = maxDiagnosticLogBytes,
    this.maxAge = maxDiagnosticLogAge,
  });

  final File file;

  /// Release builds drop more (T10.3, T10.4).
  final bool release;
  final int maxBytes;
  final Duration maxAge;

  /// Writes one after another, so lines never interleave.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  @override
  Future<void> log(String category, LogLevel level, String message) {
    final entry = sanitizeLogEntry(
      LogEntry(
        time: clock.now().toUtc(),
        category: category,
        level: level,
        message: message,
      ),
      release: release,
    );
    if (entry == null) return Future.value();
    final line =
        '${entry.time.toIso8601String()} ${entry.level.name.toUpperCase()} '
        '${entry.category} ${entry.message.replaceAll('\n', ' | ')}\n';
    return _serial(() async {
      try {
        await file.parent.create(recursive: true);
        await file.writeAsString(line, mode: FileMode.append, flush: true);
        if (await file.length() > maxBytes) await _trim();
      } on Exception {
        // Logging never breaks the app.
      }
    });
  }

  /// Keeps the newest lines that fit into three quarters of [maxBytes],
  /// so trimming does not happen on every write.
  Future<void> _trim() async {
    final lines = await _readLines();
    final keep = <String>[];
    var size = 0;
    for (final line in lines.reversed) {
      final bytes = utf8.encode(line).length + 1;
      if (size + bytes > maxBytes * 3 ~/ 4) break;
      keep.add(line);
      size += bytes;
    }
    await _write(keep.reversed.toList());
  }

  Future<List<String>> _readLines() async {
    if (!await file.exists()) return [];
    final text = await file.readAsString();
    return [
      for (final l in const LineSplitter().convert(text))
        if (l.isNotEmpty) l,
    ];
  }

  Future<void> _write(List<String> lines) => file.writeAsString(
    lines.isEmpty ? '' : '${lines.join('\n')}\n',
    flush: true,
  );

  /// Removes entries older than [maxAge] (app start, T10.9).
  Future<void> prune() => _serial(() async {
    try {
      final limit = clock.now().toUtc().subtract(maxAge);
      final lines = await _readLines();
      final keep = [
        for (final l in lines)
          if (DateTime.tryParse(l.split(' ').first)?.isAfter(limit) ?? false) l,
      ];
      if (keep.length != lines.length) await _write(keep);
    } on Exception {
      // Next start tries again.
    }
  });

  @override
  Future<List<String>> lines() => _serial(_readLines);

  @override
  Future<String> export(DiagnosticHeader header) async {
    final body = await lines();
    return [
      'DiveDown ${header.appVersion} (Build ${header.build})',
      'System: ${header.os}',
      'Gerät: ${header.model}',
      'libdivecomputer: ${header.libdivecomputer}',
      'Erstellt: ${clock.now().toUtc().toIso8601String()}',
      '',
      ...body,
    ].join('\n');
  }
}

/// Writes plugin log events into [log] (design.md §9: `onLogEvent`).
/// Returns the subscription so the caller can cancel it.
StreamSubscription<Object?> connectPluginLogs(
  Stream<({String category, String level, String message})> events,
  DiagnosticLog log,
) => events.listen((e) {
  final level = switch (e.level.toUpperCase()) {
    'DEBUG' => LogLevel.debug,
    'WARN' || 'WARNING' => LogLevel.warn,
    'ERROR' => LogLevel.error,
    _ => LogLevel.info,
  };
  log.log(e.category, level, e.message);
});

/// Writes an uncaught error with its stack (FlutterError.onError,
/// PlatformDispatcher.onError) as category `error`. User paths in the
/// stack are removed by the content filter (T10.12).
Future<void> recordError(DiagnosticLog log, Object error, StackTrace? stack) {
  final trace = stack?.toString().trim().split('\n').take(20).join('\n');
  return log.log(
    errorLogCategory,
    LogLevel.error,
    trace == null || trace.isEmpty ? '$error' : '$error\n$trace',
  );
}
