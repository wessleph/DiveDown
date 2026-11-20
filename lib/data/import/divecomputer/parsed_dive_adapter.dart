import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

import '../../../domain/import/imported_dive.dart';

/// Translates one dive from the plugin into [ImportedDive] (ADR 0003).
/// Only translates: no duplicate checks, no saving (design.md §2).
///
/// - Wall-clock start from the device; the UTC instant only when the device
///   knows its offset (T4.1, T4.2).
/// - Per-tank pressures, gas mixes as fractions (T4.3, T4.4).
/// - Mean depth and temperatures from the samples when the device reports
///   none; a mean depth of exactly 0 counts as none (EON Core, T4.6, T4.7).
/// - `sourceId` = `<product>:<fingerprint>` (T4.8).
ImportedDive importedFromParsedDive(
  dc.ParsedDive dive, {
  required String product,
}) => throw UnimplementedError('T4: importedFromParsedDive');
