import 'package:flutter/material.dart';

/// Manuell eintragen / Bearbeiten (ui-spec §5.4).
class ManualDiveScreen extends StatelessWidget {
  const ManualDiveScreen({super.key, this.diveId});

  static const newPath = '/logbook/new';
  static String editPathFor(String diveId) => '/logbook/dive/$diveId/edit';

  /// The dive to edit; null for a new one.
  final String? diveId;

  @override
  Widget build(BuildContext context) =>
      throw UnimplementedError('T15: ManualDiveScreen');
}
