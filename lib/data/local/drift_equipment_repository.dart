import '../../domain/equipment/equipment.dart';
import 'database.dart';

/// Equipment in the local database (ADR 0007).
class DriftEquipmentRepository implements EquipmentRepository {
  DriftEquipmentRepository(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<Equipment> save(Equipment item) => throw UnimplementedError('T30.2');

  @override
  Future<List<Equipment>> list(String diverId) =>
      throw UnimplementedError('T30.2');

  @override
  Future<void> delete(String id) => throw UnimplementedError('T30.2');

  @override
  Future<List<Equipment>> forDive(String diveId) =>
      throw UnimplementedError('T30.3');
}
