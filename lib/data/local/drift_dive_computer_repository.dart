import '../../domain/import/dive_computer_registry.dart';
import 'database.dart';

class DriftDiveComputerRepository implements DiveComputerRepository {
  DriftDiveComputerRepository(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<KnownDiveComputer?> findByAddress(String address) =>
      throw UnimplementedError('T3: findByAddress');

  @override
  Future<KnownDiveComputer?> findBySerial(String vendor, String serial) =>
      throw UnimplementedError('T3: findBySerial');

  @override
  Future<KnownDiveComputer> create(KnownDiveComputer computer) =>
      throw UnimplementedError('T3: create');

  @override
  Future<void> update(KnownDiveComputer computer) =>
      throw UnimplementedError('T3: update');
}
