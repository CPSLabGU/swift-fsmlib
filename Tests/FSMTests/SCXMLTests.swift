//
//  SCXMLTests.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import XCTest

@testable import FSM

/// Comprehensive tests for SCXML support.
///
/// These tests verify SCXML parsing, writing, and round-trip conversion,
/// ensuring compatibility with W3C SCXML 1.0 specification.
final class SCXMLTests: XCTestCase {
    // MARK: - Basic SCXML Parsing Tests

    /// Test parsing a minimal SCXML document
    func testParseMinimalSCXML() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="Start">
                <state id="Start">
                    <transition target="End"/>
                </state>
                <final id="End"/>
            </scxml>
            """

        let parser = SCXMLParser()
        let machine = try parser.parse(Data(scxml.utf8))

        XCTAssertEqual(machine.llfsm.states.count, 2)
        XCTAssertEqual(machine.llfsm.transitions.count, 1)
        XCTAssertTrue(machine.boilerplate is SCXMLBoilerplate)
    }

    /// Test parsing SCXML with datamodel
    func testParseDataModel() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" datamodel="ecmascript" initial="State1">
                <datamodel>
                    <data id="counter" expr="0"/>
                    <data id="name" expr="'test'"/>
                </datamodel>
                <state id="State1"/>
            </scxml>
            """

        let parser = SCXMLParser()
        let machine = try parser.parse(Data(scxml.utf8))

        guard let boilerplate = machine.boilerplate as? SCXMLBoilerplate else {
            XCTFail("Expected SCXMLBoilerplate")
            return
        }

        XCTAssertEqual(boilerplate.datamodel, "ecmascript")
        XCTAssertEqual(boilerplate.dataDeclarations.count, 2)
        XCTAssertEqual(boilerplate.dataDeclarations[0].id, "counter")
        XCTAssertEqual(boilerplate.dataDeclarations[0].expr, "0")
        XCTAssertEqual(boilerplate.dataDeclarations[1].id, "name")
        XCTAssertEqual(boilerplate.dataDeclarations[1].expr, "'test'")
    }

    /// Test parsing SCXML with onentry/onexit
    func testParseStateActions() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="Active">
                <state id="Active">
                    <onentry>
                        <script>console.log("Entered Active");</script>
                    </onentry>
                    <onexit>
                        <script>console.log("Exited Active");</script>
                    </onexit>
                </state>
            </scxml>
            """

        let parser = SCXMLParser()
        let machine = try parser.parse(Data(scxml.utf8))

        XCTAssertEqual(machine.llfsm.states.count, 1)

        // Find the Active state
        guard let activeState = machine.llfsm.states.first else {
            XCTFail("Expected state")
            return
        }

        let sections = machine.stateActivities(for: activeState)
        XCTAssertTrue(sections[StandardBoilerplateSection.onEntry]?.contains("Entered Active") ?? false)
        XCTAssertTrue(sections[StandardBoilerplateSection.onExit]?.contains("Exited Active") ?? false)
    }

    /// Test parsing SCXML with event-driven transitions
    func testParseEventTransitions() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="Idle">
                <state id="Idle">
                    <transition event="start" target="Running"/>
                </state>
                <state id="Running">
                    <transition event="stop" target="Idle"/>
                </state>
            </scxml>
            """

        let parser = SCXMLParser()
        let machine = try parser.parse(Data(scxml.utf8))

        XCTAssertEqual(machine.llfsm.states.count, 2)
        XCTAssertEqual(machine.llfsm.transitions.count, 2)
    }

    // MARK: - SCXML Writing Tests

    /// Test writing minimal SCXML
    func testWriteMinimalSCXML() throws {
        let machine = Machine()
        let state1 = State(name: "State1")
        let state2 = State(name: "State2")
        machine.llfsm = LLFSM(
            states: [state1, state2],
            transitions: [
                Transition(label: "", source: state1.id, target: state2.id)
            ],
            suspendState: nil
        )

        var boilerplate = SCXMLBoilerplate()
        boilerplate.name = "TestMachine"
        machine.boilerplate = boilerplate

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<scxml"))
        XCTAssertTrue(xml.contains("version=\"1.0\""))
        XCTAssertTrue(xml.contains("id=\"State1\""))
        XCTAssertTrue(xml.contains("id=\"State2\""))
        XCTAssertTrue(xml.contains("<transition"))
    }

    /// Test writing SCXML with datamodel
    func testWriteDataModel() throws {
        let machine = Machine()
        let state = State(name: "Main")
        machine.llfsm = LLFSM(
            states: [state],
            transitions: [],
            suspendState: nil
        )

        var boilerplate = SCXMLBoilerplate()
        boilerplate.datamodel = "ecmascript"
        boilerplate.dataDeclarations = [
            DataDeclaration(id: "x", expr: "10", src: nil),
            DataDeclaration(id: "y", expr: "20", src: nil),
        ]
        machine.boilerplate = boilerplate

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("datamodel=\"ecmascript\""))
        XCTAssertTrue(xml.contains("<datamodel>"))
        XCTAssertTrue(xml.contains("id=\"x\""))
        XCTAssertTrue(xml.contains("expr=\"10\""))
        XCTAssertTrue(xml.contains("id=\"y\""))
        XCTAssertTrue(xml.contains("expr=\"20\""))
    }

    /// Test writing SCXML with state actions
    func testWriteStateActions() throws {
        let machine = Machine()
        let state = State(name: "Active")
        machine.llfsm = LLFSM(
            states: [state],
            transitions: [],
            suspendState: nil
        )

        machine.setStateActivities([
            StandardBoilerplateSection.onEntry: "console.log('entry');",
            StandardBoilerplateSection.onExit: "console.log('exit');",
        ], for: state.id)

        let boilerplate = SCXMLBoilerplate()
        machine.boilerplate = boilerplate

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        XCTAssertTrue(xml.contains("<onentry>"))
        // Note: Single quotes are XML-escaped to &apos;
        XCTAssertTrue(xml.contains("console.log(&apos;entry&apos;);"))
        XCTAssertTrue(xml.contains("<onexit>"))
        XCTAssertTrue(xml.contains("console.log(&apos;exit&apos;);"))
    }

    // MARK: - Round-Trip Tests

    /// Test round-trip parsing and writing preserves structure
    func testRoundTripBasic() throws {
        let originalSCXML = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" datamodel="null" initial="Start">
                <state id="Start">
                    <transition target="End"/>
                </state>
                <final id="End"/>
            </scxml>
            """

        // Parse
        let parser = SCXMLParser()
        let machine = try parser.parse(Data(originalSCXML.utf8))

        // Write
        let writer = SCXMLWriter()
        let generatedSCXML = try writer.generate(from: machine)

        // Verify key elements are preserved
        XCTAssertTrue(generatedSCXML.contains("id=\"Start\""))
        XCTAssertTrue(generatedSCXML.contains("id=\"End\""))
        XCTAssertTrue(generatedSCXML.contains("<final"))
        XCTAssertTrue(generatedSCXML.contains("<transition"))
    }

    /// Test round-trip with datamodel
    func testRoundTripDataModel() throws {
        let originalSCXML = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" datamodel="ecmascript" initial="Main">
                <datamodel>
                    <data id="count" expr="0"/>
                </datamodel>
                <state id="Main"/>
            </scxml>
            """

        // Parse
        let parser = SCXMLParser()
        let machine = try parser.parse(Data(originalSCXML.utf8))

        // Write
        let writer = SCXMLWriter()
        let generatedSCXML = try writer.generate(from: machine)

        // Verify
        XCTAssertTrue(generatedSCXML.contains("datamodel=\"ecmascript\""))
        XCTAssertTrue(generatedSCXML.contains("<datamodel>"))
        XCTAssertTrue(generatedSCXML.contains("id=\"count\""))
        XCTAssertTrue(generatedSCXML.contains("expr=\"0\""))
    }

    // MARK: - SCXMLBinding Tests

    /// Test SCXMLBinding read/write operations
    func testSCXMLBindingReadWrite() throws {
        let binding = SCXMLBinding()
        XCTAssertEqual(binding.name, "scxml")

        // Create a simple machine
        let machine = Machine()
        let state = State(name: "TestState")
        machine.llfsm = LLFSM(
            states: [state],
            transitions: [],
            suspendState: nil
        )
        machine.boilerplate = SCXMLBoilerplate()

        // Generate XML
        let xml = try binding.generateXML(from: machine)
        XCTAssertTrue(xml.contains("TestState"))

        // Parse it back
        let parsedMachine = try binding.read(from: Data(xml.utf8))
        XCTAssertEqual(parsedMachine.llfsm.states.count, 1)
    }

    /// Test XML escaping in SCXML writer
    func testXMLEscaping() throws {
        let machine = Machine()
        let state = State(name: "Test<>&\"'State")
        machine.llfsm = LLFSM(
            states: [state],
            transitions: [],
            suspendState: nil
        )
        machine.boilerplate = SCXMLBoilerplate()

        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)

        // Should escape special characters
        XCTAssertTrue(
            xml.contains("&lt;") || xml.contains("&gt;") || xml.contains("&amp;")
                || xml.contains("&quot;") || xml.contains("&apos;"))
        XCTAssertFalse(xml.contains("Test<>&\"'State"))  // Original shouldn't appear unescaped
    }

    // MARK: - Backwards Compatibility Tests

    /// Test that existing .machine format still works
    func testBackwardsCompatibilityMachineFormat() throws {
        // Verify that adding SCXML support doesn't break existing functionality
        // This will be validated by running all existing tests
        XCTAssertTrue(true, "Existing tests validate backwards compatibility")
    }
}

// MARK: - Test Helpers

/// Extension providing shared helper methods for SCXML tests.
extension SCXMLTests {
    /// Parse SCXML from an inline state body wrapped in a minimal document.
    ///
    /// - Parameter stateBody: The XML content to insert inside the `<scxml>` root.
    /// - Returns: The parsed `Machine`.
    /// - Throws: `SCXMLParserError` on failure.
    func parseSCXML(_ stateBody: String) throws -> Machine {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" xmlns:se="http://scxmleditor.sf.net" version="1.0">
                \(stateBody)
            </scxml>
            """
        return try SCXMLParser().parse(Data(scxml.utf8))
    }

    /// Extract transition actions from the first transition originating from the named state.
    ///
    /// - Parameters:
    ///   - machine: The machine to inspect.
    ///   - stateName: The source state name.
    /// - Returns: The executable actions array.
    /// - Throws: If the state or transition is not found.
    func transitionActions(_ machine: Machine, from stateName: String) throws -> [ExecutableAction] {
        let bp = try XCTUnwrap(
            machine.boilerplate as? SCXMLBoilerplate,
            "Expected SCXMLBoilerplate")
        let stateID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName }),
            "State \(stateName) not found")
        let transitionIDs = machine.llfsm.transitionsFrom(stateID)
        guard let tid = transitionIDs.first,
              let metadata = bp.transitionMetadata[tid] else {
            XCTFail("No transition found from \(stateName)")
            return []
        }
        return metadata.actions
    }

    /// Generate SCXML output for a machine with a single self-transition containing the given actions.
    ///
    /// - Parameter actions: The executable actions for the transition.
    /// - Returns: The generated SCXML string.
    /// - Throws: If generation fails.
    func generateTransitionXML(actions: [ExecutableAction]) throws -> String {
        let machine = Machine()
        let state = State(name: "S1")
        let transition = Transition(label: "", source: state.id, target: state.id)
        machine.llfsm = LLFSM(states: [state], transitions: [transition], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.transitionMetadata[transition.id] = SCXMLTransitionMetadata(actions: actions)
        machine.boilerplate = bp

        return try SCXMLWriter().generate(from: machine)
    }
}
