import 'dart:typed_data';

import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

import '../../../domain/import/dive_computer_source.dart';

/// [DiveComputerSource] over the libdivecomputer plugin (ADR 0002).
/// Translates only; dives go through `importedFromParsedDive`.
class PluginDiveComputerSource implements DiveComputerSource {
  PluginDiveComputerSource(this._service);

  // ignore: unused_field
  final dc.DiveComputerService _service;

  /// Plugin error codes that mean the connection failed or broke off.
  static const connectionErrorCodes = {
    'connect_failed',
    'bond_failed',
    'not_found',
    'download_error',
  };

  @override
  Stream<DiscoveredComputer> discover() =>
      throw UnimplementedError('PluginDiveComputerSource.discover');

  @override
  Future<void> stopDiscovery() =>
      throw UnimplementedError('PluginDiveComputerSource.stopDiscovery');

  @override
  Stream<TransferEvent> download(
    DiscoveredComputer computer, {
    Uint8List? sinceFingerprint,
  }) => throw UnimplementedError('PluginDiveComputerSource.download');

  @override
  Future<void> submitPin(String pin) =>
      throw UnimplementedError('PluginDiveComputerSource.submitPin');

  @override
  Future<void> cancel() =>
      throw UnimplementedError('PluginDiveComputerSource.cancel');
}
