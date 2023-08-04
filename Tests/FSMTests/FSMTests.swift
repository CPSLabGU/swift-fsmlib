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
}
