import Foundation

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
    // Phase 40: not implemented yet (T20.9-T20.11).
    return nil
  }
}
