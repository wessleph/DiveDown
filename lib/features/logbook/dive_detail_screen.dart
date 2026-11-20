import 'package:flutter/material.dart';

/// Tauchgang-Detail (ui-spec §5.3).
class DiveDetailScreen extends StatelessWidget {
  const DiveDetailScreen({super.key, required this.diveId});

  static String pathFor(String diveId) => '/logbook/dive/$diveId';

  final String diveId;

  @override
  Widget build(BuildContext context) =>
      throw UnimplementedError('T15: DiveDetailScreen');
}
