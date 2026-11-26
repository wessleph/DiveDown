import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiveDownBackupExclusion") {
      registerBackupExclusion(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiveDownDevice") {
      registerDevice(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiveDownHealth") {
      healthDiveChannel = HealthDiveChannel(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DiveDownShare") {
      let receiver = SharedFileReceiver(messenger: registrar.messenger())
      sharedFileReceiver = receiver
      registrar.addSceneDelegate(receiver)
    }
  }

  /// Kept alive here; the registrar holds scene delegates weakly.
  private var sharedFileReceiver: SharedFileReceiver?

  /// Apple Health import, read only (T6); its handler holds it weakly.
  private var healthDiveChannel: HealthDiveChannel?

  /// Keeps the display on during a dive computer transfer (ui-spec §5.7).
  /// Counterpart of lib/data/platform/device_channel.dart; the Bluetooth calls
  /// there are Android only.
  private func registerDevice(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "io.github.wessleph.divedown/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "keepScreenOn", let on = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.isIdleTimerDisabled = on
      result(nil)
    }
  }

  /// Keeps the database folder out of iCloud backups (security.md O1 a), T11.9).
  /// Counterpart of lib/data/platform/backup_exclusion.dart.
  private func registerBackupExclusion(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "io.github.wessleph.divedown/backup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Read back for the iOS integration test (T20.12).
      if call.method == "isExcludedFromBackup" {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        do {
          result(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup)
        } catch {
          result(
            FlutterError(
              code: "read_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "exclude_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
