import Flutter
import UIKit
import XCTest

@testable import Runner

/// T20.9-T20.11: only files inside Documents/Inbox reach Dart (security.md A2).
/// Runs on the iOS simulator in CI (`xcodebuild test`, ci.yml job `ios`).
class SharedFileInboxTests: XCTestCase {
  private var root: URL!
  private var inbox: URL!

  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    inbox = root.appendingPathComponent("Documents/Inbox", isDirectory: true)
    try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: root)
  }

  private func write(_ url: URL) throws {
    try Data([0x0E, 0x10]).write(to: url)
  }

  func testT20_9_fileInInboxIsAccepted() throws {
    let file = inbox.appendingPathComponent("dive.fit")
    try write(file)
    let accepted = SharedFileInbox.acceptedPath(file, inbox: inbox)
    XCTAssertEqual(accepted, file.resolvingSymlinksInPath().path)
  }

  func testT20_10_fileOutsideInboxIsRefused() throws {
    let outside = root.appendingPathComponent("Documents/x.fit")
    try write(outside)
    XCTAssertNil(SharedFileInbox.acceptedPath(outside, inbox: inbox))

    let dotDot = URL(fileURLWithPath: inbox.path + "/../x.fit")
    XCTAssertNil(SharedFileInbox.acceptedPath(dotDot, inbox: inbox))

    let link = inbox.appendingPathComponent("link.fit")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
    XCTAssertNil(SharedFileInbox.acceptedPath(link, inbox: inbox))

    let sibling = root.appendingPathComponent("Documents/InboxEvil", isDirectory: true)
    try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)
    let evil = sibling.appendingPathComponent("x.fit")
    try write(evil)
    XCTAssertNil(SharedFileInbox.acceptedPath(evil, inbox: inbox))
  }

  func testT20_11_remoteUrlsDirectoriesAndMissingFilesAreRefused() throws {
    XCTAssertNil(
      SharedFileInbox.acceptedPath(URL(string: "https://example.org/x.fit")!, inbox: inbox))
    let dir = inbox.appendingPathComponent("folder.fit", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    XCTAssertNil(SharedFileInbox.acceptedPath(dir, inbox: inbox))
    XCTAssertNil(
      SharedFileInbox.acceptedPath(inbox.appendingPathComponent("gone.fit"), inbox: inbox))
  }
}
