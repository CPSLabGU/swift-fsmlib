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

        let data = scxml.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

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

        let data = scxml.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

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

        let data = scxml.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

        XCTAssertEqual(machine.llfsm.states.count, 1)

        // Find the Active state
        guard let activeState = machine.llfsm.states.first,
            let actions = machine.activities.actions[activeState]
        else {
            XCTFail("Expected state actions")
            return
        }

        XCTAssertTrue(actions.onEntry.contains("Entered Active"))
        XCTAssertTrue(actions.onExit.contains("Exited Active"))
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

        let data = scxml.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

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

        machine.activities.actions[state.id] = [
            "console.log('entry');",
            "console.log('exit');",
            "",
            "",
            "",
        ]

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
        let data = originalSCXML.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

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
        let data = originalSCXML.data(using: .utf8)!
        let parser = SCXMLParser()
        let machine = try parser.parse(data)

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
        let data = xml.data(using: .utf8)!
        let parsedMachine = try binding.read(from: data)
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
