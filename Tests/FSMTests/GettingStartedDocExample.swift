import XCTest
import FSM

final class GettingStartedDocExample: XCTestCase {
    func testGettingStartedExampleCompilesAndRuns() {
        // Define two states using the real State struct
        let red = State(name: "Red")
        let green = State(name: "Green")

        // Define transitions using the Transition struct
        let toGreen = Transition(label: "timer", source: red.id, target: green.id)
        let toRed = Transition(label: "timer", source: green.id, target: red.id)

        // Create a minimal LLFSM using the tested API
        let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed], suspendState: nil)

        // Check that the FSM has the correct states and transitions
        XCTAssertEqual(fsm.states.count, 2)
        XCTAssertEqual(fsm.transitions.count, 2)
        XCTAssertTrue(fsm.states.contains(red.id))
        XCTAssertTrue(fsm.states.contains(green.id))
        XCTAssertTrue(fsm.transitions.contains(toGreen.id))
        XCTAssertTrue(fsm.transitions.contains(toRed.id))
        // Print for demonstration (not required for test pass)
        print("Initial state: \(fsm.initialState)")
        print("States: \(fsm.states)")
        print("Transitions: \(fsm.transitions)")
    }
}
