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

/// libdivecomputer event names (`DiveEvent.type`) in German.
String eventLabel(AppLocalizations l10n, String type) => switch (type) {
  'gaschange' || 'gaschange2' => l10n.eventGasChange,
  'ascent' => l10n.eventAscent,
  'safetystop' || 'safetystop_mandatory' => l10n.eventSafetyStop,
  'decostop' => l10n.eventDeco,
  _ => type,
};
