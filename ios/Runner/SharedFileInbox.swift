import Flutter
import Foundation
import UIKit

/// Files other apps hand to DiveDown through "Open in" / "Share" (security.md
/// A2, T5.9). With LSSupportsOpeningDocumentsInPlace = false, iOS copies them
/// into Documents/Inbox. Only a path inside that folder goes to Dart, where
/// readSharedFile reads it into memory (≤ 10 MB) and deletes the copy.
enum SharedFileInbox {
  /// Documents/Inbox of this app.
  static func inbox() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Inbox", isDirectory: true)
  }

  /// The path of [url] if it is a regular local file inside [inbox] (after
  /// resolving symlinks and `..`), otherwise nil.
  static func acceptedPath(_ url: URL, inbox: URL) -> String? {
    guard url.isFileURL else { return nil }
    let file = url.standardizedFileURL.resolvingSymlinksInPath()
    let folder = inbox.standardizedFileURL.resolvingSymlinksInPath().path
    let prefix = folder.hasSuffix("/") ? folder : folder + "/"
    guard file.path.hasPrefix(prefix) else { return nil }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else { return nil }
    return file.path
  }
}

/// Receives shared files from the scene and hands them to Dart over
/// `io.github.wessleph.divedown/share` (lib/data/platform/share_channel.dart):
/// `initial` returns the file the app was opened with, later files arrive as
/// `shared`. Each message is `{name, path}` or `{name, error}`; the name is
/// only shown.
final class SharedFileReceiver: NSObject, FlutterSceneLifeCycleDelegate {
  private let channel: FlutterMethodChannel
  private var pending: [[String: Any]] = []
  private var dartListens = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "io.github.wessleph.divedown/share", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "initial" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.dartListens = true
      result(self.pending.isEmpty ? nil : self.pending.removeFirst())
      let rest = self.pending
      self.pending = []
      rest.forEach { self.channel.invokeMethod("shared", arguments: $0) }
    }
  }

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts, !contexts.isEmpty else { return false }
    return receive(contexts)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    receive(URLContexts)
  }

  private func receive(_ contexts: Set<UIOpenURLContext>) -> Bool {
    let files = contexts.map(\.url).filter(\.isFileURL)
    for url in files {
      let name = url.lastPathComponent
      let message: [String: Any]
      if let path = SharedFileInbox.acceptedPath(url, inbox: SharedFileInbox.inbox()) {
        message = ["name": name, "path": path]
      } else {
        message = ["name": name, "error": "unreadable"]
      }
      if dartListens {
        channel.invokeMethod("shared", arguments: message)
      } else {
        pending.append(message)
      }
    }
    return !files.isEmpty
  }
}
