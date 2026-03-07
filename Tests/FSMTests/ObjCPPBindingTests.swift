//
//  ObjCPPBindingTests.swift
//
//  Created by Rene Hexel on 26/02/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

/// Unit tests for `ObjCPPBinding` protocol methods and associated free functions.
///
/// These tests exercise `extractSections`, `extractActivities`, `createStateBoilerplate`,
/// the URL-based and wrapper-based boilerplate helpers, and the protocol method
/// failure paths when given non-`MachineDirectoryWrapper` storage.
final class ObjCPPBindingTests: XCTestCase {

    // MARK: - extractSections

    /// Test that `extractSections` returns all sections from a `CBoilerplate`.
    func testExtractSectionsFromCBoilerplate() {
        var boilerplate = CBoilerplate()
        boilerplate.sections[.includes] = "#include <stdio.h>"
        boilerplate.sections[.variables] = "int x = 0;"
        boilerplate.sections[.functions] = "void foo() {}"

        let binding = ObjCPPBinding()
        let sections = binding.extractSections(from: boilerplate)
        XCTAssertEqual(sections[.includes], "#include <stdio.h>")
        XCTAssertEqual(sections[.variables], "int x = 0;")
        XCTAssertEqual(sections[.functions], "void foo() {}")
    }

    /// Test that `extractSections` returns empty dict for non-`CBoilerplate`.
    func testExtractSectionsFromNonCBoilerplateReturnsEmpty() {
        let binding = ObjCPPBinding()
        let sections = binding.extractSections(from: SCXMLBoilerplate())
        XCTAssertTrue(sections.isEmpty)
    }

    /// Test that `extractStateSections` delegates to `extractSections`.
    func testExtractStateSections() {
        var boilerplate = CBoilerplate()
        boilerplate.sections[.onEntry] = "doEntry();"

        let binding = ObjCPPBinding()
        let sections = binding.extractStateSections(from: boilerplate, stateName: "MyState")
        XCTAssertEqual(sections[.onEntry], "doEntry();")
    }

    // MARK: - extractActivities

    /// Test that `extractActivities` returns nil for non-`CBoilerplate`.
    func testExtractActivitiesFromNonCBoilerplateReturnsNil() {
        let binding = ObjCPPBinding()
        let result = binding.extractActivities(from: SCXMLBoilerplate(), stateName: "S1")
        XCTAssertNil(result)
    }

    /// Test that `extractActivities` returns nil when no activity sections exist.
    func testExtractActivitiesEmptyBoilerplateReturnsNil() {
        let binding = ObjCPPBinding()
        var boilerplate = CBoilerplate()
        // Remove all sections so none of the activity sections have values
        for section in StandardBoilerplateSection.allCases {
            boilerplate.sections[section] = nil
        }
        let result = binding.extractActivities(from: boilerplate, stateName: "S1")
        XCTAssertNil(result)
    }

    /// Test that `extractActivities` returns an array of activity strings for a populated boilerplate.
    func testExtractActivitiesReturnsArray() {
        let binding = ObjCPPBinding()
        var boilerplate = CBoilerplate()
        boilerplate.sections[.onEntry] = "onEntryCode();"
        boilerplate.sections[.onExit] = "onExitCode();"

        let result = binding.extractActivities(from: boilerplate, stateName: "S1")
        XCTAssertNotNil(result)
        // Should contain content for sections up to and including the last non-nil one
        XCTAssertTrue(result?.contains("onEntryCode();") ?? false)
    }

    // MARK: - createStateBoilerplate(from:activities:)

    /// Test that `createStateBoilerplate(from:activities:)` maps activities to sections.
    func testCreateStateBoilerplateFromActivities() {
        let binding = ObjCPPBinding()
        let activities = ["onEntryCode();", "onExitCode();", "internalCode();"]
        let boilerplate = binding.createStateBoilerplate(from: activities, stateName: "S1")
        guard let cBoilerplate = boilerplate as? CBoilerplate else {
            XCTFail("Expected CBoilerplate")
            return
        }
        // Activities are mapped to CBinding.activitySections in order
        XCTAssertNotNil(cBoilerplate.sections[CBinding.activitySections[0]])
    }

    // MARK: - Protocol methods with non-MachineDirectoryWrapper storage

    /// Test that `numberOfTransitions` returns 0 for non-directory storage.
    func testNumberOfTransitionsNonDirectoryStorageReturnsZero() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let count = binding.numberOfTransitions(for: storage, stateName: "S1")
        XCTAssertEqual(count, 0)
    }

    /// Test that `expression(of:for:stateName:)` returns empty string for non-directory storage.
    func testExpressionNonDirectoryStorageReturnsEmpty() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let expr = binding.expression(of: 0, for: storage, stateName: "S1")
        XCTAssertEqual(expr, "")
    }

    /// Test that `target(of:for:stateName:with:)` returns nil for non-directory storage.
    func testTargetNonDirectoryStorageReturnsNil() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let target = binding.target(of: 0, for: storage, stateName: "S1", with: [])
        XCTAssertNil(target)
    }

    /// Test that `suspendState(for:states:)` returns nil for non-directory storage.
    func testSuspendStateNonDirectoryStorageReturnsNil() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let result = binding.suspendState(for: storage, states: [])
        XCTAssertNil(result)
    }

    /// Test that `boilerplate(for:)` returns a default `CBoilerplate` for non-directory storage.
    func testBoilerplateNonDirectoryStorageReturnsDefault() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let bp = binding.boilerplate(for: storage)
        XCTAssertTrue(bp is CBoilerplate)
    }

    /// Test that `stateBoilerplate(for:stateName:)` returns a default `CBoilerplate` for non-directory storage.
    func testStateBoilerplateNonDirectoryStorageReturnsDefault() {
        let binding = ObjCPPBinding()
        let machine = Machine()
        let storage = MachineFileWrapper(machine: machine, named: "Test.scxml")
        let bp = binding.stateBoilerplate(for: storage, stateName: "S1")
        XCTAssertTrue(bp is CBoilerplate)
    }

    // MARK: - numberOfObjCPPTransitionsIn

    /// Test `numberOfObjCPPTransitionsIn(header:)` with matching content.
    func testNumberOfTransitionsInHeader() {
        let header = """
            class State_S1 : public CLState {
            public:
                virtual int numberOfTransitions() const { return 3; }
            };
            """
        XCTAssertEqual(numberOfObjCPPTransitionsIn(header: header), 3)
    }

    /// Test `numberOfObjCPPTransitionsIn(header:)` with no match returns zero.
    func testNumberOfTransitionsInHeaderNoMatch() {
        XCTAssertEqual(numberOfObjCPPTransitionsIn(header: "no transitions here"), 0)
    }

    // MARK: - targetStateIndexOfObjCPPTransition

    /// Test `targetStateIndexOfObjCPPTransition` with matching content.
    func testTargetStateIndexParsed() {
        // The regex pattern is: Transition_N.*int.*toState.*=[^0-9]*([0-9]*)
        let header = """
            virtual int Transition_0() const { int toState = 2; return toState; }
            virtual int Transition_1() const { int toState = 0; return toState; }
            """
        XCTAssertEqual(targetStateIndexOfObjCPPTransition(0, inHeader: header), 2)
        XCTAssertEqual(targetStateIndexOfObjCPPTransition(1, inHeader: header), 0)
    }

    /// Test `targetStateIndexOfObjCPPTransition` returns nil when not found.
    func testTargetStateIndexNotFound() {
        let result = targetStateIndexOfObjCPPTransition(99, inHeader: "no relevant content")
        XCTAssertNil(result)
    }

    // MARK: - suspendStateIndexOfObjCPPMachine

    /// Test `suspendStateIndexOfObjCPPMachine` with matching content.
    func testSuspendStateIndexParsed() {
        let impl = "setSuspendState(static_cast<CLState *>(_states[2]));"
        XCTAssertEqual(suspendStateIndexOfObjCPPMachine(inImplementation: impl), 2)
    }

    /// Test `suspendStateIndexOfObjCPPMachine` returns nil when absent.
    func testSuspendStateIndexNotFound() {
        XCTAssertNil(suspendStateIndexOfObjCPPMachine(inImplementation: "no suspend state"))
    }

    // MARK: - boilerplateofObjCPPMachine (wrapper version)

    /// Test that the wrapper-based boilerplate function returns a `CBoilerplate`.
    func testBoilerplateOfObjCPPMachineForWrapper() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = CBinding()

        let machineURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestBoilerplate_\(UUID().uuidString).machine")
        defer { try? FileManager.default.removeItem(at: machineURL) }
        try machine.write(to: machineURL, isSuspensible: false)

        let wrapper = try MachineDirectoryWrapper(url: machineURL)
        let bp = boilerplateofObjCPPMachine(for: wrapper)
        XCTAssertTrue(bp is CBoilerplate)
    }

    // MARK: - boilerplateofObjCPPState (wrapper version)

    /// Test that the wrapper-based state boilerplate function returns a `CBoilerplate`.
    func testBoilerplateOfObjCPPStateForWrapper() throws {
        let machine = Machine()
        let state = State(name: "TestState")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = CBinding()

        let machineURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestStateBoilerplate_\(UUID().uuidString).machine")
        defer { try? FileManager.default.removeItem(at: machineURL) }
        try machine.write(to: machineURL, isSuspensible: false)

        let wrapper = try MachineDirectoryWrapper(url: machineURL)
        let bp = boilerplateofObjCPPState("TestState", of: wrapper)
        XCTAssertTrue(bp is CBoilerplate)
    }
}
