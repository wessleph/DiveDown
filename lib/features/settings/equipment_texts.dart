import 'package:flutter/material.dart';

import '../../domain/equipment/equipment.dart';
import '../../l10n/app_localizations.dart';

/// German name of an equipment kind (ui-spec §5.11).
String equipmentKindLabel(AppLocalizations l10n, EquipmentKind kind) =>
    switch (kind) {
      EquipmentKind.suit => l10n.equipmentKindSuit,
      EquipmentKind.bcd => l10n.equipmentKindBcd,
      EquipmentKind.regulator => l10n.equipmentKindRegulator,
      EquipmentKind.computer => l10n.equipmentKindComputer,
      EquipmentKind.tank => l10n.equipmentKindTank,
      EquipmentKind.mask => l10n.equipmentKindMask,
      EquipmentKind.fins => l10n.equipmentKindFins,
      EquipmentKind.light => l10n.equipmentKindLight,
      EquipmentKind.other => l10n.equipmentKindOther,
    };

/// Icon of an equipment kind, in lists and chips.
IconData equipmentKindIcon(EquipmentKind kind) => switch (kind) {
  EquipmentKind.suit => Icons.checkroom,
  EquipmentKind.bcd => Icons.backpack_outlined,
  EquipmentKind.regulator => Icons.air,
  EquipmentKind.computer => Icons.watch_outlined,
  EquipmentKind.tank => Icons.propane_tank_outlined,
  EquipmentKind.mask => Icons.visibility_outlined,
  EquipmentKind.fins => Icons.scuba_diving,
  EquipmentKind.light => Icons.flashlight_on_outlined,
  EquipmentKind.other => Icons.category_outlined,
};

/// „6 kg“, „6,5 kg“: lead with at most one decimal and a comma.
String formatKg(double kg) {
  final rounded = (kg * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1).replaceAll('.', ',');
  return text;
}
