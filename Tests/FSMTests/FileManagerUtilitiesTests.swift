import XCTest
@testable import FSM

/// Unit tests for the FileManager+Utilities extension.
///
/// These tests verify the correct behaviour of the currentDirectoryURL and currentDirectoryName properties
/// in various scenarios, ensuring cross-platform compatibility and correct path handling.
final class FileManagerUtilitiesTests: XCTestCase {
    /// Test that currentDirectoryURL returns a URL matching currentDirectoryPath.
    func testCurrentDirectoryURLMatchesPath() {
        let fm = FileManager.default
        let url = fm.currentDirectoryURL
        let path = fm.currentDirectoryPath
        XCTAssertEqual(url.path, path, "currentDirectoryURL's path should match currentDirectoryPath")
    }

    /// Test that currentDirectoryName returns the last path component of the current directory.
    func testCurrentDirectoryNameMatchesLastComponent() {
        let fm = FileManager.default
        let url = fm.currentDirectoryURL
        let expectedName = url.lastPathComponent
        XCTAssertEqual(fm.currentDirectoryName, expectedName, "currentDirectoryName should be the last path component of the current directory URL")
    }

    /// Test behaviour when changing the current directory.
    func testCurrentDirectoryNameAfterChangingDirectory() throws {
        let fm = FileManager.default
        let originalPath = fm.currentDirectoryPath
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
            FileManager.default.changeCurrentDirectoryPath(originalPath)
        }
        let changed = FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        XCTAssertTrue(changed, "Should be able to change to temporary directory")
        XCTAssertEqual(fm.currentDirectoryName, tempDir.lastPathComponent, "currentDirectoryName should update after changing directory")
    }
}
