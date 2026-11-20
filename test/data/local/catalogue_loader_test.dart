// T8.7-T8.8: bundled site catalogue (tasks.md, ADR 0006).
import 'dart:convert';
import 'dart:io';

import 'package:divedown/data/local/catalogue_loader.dart';
import 'package:divedown/data/local/database.dart';
import 'package:divedown/data/local/drift_dive_repository.dart';
import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/dive/diver.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _catalogue(List<Map<String, Object?>> sites) {
  final json = jsonEncode({
    'metadata': {'format': 1, 'count': sites.length},
    'sites': sites,
  });
  return gzip.encode(utf8.encode(json));
}

Map<String, Object?> _site(String id, String name) => {
  'id': id,
  'name': name,
  'region': 'Rotes Meer',
  'country_code': 'EG',
  'lat': 27.81361,
  'lon': 33.92139,
  'max_depth_m': 30.0,
  'types': ['wreck'],
};

void main() {
  late AppDatabase db;
  late CatalogueLoader loader;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    loader = CatalogueLoader(db);
  });

  tearDown(() => db.close());

  final v1 = _catalogue([
    _site('osm_1', 'SS Thistlegorm'),
    _site('osm_2', 'Yolanda Reef'),
    _site('osm_3', "Sha'ab El Erg"),
  ]);
  final v2 = _catalogue([
    _site('osm_1', 'SS Thistlegorm'),
    _site('osm_4', 'Abu Nuhas'),
  ]);

  test('T8.7 the same version is not loaded twice', () async {
    expect(
      await loader.ensureLoaded(version: 'V1', readGzip: () async => v1),
      isTrue,
    );
    expect(await loader.count(), 3);

    var read = false;
    final reloaded = await loader.ensureLoaded(
      version: 'V1',
      readGzip: () async {
        read = true;
        return v1;
      },
    );

    expect(reloaded, isFalse);
    expect(read, isFalse, reason: 'file must not be read again');
    expect(await loader.count(), 3);
  });

  test('T8.8 a new version refills the table, dives keep their site', () async {
    final diver = await DriftDiverRepository(db)
        .create(const Diver(name: 'Anna'));
    final dives = DriftDiveRepository(db);
    await loader.ensureLoaded(version: 'V1', readGzip: () async => v1);
    final saved = await dives.save(
      Dive(
        diverId: diver.id!,
        siteName: 'Yolanda Reef',
        siteCatalogueId: 'osm_2',
        siteLat: 27.7,
        siteLon: 34.2,
        source: DiveSource.manual,
        start: DateTime.utc(2026, 11, 14, 10, 42),
        durationS: 2820,
        maxDepthM: 18.4,
      ),
    );

    final refilled = await loader.ensureLoaded(
      version: 'V2',
      readGzip: () async => v2,
    );

    expect(refilled, isTrue);
    expect(await loader.count(), 2);
    final dive = await dives.findById(saved.dive.id!);
    expect(dive!.siteName, 'Yolanda Reef');
    expect(dive.siteCatalogueId, 'osm_2');
    expect(dive.siteLat, 27.7);
  });
}
