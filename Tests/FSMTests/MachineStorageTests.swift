//
//  MachineStorageTests.swift
//
//  Created by Rene Hexel on 26/02/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

/// Unit tests for `MachineStorage` protocol default implementations,
/// `MachineStorageFactory`, and `MachineFileWrapper`.
///
/// These tests exercise the `name` computed property, `write(to:)` default
/// implementation, and the factory's `create(for:format:at:)` method.
final class MachineStorageTests: XCTestCase {

    /// Temporary directory for file-system operations.
    let tempDir: URL = {
        let tmp = FileManager.default.temporaryDirectory
        let dir = tmp.appendingPathComponent("MachineStorageTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - MachineStorage.name (default implementation)

    /// Test that the `name` property strips the file extension from a filename.
    func testNameStripsExtension() {
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "MyMachine.scxml")
        XCTAssertEqual(storage.name, "MyMachine")
    }

    /// Test that the `name` property handles filenames without extension.
    func testNameNoExtension() {
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "NoExtension")
        XCTAssertEqual(storage.name, "NoExtension")
    }

    /// Test that the `name` property returns the first extension part for compound extensions.
    func testNameCompoundExtension() {
        let machine = Machine()
        // "swift.machine" is the extension for swift machines; after stripping last extension
        // the name computation stops at the first dot
        let storage = MachineFileWrapper(machine: machine, named: "MySwift.swift.machine")
        // MachineStorage.name uses lastIndex(of:".") so strips from the LAST dot
        XCTAssertEqual(storage.name, "MySwift.swift")
    }

    // MARK: - MachineStorage.write(to:) default implementation

    /// Test that the default `write(to:)` delegates to `write(to:options:)` for SCXML.
    func testDefaultWriteDelegatesToWriteWithOptions() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()
        machine.language = SCXMLBinding()

        let outputURL = tempDir.appendingPathComponent("Test.scxml")
        let storage = MachineFileWrapper(machine: machine, named: outputURL.lastPathComponent)
        try storage.write(to: outputURL)

        let content = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(content.contains("<scxml"))
        XCTAssertTrue(content.contains("id=\"S1\""))
    }

    // MARK: - MachineStorageFactory.create

    /// Test that `create` produces a `MachineFileWrapper` for SCXML format.
    func testCreateForSCXMLFormat() {
        let machine = Machine()
        let outputURL = tempDir.appendingPathComponent("Out.scxml")
        let storage = MachineStorageFactory.create(for: machine, format: .scxml, at: outputURL)
        XCTAssertTrue(storage is MachineFileWrapper)
    }

    /// Test that `create` produces a `MachineDirectoryWrapper` for machine format.
    func testCreateForMachineFormat() {
        let machine = Machine()
        let outputURL = tempDir.appendingPathComponent("Out.machine")
        let storage = MachineStorageFactory.create(for: machine, format: .c, at: outputURL)
        XCTAssertTrue(storage is MachineDirectoryWrapper)
    }

    /// Test that `create` infers format from URL extension when format is nil.
    func testCreateInfersFormatFromURL() {
        let machine = Machine()
        let outputURL = tempDir.appendingPathComponent("Inferred.scxml")
        let storage = MachineStorageFactory.create(for: machine, format: nil, at: outputURL)
        XCTAssertTrue(storage is MachineFileWrapper)
    }

    /// Test that `create` defaults to directory-based storage for unknown extensions.
    func testCreateDefaultsToDirectoryForUnknownExtension() {
        let machine = Machine()
        let outputURL = tempDir.appendingPathComponent("Unknown.xyz")
        let storage = MachineStorageFactory.create(for: machine, format: nil, at: outputURL)
        XCTAssertTrue(storage is MachineDirectoryWrapper)
    }

    /// Test that `create` with ObjCPP format produces a `MachineDirectoryWrapper`.
    func testCreateForObjCPPFormat() {
        let machine = Machine()
        let outputURL = tempDir.appendingPathComponent("Out.machine")
        let storage = MachineStorageFactory.create(for: machine, format: .objCX, at: outputURL)
        XCTAssertTrue(storage is MachineDirectoryWrapper)
    }

    // MARK: - MachineStorageFactory.read

    /// Test that `read(from:)` returns a `MachineDirectoryWrapper` for a directory.
    func testReadFromDirectory() throws {
        // Use an existing machine directory from test resources
        let resourceDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("TrafficLight.machine")
        guard FileManager.default.fileExists(atPath: resourceDir.path) else {
            throw XCTSkip("TrafficLight.machine resource not available")
        }
        let storage = try MachineStorageFactory.read(from: resourceDir)
        XCTAssertTrue(storage is MachineDirectoryWrapper)
    }

    /// Test that `read(from:)` returns a `MachineFileWrapper` for an SCXML file.
    func testReadFromSCXMLFile() throws {
        let scxmlURL = tempDir.appendingPathComponent("Read.scxml")
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        try scxml.write(to: scxmlURL, atomically: true, encoding: .utf8)

        let storage = try MachineStorageFactory.read(from: scxmlURL)
        XCTAssertTrue(storage is MachineFileWrapper)
        XCTAssertEqual(storage.machine.llfsm.states.count, 1)
    }
}
