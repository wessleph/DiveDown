// Diagnostic log (design.md §9, security.md A4). Pure Dart.

enum LogLevel { debug, info, warn, error }

/// One line of the diagnostic log.
class LogEntry {
  const LogEntry({
    required this.time,
    required this.category,
    required this.level,
    required this.message,
  });

  /// UTC.
  final DateTime time;

  /// e.g. `BLE`, `SER`, `LDC` (plugin) or `app`, `import`, `backup`, `error`.
  final String category;
  final LogLevel level;
  final String message;

  LogEntry copyWith({String? message}) => LogEntry(
    time: time,
    category: category,
    level: level,
    message: message ?? this.message,
  );
}

/// What the export starts with (T10.10): no names, no places.
class DiagnosticHeader {
  const DiagnosticHeader({
    required this.appVersion,
    required this.build,
    required this.os,
    required this.model,
    required this.libdivecomputer,
  });

  final String appVersion;
  final String build;

  /// e.g. „Android 17 (SDK 37)“ or „iOS 26.1“.
  final String os;

  /// e.g. „samsung SM-S938B“.
  final String model;
  final String libdivecomputer;
}

/// Where the app writes what may later be shared (design.md §9). Nothing
/// is ever sent by itself.
abstract interface class DiagnosticLog {
  /// Filters and stores one entry; never throws.
  Future<void> log(String category, LogLevel level, String message);

  /// All stored lines, oldest first.
  Future<List<String>> lines();

  /// Header and lines as one text for the share dialog.
  Future<String> export(DiagnosticHeader header);
}
