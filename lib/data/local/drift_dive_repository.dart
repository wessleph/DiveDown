import '../../domain/dive/dive.dart';
import '../../domain/dive/dive_repository.dart';
import '../../domain/dive/diver.dart';
import 'database.dart';

class DriftDiverRepository implements DiverRepository {
  DriftDiverRepository(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<Diver> create(Diver diver) => throw UnimplementedError();

  @override
  Future<Diver?> findById(String id) => throw UnimplementedError();
}

class DriftDiveRepository implements DiveRepository {
  DriftDiveRepository(this._db);

  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<SaveDiveResult> save(Dive dive) => throw UnimplementedError();

  @override
  Future<Dive?> findById(String id) => throw UnimplementedError();

  @override
  Future<List<Dive>> listForDiver(String diverId) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> restore(String id) => throw UnimplementedError();
}
