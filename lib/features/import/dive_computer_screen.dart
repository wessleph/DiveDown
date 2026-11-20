import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search, transfer and preview for the BLE import (ui-spec §5.6, §5.7, §5.9).
class DiveComputerScreen extends ConsumerStatefulWidget {
  const DiveComputerScreen({super.key});

  static const path = '/import/divecomputer';

  @override
  ConsumerState<DiveComputerScreen> createState() => _DiveComputerScreenState();
}

class _DiveComputerScreenState extends ConsumerState<DiveComputerScreen> {
  @override
  Widget build(BuildContext context) =>
      throw UnimplementedError('DiveComputerScreen');
}
