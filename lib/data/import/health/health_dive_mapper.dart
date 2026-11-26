// Turns a raw Apple Health workout into an ImportedDive (T6.1-T6.5).
//
// Derived from Submersion (GPL-3.0),
// lib/features/dive_import/data/services/healthkit_service.dart:
// deepest reading per second, temperature and heart rate matched to the
// nearest depth point within 30 s, wall-clock start. Rewritten for
// DiveDown's model; see THIRD_PARTY.md.

import '../../../domain/import/health_import.dart';
import '../../../domain/import/imported_dive.dart';

/// Widest gap between a depth point and a temperature or heart rate reading
/// for the two to belong together.
const healthMatchWindow = Duration(seconds: 30);

/// The dive for [workout]; null without any depth reading (T6.5).
ImportedDive? mapHealthDive(HealthWorkout workout) =>
    throw UnimplementedError();
