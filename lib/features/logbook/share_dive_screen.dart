import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// „Tauchgang teilen“ (ui-spec §5.16, T43).
class ShareDiveScreen extends ConsumerStatefulWidget {
  const ShareDiveScreen({super.key, required this.diveId});

  static String pathFor(String diveId) => '/logbook/dive/$diveId/share';

  final String diveId;

  @override
  ConsumerState<ShareDiveScreen> createState() => _ShareDiveScreenState();
}

class _ShareDiveScreenState extends ConsumerState<ShareDiveScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold();
}
