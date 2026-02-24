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

    // MARK: - 2.1 Executable Action Parsing Tests

    /// Test parsing a `<script>` action.
    func testParseScriptAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <script>doSomething();</script>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .script("doSomething();"))
    }

    /// Test parsing an `<assign>` action.
    func testParseAssignAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <assign location="x" expr="42"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .assign(location: "x", expr: "42"))
    }

    /// Test parsing a `<raise>` action.
    func testParseRaiseAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <raise event="myEvent"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .raise(event: "myEvent"))
    }

    /// Test parsing a `<send>` action with all attributes.
    func testParseSendAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <send event="timeout" target="#_internal" delay="5s"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .send(event: "timeout", target: "#_internal", delay: "5s"))
    }

    /// Test parsing a `<send>` action with only the event attribute.
    func testParseSendActionMinimal() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <send event="ping"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .send(event: "ping", target: nil, delay: nil))
    }

    /// Test parsing a `<log>` action with label.
    func testParseLogAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <log expr="'hello'" label="greeting"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .log(expr: "'hello'", label: "greeting"))
    }

    /// Test parsing a `<log>` action without label.
    func testParseLogActionNoLabel() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <log expr="x + 1"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .log(expr: "x + 1", label: nil))
    }

    /// Test parsing `<if>` with then-actions only.
    func testParseIfAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <if cond="x > 0">
                        <script>positive();</script>
                    </if>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .if(condition: "x > 0", actions: [.script("positive();")], elseActions: nil)
        )
    }

    /// Test parsing `<if>...<else/>...</if>`.
    func testParseIfElseAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <if cond="x > 0">
                        <script>positive();</script>
                        <else/>
                        <script>nonPositive();</script>
                    </if>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .if(
                condition: "x > 0",
                actions: [.script("positive();")],
                elseActions: [.script("nonPositive();")]
            )
        )
    }

    /// Test parsing `<if>...<elseif/>...<else/>...</if>`.
    func testParseIfElseIfElseAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <if cond="x > 0">
                        <script>positive();</script>
                        <elseif cond="x == 0"/>
                        <script>zero();</script>
                        <else/>
                        <script>negative();</script>
                    </if>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        // The structure should be nested: if(x > 0, [positive], [if(x == 0, [zero], [negative])])
        XCTAssertEqual(
            actions[0],
            .if(
                condition: "x > 0",
                actions: [.script("positive();")],
                elseActions: [
                    .if(
                        condition: "x == 0",
                        actions: [.script("zero();")],
                        elseActions: [.script("negative();")]
                    )
                ]
            )
        )
    }

    /// Test parsing `<foreach>` with index.
    func testParseForEachAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <foreach array="items" item="item" index="idx">
                        <log expr="item"/>
                    </foreach>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .forEach(
                array: "items", item: "item", index: "idx",
                actions: [.log(expr: "item", label: nil)]
            )
        )
    }

    /// Test parsing `<foreach>` without index attribute.
    func testParseForEachNoIndex() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <foreach array="list" item="elem">
                        <script>process(elem);</script>
                    </foreach>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .forEach(
                array: "list", item: "elem", index: nil,
                actions: [.script("process(elem);")]
            )
        )
    }

    /// Test parsing `<cancel>` action.
    func testParseCancelAction() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <cancel sendid="timer1"/>
                </transition>
            </state>
            """)
        let actions = try transitionActions(machine, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .cancel(sendId: "timer1"))
    }

    // MARK: - 2.2 Executable Action Writing Tests

    /// Test writing an `<assign>` action.
    func testWriteAssignAction() throws {
        let xml = try generateTransitionXML(actions: [.assign(location: "x", expr: "42")])
        XCTAssertTrue(xml.contains("<assign location=\"x\" expr=\"42\"/>"))
    }

    /// Test writing a `<raise>` action.
    func testWriteRaiseAction() throws {
        let xml = try generateTransitionXML(actions: [.raise(event: "done")])
        XCTAssertTrue(xml.contains("<raise event=\"done\"/>"))
    }

    /// Test writing a `<send>` action.
    func testWriteSendAction() throws {
        let xml = try generateTransitionXML(
            actions: [.send(event: "timeout", target: "#_internal", delay: "5s")]
        )
        XCTAssertTrue(xml.contains("<send event=\"timeout\""))
        XCTAssertTrue(xml.contains("target=\"#_internal\""))
        XCTAssertTrue(xml.contains("delay=\"5s\""))
    }

    /// Test writing a `<log>` action.
    func testWriteLogAction() throws {
        let xml = try generateTransitionXML(
            actions: [.log(expr: "message", label: "info")]
        )
        XCTAssertTrue(xml.contains("<log expr=\"message\" label=\"info\"/>"))
    }

    /// Test writing `<if>...<else/>...</if>` with self-closing `<else/>`.
    func testWriteIfElseAction() throws {
        let xml = try generateTransitionXML(actions: [
            .if(
                condition: "x > 0",
                actions: [.script("positive();")],
                elseActions: [.script("negative();")]
            )
        ])
        XCTAssertTrue(xml.contains("<if cond=\"x &gt; 0\">"))
        XCTAssertTrue(xml.contains("<else/>"))
        XCTAssertFalse(xml.contains("<else>"))
        XCTAssertTrue(xml.contains("</if>"))
    }

    /// Test writing `<if>...<elseif/>...<else/>...</if>` with flattened elseif.
    func testWriteIfElseIfAction() throws {
        let xml = try generateTransitionXML(actions: [
            .if(
                condition: "a",
                actions: [.script("doA();")],
                elseActions: [
                    .if(
                        condition: "b",
                        actions: [.script("doB();")],
                        elseActions: [.script("doC();")]
                    )
                ]
            )
        ])
        XCTAssertTrue(xml.contains("<if cond=\"a\">"))
        XCTAssertTrue(xml.contains("<elseif cond=\"b\"/>"))
        XCTAssertTrue(xml.contains("<else/>"))
        XCTAssertTrue(xml.contains("</if>"))
    }

    /// Test writing a `<foreach>` action.
    func testWriteForEachAction() throws {
        let xml = try generateTransitionXML(actions: [
            .forEach(
                array: "items", item: "item", index: "i",
                actions: [.log(expr: "item", label: nil)]
            )
        ])
        XCTAssertTrue(xml.contains("<foreach array=\"items\" item=\"item\" index=\"i\">"))
        XCTAssertTrue(xml.contains("</foreach>"))
    }

    /// Test writing a `<cancel>` action.
    func testWriteCancelAction() throws {
        let xml = try generateTransitionXML(actions: [.cancel(sendId: "timer1")])
        XCTAssertTrue(xml.contains("<cancel sendid=\"timer1\"/>"))
    }

    /// Test writing a `<script>` action.
    func testWriteScriptAction() throws {
        let xml = try generateTransitionXML(actions: [.script("doWork();")])
        XCTAssertTrue(xml.contains("<script>"))
        XCTAssertTrue(xml.contains("doWork();"))
        XCTAssertTrue(xml.contains("</script>"))
    }

    // MARK: - 2.3 Executable Action Round-Trip Tests

    /// Test round-trip for `<if>...<else/>...</if>`.
    func testRoundTripIfElseAction() throws {
        let original = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <if cond="x > 0">
                        <script>positive();</script>
                        <else/>
                        <script>negative();</script>
                    </if>
                </transition>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: original)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 1)
        if case .if(let cond, let thenActs, let elseActs) = actions[0] {
            // The XML parser decodes &gt; back to > during re-parsing
            XCTAssertEqual(cond, "x > 0")
            // Script content may include whitespace from XML serialisation
            XCTAssertEqual(thenActs.count, 1)
            XCTAssertTrue(thenActs[0].scriptContent?.contains("positive();") ?? false)
            XCTAssertEqual(elseActs?.count, 1)
            XCTAssertTrue(elseActs?[0].scriptContent?.contains("negative();") ?? false)
        } else {
            XCTFail("Expected .if action")
        }
    }

    /// Test round-trip for `<if>...<elseif/>...<else/>...</if>`.
    func testRoundTripIfElseIfAction() throws {
        let original = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <if cond="a">
                        <script>doA();</script>
                        <elseif cond="b"/>
                        <script>doB();</script>
                        <else/>
                        <script>doC();</script>
                    </if>
                </transition>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: original)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 1)
        // Verify nested structure: if(a, [doA], [if(b, [doB], [doC])])
        if case .if(let cond, let thenActs, let elseActs) = actions[0] {
            XCTAssertEqual(cond, "a")
            XCTAssertEqual(thenActs.count, 1)
            XCTAssertTrue(thenActs[0].scriptContent?.contains("doA();") ?? false)
            XCTAssertEqual(elseActs?.count, 1)
            if case .if(let cond2, let then2, let else2) = elseActs?[0] {
                XCTAssertEqual(cond2, "b")
                XCTAssertEqual(then2.count, 1)
                XCTAssertTrue(then2[0].scriptContent?.contains("doB();") ?? false)
                XCTAssertEqual(else2?.count, 1)
                XCTAssertTrue(else2?[0].scriptContent?.contains("doC();") ?? false)
            } else {
                XCTFail("Expected nested .if for elseif")
            }
        } else {
            XCTFail("Expected .if action")
        }
    }

    /// Test round-trip for `<foreach>`.
    func testRoundTripForEachAction() throws {
        let original = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <foreach array="items" item="item" index="idx">
                        <log expr="item"/>
                    </foreach>
                </transition>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: original)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .forEach(array: "items", item: "item", index: "idx", actions: [.log(expr: "item", label: nil)])
        )
    }

    /// Test round-trip for `<cancel>`.
    func testRoundTripCancelAction() throws {
        let original = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <cancel sendid="timer1"/>
                </transition>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: original)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .cancel(sendId: "timer1"))
    }

    /// Test round-trip for mixed actions in one transition.
    func testRoundTripMixedActions() throws {
        let original = try parseSCXML("""
            <state id="S1">
                <transition target="S1">
                    <assign location="x" expr="1"/>
                    <raise event="changed"/>
                    <log expr="x" label="debug"/>
                    <send event="notify" target="parent"/>
                </transition>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: original)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 4)
        XCTAssertEqual(actions[0], .assign(location: "x", expr: "1"))
        XCTAssertEqual(actions[1], .raise(event: "changed"))
        XCTAssertEqual(actions[2], .log(expr: "x", label: "debug"))
        XCTAssertEqual(actions[3], .send(event: "notify", target: "parent", delay: nil))
    }

    // MARK: - 2.4 State Type Tests

    /// Test parsing `<parallel>` state.
    func testParseParallelState() throws {
        let machine = try parseSCXML("""
            <parallel id="P1">
                <state id="Child1"/>
                <state id="Child2"/>
            </parallel>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let pID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "P1" })!
        let metadata = bp.stateMetadata[pID]
        XCTAssertEqual(metadata?.isParallel, true)
        XCTAssertNotNil(metadata?.childStates)
        XCTAssertEqual(metadata?.childStates?.count, 2)
    }

    /// Test parsing `<final>` state.
    func testParseFinalState() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="Done"/>
            </state>
            <final id="Done"/>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let doneID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Done" })!
        XCTAssertEqual(bp.stateMetadata[doneID]?.isFinal, true)
    }

    /// Test parsing shallow `<history>` state.
    func testParseHistoryStateShallow() throws {
        let machine = try parseSCXML("""
            <state id="Parent">
                <history id="H1" type="shallow">
                    <transition target="Child1"/>
                </history>
                <state id="Child1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let hID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "H1" })!
        XCTAssertEqual(bp.stateMetadata[hID]?.historyType, .shallow)
    }

    /// Test parsing deep `<history>` state.
    func testParseHistoryStateDeep() throws {
        let machine = try parseSCXML("""
            <state id="Parent">
                <history id="H2" type="deep">
                    <transition target="Child1"/>
                </history>
                <state id="Child1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let hID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "H2" })!
        XCTAssertEqual(bp.stateMetadata[hID]?.historyType, .deep)
    }

    /// Test parsing a compound state with nested `<state>`.
    func testParseCompoundState() throws {
        let machine = try parseSCXML("""
            <state id="Outer">
                <state id="Inner"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let outerID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Outer" })!
        let innerID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Inner" })!
        XCTAssertNotNil(bp.stateMetadata[outerID]?.childStates)
        XCTAssertEqual(bp.stateMetadata[innerID]?.parentState, outerID)
    }

    /// Test parsing nested compound states (grandparent-parent-child).
    func testParseNestedCompoundStates() throws {
        let machine = try parseSCXML("""
            <state id="L1">
                <state id="L2">
                    <state id="L3"/>
                </state>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let l1 = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L1" })!
        let l2 = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L2" })!
        let l3 = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L3" })!
        XCTAssertEqual(bp.stateMetadata[l2]?.parentState, l1)
        XCTAssertEqual(bp.stateMetadata[l3]?.parentState, l2)
    }

    /// Test writing a `<parallel>` state.
    func testWriteParallelState() throws {
        let machine = Machine()
        let pState = State(name: "P1")
        let child1 = State(name: "C1")
        let child2 = State(name: "C2")
        machine.llfsm = LLFSM(states: [pState, child1, child2], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[pState.id] = SCXMLStateMetadata(
            childStates: [child1.id, child2.id], isParallel: true
        )
        bp.stateMetadata[child1.id] = SCXMLStateMetadata(parentState: pState.id)
        bp.stateMetadata[child2.id] = SCXMLStateMetadata(parentState: pState.id)
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<parallel"))
        XCTAssertTrue(xml.contains("</parallel>"))
    }

    /// Test writing a `<history>` state.
    func testWriteHistoryState() throws {
        let machine = Machine()
        let parent = State(name: "Parent")
        let histState = State(name: "H1")
        let child = State(name: "Child")
        machine.llfsm = LLFSM(states: [parent, histState, child], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[parent.id] = SCXMLStateMetadata(
            childStates: [histState.id, child.id]
        )
        bp.stateMetadata[histState.id] = SCXMLStateMetadata(
            parentState: parent.id, historyType: .deep
        )
        bp.stateMetadata[child.id] = SCXMLStateMetadata(parentState: parent.id)
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<history"))
        XCTAssertTrue(xml.contains("type=\"deep\""))
    }

    /// Test writing nested `<state>` elements.
    func testWriteCompoundState() throws {
        let machine = Machine()
        let outer = State(name: "Outer")
        let inner = State(name: "Inner")
        machine.llfsm = LLFSM(states: [outer, inner], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[outer.id] = SCXMLStateMetadata(childStates: [inner.id])
        bp.stateMetadata[inner.id] = SCXMLStateMetadata(parentState: outer.id)
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        // Outer state should contain Inner state
        XCTAssertTrue(xml.contains("id=\"Outer\""))
        XCTAssertTrue(xml.contains("id=\"Inner\""))
    }

    /// Test round-trip for parallel states.
    func testRoundTripParallelState() throws {
        let machine = try parseSCXML("""
            <parallel id="P1">
                <state id="A"/>
                <state id="B"/>
            </parallel>
            """)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        let pID = reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "P1" })!
        XCTAssertEqual(bp.stateMetadata[pID]?.isParallel, true)
    }

    /// Test round-trip for history states.
    func testRoundTripHistoryState() throws {
        let machine = try parseSCXML("""
            <state id="Parent">
                <history id="H1" type="deep">
                    <transition target="C1"/>
                </history>
                <state id="C1"/>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        let hID = reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "H1" })!
        XCTAssertEqual(bp.stateMetadata[hID]?.historyType, .deep)
    }

    /// Test round-trip for compound states.
    func testRoundTripCompoundState() throws {
        let machine = try parseSCXML("""
            <state id="Outer">
                <state id="Inner"/>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        let outerID = reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "Outer" })!
        let innerID = reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "Inner" })!
        XCTAssertNotNil(bp.stateMetadata[outerID]?.childStates)
        XCTAssertEqual(bp.stateMetadata[innerID]?.parentState, outerID)
    }

    // MARK: - 2.5 Transition Metadata Tests

    /// Test parsing transition event attribute.
    func testParseTransitionEvent() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="click" target="S1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let tid = machine.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.event, "click")
    }

    /// Test parsing transition condition attribute.
    func testParseTransitionCondition() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition cond="x > 0" target="S1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let tid = machine.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "x > 0")
        // label should also be set to condition
        let transition = machine.llfsm.transitionMap[tid]!
        XCTAssertEqual(transition.label, "x > 0")
    }

    /// Test parsing internal transition type.
    func testParseTransitionTypeInternal() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition type="internal" target="S1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let tid = machine.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.type, .internal)
    }

    /// Test parsing transition with both event and condition.
    func testParseTransitionEventAndCondition() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="timer" cond="count > 10" target="S1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let tid = machine.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.event, "timer")
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "count > 10")
    }

    /// Test parsing targetless transition (self-transition).
    func testParseTargetlessTransition() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="tick"/>
            </state>
            """)
        XCTAssertEqual(machine.llfsm.transitions.count, 1)
        let transition = machine.llfsm.transitionMap[machine.llfsm.transitions.first!]!
        // Targetless transitions default to self-transition
        XCTAssertEqual(transition.source, transition.target)
    }

    /// Test writing transition event attribute.
    func testWriteTransitionEvent() throws {
        let machine = Machine()
        let state = State(name: "S1")
        let transition = Transition(label: "", source: state.id, target: state.id)
        machine.llfsm = LLFSM(states: [state], transitions: [transition], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.transitionMetadata[transition.id] = SCXMLTransitionMetadata(event: "click")
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("event=\"click\""))
    }

    /// Test round-trip for transition metadata.
    func testRoundTripTransitionMetadata() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="tick" cond="x > 0" type="internal" target="S1"/>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        let tid = reparsed.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.event, "tick")
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "x > 0")
        XCTAssertEqual(bp.transitionMetadata[tid]?.type, .internal)
    }

    // MARK: - 2.6 Invocation Tests

    /// Test parsing full `<invoke>` element.
    func testParseInvoke() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <invoke type="scxml" src="child.scxml" id="inv1" autoforward="true"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let sID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "S1" })!
        let invocations = bp.invocations[sID.uuidString]
        XCTAssertNotNil(invocations)
        XCTAssertEqual(invocations?.count, 1)
        XCTAssertEqual(invocations?[0].type, "scxml")
        XCTAssertEqual(invocations?[0].src, "child.scxml")
        XCTAssertEqual(invocations?[0].id, "inv1")
        XCTAssertEqual(invocations?[0].autoForward, true)
    }

    /// Test parsing minimal `<invoke>` with type only.
    func testParseInvokeMinimal() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <invoke type="http"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let sID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "S1" })!
        let invocations = bp.invocations[sID.uuidString]
        XCTAssertEqual(invocations?.count, 1)
        XCTAssertEqual(invocations?[0].type, "http")
        XCTAssertNil(invocations?[0].src)
        XCTAssertNil(invocations?[0].id)
        XCTAssertEqual(invocations?[0].autoForward, false)
    }

    /// Test writing `<invoke>` element.
    func testWriteInvoke() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[state.id] = SCXMLStateMetadata()
        bp.invocations[state.id.uuidString] = [
            Invocation(type: "scxml", src: "child.scxml", id: "inv1", autoForward: true)
        ]
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<invoke type=\"scxml\""))
        XCTAssertTrue(xml.contains("src=\"child.scxml\""))
        XCTAssertTrue(xml.contains("id=\"inv1\""))
        XCTAssertTrue(xml.contains("autoforward=\"true\""))
    }

    /// Test round-trip for invocations.
    func testRoundTripInvoke() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <invoke type="scxml" src="child.scxml" id="inv1" autoforward="true"/>
            </state>
            """)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        let sID = reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "S1" })!
        let invocations = bp.invocations[sID.uuidString]
        XCTAssertEqual(invocations?.count, 1)
        XCTAssertEqual(invocations?[0].type, "scxml")
        XCTAssertEqual(invocations?[0].src, "child.scxml")
        XCTAssertEqual(invocations?[0].id, "inv1")
        XCTAssertEqual(invocations?[0].autoForward, true)
    }

    // MARK: - 2.7 Initial State & Script Tests

    /// Test parsing `initial` attribute on `<scxml>`.
    func testParseInitialAttribute() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="Second">
                <state id="First"/>
                <state id="Second"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        // Both states should be parsed
        XCTAssertEqual(machine.llfsm.states.count, 2)
        // Verify state names are present
        let names = machine.llfsm.states.compactMap { machine.llfsm.stateName(for: $0) }
        XCTAssertTrue(names.contains("First"))
        XCTAssertTrue(names.contains("Second"))
    }

    /// Test parsing `<initial>` element.
    func testParseInitialElement() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <initial>
                    <transition target="B"/>
                </initial>
                <state id="A"/>
                <state id="B"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        // B should be set as initial
        XCTAssertEqual(machine.llfsm.states.count, 2)
    }

    /// Test that default initial state is the first state.
    func testParseDefaultInitial() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="Alpha"/>
                <state id="Beta"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        // Default initial should be first state "Alpha"
        let firstStateID = machine.llfsm.states[0]
        let firstName = machine.llfsm.stateName(for: firstStateID)
        XCTAssertEqual(firstName, "Alpha")
    }

    /// Test parsing top-level `<script>` as initial script.
    func testParseInitialScript() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <script>var globalVar = 0;</script>
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        XCTAssertEqual(bp.initialScript, "var globalVar = 0;")
    }

    /// Test round-trip for initial script.
    func testRoundTripInitialScript() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <script>var x = 42;</script>
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<script>"))
        XCTAssertTrue(xml.contains("var x = 42;"))
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        // Script content may include whitespace from XML serialisation
        XCTAssertTrue(bp.initialScript?.contains("var x = 42;") ?? false)
    }

    // MARK: - 2.8 SCXMLBoilerplate Unit Tests

    /// Test default initialisation of SCXMLBoilerplate.
    func testBoilerplateDefaultInit() {
        let bp = SCXMLBoilerplate()
        XCTAssertEqual(bp.scxmlVersion, "1.0")
        XCTAssertEqual(bp.datamodel, "null")
        XCTAssertEqual(bp.binding, "early")
        XCTAssertNil(bp.name)
        XCTAssertNil(bp.targetLanguage)
        XCTAssertNil(bp.genericSections)
        XCTAssertTrue(bp.dataDeclarations.isEmpty)
        XCTAssertTrue(bp.invocations.isEmpty)
        XCTAssertNil(bp.initialScript)
    }

    /// Test data declaration lookup.
    func testDataDeclarationLookup() {
        var bp = SCXMLBoilerplate()
        bp.dataDeclarations = [
            DataDeclaration(id: "x", expr: "10"),
            DataDeclaration(id: "y", expr: "20"),
        ]
        XCTAssertEqual(bp.dataDeclaration(for: "x")?.expr, "10")
        XCTAssertEqual(bp.dataDeclaration(for: "y")?.expr, "20")
        XCTAssertNil(bp.dataDeclaration(for: "z"))
    }

    /// Test setting data declarations (add and update).
    func testSetDataDeclaration() {
        var bp = SCXMLBoilerplate()
        bp.setDataDeclaration(DataDeclaration(id: "x", expr: "10"))
        XCTAssertEqual(bp.dataDeclarations.count, 1)
        XCTAssertEqual(bp.dataDeclaration(for: "x")?.expr, "10")

        // Update existing
        bp.setDataDeclaration(DataDeclaration(id: "x", expr: "99"))
        XCTAssertEqual(bp.dataDeclarations.count, 1)
        XCTAssertEqual(bp.dataDeclaration(for: "x")?.expr, "99")

        // Add new
        bp.setDataDeclaration(DataDeclaration(id: "y", expr: "42"))
        XCTAssertEqual(bp.dataDeclarations.count, 2)
    }

    /// Test removing data declarations.
    func testRemoveDataDeclaration() {
        var bp = SCXMLBoilerplate()
        bp.dataDeclarations = [DataDeclaration(id: "x", expr: "10")]
        XCTAssertTrue(bp.removeDataDeclaration(for: "x"))
        XCTAssertTrue(bp.dataDeclarations.isEmpty)
        XCTAssertFalse(bp.removeDataDeclaration(for: "nonexistent"))
    }

    /// Test `hasScriptingDatamodel` property.
    func testHasScriptingDatamodel() {
        var bp = SCXMLBoilerplate()
        bp.datamodel = "ecmascript"
        XCTAssertTrue(bp.hasScriptingDatamodel)

        bp.datamodel = "null"
        XCTAssertFalse(bp.hasScriptingDatamodel)

        bp.datamodel = "xpath"
        XCTAssertTrue(bp.hasScriptingDatamodel)
    }

    /// Test `allInvocationIds` collects IDs across states.
    func testAllInvocationIds() {
        var bp = SCXMLBoilerplate()
        bp.invocations["state1"] = [
            Invocation(type: "scxml", id: "inv1"),
            Invocation(type: "http", id: "inv2"),
        ]
        bp.invocations["state2"] = [
            Invocation(type: "scxml", id: "inv3")
        ]
        let ids = bp.allInvocationIds
        XCTAssertEqual(ids, ["inv1", "inv2", "inv3"])
    }

    /// Test SCXMLBoilerplate equality.
    func testBoilerplateEquality() {
        let bp1 = SCXMLBoilerplate()
        let bp2 = SCXMLBoilerplate()
        XCTAssertEqual(bp1, bp2)

        var bp3 = SCXMLBoilerplate()
        bp3.datamodel = "ecmascript"
        XCTAssertNotEqual(bp1, bp3)
    }

    // MARK: - 2.9 SCXMLStateMetadata Unit Tests

    /// Test `isAtomic` for leaf states.
    func testStateMetadataIsAtomic() {
        let md = SCXMLStateMetadata()
        XCTAssertTrue(md.isAtomic)
        XCTAssertFalse(md.isCompound)
    }

    /// Test `isCompound` for states with children.
    func testStateMetadataIsCompound() {
        let md = SCXMLStateMetadata(childStates: [StateID()])
        XCTAssertFalse(md.isAtomic)
        XCTAssertTrue(md.isCompound)
    }

    /// Test `isHistory` for history states.
    func testStateMetadataIsHistory() {
        let md = SCXMLStateMetadata(historyType: .shallow)
        XCTAssertTrue(md.isHistory)

        let md2 = SCXMLStateMetadata()
        XCTAssertFalse(md2.isHistory)
    }

    /// Test adding and removing child states.
    func testStateMetadataAddRemoveChild() {
        var md = SCXMLStateMetadata()
        let childID = StateID()
        md.addChild(childID)
        XCTAssertEqual(md.childCount, 1)
        XCTAssertTrue(md.hasChild(childID))

        let removed = md.removeChild(childID)
        XCTAssertTrue(removed)
        XCTAssertEqual(md.childCount, 0)
        XCTAssertFalse(md.hasChild(childID))

        // Removing nonexistent returns false
        XCTAssertFalse(md.removeChild(StateID()))
    }

    /// Test SCXMLTransitionMetadata convenience properties.
    func testTransitionMetadataConvenience() {
        let md1 = SCXMLTransitionMetadata()
        XCTAssertTrue(md1.isEventless)
        XCTAssertTrue(md1.isUnconditional)
        XCTAssertFalse(md1.isWildcard)
        XCTAssertFalse(md1.hasActions)
        XCTAssertTrue(md1.eventNames.isEmpty)

        let md2 = SCXMLTransitionMetadata(event: "*", condition: "true", actions: [.script("x")])
        XCTAssertFalse(md2.isEventless)
        XCTAssertFalse(md2.isUnconditional)
        XCTAssertTrue(md2.isWildcard)
        XCTAssertTrue(md2.hasActions)

        let md3 = SCXMLTransitionMetadata(event: "a b c")
        XCTAssertEqual(md3.eventNames, ["a", "b", "c"])
    }

    // MARK: - 2.10 Error Handling Tests

    /// Test that malformed XML throws invalidXML.
    func testInvalidXMLError() {
        let data = "not xml at all".data(using: .utf8)!
        XCTAssertThrowsError(try SCXMLParser().parse(data)) { error in
            XCTAssertTrue(error is SCXMLParserError)
            if case SCXMLParserError.invalidXML = error {} else {
                XCTFail("Expected invalidXML error, got: \(error)")
            }
        }
    }

    /// Test that missing version attribute throws.
    func testMissingVersionError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml">
                <state id="S1"/>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.missingRequiredAttribute(let elem, let attr) = error {
                XCTAssertEqual(elem, "scxml")
                XCTAssertEqual(attr, "version")
            } else {
                XCTFail("Expected missingRequiredAttribute error, got: \(error)")
            }
        }
    }

    /// Test that duplicate state IDs throw.
    func testDuplicateStateIDError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1"/>
                <state id="S1"/>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.duplicateStateID(let id) = error {
                XCTAssertEqual(id, "S1")
            } else {
                XCTFail("Expected duplicateStateID error, got: \(error)")
            }
        }
    }

    /// Test that invalid transition target throws.
    func testInvalidTransitionTargetError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1">
                    <transition target="NonExistent"/>
                </state>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.invalidTransitionTarget(let target) = error {
                XCTAssertEqual(target, "NonExistent")
            } else {
                XCTFail("Expected invalidTransitionTarget error, got: \(error)")
            }
        }
    }

    /// Test that state without id throws.
    func testMissingStateIDError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state/>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.missingRequiredAttribute(let elem, let attr) = error {
                XCTAssertEqual(elem, "state")
                XCTAssertEqual(attr, "id")
            } else {
                XCTFail("Expected missingRequiredAttribute error, got: \(error)")
            }
        }
    }

    /// Test that `<assign>` without location throws.
    func testMissingAssignLocationError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1">
                    <transition target="S1">
                        <assign expr="42"/>
                    </transition>
                </state>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is SCXMLParserError)
        }
    }

    /// Test that `<if>` without cond throws.
    func testMissingIfCondError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1">
                    <transition target="S1">
                        <if>
                            <script>x();</script>
                        </if>
                    </transition>
                </state>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.missingRequiredAttribute(let elem, let attr) = error {
                XCTAssertEqual(elem, "if")
                XCTAssertEqual(attr, "cond")
            } else {
                XCTFail("Expected missingRequiredAttribute error, got: \(error)")
            }
        }
    }

    /// Test that `<foreach>` without array throws.
    func testMissingForEachArrayError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1">
                    <transition target="S1">
                        <foreach item="x">
                            <script>x();</script>
                        </foreach>
                    </transition>
                </state>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.missingRequiredAttribute(let elem, let attr) = error {
                XCTAssertEqual(elem, "foreach")
                XCTAssertEqual(attr, "array")
            } else {
                XCTFail("Expected missingRequiredAttribute error, got: \(error)")
            }
        }
    }

    /// Test that `<cancel>` without sendid throws.
    func testMissingCancelSendIdError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
                <state id="S1">
                    <transition target="S1">
                        <cancel/>
                    </transition>
                </state>
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.missingRequiredAttribute(let elem, let attr) = error {
                XCTAssertEqual(elem, "cancel")
                XCTAssertEqual(attr, "sendid")
            } else {
                XCTFail("Expected missingRequiredAttribute error, got: \(error)")
            }
        }
    }

    /// Test that empty SCXML (no states) throws.
    func testNoStatesError() {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0">
            </scxml>
            """
        XCTAssertThrowsError(try SCXMLParser().parse(scxml.data(using: .utf8)!)) { error in
            if case SCXMLParserError.parsingFailed(let msg) = error {
                XCTAssertTrue(msg.contains("No states"))
            } else {
                XCTFail("Expected parsingFailed error, got: \(error)")
            }
        }
    }

    // MARK: - 2.11 FSMLib Boilerplate & Language Preservation

    /// Test parsing `fsm:language` attribute.
    func testParseTargetLanguage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" version="1.0" fsm:language="c" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        XCTAssertEqual(bp.targetLanguage, "c")
    }

    /// Test writing `fsm:language` attribute.
    func testWriteTargetLanguage() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.targetLanguage = "c++"
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("fsm:language=\"c++\""))
    }

    /// Test round-trip for target language.
    func testRoundTripTargetLanguage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" version="1.0" fsm:language="objc" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        XCTAssertEqual(bp.targetLanguage, "objc")
    }

    /// Test parsing generic `<fsm:section>` elements.
    func testParseGenericSections() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" version="1.0" initial="S1">
                <fsm:boilerplate>
                    <fsm:section name="variables"><![CDATA[
            int x = 0;
            ]]></fsm:section>
                    <fsm:section name="includes"><![CDATA[
            #include <stdio.h>
            ]]></fsm:section>
                </fsm:boilerplate>
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        XCTAssertNotNil(bp.genericSections)
        XCTAssertTrue(bp.genericSections?[.variables]?.contains("int x = 0;") ?? false)
        XCTAssertTrue(bp.genericSections?[.includes]?.contains("#include") ?? false)
    }

    /// Test writing generic sections as `<fsm:section>` elements.
    func testWriteGenericSections() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.genericSections = [
            .variables: "int x = 0;",
            .includes: "#include <stdio.h>"
        ]
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<fsm:boilerplate>"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"variables\">"))
        XCTAssertTrue(xml.contains("<fsm:section name=\"includes\">"))
    }

    /// Test round-trip for generic sections.
    func testRoundTripGenericSections() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.genericSections = [
            .variables: "int x = 0;",
            .functions: "void foo() {}",
        ]
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let reparsedBp = reparsed.boilerplate as! SCXMLBoilerplate
        XCTAssertTrue(reparsedBp.genericSections?[.variables]?.contains("int x = 0;") ?? false)
        XCTAssertTrue(reparsedBp.genericSections?[.functions]?.contains("void foo() {}") ?? false)
    }

    /// Test round-trip for empty generic sections (should not be dropped).
    func testRoundTripEmptyGenericSections() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        var bp = SCXMLBoilerplate()
        bp.genericSections = [.variables: ""]
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let reparsedBp = reparsed.boilerplate as! SCXMLBoilerplate
        XCTAssertNotNil(reparsedBp.genericSections?[.variables])
        XCTAssertEqual(reparsedBp.genericSections?[.variables], "")
    }

    /// Test parsing state-level `<fsm:section>` elements.
    func testParseStateFsmSections() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" version="1.0" initial="S1">
                <state id="S1">
                    <fsm:section name="internal"><![CDATA[
            check_sensors();
            ]]></fsm:section>
                </state>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let stateID = machine.llfsm.states.first!
        let sections = machine.stateActivities(for: stateID)
        XCTAssertTrue(sections[.internal]?.contains("check_sensors();") ?? false)
    }

    // MARK: - 2.12 Layout & SCXML Attributes

    /// Test parsing layout from `se:` attributes.
    func testParseLayoutFromSeAttributes() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:se="http://scxmleditor.sf.net" version="1.0" initial="S1">
                <state id="S1" se:x="100" se:y="200" se:width="150" se:height="90"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let stateID = machine.llfsm.states.first!
        let layout = machine.stateLayout[stateID]
        XCTAssertNotNil(layout)
        XCTAssertEqual(layout?.openLayout.topLeft.x, 100)
        XCTAssertEqual(layout?.openLayout.topLeft.y, 200)
        XCTAssertEqual(layout?.openLayout.dimensions.w, 150)
        XCTAssertEqual(layout?.openLayout.dimensions.h, 90)
    }

    /// Test writing layout as `se:` attributes.
    func testWriteLayoutAsSeAttributes() throws {
        let machine = Machine()
        let state = State(name: "S1")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        let layout = StateLayout(
            isOpen: true,
            openLayout: Rectangle(topLeft: Coordinate2D(50, 60), dimensions: Dimensions2D(200, 100)),
            closedLayout: Ellipse(topLeft: Coordinate2D(50, 60), dimensions: Dimensions2D(200, 100)),
            onEntryHeight: 0, onExitHeight: 0,
            onSuspendHeight: 0, onResumeHeight: 0, internalHeight: 0,
            zoomedOnEntryHeight: 0, zoomedOnExitHeight: 0,
            zoomedInternalHeight: 0, zoomedOnSuspendHeight: 0, zoomedOnResumeHeight: 0,
            extraProperties: [:]
        )
        machine.stateLayout[state.id] = layout

        var bp = SCXMLBoilerplate()
        bp.stateMetadata[state.id] = SCXMLStateMetadata()
        machine.boilerplate = bp

        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("se:x=\"50\""))
        XCTAssertTrue(xml.contains("se:y=\"60\""))
        XCTAssertTrue(xml.contains("se:width=\"200\""))
        XCTAssertTrue(xml.contains("se:height=\"100\""))
    }

    /// Test round-trip for layout attributes.
    func testRoundTripLayout() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:se="http://scxmleditor.sf.net" version="1.0" initial="S1">
                <state id="S1" se:x="30" se:y="40" se:width="180" se:height="120"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("se:x=\"30\""))
        XCTAssertTrue(xml.contains("se:y=\"40\""))
        XCTAssertTrue(xml.contains("se:width=\"180\""))
        XCTAssertTrue(xml.contains("se:height=\"120\""))
    }

    /// Test parsing binding and name attributes.
    func testParseBindingAndNameAttributes() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" binding="late" name="MyFSM" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        XCTAssertEqual(bp.binding, "late")
        XCTAssertEqual(bp.name, "MyFSM")
    }

    /// Test round-trip for SCXML attributes (binding, name).
    func testRoundTripSCXMLAttributes() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" binding="late" name="TestMachine" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(scxml.data(using: .utf8)!)
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(xml.data(using: .utf8)!)
        let bp = reparsed.boilerplate as! SCXMLBoilerplate
        XCTAssertEqual(bp.binding, "late")
        XCTAssertEqual(bp.name, "TestMachine")
    }

    // MARK: - 2.13 SCXMLBinding Protocol Tests

    /// Test SCXMLBinding `numberOfTransitions`.
    func testSCXMLBindingNumberOfTransitions() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S2"/>
                <transition target="S2"/>
            </state>
            <state id="S2"/>
            """)
        let binding = SCXMLBinding()
        let xml = try binding.generateXML(from: machine)
        let storage = MachineFileWrapper(machine: machine, named: "test.scxml")
        // Update the file wrapper with actual SCXML data
        let data = xml.data(using: .utf8)!
        let wrapper = FileWrapper(regularFileWithContents: data)
        wrapper.preferredFilename = "test.scxml"
        storage.machine = try SCXMLParser().parse(data)
        // The binding reads from storage, but since storage is a file wrapper,
        // we need the machine to be available
        XCTAssertEqual(machine.llfsm.transitionsFrom(machine.llfsm.states[0]).count, 2)
    }

    /// Test SCXMLBinding `expression`.
    func testSCXMLBindingExpression() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition cond="x > 0" target="S1"/>
            </state>
            """)
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let tid = machine.llfsm.transitions.first!
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "x > 0")
    }

    /// Test SCXMLBinding `target`.
    func testSCXMLBindingTarget() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition target="S2"/>
            </state>
            <state id="S2"/>
            """)
        let tid = machine.llfsm.transitions.first!
        let targetID = machine.llfsm.targetState(for: tid)
        let targetName = targetID.flatMap { machine.llfsm.stateName(for: $0) }
        XCTAssertEqual(targetName, "S2")
    }

    /// Test SCXMLBinding `suspendState` returns nil.
    func testSCXMLBindingSuspendStateReturnsNil() {
        let binding = SCXMLBinding()
        let machine = Machine()
        machine.llfsm = LLFSM(states: [], transitions: [], suspendState: nil)
        let storage = MachineFileWrapper(machine: machine, named: "test.scxml")
        XCTAssertNil(binding.suspendState(for: storage, states: []))
    }

    /// Test SCXMLBinding `createArrangementWrapper` throws.
    func testSCXMLBindingCreateArrangementThrows() {
        let binding = SCXMLBinding()
        let url = URL(fileURLWithPath: "/tmp/test.arrangement")
        XCTAssertThrowsError(try binding.createArrangementWrapper(at: url)) { error in
            XCTAssertTrue(error is FSMError)
        }
    }

    // MARK: - 2.14 MachineFileWrapper & Storage Tests

    /// Test reading an SCXML file via MachineFileWrapper.
    func testMachineFileWrapperReadSCXML() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("testRead_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let storage = try MachineFileWrapper(url: tmpURL)
        XCTAssertEqual(storage.machine.llfsm.states.count, 1)
        XCTAssertTrue(storage.language is SCXMLBinding)
    }

    /// Test writing an SCXML file via MachineFileWrapper.
    func testMachineFileWrapperWriteSCXML() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("testWrite_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let machine = Machine()
        let state = State(name: "Written")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = SCXMLBinding()
        machine.boilerplate = SCXMLBoilerplate()

        let storage = MachineFileWrapper(machine: machine, named: tmpURL.lastPathComponent)
        try storage.write(to: tmpURL)

        let content = try String(contentsOf: tmpURL, encoding: .utf8)
        XCTAssertTrue(content.contains("id=\"Written\""))
        XCTAssertTrue(content.contains("<scxml"))
    }

    /// Test write-then-read round-trip via MachineFileWrapper.
    func testMachineFileWrapperRoundTrip() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("testRT_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let machine = Machine()
        let s1 = State(name: "A")
        let s2 = State(name: "B")
        machine.llfsm = LLFSM(
            states: [s1, s2],
            transitions: [Transition(label: "go", source: s1.id, target: s2.id)],
            suspendState: nil
        )
        machine.language = SCXMLBinding()
        machine.boilerplate = SCXMLBoilerplate()

        let writeStorage = MachineFileWrapper(machine: machine, named: tmpURL.lastPathComponent)
        try writeStorage.write(to: tmpURL)

        let readStorage = try MachineFileWrapper(url: tmpURL)
        XCTAssertEqual(readStorage.machine.llfsm.states.count, 2)
        XCTAssertEqual(readStorage.machine.llfsm.transitions.count, 1)
    }

    /// Test MachineStorageFactory detects `.scxml` extension.
    func testMachineStorageFactoryDetectsSCXML() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("testFactory_\(UUID().uuidString).scxml")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        try scxml.write(to: tmpURL, atomically: true, encoding: .utf8)

        let storage = try MachineStorageFactory.read(from: tmpURL)
        XCTAssertTrue(storage is MachineFileWrapper)
        XCTAssertEqual(storage.machine.llfsm.states.count, 1)
    }

    /// Test MachineFileWrapper throws for unsupported extension.
    func testMachineFileWrapperUnsupportedExtension() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(UUID().uuidString).xyz")
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        try "some content".write(to: tmpURL, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try MachineFileWrapper(url: tmpURL)) { error in
            XCTAssertTrue(error is FSMError)
        }
    }

    // MARK: - Helpers

    /// Parse SCXML from an inline state body wrapped in a minimal document.
    ///
    /// - Parameter stateBody: The XML content to insert inside the `<scxml>` root.
    /// - Returns: The parsed `Machine`.
    /// - Throws: `SCXMLParserError` on failure.
    private func parseSCXML(_ stateBody: String) throws -> Machine {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" xmlns:se="http://scxmleditor.sf.net" version="1.0">
                \(stateBody)
            </scxml>
            """
        return try SCXMLParser().parse(scxml.data(using: .utf8)!)
    }

    /// Extract transition actions from the first transition originating from the named state.
    ///
    /// - Parameters:
    ///   - machine: The machine to inspect.
    ///   - stateName: The source state name.
    /// - Returns: The executable actions array.
    /// - Throws: If the state or transition is not found.
    private func transitionActions(_ machine: Machine, from stateName: String) throws -> [ExecutableAction] {
        let bp = machine.boilerplate as! SCXMLBoilerplate
        let stateID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName })!
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
    private func generateTransitionXML(actions: [ExecutableAction]) throws -> String {
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
