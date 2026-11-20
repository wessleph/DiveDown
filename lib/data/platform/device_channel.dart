import 'package:flutter/services.dart';

import '../../domain/import/bluetooth_access.dart';

/// Small platform calls without a pub package (ui-spec §5.6, §5.7).
/// Android: `MainActivity.kt`; iOS: `AppDelegate.swift` (only keepScreenOn).
class DeviceChannel {
  const DeviceChannel([this._channel = const MethodChannel(channelName)]);

  static const channelName = 'io.github.wessleph.divedown/device';

  final MethodChannel _channel;

  /// Android API level.
  Future<int> sdkInt() async => (await _channel.invokeMethod<int>('sdkInt'))!;

  /// Android: whether the Bluetooth radio is on.
  Future<bool> isBluetoothOn() async =>
      await _channel.invokeMethod<bool>('isBluetoothOn') ?? false;

  /// Android: the system dialog „Bluetooth einschalten?“.
  Future<void> requestBluetoothEnable() =>
      _channel.invokeMethod<void>('requestBluetoothEnable');

  Future<void> keepScreenOn(bool on) =>
      _channel.invokeMethod<void>('keepScreenOn', on);
}

class ChannelScreenAwake implements ScreenAwake {
  const ChannelScreenAwake([this._channel = const DeviceChannel()]);

  final DeviceChannel _channel;

  @override
  Future<void> keepOn(bool on) => _channel.keepScreenOn(on);
}
