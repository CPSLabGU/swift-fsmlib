//
//  SCXMLBindingTests.swift
//
//  Created by Rene Hexel on 26/02/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

/// Tests for `SCXMLBinding` protocol methods, read/write paths, and boilerplate helpers.
///
/// These tests exercise `read(from:URL)`, `numberOfTransitions`, `expression`,
/// `target`, `boilerplate`, `stateBoilerplate`, `extractSections`,
/// `createBoilerplate`, `convertBoilerplate`, `createWrapper`,
/// and the no-op/throwing methods of the binding.
final class SCXMLBindingTests: XCTestCase {

    // MARK: - read(from:URL)

    /// Test that `SCXMLBinding.read(from:URL)` reads and parses an SCXML file.
    func testReadFromURL() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BindingReadTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="ReadState">
                <state id="ReadState"/>
            </scxml>
            """
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let machine = try binding.read(from: tmpURL)
        XCTAssertEqual(machine.llfsm.states.count, 1)
        let name = machine.llfsm.states.first.flatMap { machine.llfsm.stateName(for: $0) }
        XCTAssertEqual(name, "ReadState")
    }

    // MARK: - numberOfTransitions via storage

    /// Test `numberOfTransitions(for:stateName:)` via a file wrapper with SCXML data.
    func testNumberOfTransitionsViaStorage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1">
                    <transition target="S2"/>
                    <transition target="S2"/>
                </state>
                <state id="S2"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NTransTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let readStorage = try MachineFileWrapper(url: tmpURL)
        let count = binding.numberOfTransitions(for: readStorage, stateName: "S1")
        XCTAssertEqual(count, 2)
    }

    /// Test `numberOfTransitions` returns 0 when state is not found.
    func testNumberOfTransitionsForMissingState() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MissState_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let count = binding.numberOfTransitions(for: storage, stateName: "NonExistent")
        XCTAssertEqual(count, 0)
    }

    // MARK: - expression via storage

    /// Test `expression(of:for:stateName:)` returns the condition.
    func testExpressionViaStorage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1">
                    <transition cond="x &gt; 5" target="S1"/>
                </state>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExprTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let expr = binding.expression(of: 0, for: storage, stateName: "S1")
        XCTAssertEqual(expr, "x > 5")
    }

    /// Test `expression(of:for:stateName:)` returns the label when no condition metadata.
    func testExpressionFallsBackToLabel() throws {
        let machine = Machine()
        let state = State(name: "S1")
        let trans = Transition(label: "myLabel", source: state.id, target: state.id)
        machine.llfsm = LLFSM(states: [state], transitions: [trans], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LabelTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        let binding = SCXMLBinding()
        try binding.write(machine, to: tmpURL)

        let storage = try MachineFileWrapper(url: tmpURL)
        let expr = binding.expression(of: 0, for: storage, stateName: "S1")
        XCTAssertEqual(expr, "myLabel")
    }

    /// Test `expression(of:for:stateName:)` returns empty string when state is not found.
    func testExpressionForMissingState() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MissExpr_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let expr = binding.expression(of: 0, for: storage, stateName: "NonExistent")
        XCTAssertEqual(expr, "")
    }

    // MARK: - target via storage

    /// Test `target(of:for:stateName:with:)` returns a non-nil StateID for a valid transition.
    func testTargetViaStorage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1">
                    <transition target="S2"/>
                </state>
                <state id="S2"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TargetTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let states = storage.machine.llfsm.states.compactMap { storage.machine.llfsm.stateMap[$0] }
        let targetID = binding.target(of: 0, for: storage, stateName: "S1", with: states)
        XCTAssertNotNil(targetID)
    }

    /// Test `target(of:for:stateName:with:)` returns nil when state is not found.
    func testTargetForMissingState() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MissTgt_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let tgt = binding.target(of: 0, for: storage, stateName: "NonExistent", with: [])
        XCTAssertNil(tgt)
    }

    // MARK: - boilerplate via storage

    /// Test `boilerplate(for:)` returns the machine's boilerplate.
    func testBoilerplateViaStorage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BPTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let bp = binding.boilerplate(for: storage)
        XCTAssertTrue(bp is SCXMLBoilerplate)
    }

    /// Test `boilerplate(for:)` returns a default `SCXMLBoilerplate` when file data is empty.
    func testBoilerplateForStorageWithoutSCXMLDataReturnsDefault() {
        let binding = SCXMLBinding()
        let machine = Machine()
        machine.boilerplate = SCXMLBoilerplate()
        let storage = MachineFileWrapper(machine: machine, named: "empty.scxml")
        let bp = binding.boilerplate(for: storage)
        XCTAssertTrue(bp is SCXMLBoilerplate)
    }

    // MARK: - stateBoilerplate via storage

    /// Test `stateBoilerplate(for:stateName:)` returns boilerplate from machine when state exists.
    func testStateBoilerplateFromMachine() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SBPTest_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let binding = SCXMLBinding()
        let storage = try MachineFileWrapper(url: tmpURL)
        let bp = binding.stateBoilerplate(for: storage, stateName: "S1")
        XCTAssertTrue(bp is SCXMLBoilerplate)
    }

    // MARK: - extractSections / createBoilerplate / convertBoilerplate

    /// Test `extractSections(from:)` with an `SCXMLBoilerplate` returns its generic sections.
    func testExtractSectionsFromSCXMLBoilerplate() {
        let binding = SCXMLBinding()
        var bp = SCXMLBoilerplate()
        bp.genericSections = [.variables: "int x = 0;", .includes: "#include <stdio.h>"]
        let sections = binding.extractSections(from: bp)
        XCTAssertEqual(sections[.variables], "int x = 0;")
        XCTAssertEqual(sections[.includes], "#include <stdio.h>")
    }

    /// Test `extractSections(from:)` returns empty dict for non-SCXML boilerplate.
    func testExtractSectionsFromNonSCXMLBoilerplate() {
        let binding = SCXMLBinding()
        let sections = binding.extractSections(from: CBoilerplate())
        XCTAssertTrue(sections.isEmpty)
    }

    /// Test `createBoilerplate(from:)` creates an `SCXMLBoilerplate` with the given sections.
    func testCreateBoilerplate() {
        let binding = SCXMLBinding()
        let sections: [StandardBoilerplateSection: String] = [.variables: "int n = 0;"]
        let bp = binding.createBoilerplate(from: sections)
        guard let scxmlBP = bp as? SCXMLBoilerplate else {
            XCTFail("Expected SCXMLBoilerplate")
            return
        }
        XCTAssertEqual(scxmlBP.genericSections?[.variables], "int n = 0;")
    }

    /// Test `createStateBoilerplate(from:stateName:)` creates an `SCXMLBoilerplate`.
    func testCreateStateBoilerplate() {
        let binding = SCXMLBinding()
        let sections: [StandardBoilerplateSection: String] = [.onEntry: "doEntry();"]
        let bp = binding.createStateBoilerplate(from: sections, stateName: "S1")
        guard let scxmlBP = bp as? SCXMLBoilerplate else {
            XCTFail("Expected SCXMLBoilerplate")
            return
        }
        XCTAssertEqual(scxmlBP.genericSections?[.onEntry], "doEntry();")
    }

    /// Test `convertBoilerplate(from:sourceLanguage:)` captures source language name.
    func testConvertBoilerplate() {
        let binding = SCXMLBinding()
        let cBinding = CBinding()
        var cBP = CBoilerplate()
        cBP.sections[.variables] = "int x = 0;"
        let converted = binding.convertBoilerplate(from: cBP, sourceLanguage: cBinding)
        guard let scxmlBP = converted as? SCXMLBoilerplate else {
            XCTFail("Expected SCXMLBoilerplate")
            return
        }
        XCTAssertEqual(scxmlBP.targetLanguage, cBinding.name)
    }

    // MARK: - addCode (directory wrapper path)

    /// Test that `addCode(for:to:isSuspensible:)` adds an SCXML file to a directory wrapper.
    func testAddCodeToDirectoryWrapper() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()

        let storage = MachineDirectoryWrapper(machine: machine, named: "Test.scxml")
        let binding = SCXMLBinding()
        try binding.addCode(for: machine.llfsm, to: storage, isSuspensible: false)

        let hasScxml = storage.fileWrappers?.keys.contains("document.scxml") ?? false
        XCTAssertTrue(hasScxml)
    }

    // MARK: - Throwing arrangement methods

    /// Test that `addArrangementCode(for:to:isSuspensible:)` throws unsupportedOutputFormat.
    func testAddArrangementCodeThrows() {
        let binding = SCXMLBinding()
        let arrangement = Arrangement(namedInstances: [])
        let wrapper = ArrangementWrapper(for: arrangement, named: "Test.arrangement")
        XCTAssertThrowsError(
            try binding.addArrangementCode(for: [], to: wrapper, isSuspensible: false)
        ) { error in
            XCTAssertTrue(error is FSMError)
        }
    }

    /// Test that `addArrangementCMakeFile(for:to:isSuspensible:)` throws unsupportedOutputFormat.
    func testAddArrangementCMakeFileThrows() {
        let binding = SCXMLBinding()
        let arrangement = Arrangement(namedInstances: [])
        let wrapper = ArrangementWrapper(for: arrangement, named: "Test.arrangement")
        XCTAssertThrowsError(
            try binding.addArrangementCMakeFile(for: [], to: wrapper, isSuspensible: false)
        ) { error in
            XCTAssertTrue(error is FSMError)
        }
    }

    // MARK: - No-op protocol methods

    /// Test that the no-op methods on `SCXMLBinding` do not throw.
    func testNoOpMethods() throws {
        let binding = SCXMLBinding()
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let wrapper = FileWrapper(regularFileWithContents: Data())

        XCTAssertNoThrow(try binding.addLanguage(to: wrapper))
        XCTAssertNoThrow(try binding.add(layout: [:], to: storage))
        XCTAssertNoThrow(try binding.add(windowLayout: nil, to: storage))
        XCTAssertNoThrow(try binding.add(stateNames: [], to: storage))
        XCTAssertNoThrow(try binding.add(boilerplate: SCXMLBoilerplate(), to: storage))
        XCTAssertNoThrow(try binding.add(stateBoilerplate: SCXMLBoilerplate(), to: storage, for: "S1"))
        XCTAssertNoThrow(try binding.addInterface(for: machine.llfsm, to: storage, isSuspensible: false))
        XCTAssertNoThrow(try binding.addStateInterface(for: machine.llfsm, to: storage, isSuspensible: false))
        XCTAssertNoThrow(try binding.addStateCode(for: machine.llfsm, to: storage, isSuspensible: false))
        XCTAssertNoThrow(try binding.addTransitionCode(for: machine.llfsm, to: storage, isSuspensible: false))
        XCTAssertNoThrow(try binding.addCMakeFile(
            for: machine.llfsm, boilerplate: SCXMLBoilerplate(), to: storage, isSuspensible: false
        ))
    }

    // MARK: - createWrapper

    /// Test that `createWrapper(at:for:)` creates a `MachineFileWrapper`.
    func testCreateWrapper() throws {
        let binding = SCXMLBinding()
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()

        let url = URL(fileURLWithPath: "/tmp/created.scxml")
        let storage = try binding.createWrapper(at: url, for: machine)
        XCTAssertTrue(storage is MachineFileWrapper)
        XCTAssertEqual(storage.name, "created")
    }

    /// Test that `createWrapper(at:for:nil)` creates a `MachineFileWrapper` with a default machine.
    func testCreateWrapperNilMachine() throws {
        let binding = SCXMLBinding()
        let url = URL(fileURLWithPath: "/tmp/defaultMachine.scxml")
        let storage = try binding.createWrapper(at: url, for: nil)
        XCTAssertTrue(storage is MachineFileWrapper)
    }
}
