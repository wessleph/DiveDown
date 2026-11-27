import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dive/dive.dart';
import '../../l10n/app_localizations.dart';

// Display texts for a dive that list and detail share. Dates use the
// wall-clock fields of [Dive.start] as stored, never toLocal() (ADR 0004).

final dateFormat = DateFormat('dd.MM.yyyy', 'de');
final timeFormat = DateFormat('HH:mm', 'de');
final monthFormat = DateFormat.yMMMM('de');
final spokenDateFormat = DateFormat('d. MMMM', 'de');

IconData sourceIcon(DiveSource source) => switch (source) {
  DiveSource.diveComputer => Icons.watch_outlined,
  DiveSource.fit => Icons.description_outlined,
  DiveSource.appleHealth => Icons.watch,
  DiveSource.manual => Icons.edit_outlined,
};

String sourceLabel(AppLocalizations l10n, DiveSource source) =>
    switch (source) {
      DiveSource.diveComputer => l10n.sourceDiveComputer,
      DiveSource.fit => l10n.sourceFit,
      DiveSource.appleHealth => l10n.sourceAppleHealth,
      DiveSource.manual => l10n.sourceManual,
    };

String sourceSpoken(AppLocalizations l10n, DiveSource source) =>
    switch (source) {
      DiveSource.diveComputer => l10n.sourceSpokenDiveComputer,
      DiveSource.fit => l10n.sourceSpokenFit,
      DiveSource.appleHealth => l10n.sourceSpokenAppleHealth,
      DiveSource.manual => l10n.sourceSpokenManual,
    };

String waterTypeLabel(AppLocalizations l10n, WaterType type) => switch (type) {
  WaterType.salt => l10n.waterSalt,
  WaterType.fresh => l10n.waterFresh,
};

String visibilityLabel(AppLocalizations l10n, WaterVisibility v) => switch (v) {
  WaterVisibility.poor => l10n.visibilityPoor,
  WaterVisibility.moderate => l10n.visibilityModerate,
  WaterVisibility.good => l10n.visibilityGood,
  WaterVisibility.excellent => l10n.visibilityExcellent,
};

/// „Sicht gut“, for „Zuletzt bei …“ (T40).
String visibilityShort(AppLocalizations l10n, WaterVisibility v) => switch (v) {
  WaterVisibility.poor => l10n.visibilityShortPoor,
  WaterVisibility.moderate => l10n.visibilityShortModerate,
  WaterVisibility.good => l10n.visibilityShortGood,
  WaterVisibility.excellent => l10n.visibilityShortExcellent,
};

String currentLabel(AppLocalizations l10n, WaterCurrent c) => switch (c) {
  WaterCurrent.none => l10n.currentNone,
  WaterCurrent.light => l10n.currentLight,
  WaterCurrent.moderate => l10n.currentModerate,
  WaterCurrent.strong => l10n.currentStrong,
};

/// „Strömung leicht“, „keine Strömung“ (T40).
String currentShort(AppLocalizations l10n, WaterCurrent c) => switch (c) {
  WaterCurrent.none => l10n.currentShortNone,
  WaterCurrent.light => l10n.currentShortLight,
  WaterCurrent.moderate => l10n.currentShortModerate,
  WaterCurrent.strong => l10n.currentShortStrong,
};

String diveKindLabel(AppLocalizations l10n, DiveKind k) => switch (k) {
  DiveKind.reef => l10n.diveKindReef,
  DiveKind.wreck => l10n.diveKindWreck,
  DiveKind.wall => l10n.diveKindWall,
  DiveKind.cave => l10n.diveKindCave,
  DiveKind.night => l10n.diveKindNight,
  DiveKind.lake => l10n.diveKindLake,
  DiveKind.training => l10n.diveKindTraining,
  DiveKind.drift => l10n.diveKindDrift,
};

/// Kinds in their fixed order, e.g. „Wrack · Nacht“.
String diveKindsText(
  AppLocalizations l10n,
  Set<DiveKind> kinds, {
  String separator = ' · ',
}) => [
  for (final k in DiveKind.values)
    if (kinds.contains(k)) diveKindLabel(l10n, k),
].join(separator);

/// libdivecomputer event names (`DiveEvent.type`) in German (ui-spec §5.3).
String eventLabel(AppLocalizations l10n, String type) => switch (type) {
  'gaschange' || 'gaschange2' => l10n.eventGasChange,
  'ascent' => l10n.eventAscent,
  'safetystop' ||
  'safetystop_mandatory' ||
  'safetystop_voluntary' ||
  'ceiling_safetystop' => l10n.eventSafetyStop,
  'decostop' => l10n.eventDeco,
  'deepstop' => l10n.eventDeepStop,
  'ceiling' => l10n.eventCeiling,
  'violation' => l10n.eventViolation,
  'bookmark' => l10n.eventBookmark,
  'surface' => l10n.eventSurface,
  'rbt' => l10n.eventRbt,
  'airtime' => l10n.eventAirTime,
  'maxdepth' => l10n.eventMaxDepth,
  'divetime' => l10n.eventDiveTime,
  'workload' => l10n.eventWorkload,
  'transmitter' => l10n.eventTransmitter,
  'tissuelevel' => l10n.eventTissueLevel,
  'heading' => l10n.eventHeading,
  'floor' => l10n.eventFloor,
  'olf' => l10n.eventOlf,
  'po2' => l10n.eventPo2,
  'rgbm' => l10n.eventRgbm,
  _ => l10n.eventUnknown(type),
};

/// Events of one type within 60 s of the first, shown as one row with a
/// count (ui-spec §5.3): „Sicherheitsstopp 3×“.
class EventGroup {
  const EventGroup({
    required this.timeS,
    required this.type,
    required this.count,
  });

  final int timeS;
  final String type;
  final int count;
}

/// Groups [events] (sorted by time) for the detail list. An event joins the
/// latest group of its type when it is at most [windowS] after that group's
/// first event.
List<EventGroup> groupEvents(List<DiveEvent> events, {int windowS = 60}) {
  final groups = <EventGroup>[];
  final latest = <String, int>{}; // type -> index in groups
  for (final e in events) {
    final i = latest[e.type];
    if (i != null && e.timeS - groups[i].timeS <= windowS) {
      final g = groups[i];
      groups[i] = EventGroup(timeS: g.timeS, type: g.type, count: g.count + 1);
    } else {
      latest[e.type] = groups.length;
      groups.add(EventGroup(timeS: e.timeS, type: e.type, count: 1));
    }
  }
  return groups;
}

const _warningEvents = {
  'ascent',
  'ceiling',
  'violation',
  'decostop',
  'transmitter',
  'workload',
  'rbt',
  'maxdepth',
  'divetime',
  'airtime',
  'po2',
  'olf',
  'floor',
  'rgbm',
};

/// Events that warn the diver (red dot), the rest are information.
bool isWarningEvent(String type) => _warningEvents.contains(type);
