import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/drift_app_settings.dart';
import '../data/local/drift_dive_repository.dart';
import '../domain/dive/dive.dart';
import '../domain/dive/dive_repository.dart';
import '../domain/dive/diver.dart';
import '../domain/settings/app_settings.dart';

/// The open database. Set by [AppStartupGate] once the file is open;
/// tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final diveRepositoryProvider = Provider<DiveRepository>(
  (ref) => DriftDiveRepository(ref.watch(appDatabaseProvider)),
);

final diverRepositoryProvider = Provider<DiverRepository>(
  (ref) => DriftDiverRepository(ref.watch(appDatabaseProvider)),
);

final appSettingsProvider = Provider<AppSettings>(
  (ref) => DriftAppSettings(ref.watch(appDatabaseProvider)),
);

/// The diver logbook and import work for (ui-spec §2); null before §5.1.
final activeDiverProvider = FutureProvider<Diver?>((ref) async {
  final id = await ref.watch(appSettingsProvider).activeDiverId();
  if (id == null) return null;
  return ref.watch(diverRepositoryProvider).findById(id);
});

/// Dives of the active diver, newest first. Invalidate after changes.
final logbookProvider = FutureProvider<List<Dive>>((ref) async {
  final diver = await ref.watch(activeDiverProvider.future);
  if (diver == null) return const [];
  return ref.watch(diveRepositoryProvider).listForDiver(diver.id!);
});

/// One dive with all samples, and the name of its diver.
final diveDetailProvider = FutureProvider.autoDispose
    .family<({Dive dive, String? diverName})?, String>((ref, id) async {
      final dive = await ref.watch(diveRepositoryProvider).findById(id);
      if (dive == null) return null;
      final diver = await ref
          .watch(diverRepositoryProvider)
          .findById(dive.diverId);
      return (dive: dive, diverName: diver?.name);
    });

extension RefreshDives on WidgetRef {
  /// Call after a dive was saved, deleted or restored.
  void refreshDives({String? diveId}) {
    invalidate(logbookProvider);
    if (diveId != null) invalidate(diveDetailProvider(diveId));
  }
}

/// Like [RefreshDives.refreshDives], for callbacks that outlive the widget
/// (e.g. the undo action of a snackbar).
void refreshDivesIn(ProviderContainer container, {String? diveId}) {
  container.invalidate(logbookProvider);
  if (diveId != null) container.invalidate(diveDetailProvider(diveId));
}
