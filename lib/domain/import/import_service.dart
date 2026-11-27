import '../dive/dive.dart';
import '../dive/dive_repository.dart';
import 'imported_dive.dart';
import 'plausibility.dart';

/// Time and depth tolerance for possible duplicates (ADR 0003).
const duplicateStartTolerance = Duration(minutes: 2);
const duplicateDepthToleranceM = 0.5;

enum ConfirmReason {
  /// Same source and id, but the content differs (T2.3).
  sameIdDifferentContent,

  /// Another id, but start and depth are close to a stored dive (T2.4).
  similar,
}

sealed class ImportResult {
  const ImportResult(this.dive);

  final ImportedDive dive;
}

class Saved extends ImportResult {
  const Saved(super.dive, this.saved);

  final Dive saved;
}

class SkippedDuplicate extends ImportResult {
  const SkippedDuplicate(super.dive, this.existingId);

  final String existingId;
}

class NeedsConfirmation extends ImportResult {
  const NeedsConfirmation(super.dive, this.reason, this.possibleMatchId);

  final ConfirmReason reason;
  final String possibleMatchId;
}

class Rejected extends ImportResult {
  const Rejected(super.dive, this.reason);

  final RejectReason reason;
}

class Failed extends ImportResult {
  const Failed(super.dive, this.error);

  final Object error;
}

/// Checks imported dives and saves them (ADR 0003, design.md §3).
class ImportService {
  ImportService(this._dives);

  final DiveRepository _dives;

  /// What [importDives] would do, without saving: for the preview.
  /// Dives that would be saved come back as [Saved] without an id.
  Future<List<ImportResult>> preview(
    String diverId,
    List<ImportedDive> dives,
  ) async {
    final results = <ImportResult>[];
    final inBatch = <String>{};
    for (final dive in dives) {
      final check = checkPlausibility(dive);
      if (check is Implausible) {
        results.add(Rejected(dive, check.reason));
        continue;
      }
      final clean = (check as Plausible).dive;
      if (!inBatch.add('${clean.source.name}:${clean.sourceId}')) {
        // Twice in one download; the first one decides.
        results.add(SkippedDuplicate(dive, ''));
        continue;
      }
      results.add(
        await _classify(diverId, dive, clean) ??
            Saved(dive, clean.toDive(diverId: diverId)),
      );
    }
    return results;
  }

  /// Saves each dive in its own transaction. Duplicates are skipped;
  /// dives that need confirmation are saved only when their index is in
  /// [confirmed]. Results keep the order of [dives].
  Future<List<ImportResult>> importDives(
    String diverId,
    List<ImportedDive> dives, {
    String? diveComputerId,
    Set<int> confirmed = const {},
  }) async {
    final results = <ImportResult>[];
    for (final (i, dive) in dives.indexed) {
      final check = checkPlausibility(dive);
      if (check is Implausible) {
        results.add(Rejected(dive, check.reason));
        continue;
      }
      final clean = (check as Plausible).dive;
      try {
        final found = await _classify(diverId, dive, clean);
        results.add(switch (found) {
          null => Saved(dive, await _save(clean, diverId, diveComputerId)),
          NeedsConfirmation(:final reason, :final possibleMatchId)
              when confirmed.contains(i) =>
            Saved(
              dive,
              reason == ConfirmReason.sameIdDifferentContent
                  ? await _replace(possibleMatchId, clean, diveComputerId)
                  : await _save(clean, diverId, diveComputerId),
            ),
          _ => found,
        });
      } on Object catch (e) {
        // One broken dive must not stop the others (T2.8).
        results.add(Failed(dive, e));
      }
    }
    return results;
  }

  /// A duplicate or a reason to ask; null when the dive is new.
  Future<ImportResult?> _classify(
    String diverId,
    ImportedDive original,
    ImportedDive dive,
  ) async {
    final same = await _dives.findBySource(diverId, dive.source, dive.sourceId);
    if (same != null) {
      return _sameContent(same, dive)
          ? SkippedDuplicate(original, same.id!)
          : NeedsConfirmation(
              original,
              ConfirmReason.sameIdDifferentContent,
              same.id!,
            );
    }
    final near = await _dives.listStartingBetween(
      diverId,
      dive.start.subtract(duplicateStartTolerance),
      dive.start.add(duplicateStartTolerance),
    );
    for (final other in near) {
      if ((other.maxDepthM - dive.maxDepthM).abs() <=
          duplicateDepthToleranceM) {
        return NeedsConfirmation(original, ConfirmReason.similar, other.id!);
      }
    }
    return null;
  }

  static bool _sameContent(Dive stored, ImportedDive dive) =>
      (stored.maxDepthM - dive.maxDepthM).abs() < 0.01 &&
      stored.durationS == dive.durationS &&
      _sameWallClock(stored.start, dive.start);

  static bool _sameWallClock(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute &&
      a.second == b.second;

  Future<Dive> _save(
    ImportedDive dive,
    String diverId,
    String? diveComputerId,
  ) async => (await _dives.save(
    dive.toDive(diverId: diverId, diveComputerId: diveComputerId),
  )).dive;

  /// Confirmed new content for a stored dive with the same source id:
  /// the measured data is replaced; number, site, notes and rating stay.
  Future<Dive> _replace(
    String id,
    ImportedDive dive,
    String? diveComputerId,
  ) async {
    final old = (await _dives.findById(id))!;
    final fresh = dive.toDive(
      diverId: old.diverId,
      diveComputerId: diveComputerId ?? old.diveComputerId,
    );
    return (await _dives.save(
      Dive(
        id: old.id,
        diverId: old.diverId,
        number: old.number,
        // A site set in the preview only fills an empty one (T25.3).
        siteName: old.siteName ?? fresh.siteName,
        siteCatalogueId: old.siteName != null
            ? old.siteCatalogueId
            : fresh.siteCatalogueId,
        siteLat: old.siteLat ?? fresh.siteLat,
        siteLon: old.siteLon ?? fresh.siteLon,
        diveComputerId: fresh.diveComputerId,
        source: fresh.source,
        sourceId: fresh.sourceId,
        start: fresh.start,
        utcOffsetS: fresh.utcOffsetS,
        durationS: fresh.durationS,
        maxDepthM: fresh.maxDepthM,
        avgDepthM: fresh.avgDepthM,
        minTemperatureC: fresh.minTemperatureC,
        maxTemperatureC: fresh.maxTemperatureC,
        waterType: old.waterType,
        notes: old.notes,
        rating: old.rating,
        // Lead and equipment are the user's (ADR 0007); null keeps the links.
        weightKg: old.weightKg,
        visibility: old.visibility,
        current: old.current,
        kinds: old.kinds,
        samples: fresh.samples,
        tanks: fresh.tanks,
        events: fresh.events,
      ),
    )).dive;
  }
}
