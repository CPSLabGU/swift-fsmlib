//
//  SCXMLWriterTests.swift
//
//  Created by Rene Hexel on 26/02/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

/// Tests for uncovered paths in `SCXMLWriter`.
///
/// These tests exercise:
/// - `generateFromGenericMachine` (non-SCXML boilerplate path)
/// - `generateBasicState` fallback
/// - `generateFSMLibBoilerplate` with CBoilerplate
/// - `generateDatamodel` with `src`/content attributes
/// - `stateOpenTag` with `initialChild`
/// - `generateSCXMLActivities` with internal/onSuspend/onResume sections
final class SCXMLWriterTests: XCTestCase {

    // MARK: - Generic Machine Path (non-SCXML boilerplate)

    /// Test that `generate(from:)` uses `generateFromGenericMachine` when the
    /// machine has a non-SCXML boilerplate (e.g., `CBoilerplate`).
    func testGenerateFromMachineWithCBoilerplate() throws {
        let machine = Machine()
        let state1 = State(name: "Alpha")
        let state2 = State(name: "Beta")
        let transition = Transition(label: "go", source: state1.id, target: state2.id)
        machine.llfsm = LLFSM(states: [state1, state2], transitions: [transition], suspendState: nil)
        machine.boilerplate = CBoilerplate()
        machine.language = CBinding()

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<?xml version=\"1.0\""))
        XCTAssertTrue(xml.contains("<scxml"))
        XCTAssertTrue(xml.contains("initial=\"Alpha\""))
        XCTAssertTrue(xml.contains("id=\"Alpha\""))
        XCTAssertTrue(xml.contains("id=\"Beta\""))
        XCTAssertTrue(xml.contains("<transition"))
        XCTAssertTrue(xml.contains("</scxml>"))
    }

    /// Test that a state with no transitions and no activities uses self-closing tag in generic path.
    func testGenerateGenericMachineEmptyState() throws {
        let machine = Machine()
        let state = State(name: "EmptyState")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = CBoilerplate()

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("id=\"EmptyState\""))
        XCTAssertTrue(xml.contains("/>"))  // self-closing
    }

    /// Test that the generic machine path embeds boilerplate sections as fsm:section elements.
    func testGenerateGenericMachineWithBoilerplateSections() throws {
        let machine = Machine()
        let state = State(name: "Main")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = CBoilerplate()
        bp.sections[.variables] = "int x = 0;"
        machine.boilerplate = bp
        machine.language = CBinding()

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<fsm:boilerplate>") || xml.contains("<fsm:section"))
    }

    /// Test that onEntry/onExit activities appear in the generic machine path.
    func testGenerateGenericMachineWithStateActivities() throws {
        let machine = Machine()
        let state = State(name: "Active")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = CBoilerplate()
        machine.setStateActivities([
            .onEntry: "startUp();",
            .onExit: "shutDown();"
        ], for: state.id)

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<onentry>"))
        XCTAssertTrue(xml.contains("startUp();"))
        XCTAssertTrue(xml.contains("<onexit>"))
        XCTAssertTrue(xml.contains("shutDown();"))
    }

    // MARK: - generateBasicState fallback

    /// Test that a machine with SCXMLBoilerplate but no metadata uses basic state generation.
    func testGenerateBasicStateViaNoMetadata() throws {
        let machine = Machine()
        let state1 = State(name: "S1")
        let state2 = State(name: "S2")
        let transition = Transition(label: "cond", source: state1.id, target: state2.id)
        machine.llfsm = LLFSM(states: [state1, state2], transitions: [transition], suspendState: nil)

        // Use non-SCXML boilerplate to trigger the basic state path
        machine.boilerplate = CBoilerplate()

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)
        XCTAssertTrue(xml.contains("id=\"S1\""))
        XCTAssertTrue(xml.contains("id=\"S2\""))

        // Restore SCXML boilerplate and check generateBasicTransition via no SCXML metadata
        let bp = SCXMLBoilerplate()
        machine.boilerplate = bp
        let xml2 = try writer.generate(from: machine)
        XCTAssertTrue(xml2.contains("cond=\"cond\""))
    }

    // MARK: - generateDatamodel with src and content

    /// Test that `<data>` elements with `src` attribute are correctly generated.
    func testGenerateDatamodelWithSrc() throws {
        let machine = Machine()
        let state = State(name: "Main")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.dataDeclarations = [
            DataDeclaration(id: "data1", expr: nil, src: "data.json")
        ]
        machine.boilerplate = bp

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<datamodel>"))
        XCTAssertTrue(xml.contains("id=\"data1\""))
        XCTAssertTrue(xml.contains("src=\"data.json\""))
    }

    /// Test that `<data>` elements with inline content generate body elements.
    func testGenerateDatamodelWithContent() throws {
        let machine = Machine()
        let state = State(name: "Main")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.dataDeclarations = [
            DataDeclaration(id: "inlineData", expr: nil, src: nil, content: "<someContent/>")
        ]
        machine.boilerplate = bp

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<datamodel>"))
        XCTAssertTrue(xml.contains("id=\"inlineData\""))
        XCTAssertTrue(xml.contains("</data>"))
    }

    // MARK: - stateOpenTag with initialChild

    /// Test that states with `initialChild` include the `initial=` attribute in the tag.
    func testStateOpenTagWithInitialChild() throws {
        let machine = Machine()
        let outer = State(name: "Outer")
        let inner1 = State(name: "Inner1")
        let inner2 = State(name: "Inner2")
        machine.llfsm = LLFSM(states: [outer, inner1, inner2], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[outer.id] = SCXMLStateMetadata(
            childStates: [inner1.id, inner2.id],
            initialChild: inner2.id
        )
        bp.stateMetadata[inner1.id] = SCXMLStateMetadata(parentState: outer.id)
        bp.stateMetadata[inner2.id] = SCXMLStateMetadata(parentState: outer.id)
        machine.boilerplate = bp

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("initial=\"Inner2\""))
        XCTAssertTrue(xml.contains("id=\"Outer\""))
    }

    // MARK: - generateSCXMLActivities with fsm:section extensions

    /// Test that `internal`, `onSuspend`, and `onResume` sections appear as `<fsm:section>` elements.
    func testSCXMLActivitiesExtensionSections() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.boilerplate = SCXMLBoilerplate()

        machine.setStateActivities([
            .internal: "internalCode();",
            .onSuspend: "suspendCode();",
            .onResume: "resumeCode();"
        ], for: state.id)

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<fsm:section name=\"internal\">"))
        XCTAssertTrue(xml.contains("internalCode();"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"onSuspend\">"))
        XCTAssertTrue(xml.contains("suspendCode();"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"onResume\">"))
        XCTAssertTrue(xml.contains("resumeCode();"))
    }

    // MARK: - generateFSMLibBoilerplateFromSections (extension sections)

    /// Test that extension sections are written inside `<fsm:boilerplate>` when using SCXML boilerplate.
    func testGenerateFSMLibBoilerplateFromSections() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.genericSections = [
            .includePath: "/usr/include",
            .includes: "#include <math.h>",
            .variables: "double pi = 3.14;",
            .functions: "double square(double x) { return x * x; }"
        ]
        machine.boilerplate = bp

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<fsm:boilerplate>"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"includePath\">"))
        XCTAssertTrue(xml.contains("/usr/include"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"includes\">"))
        XCTAssertTrue(xml.contains("#include <math.h>"))
    }
}
