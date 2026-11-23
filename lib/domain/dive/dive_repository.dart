import 'dive.dart';
import 'diver.dart';

/// Non-blocking hints returned when a dive is saved.
enum DiveWarning {
  /// Another dive of the same diver already has this number (ADR 0004).
  duplicateNumber,
}

class SaveDiveResult {
  const SaveDiveResult(this.dive, {this.warnings = const {}});

  /// The dive as stored, with id and number filled in.
  final Dive dive;
  final Set<DiveWarning> warnings;
}

abstract interface class DiverRepository {
  Future<Diver> create(Diver diver);
  Future<Diver?> findById(String id);

  /// All divers that are not deleted, in the order they were created.
  Future<List<Diver>> list();

  /// Stores name and start number (ui-spec §5.11).
  Future<void> update(Diver diver);
}

/// Dive numbers of one diver (ui-spec §5.11, decision of 2026-11-22).
abstract interface class DiveNumbering {
  /// Adds [delta] to every dive number of the diver.
  Future<void> shiftNumbers(String diverId, int delta);

  /// Gives the diver's dives the numbers start, start + 1, … by start time
  /// (ties: old number). Returns how many dives were numbered.
  Future<int> renumberByDate(String diverId, {required int start});

  /// True when sorting by number gives the same order as sorting by date.
  Future<bool> numbersFollowDates(String diverId);
}

abstract interface class DiveRepository {
  /// Inserts or updates a dive with all samples, tanks and events.
  Future<SaveDiveResult> save(Dive dive);
  Future<Dive?> findById(String id);

  /// Dives of one diver that are not deleted, newest first.
  /// For the list only: samples, tanks and events are left empty.
  Future<List<Dive>> listForDiver(String diverId);

  /// The number [save] would give a new dive of this diver (ui-spec §5.4).
  Future<int> nextNumber(String diverId);

  /// The diver's dive from this source with this id, not deleted (T2).
  Future<Dive?> findBySource(
    String diverId,
    DiveSource source,
    String sourceId,
  );

  /// The diver's dives starting within [from]..[to] (wall clock, inclusive),
  /// not deleted. For the list only, like [listForDiver].
  Future<List<Dive>> listStartingBetween(
    String diverId,
    DateTime from,
    DateTime to,
  );

  /// Lead of the diver's newest other dive at the same site (ADR 0007):
  /// same [siteCatalogueId], else the same [siteName] ignoring case and
  /// surrounding spaces. Dives without lead, deleted dives and
  /// [excludeDiveId] do not count. Null when there is none.
  Future<({double weightKg, String siteName})?> lastWeightAt(
    String diverId, {
    String? siteName,
    String? siteCatalogueId,
    String? excludeDiveId,
  });

  /// Marks the dive as deleted (soft delete, ADR 0004).
  Future<void> delete(String id);

  /// Undoes [delete].
  Future<void> restore(String id);
}
