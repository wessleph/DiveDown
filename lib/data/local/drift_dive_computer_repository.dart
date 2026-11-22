import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/import/dive_computer_registry.dart';
import 'database.dart';

const _uuid = Uuid();

class DriftDiveComputerRepository implements DiveComputerRepository {
  DriftDiveComputerRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<KnownDiveComputer>> listAll() async {
    final rows =
        await (_db.select(_db.diveComputers)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> forget(String id) {
    final now = clock.now().toUtc();
    return (_db.update(_db.diveComputers)..where((t) => t.id.equals(id))).write(
      DiveComputersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<KnownDiveComputer?> findById(String id) =>
      _findOne((t) => t.id.equals(id));

  @override
  Future<KnownDiveComputer?> findByAddress(String address) =>
      _findOne((t) => t.address.equals(address));

  @override
  Future<KnownDiveComputer?> findBySerial(String vendor, String serial) =>
      _findOne((t) => t.vendor.equals(vendor) & t.serial.equals(serial));

  Future<KnownDiveComputer?> _findOne(
    Expression<bool> Function($DiveComputersTable t) filter,
  ) async {
    final row =
        await (_db.select(_db.diveComputers)
              ..where((t) => filter(t) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<KnownDiveComputer> create(KnownDiveComputer computer) async {
    final now = clock.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.diveComputers)
        .insert(
          DiveComputersCompanion.insert(
            id: id,
            vendor: computer.vendor,
            product: computer.product,
            modelNumber: Value(computer.model),
            serial: Value(computer.serial),
            firmware: Value(computer.firmware),
            address: Value(computer.address),
            lastFingerprint: Value(computer.lastFingerprint),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await _findOne((t) => t.id.equals(id)))!;
  }

  @override
  Future<void> update(KnownDiveComputer computer) =>
      (_db.update(
        _db.diveComputers,
      )..where((t) => t.id.equals(computer.id))).write(
        DiveComputersCompanion(
          vendor: Value(computer.vendor),
          product: Value(computer.product),
          modelNumber: Value(computer.model),
          serial: Value(computer.serial),
          firmware: Value(computer.firmware),
          address: Value(computer.address),
          lastFingerprint: Value(computer.lastFingerprint),
          updatedAt: Value(clock.now().toUtc()),
        ),
      );

  static KnownDiveComputer _fromRow(DiveComputerRow r) => KnownDiveComputer(
    id: r.id,
    vendor: r.vendor,
    product: r.product,
    model: r.modelNumber,
    serial: r.serial,
    firmware: r.firmware,
    address: r.address,
    lastFingerprint: r.lastFingerprint,
  );
}
