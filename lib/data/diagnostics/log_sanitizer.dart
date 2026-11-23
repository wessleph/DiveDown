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
LogEntry? sanitizeLogEntry(LogEntry entry, {required bool release}) {
  if (!allowedLogCategories.contains(entry.category)) return null;
  final m = entry.message;
  if (release && (_hexdump.hasMatch(m) || _unmatched.hasMatch(m))) {
    return null;
  }
  return entry.copyWith(message: sanitizeLogText(m));
}

/// The content rules alone (T10.1, T10.2, T10.5, T10.6), also for stack
/// traces (T10.12).
String sanitizeLogText(String text) => text
    .replaceAll(_email, '[entfernt]')
    .replaceAllMapped(_userPath, (_) => '[entfernt]')
    .replaceAllMapped(_mac, (m) => '••:${m[1]}:${m[2]}')
    .replaceAllMapped(_serial, (m) {
      final value = m[2]!;
      final tail = value.length <= 3 ? '' : value.substring(value.length - 4);
      return '${m[1]}••$tail';
    })
    .replaceAll(_coordinatePair, '[Ort entfernt]')
    .replaceAll(_coordinate, '[Ort entfernt]');

final _hexdump = RegExp(r'HEXDUMP', caseSensitive: false);
final _unmatched = RegExp(r'Unmatched device', caseSensitive: false);

/// Six hex pairs with colons or dashes; keeps the last two.
final _mac = RegExp(
  r'\b(?:[0-9A-Fa-f]{2}[:-]){4}([0-9A-Fa-f]{2})[:-]([0-9A-Fa-f]{2})\b',
);

/// `serial=…` / `serial: …` / `sn=…`, hex or decimal, optional `0x`.
final _serial = RegExp(
  r'\b((?:serial|sn)\s*[=:]\s*)(?:0x)?([0-9A-Za-z]+)',
  caseSensitive: false,
);

/// Decimal degrees with at least four decimals: depths (18.4), durations
/// and versions (1.2.3) have fewer and stay.
final _coordinate = RegExp(r'-?\b\d{1,3}\.\d{4,}\b');

/// „27.8123, 33.9201“ is one place, so it becomes one marker.
final _coordinatePair = RegExp(
  r'-?\b\d{1,3}\.\d{4,}\s*[,;]\s*-?\d{1,3}\.\d{4,}\b',
);

final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');

/// Windows, macOS and Linux paths below a user folder, up to the next
/// space, closing bracket or the end.
final _userPath = RegExp(
  r'(?:[A-Za-z]:[\\/]Users[\\/]|/Users/|/home/)[^\s)\]]*',
  caseSensitive: false,
);
