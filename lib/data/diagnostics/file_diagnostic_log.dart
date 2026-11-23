import 'dart:io';

import '../../domain/diagnostics/diagnostic_log.dart';

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

  @override
  Future<void> log(String category, LogLevel level, String message) =>
      throw UnimplementedError('FileDiagnosticLog.log');

  /// Removes entries older than [maxAge] (app start, T10.9).
  Future<void> prune() => throw UnimplementedError('FileDiagnosticLog.prune');

  @override
  Future<List<String>> lines() =>
      throw UnimplementedError('FileDiagnosticLog.lines');

  @override
  Future<String> export(DiagnosticHeader header) =>
      throw UnimplementedError('FileDiagnosticLog.export');
}

/// Writes plugin log events into [log] (design.md §9: `onLogEvent`).
/// Returns the subscription so the caller can cancel it.
Object connectPluginLogs(
  Stream<({String category, String level, String message})> events,
  DiagnosticLog log,
) => throw UnimplementedError('connectPluginLogs');

/// Writes an uncaught error with its stack (FlutterError.onError,
/// PlatformDispatcher.onError) as category `error`.
Future<void> recordError(DiagnosticLog log, Object error, StackTrace? stack) =>
    throw UnimplementedError('recordError');
