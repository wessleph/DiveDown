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
}

abstract interface class DiveRepository {
  /// Inserts or updates a dive with all samples, tanks and events.
  Future<SaveDiveResult> save(Dive dive);
  Future<Dive?> findById(String id);

  /// Dives of one diver that are not deleted, newest first.
  /// For the list only: samples, tanks and events are left empty.
  Future<List<Dive>> listForDiver(String diverId);

  /// Marks the dive as deleted (soft delete, ADR 0004).
  Future<void> delete(String id);

  /// Undoes [delete].
  Future<void> restore(String id);
}
