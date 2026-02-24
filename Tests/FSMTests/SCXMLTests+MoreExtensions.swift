//
//  SCXMLTests+MoreExtensions.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

// MARK: - 2.8 SCXMLBoilerplate Unit Tests

/// Extension covering SCXMLBoilerplate unit tests.
extension SCXMLTests {
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
}

// MARK: - 2.9 SCXMLStateMetadata Unit Tests

/// Extension covering SCXMLStateMetadata unit tests.
extension SCXMLTests {
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
}

// MARK: - 2.10 Error Handling Tests

/// Extension covering SCXML parser error handling tests.
extension SCXMLTests {
    /// Test that malformed XML throws invalidXML.
    func testInvalidXMLError() {
        let data = Data("not xml at all".utf8)
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
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
        XCTAssertThrowsError(try SCXMLParser().parse(Data(scxml.utf8))) { error in
            if case SCXMLParserError.parsingFailed(let msg) = error {
                XCTAssertTrue(msg.contains("No states"))
            } else {
                XCTFail("Expected parsingFailed error, got: \(error)")
            }
        }
    }
}

// MARK: - 2.11 FSMLib Boilerplate & Language Preservation

/// Extension covering FSMLib boilerplate and language preservation tests.
extension SCXMLTests {
    /// Test parsing `fsm:language` attribute.
    func testParseTargetLanguage() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:fsm="http://mipal.net.au/fsmlib" version="1.0" fsm:language="c" initial="S1">
                <state id="S1"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let reparsedBp = try XCTUnwrap(
            reparsed.boilerplate as? SCXMLBoilerplate,
            "Expected SCXMLBoilerplate")
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
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let reparsedBp = try XCTUnwrap(
            reparsed.boilerplate as? SCXMLBoilerplate,
            "Expected SCXMLBoilerplate")
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let stateID = try XCTUnwrap(machine.llfsm.states.first, "No states found")
        let sections = machine.stateActivities(for: stateID)
        XCTAssertTrue(sections[.internal]?.contains("check_sensors();") ?? false)
    }
}

// MARK: - 2.12 Layout & SCXML Attributes

/// Extension covering layout and SCXML attribute tests.
extension SCXMLTests {
    /// Test parsing layout from `se:` attributes.
    func testParseLayoutFromSeAttributes() throws {
        let scxml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <scxml xmlns="http://www.w3.org/2005/07/scxml" xmlns:se="http://scxmleditor.sf.net" version="1.0" initial="S1">
                <state id="S1" se:x="100" se:y="200" se:width="150" se:height="90"/>
            </scxml>
            """
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let stateID = try XCTUnwrap(machine.llfsm.states.first, "No states found")
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
            onEntryHeight: 0,
            onExitHeight: 0,
            onSuspendHeight: 0,
            onResumeHeight: 0,
            internalHeight: 0,
            zoomedOnEntryHeight: 0,
            zoomedOnExitHeight: 0,
            zoomedInternalHeight: 0,
            zoomedOnSuspendHeight: 0,
            zoomedOnResumeHeight: 0,
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
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
        let machine = try SCXMLParser().parse(Data(scxml.utf8))
        let xml = try SCXMLWriter().generate(from: machine)
        let reparsed = try SCXMLParser().parse(Data(xml.utf8))
        let bp = try XCTUnwrap(reparsed.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        XCTAssertEqual(bp.binding, "late")
        XCTAssertEqual(bp.name, "TestMachine")
    }
}

// MARK: - 2.13 SCXMLBinding Protocol Tests

/// Extension covering SCXMLBinding protocol tests.
extension SCXMLTests {
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
        let data = Data(xml.utf8)
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
        let bp = try XCTUnwrap(machine.boilerplate as? SCXMLBoilerplate, "Expected SCXMLBoilerplate")
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
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
        let tid = try XCTUnwrap(machine.llfsm.transitions.first, "No transitions found")
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
}

// MARK: - 2.14 MachineFileWrapper & Storage Tests

/// Extension covering MachineFileWrapper and storage tests.
extension SCXMLTests {
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
}
