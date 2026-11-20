import '../dive/dive.dart';
import '../dive/dive_repository.dart';
import 'imported_dive.dart';
import 'plausibility.dart';

/// Time and depth tolerance for possible duplicates (ADR 0003).
const duplicateStartTolerance = Duration(minutes: 2);
const duplicateDepthToleranceM = 0.5;

enum ConfirmReason {
  /// Same source and id, but the content differs (T2.3).
  sameIdDifferentContent,

  /// Another id, but start and depth are close to a stored dive (T2.4).
  similar,
}

sealed class ImportResult {
  const ImportResult(this.dive);

  final ImportedDive dive;
}

class Saved extends ImportResult {
  const Saved(super.dive, this.saved);

  final Dive saved;
}

class SkippedDuplicate extends ImportResult {
  const SkippedDuplicate(super.dive, this.existingId);

  final String existingId;
}

class NeedsConfirmation extends ImportResult {
  const NeedsConfirmation(super.dive, this.reason, this.possibleMatchId);

  final ConfirmReason reason;
  final String possibleMatchId;
}

class Rejected extends ImportResult {
  const Rejected(super.dive, this.reason);

  final RejectReason reason;
}

class Failed extends ImportResult {
  const Failed(super.dive, this.error);

  final Object error;
}

/// Checks imported dives and saves them (ADR 0003, design.md §3).
class ImportService {
  ImportService(this._dives);

  // ignore: unused_field
  final DiveRepository _dives;

  /// What [importDives] would do, without saving: for the preview.
  Future<List<ImportResult>> preview(
    String diverId,
    List<ImportedDive> dives,
  ) => throw UnimplementedError('T2: ImportService.preview');

  /// Saves each dive in its own transaction. Duplicates are skipped;
  /// dives that need confirmation are saved only when their index is in
  /// [confirmed]. Results keep the order of [dives].
  Future<List<ImportResult>> importDives(
    String diverId,
    List<ImportedDive> dives, {
    String? diveComputerId,
    Set<int> confirmed = const {},
  }) => throw UnimplementedError('T2: ImportService.importDives');
}
