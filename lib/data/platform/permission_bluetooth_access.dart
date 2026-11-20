import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/import/bluetooth_access.dart';
import 'device_channel.dart';

/// [BluetoothAccess] over permission_handler (security.md §4).
///
/// Android 12+: `BLUETOOTH_SCAN` (neverForLocation) and `BLUETOOTH_CONNECT`.
/// Android ≤ 11: the scan needs the location permission instead.
/// iOS: one Bluetooth permission; the radio state comes from the same
/// permission's service status.
class PermissionBluetoothAccess implements BluetoothAccess {
  PermissionBluetoothAccess({
    this._channel = const DeviceChannel(),
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform;

  final DeviceChannel _channel;
  final TargetPlatform _platform;

  bool get _android => _platform == TargetPlatform.android;

  Future<List<ph.Permission>> _permissions() async {
    if (!_android) return [ph.Permission.bluetooth];
    return await _channel.sdkInt() >= 31
        ? [ph.Permission.bluetoothScan, ph.Permission.bluetoothConnect]
        : [ph.Permission.locationWhenInUse];
  }

  @override
  Future<BluetoothReadiness> check() async {
    final statuses = [for (final p in await _permissions()) await p.status];
    return _readiness(statuses);
  }

  @override
  Future<BluetoothReadiness> requestPermission() async {
    final result = await (await _permissions()).request();
    return _readiness(result.values.toList());
  }

  Future<BluetoothReadiness> _readiness(
    List<ph.PermissionStatus> statuses,
  ) async {
    if (statuses.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return BluetoothReadiness.permanentlyDenied;
    }
    if (!statuses.every((s) => s.isGranted || s.isLimited)) {
      return BluetoothReadiness.needsPermission;
    }
    final on = _android
        ? await _channel.isBluetoothOn()
        : await ph.Permission.bluetooth.serviceStatus.isEnabled;
    return on ? BluetoothReadiness.ready : BluetoothReadiness.off;
  }

  @override
  Future<void> requestEnable() async {
    if (_android) await _channel.requestBluetoothEnable();
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();
}
