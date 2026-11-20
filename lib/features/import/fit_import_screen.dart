import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads the picked or shared FIT file and shows its preview
/// (ui-spec §5.8, §5.9).
class FitImportScreen extends ConsumerStatefulWidget {
  const FitImportScreen({super.key});

  static const path = '/import/fit';

  @override
  ConsumerState<FitImportScreen> createState() => _FitImportScreenState();
}

class _FitImportScreenState extends ConsumerState<FitImportScreen> {
  @override
  Widget build(BuildContext context) =>
      throw UnimplementedError('FitImportScreen');
}
