// Equipment of the diver (ADR 0007, ui-spec §5.11). Pure Dart.

/// Kinds in the order of the settings list (ui-spec §5.11).
enum EquipmentKind {
  suit,
  bcd,
  regulator,
  computer,
  tank,
  mask,
  fins,
  light,
  other,
}

class Equipment {
  const Equipment({
    this.id,
    required this.diverId,
    required this.kind,
    required this.name,
    this.notes,
    this.isDefault = false,
    this.deleted = false,
  });

  /// UUID v4, assigned by the repository on first save.
  final String? id;
  final String diverId;
  final EquipmentKind kind;

  /// Up to [maxNameLength] characters, never logged (ADR 0007).
  final String name;
  final String? notes;

  /// New dives get this piece automatically (standard set).
  final bool isDefault;

  /// Soft deleted: hidden from the list, still shown on old dives.
  final bool deleted;

  static const maxNameLength = 60;

  Equipment copyWith({
    String? id,
    EquipmentKind? kind,
    String? name,
    String? notes,
    bool? isDefault,
  }) => Equipment(
    id: id ?? this.id,
    diverId: diverId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    isDefault: isDefault ?? this.isDefault,
    deleted: deleted,
  );
}

abstract interface class EquipmentRepository {
  /// Inserts or updates [item]; returns it with its id.
  Future<Equipment> save(Equipment item);

  /// The diver's pieces that are not deleted, by kind (enum order), then
  /// name (case-insensitive).
  Future<List<Equipment>> list(String diverId);

  /// Soft delete (ADR 0007).
  Future<void> delete(String id);

  /// The pieces linked to a dive, deleted ones included, ordered like
  /// [list].
  Future<List<Equipment>> forDive(String diveId);
}
