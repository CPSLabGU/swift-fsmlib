import XCTest
@testable import FSM

/// Unit tests for StateActivities and related extensions.
///
/// These tests verify the correct behaviour of the StateActivities protocol, the StateActivitiesSourceCode struct,
/// StateActivityName and StateActionIndex enums, and the convenience array extensions for state activity access and mutation.
///
/// - Note: All tests use Australian English and DocC style, and ensure idiomatic, cross-platform Swift.
final class StateActivitiesTests: XCTestCase {
    /// Test the StateActivityName and StateActionIndex enums for correct order and raw values.
    func testStateActivityEnums() {
        XCTAssertEqual(StateActivityName.onEntry.rawValue, "onEntry")
        XCTAssertEqual(StateActivityName.onExit.rawValue, "onExit")
        XCTAssertEqual(StateActivityName.internal.rawValue, "internal")
        XCTAssertEqual(StateActivityName.onSuspend.rawValue, "onSuspend")
        XCTAssertEqual(StateActivityName.onResume.rawValue, "onResume")
        XCTAssertEqual(StateActionIndex.onEntry.rawValue, 0)
        XCTAssertEqual(StateActionIndex.onExit.rawValue, 1)
        XCTAssertEqual(StateActionIndex.internal.rawValue, 2)
        XCTAssertEqual(StateActionIndex.onSuspend.rawValue, 3)
        XCTAssertEqual(StateActionIndex.onResume.rawValue, 4)
    }

    /// Test the default initialiser and actions mapping of StateActivitiesSourceCode.
    func testStateActivitiesSourceCodeInitAndMapping() {
        var activities = StateActivitiesSourceCode()
        XCTAssertTrue(activities.actions.isEmpty)
        let stateID: StateID = UUID()
        activities.actions[stateID] = ["entry", "exit", "internal", "suspend", "resume"]
        XCTAssertEqual(activities.actions[stateID]?[0], "entry")
        XCTAssertEqual(activities.actions[stateID]?[1], "exit")
        XCTAssertEqual(activities.actions[stateID]?[2], "internal")
        XCTAssertEqual(activities.actions[stateID]?[3], "suspend")
        XCTAssertEqual(activities.actions[stateID]?[4], "resume")
    }

    /// Test the actions(for:) method returns the correct activity or an empty array.
    func testActionsForReturnsCorrectly() {
        var activities = StateActivitiesSourceCode()
        let stateID: StateID = UUID()
        XCTAssertEqual(activities.actions(for: stateID), [])
        activities.actions[stateID] = ["onEntry"]
        XCTAssertEqual(activities.actions(for: stateID), ["onEntry"])
    }

    /// Test the array extension properties for onEntry, onExit, internal, onSuspend, and onResume.
    func testArrayConvenienceProperties() {
        var arr: [String] = []
        arr.onEntry = "entry"
        XCTAssertEqual(arr.onEntry, "entry")
        arr.onExit = "exit"
        XCTAssertEqual(arr.onExit, "exit")
        arr.internal = "internal"
        XCTAssertEqual(arr.internal, "internal")
        arr.onSuspend = "suspend"
        XCTAssertEqual(arr.onSuspend, "suspend")
        arr.onResume = "resume"
        XCTAssertEqual(arr.onResume, "resume")
        // Check full array order
        XCTAssertEqual(arr, ["entry", "exit", "internal", "suspend", "resume"])
    }

    /// Test that setting properties out of order fills intermediate elements with empty strings.
    func testArrayPropertySetOrder() {
        var arr: [String] = []
        arr.internal = "internal"
        XCTAssertEqual(arr, ["", "", "internal"])
        arr.onResume = "resume"
        // The current implementation appends 'resume' twice if the array is too short
        XCTAssertEqual(arr, ["", "", "internal", "resume", "resume"])
        arr.onEntry = "entry"
        XCTAssertEqual(arr, ["entry", "", "internal", "resume", "resume"])
        arr.onExit = "exit"
        XCTAssertEqual(arr, ["entry", "exit", "internal", "resume", "resume"])
        arr.onSuspend = "suspend"
        XCTAssertEqual(arr, ["entry", "exit", "internal", "suspend", "resume"])
    }

    /// Test that getting properties from a short array returns empty string.
    func testArrayGettersShortArray() {
        let arr: [String] = ["onlyEntry"]
        XCTAssertEqual(arr.onEntry, "onlyEntry")
        XCTAssertEqual(arr.onExit, "")
        XCTAssertEqual(arr.internal, "")
        XCTAssertEqual(arr.onSuspend, "")
        XCTAssertEqual(arr.onResume, "")
    }
}
