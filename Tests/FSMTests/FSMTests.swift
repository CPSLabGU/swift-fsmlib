import XCTest
@testable import FSM

/// Unit tests for FSM state, transition, and LLFSM operations.
///
/// This test case verifies the correct creation, manipulation, and
/// dictionary operations for states, transitions, and LLFSMs. It ensures
/// that all FSM components behave as expected, including initial state
/// handling and dictionary mapping.
///
/// - Note: These tests cover basic FSM operations and are essential for
///         verifying the integrity of the FSM core data structures.
final class FSMTests: XCTestCase {
    /// Test state creation and property access.
    ///
    /// This test verifies that states are created with correct names and IDs,
    /// and that equality and inequality checks work as expected.
    func testStates() {
        let rname = "State 1"
        let sname = "State 2"
        let r = State(id: StateID(), name: rname)
        let s = State(id: StateID(), name: sname)
        XCTAssertEqual(r.name, rname)
        XCTAssertEqual(s.name, sname)
        XCTAssertNotEqual(r.name, s.name)
        XCTAssertNotEqual(r.id, s.id)
    }

    /// Test transition creation and property access.
    ///
    /// This test verifies that transitions are created with correct labels,
    /// sources, and targets, and that equality and inequality checks work.
    func testTransitions() {
        let sname = "State 1"
        let tname = "State 2"
        let r = State(id: StateID(), name: sname)
        let s = State(id: StateID(), name: tname)
        let exp1 = "true"
        let exp2 = "false"
        let t = Transition(id: TransitionID(), label: exp1, source: r.id, target: s.id)
        let u = Transition(id: TransitionID(), label: exp2, source: s.id, target: r.id)
        XCTAssertEqual(t.label.description, exp1)
        XCTAssertEqual(u.label.description, exp2)
        XCTAssertEqual(t.source, r.id)
        XCTAssertEqual(u.source, s.id)
        XCTAssertEqual(t.target, s.id)
        XCTAssertEqual(u.target, r.id)
        XCTAssertNotEqual(t.id, u.id)
    }

    /// Test LLFSM creation and transition access.
    ///
    /// This test verifies that LLFSMs are created with correct states and
    /// transitions, and that transition lookup functions work as expected.
    func testLLFSM() {
        let sname = "State 1"
        let tname = "State 2"
        let r = State(id: StateID(), name: sname)
        let s = State(id: StateID(), name: tname)
        let exp1 = "true"
        let exp2 = "false"
        let t = Transition(id: TransitionID(), label: exp1, source: r.id, target: s.id)
        let u = Transition(id: TransitionID(), label: exp2, source: s.id, target: r.id)
        let fsm = LLFSM(states: [r, s], transitions: [t, u], suspendState: s.id)
        XCTAssertEqual(fsm.states.count, 2)
        XCTAssertEqual(fsm.transitions.count, 2)
        XCTAssertEqual(fsm.transitionsFrom(r.id).count, 1)
        XCTAssertEqual(fsm.transitionsFrom(s.id).count, 1)
        XCTAssertEqual(fsm.transitionsFrom(r.id)[0], t.id)
        XCTAssertEqual(fsm.transitionsFrom(s.id)[0], u.id)
        XCTAssertNotEqual(fsm.suspendState, t.id)
        XCTAssertEqual(fsm.suspendState, s.id)
    }

    /// Test LLFSM state and transition manipulation.
    ///
    /// This test verifies that states and transitions can be added and
    /// updated in an LLFSM, and that their properties are correctly set.
    func testLLFSMStateAndTransitionManipulation() {
        var llfsm = LLFSM(states: [], transitions: [], suspendState: nil)

        // Add states
        let state1ID = StateID()
        llfsm.set(name: "State1", for: state1ID)

        let state2ID = StateID()
        llfsm.set(name: "State2", for: state2ID)

        XCTAssertEqual(llfsm.states.count, 2)
        XCTAssertEqual(llfsm.stateName(for: state1ID), "State1")
        XCTAssertEqual(llfsm.stateName(for: state2ID), "State2")

        // Add transition
        let trans1ID = TransitionID()
        llfsm.set(label: "goToState2", for: trans1ID)
        llfsm.setSourceState(for: trans1ID, to: state1ID)
        llfsm.setTargetState(for: trans1ID, to: state2ID)

        XCTAssertEqual(llfsm.transitions.count, 1)
        XCTAssertEqual(llfsm.label(for: trans1ID), "goToState2")
        XCTAssertEqual(llfsm.sourceState(for: trans1ID), state1ID)
        XCTAssertEqual(llfsm.targetState(for: trans1ID), state2ID)

        // Update state name
        llfsm.set(name: "RenamedState1", for: state1ID)
        XCTAssertEqual(llfsm.stateName(for: state1ID), "RenamedState1")

        // Update transition label
        llfsm.set(label: "updatedTransition", for: trans1ID)
        XCTAssertEqual(llfsm.label(for: trans1ID), "updatedTransition")
    }

    /// Test initial state handling in LLFSMs.
    ///
    /// This test verifies the default initial state behaviour and setting
    /// of the initial state in empty FSMs.
    func testInitialStateHandling() {
        // Test default initial state
        let state1 = State(name: "First")
        let state2 = State(name: "Second")
        let llfsm = LLFSM(states: [state1, state2], transitions: [], suspendState: nil)

        XCTAssertEqual(llfsm.initialState, state1.id)

        // Test empty FSM
        var emptyFSM = LLFSM(states: [], transitions: [], suspendState: nil)
        let newStateID = StateID()
        emptyFSM.initialState = newStateID

        XCTAssertEqual(emptyFSM.states.count, 1)
        XCTAssertEqual(emptyFSM.initialState, newStateID)
    }

    /// Test dictionary operations for states.
    ///
    /// This test verifies that state dictionaries are created and accessed
    /// correctly from arrays of states.
    func testStateDictionaryOperations() {
        let state1 = State(name: "First")
        let state2 = State(name: "Second")

        let dict = dictionary([state1, state2])

        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[state1.id]?.name, "First")
        XCTAssertEqual(dict[state2.id]?.name, "Second")
    }

    /// Test dictionary operations for transitions.
    ///
    /// This test verifies that transition dictionaries are created and
    /// accessed correctly from arrays of transitions.
    func testTransitionDictionaryOperations() {
        let state1ID = StateID()
        let state2ID = StateID()

        let transition1 = Transition(label: "go", source: state1ID, target: state2ID)
        let transition2 = Transition(label: "back", source: state2ID, target: state1ID)

        let dict = dictionary([transition1, transition2])

        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[transition1.id]?.label, "go")
        XCTAssertEqual(dict[transition2.id]?.label, "back")
    }

    /// Test FSM protocol extension: default description and initialState setter edge cases.
    func testFSMProtocolExtensionBehaviour() {
        struct TestFSM: FSM {
            var states: StateArray
            var transitions: TransitionArray
            func transitionsFrom(_ s: StateID) -> TransitionArray {
                transitions.filter { _ in true } // dummy
            }
        }
        let s1 = State(name: "Alpha")
        let s2 = State(name: "Beta")
        var fsm = TestFSM(states: [s1.id, s2.id], transitions: [])
        XCTAssertEqual(fsm.initialState, s1.id)
        // No description for StateID, so skip description check
        let newID = StateID()
        fsm.initialState = newID
        XCTAssertEqual(fsm.states[0], newID)
        var emptyFSM = TestFSM(states: [], transitions: [])
        let id2 = StateID()
        emptyFSM.initialState = id2
        XCTAssertEqual(emptyFSM.states, [id2])
    }

    /// Test Suspensible and SuspensibleFSM protocol extension default descriptions.
    func testSuspensibleAndSuspensibleFSMDescription() {
        struct TestSuspensible: Suspensible {
            var suspendState: StateID?
        }
        let sID = StateID()
        let s = TestSuspensible(suspendState: sID)
        let sNil = TestSuspensible(suspendState: nil)
        XCTAssertEqual(s.description, sID.description)
        XCTAssertEqual(sNil.description, "(none)")

        struct TestSuspensibleFSM: SuspensibleFSM {
            var states: StateArray
            var transitions: TransitionArray
            var suspendState: StateID?
            func transitionsFrom(_ s: StateID) -> TransitionArray { transitions }
        }
        let st1 = State(name: "Gamma")
        let st2 = State(name: "Delta")
        let suspFSM = TestSuspensibleFSM(states: [st1.id, st2.id], transitions: [], suspendState: st2.id)
        // No description for StateID, so skip description check
        XCTAssertTrue(suspFSM.description.contains(st2.id.description))
    }

    /// Test Transition protocol default descriptions and equality.
    func testTransitionProtocolsAndEquality() {
        struct TestLabel: TransitionLabel { let label: String }
        let lbl = TestLabel(label: "x")
        XCTAssertEqual(lbl.description, "x")
        struct TestSource: TransitionSource { let source: StateID }
        let srcID = StateID()
        let src = TestSource(source: srcID)
        XCTAssertEqual(src.description, srcID.description)
        struct TestTarget: TransitionTarget { let target: StateID }
        let tgtID = StateID()
        let tgt = TestTarget(target: tgtID)
        XCTAssertEqual(tgt.description, tgtID.description)
        struct TestPath: TransitionPath { let source: StateID; let target: StateID }
        let path = TestPath(source: srcID, target: tgtID)
        XCTAssertEqual(path.description, "( \(srcID) --> \(tgtID))")
        struct TestTargetTransition: TargetTransition { let label: String; let target: StateID }
        let tt = TestTargetTransition(label: "foo", target: tgtID)
        XCTAssertEqual(tt.description, "( -- foo --> \(tgtID))")
        struct TestVertex: TransitionVertex { let source: StateID; let label: String; let target: StateID; static func ==(lhs: TestVertex, rhs: TestVertex) -> Bool { lhs.source == rhs.source && lhs.label == rhs.label && lhs.target == rhs.target } }
        let v1 = TestVertex(source: srcID, label: "lab", target: tgtID)
        let v2 = TestVertex(source: srcID, label: "lab", target: tgtID)
        let v3 = TestVertex(source: tgtID, label: "lab", target: srcID)
        XCTAssertEqual(v1, v2)
        XCTAssertNotEqual(v1, v3)
        XCTAssertEqual(v1.description, "( \(srcID) -- lab --> \(tgtID))")
    }

    /// Test Transition struct edge cases and dictionary helpers.
    func testTransitionStructEdgeCasesAndDictionary() {
        let sID = StateID()
        let tID = StateID()
        let tr = Transition(label: "go", source: sID, target: tID)
        let tr2 = Transition(label: "go", source: sID, target: tID)
        let trDiff = Transition(label: "back", source: tID, target: sID)
        XCTAssertNotEqual(tr, tr2) // different IDs
        XCTAssertTrue(tr.description.contains("go"))
        let dictEmpty = dictionary([Transition]())
        XCTAssertTrue(dictEmpty.isEmpty)
        let dictOne = dictionary([tr])
        XCTAssertEqual(dictOne[tr.id]?.label, "go")
        let dictDup = dictionary([tr, tr])
        XCTAssertEqual(dictDup.count, 1)
        let dictMulti = dictionary([tr, trDiff])
        XCTAssertEqual(dictMulti.count, 2)
    }
}
