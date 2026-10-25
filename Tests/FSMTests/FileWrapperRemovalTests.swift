//
//  FileWrapperRemovalTests.swift
//  FSMTests
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM

/// Tests that removing a child from a file wrapper only changes the wrapper.
@Suite("File wrapper removal")
struct FileWrapperRemovalTests {
    /// The name of the file that is removed from the wrapper.
    static let removedName = "removed.txt"

    /// The name of the file that stays in the wrapper.
    static let keptName = "kept.txt"

    /// Creates a directory that holds the removed and the kept file.
    ///
    /// - Returns: The location of the new directory; the caller removes it.
    private func makeSourceDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-fsmlib-wrapper-removal-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("removed".utf8).write(to: directory.appendingPathComponent(Self.removedName))
        try Data("kept".utf8).write(to: directory.appendingPathComponent(Self.keptName))
        return directory
    }

    /// Reads a directory and removes the removed file from the wrapper.
    ///
    /// - Parameter source: The directory to read.
    /// - Returns: The wrapper without the removed file.
    private func wrapperWithoutRemovedFile(readFrom source: URL) throws -> FileWrapper {
        let wrapper = try FileWrapper(url: source, options: [.immediate, .withoutMapping])
        let removed = try #require(wrapper.fileWrappers?[Self.removedName])
        wrapper.removeFileWrapper(removed)
        return wrapper
    }

    /// Checks that removing a child changes only the wrapper.
    @Test("removing a child read from disk keeps the file on disk")
    func removalKeepsTheSourceFile() throws {
        let source = try makeSourceDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let wrapper = try wrapperWithoutRemovedFile(readFrom: source)
        #expect(wrapper.fileWrappers?[Self.removedName] == nil)
        #expect(wrapper.fileWrappers?[Self.keptName] != nil)
        #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent(Self.removedName).path))
    }

    /// Checks that writing to another location neither writes the removed child nor changes the source.
    @Test("writing elsewhere leaves out the removed child and keeps the source intact")
    func writingElsewhereKeepsTheSource() throws {
        let source = try makeSourceDirectory()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-fsmlib-wrapper-copy-" + UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: destination)
        }
        let wrapper = try wrapperWithoutRemovedFile(readFrom: source)
        try wrapper.write(to: destination, options: [], originalContentsURL: nil)
        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent(Self.keptName).path))
        #expect(!FileManager.default.fileExists(atPath: destination.appendingPathComponent(Self.removedName).path))
        #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent(Self.removedName).path))
        #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent(Self.keptName).path))
    }

    #if !canImport(Darwin)
    // Foundation provides the file wrapper on Darwin; elsewhere the package's own
    // file wrapper removes the files of removed children when it is written.
    /// Checks that writing over the source removes the file of the removed child.
    @Test("writing over the source removes the file of the removed child")
    func writingOverTheSourceRemovesTheFile() throws {
        let source = try makeSourceDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let wrapper = try wrapperWithoutRemovedFile(readFrom: source)
        try wrapper.write(to: source, options: [], originalContentsURL: nil)
        #expect(!FileManager.default.fileExists(atPath: source.appendingPathComponent(Self.removedName).path))
        #expect(FileManager.default.fileExists(atPath: source.appendingPathComponent(Self.keptName).path))
    }
    #endif
}
