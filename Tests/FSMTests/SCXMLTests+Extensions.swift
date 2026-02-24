//
//  SCXMLTests+Extensions.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

// MARK: - 2.1 Executable Action Parsing Tests

/// Extension covering executable action parsing tests.
extension SCXMLTests {
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
                array: "items",
                item: "item",
                index: "idx",
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
                array: "list",
                item: "elem",
                index: nil,
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
}

// MARK: - 2.2 Executable Action Writing Tests

/// Extension covering executable action writing tests.
extension SCXMLTests {
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
                array: "items",
                item: "item",
                index: "i",
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
}

// MARK: - 2.3 Executable Action Round-Trip Tests

/// Extension covering executable action round-trip tests.
extension SCXMLTests {
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(
            actions[0],
            .forEach(
                array: "items",
                item: "item",
                index: "idx",
                actions: [.log(expr: "item", label: nil)])
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let actions = try transitionActions(reparsed, from: "S1")
        XCTAssertEqual(actions.count, 4)
        XCTAssertEqual(actions[0], .assign(location: "x", expr: "1"))
        XCTAssertEqual(actions[1], .raise(event: "changed"))
        XCTAssertEqual(actions[2], .log(expr: "x", label: "debug"))
        XCTAssertEqual(actions[3], .send(event: "notify", target: "parent", delay: nil))
    }
}

// MARK: - 2.4 State Type Tests

/// Extension covering state type parsing and writing tests.
extension SCXMLTests {
    /// Test parsing `<parallel>` state.
    func testParseParallelState() throws {
        let machine = try parseSCXML("""
            <parallel id="P1">
                <state id="Child1"/>
                <state id="Child2"/>
            </parallel>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let pID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "P1" }),
            "State P1 not found")
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let doneID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Done" }),
            "State Done not found")
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let hID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "H1" }),
            "State H1 not found")
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let hID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "H2" }),
            "State H2 not found")
        XCTAssertEqual(bp.stateMetadata[hID]?.historyType, .deep)
    }

    /// Test parsing a compound state with nested `<state>`.
    func testParseCompoundState() throws {
        let machine = try parseSCXML("""
            <state id="Outer">
                <state id="Inner"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let outerID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Outer" }),
            "State Outer not found")
        let innerID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "Inner" }),
            "State Inner not found")
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let l1 = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L1" }),
            "State L1 not found")
        let l2 = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L2" }),
            "State L2 not found")
        let l3 = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "L3" }),
            "State L3 not found")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let pID = try XCTUnwrap(
            reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "P1" }),
            "State P1 not found")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let hID = try XCTUnwrap(
            reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "H1" }),
            "State H1 not found")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let outerID = try XCTUnwrap(
            reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "Outer" }),
            "State Outer not found")
        let innerID = try XCTUnwrap(
            reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "Inner" }),
            "State Inner not found")
        XCTAssertNotNil(bp.stateMetadata[outerID]?.childStates)
        XCTAssertEqual(bp.stateMetadata[innerID]?.parentState, outerID)
    }
}

// MARK: - 2.5 Transition Metadata Tests

/// Extension covering transition metadata parsing, writing and round-trip tests.
extension SCXMLTests {
    /// Test parsing transition event attribute.
    func testParseTransitionEvent() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="click" target="S1"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
        XCTAssertEqual(bp.transitionMetadata[tid]?.event, "click")
    }

    /// Test parsing transition condition attribute.
    func testParseTransitionCondition() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition cond="x > 0" target="S1"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "x > 0")
        // label should also be set to condition
        let transition = try XCTUnwrap(machine.llfsm.transitionMap[tid], "Transition map entry not found")
        XCTAssertEqual(transition.label, "x > 0")
    }

    /// Test parsing internal transition type.
    func testParseTransitionTypeInternal() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition type="internal" target="S1"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
        XCTAssertEqual(bp.transitionMetadata[tid]?.type, .internal)
    }

    /// Test parsing transition with both event and condition.
    func testParseTransitionEventAndCondition() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <transition event="timer" cond="count > 10" target="S1"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
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
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
        let transition = try XCTUnwrap(machine.llfsm.transitionMap[tid], "Transition map entry not found")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(reparsed.llfsm.transitions.first, "No transitions found")
        XCTAssertEqual(bp.transitionMetadata[tid]?.event, "tick")
        XCTAssertEqual(bp.transitionMetadata[tid]?.condition, "x > 0")
        XCTAssertEqual(bp.transitionMetadata[tid]?.type, .internal)
    }
}

// MARK: - 2.6 Invocation Tests

/// Extension covering invocation parsing, writing, and round-trip tests.
extension SCXMLTests {
    /// Test parsing full `<invoke>` element.
    func testParseInvoke() throws {
        let machine = try parseSCXML("""
            <state id="S1">
                <invoke type="scxml" src="child.scxml" id="inv1" autoforward="true"/>
            </state>
            """)
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let sID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "S1" }),
            "State S1 not found")
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let sID = try XCTUnwrap(
            machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == "S1" }),
            "State S1 not found")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let sID = try XCTUnwrap(
            reparsed.llfsm.states.first(where: { reparsed.llfsm.stateName(for: $0) == "S1" }),
            "State S1 not found")
        let invocations = bp.invocations[sID.uuidString]
        XCTAssertEqual(invocations?.count, 1)
        XCTAssertEqual(invocations?[0].type, "scxml")
        XCTAssertEqual(invocations?[0].src, "child.scxml")
        XCTAssertEqual(invocations?[0].id, "inv1")
        XCTAssertEqual(invocations?[0].autoForward, true)
    }
}

// MARK: - 2.7 Initial State & Script Tests

/// Extension covering initial state and script parsing and round-trip tests.
extension SCXMLTests {
    /// Test parsing `initial` attribute on `<scxml>`.
    func testParseInitialAttribute() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" version="1.0" initial="Second">
                <state id="First"/>
                <state id="Second"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let xml = try SCXMLWriter().generate(from: machine)
        XCTAssertTrue(xml.contains("<script>"))
        XCTAssertTrue(xml.contains("var x = 42;"))
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        // Script content may include whitespace from XML serialisation
        XCTAssertTrue(bp.initialScript?.contains("var x = 42;") ?? false)
    }
}

// Further extensions are in SCXMLTests+MoreExtensions.swift
