import XCTest
@testable import FSM

final class FSMTests: XCTestCase {
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

        XCTAssertEqual(llfsm.transitions.count, 1)
        XCTAssertEqual(llfsm.label(for: trans1ID), "goToState2")

        // Update state name
        llfsm.set(name: "RenamedState1", for: state1ID)
        XCTAssertEqual(llfsm.stateName(for: state1ID), "RenamedState1")

        // Update transition label
        llfsm.set(label: "updatedTransition", for: trans1ID)
        XCTAssertEqual(llfsm.label(for: trans1ID), "updatedTransition")
    }

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

    func testStateDictionaryOperations() {
        let state1 = State(name: "First")
        let state2 = State(name: "Second")

        let dict = dictionary([state1, state2])

        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[state1.id]?.name, "First")
        XCTAssertEqual(dict[state2.id]?.name, "Second")
    }

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
}
