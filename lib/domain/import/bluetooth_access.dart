/// Whether the app can scan for dive computers (ui-spec §5.6).
enum BluetoothReadiness {
  ready,

  /// The radio is switched off.
  off,

  /// Not asked yet: show the explanation first, then the system dialog.
  needsPermission,

  /// Refused for good; only the system settings can change it.
  permanentlyDenied,
}

/// Runtime permissions and the Bluetooth radio (security.md §4).
abstract interface class BluetoothAccess {
  Future<BluetoothReadiness> check();

  /// Shows the system dialog. Returns the state afterwards; a refusal that
  /// can still be asked again comes back as [BluetoothReadiness.needsPermission].
  Future<BluetoothReadiness> requestPermission();

  /// Android: system dialog to switch Bluetooth on. iOS: no-op, the screen
  /// points to the Control Centre instead.
  Future<void> requestEnable();

  Future<void> openAppSettings();
}

/// Keeps the display on during a transfer (ui-spec §5.7).
abstract interface class ScreenAwake {
  Future<void> keepOn(bool on);
}
