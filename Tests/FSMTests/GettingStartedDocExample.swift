import XCTest
import FSM

/// Test the GettingStarted examples.
///
/// This test implements the example from `GettingStarted.md`
/// to ensure the code compiles and works.
final class GettingStartedDocExample: XCTestCase {
    /// Getting Started code.
    ///
    /// This test implements the example from `GettingStarted.md`
    /// to ensure the code compiles and works.
    func testGettingStartedExampleCompilesAndRuns() {
        // Define two states using the real State struct
        let red = State(name: "Red")
        let green = State(name: "Green")

        // Define transitions using the Transition struct
        let toGreen = Transition(label: "timer", source: red.id, target: green.id)
        let toRed = Transition(label: "timer", source: green.id, target: red.id)

        // Create a minimal LLFSM using the tested API
        let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed])

        // Check that the FSM has the correct states and transitions
        XCTAssertEqual(fsm.states.count, 2)
        XCTAssertEqual(fsm.transitions.count, 2)
        XCTAssertEqual(fsm.initialState, red.id)
        XCTAssertTrue(fsm.states.contains(red.id))
        XCTAssertTrue(fsm.states.contains(green.id))
        XCTAssertTrue(fsm.transitions.contains(toGreen.id))
        XCTAssertTrue(fsm.transitions.contains(toRed.id))
        // Print for demonstration (not required for test pass)
        print("States: \(fsm.states)")
        print("Transitions: \(fsm.transitions)")
        print("Initial state: \(fsm.initialState)")
        print("State Names: \(fsm.stateNames)")
    }
}
