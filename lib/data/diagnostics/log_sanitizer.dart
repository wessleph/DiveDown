import '../../domain/diagnostics/diagnostic_log.dart';

/// Categories that may be written (positive list, security.md A4, T10.7).
/// Plugin: `BLE`, `SER`, `LDC`. App: see the constants below.
const allowedLogCategories = {
  'BLE',
  'SER',
  'LDC',
  appLogCategory,
  importLogCategory,
  backupLogCategory,
  errorLogCategory,
};

const appLogCategory = 'app';
const importLogCategory = 'import';
const backupLogCategory = 'backup';
const errorLogCategory = 'error';

/// Applies the rules of security.md A4 and §3 to one entry; null when it
/// must not be written at all.
///
/// - not on [allowedLogCategories]: dropped (T10.7)
/// - [release]: libdivecomputer HEXDUMP lines and BLE devices that are not
///   dive computers („Unmatched device …“) are dropped (T10.3, T10.4)
/// - MAC addresses → `••:EE:FF`, `serial=12345678` → `serial=••5678`
///   (T10.1, T10.2)
/// - decimal coordinates → `[Ort entfernt]` (T10.5)
/// - e-mail addresses and paths with a user name → `[entfernt]` (T10.6)
LogEntry? sanitizeLogEntry(LogEntry entry, {required bool release}) =>
    throw UnimplementedError('sanitizeLogEntry');
