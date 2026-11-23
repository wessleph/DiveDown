import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/equipment/equipment.dart';
import 'database.dart';

const _uuid = Uuid();

/// Equipment in the local database (ADR 0007).
class DriftEquipmentRepository implements EquipmentRepository {
  DriftEquipmentRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Equipment> save(Equipment item) async {
    final now = clock.now().toUtc();
    final id = item.id ?? _uuid.v4();
    final existing = await (_db.select(
      _db.equipment,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    await _db
        .into(_db.equipment)
        .insertOnConflictUpdate(
          EquipmentCompanion.insert(
            id: id,
            diverId: item.diverId,
            kind: item.kind.name,
            name: item.name.trim(),
            notes: Value(
              item.notes == null || item.notes!.trim().isEmpty
                  ? null
                  : item.notes!.trim(),
            ),
            isDefault: Value(item.isDefault),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            deletedAt: Value(existing?.deletedAt),
          ),
        );
    return item.copyWith(id: id, name: item.name.trim());
  }

  @override
  Future<List<Equipment>> list(String diverId) async {
    final rows = await (_db.select(
      _db.equipment,
    )..where((t) => t.diverId.equals(diverId) & t.deletedAt.isNull())).get();
    return _sorted(rows);
  }

  @override
  Future<void> delete(String id) async {
    final now = clock.now().toUtc();
    await (_db.update(_db.equipment)..where((t) => t.id.equals(id))).write(
      EquipmentCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<List<Equipment>> forDive(String diveId) async {
    final link = _db.diveEquipment;
    final rows =
        await (_db.select(_db.equipment).join([
              innerJoin(link, link.equipmentId.equalsExp(_db.equipment.id)),
            ])..where(link.diveId.equals(diveId)))
            .map((r) => r.readTable(_db.equipment))
            .get();
    return _sorted(rows);
  }

  static List<Equipment> _sorted(List<EquipmentRow> rows) {
    final items = [for (final r in rows) _fromRow(r)];
    items.sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  static Equipment _fromRow(EquipmentRow r) => Equipment(
    id: r.id,
    diverId: r.diverId,
    kind: EquipmentKind.values.asNameMap()[r.kind] ?? EquipmentKind.other,
    name: r.name,
    notes: r.notes,
    isDefault: r.isDefault,
    deleted: r.deletedAt != null,
  );
}
