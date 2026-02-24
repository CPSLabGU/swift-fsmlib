import XCTest
import Foundation
@testable import FSM

/// Tests for round-trip serialization/deserialization of StateNameLayouts.
final class StateNameLayoutsRoundTripTests: XCTestCase {
    /// Helper: Compare two StateNameLayouts dictionaries and print detailed diffs
    func assertStateNameLayoutsEqual(
        _ lhs: StateNameLayouts,
        _ rhs: StateNameLayouts,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let lhsKeys = Set(lhs.keys)
        let rhsKeys = Set(rhs.keys)
        if lhsKeys != rhsKeys {
            let missingInRhs = lhsKeys.subtracting(rhsKeys)
            let missingInLhs = rhsKeys.subtracting(lhsKeys)
            XCTFail(
                "StateNameLayouts keys mismatch.\nMissing in round-tripped: \(missingInRhs)\nExtra in round-tripped: \(missingInLhs)",
                file: file,
                line: line)
        }
        for key in lhsKeys.intersection(rhsKeys) {
            guard let (lhsState, lhsTrans) = lhs[key],
                  let (rhsState, rhsTrans) = rhs[key] else { continue }
            // Compare state layouts (field by field)
            let stateMismatch = compareStateLayout(lhsState, rhsState)
            if !stateMismatch.isEmpty {
                XCTFail("State layout mismatch for key \(key):\n\(stateMismatch)", file: file, line: line)
            }
            // Compare transitions
            if lhsTrans.count != rhsTrans.count {
                XCTFail(
                    "Transition count mismatch for key \(key): original=\(lhsTrans.count), round-tripped=\(rhsTrans.count)",
                    file: file,
                    line: line)
                continue
            }
            for (i, (lt, rt)) in zip(lhsTrans, rhsTrans).enumerated() {
                let pointsMismatch = compareTransitionLayout(lt, rt)
                if !pointsMismatch.isEmpty {
                    XCTFail(
                        "Transition layout mismatch for key \(key), transition \(i):\n\(pointsMismatch)",
                        file: file,
                        line: line)
                }
            }
        }
    }

    /// Compare all fields of StateLayout and return a string diff (empty if equal).
    ///
    /// - Parameters:
    ///   - lhs: The first state layout to compare.
    ///   - rhs: The second state layout to compare.
    /// - Returns: A string describing all differences (empty if layouts are equal).
    func compareStateLayout(_ lhs: StateLayout, _ rhs: StateLayout) -> String {
        var diffs = ""
        diffs += compareEllipse(lhs.closedLayout, rhs.closedLayout, label: "closedLayout")
        diffs += compareRectangle(lhs.openLayout, rhs.openLayout, label: "openLayout")
        diffs += compareStateLayoutHeights(lhs, rhs)
        return diffs
    }

    /// Compare two Ellipse instances field by field.
    ///
    /// - Parameters:
    ///   - lhs: The first ellipse to compare.
    ///   - rhs: The second ellipse to compare.
    ///   - label: A label to prefix difference messages.
    /// - Returns: A string describing all differences (empty if ellipses are equal).
    func compareEllipse(_ lhs: Ellipse, _ rhs: Ellipse, label: String) -> String {
        var diffs = ""
        if lhs.x != rhs.x { diffs += "\(label).x: \(lhs.x) != \(rhs.x)\n" }
        if lhs.y != rhs.y { diffs += "\(label).y: \(lhs.y) != \(rhs.y)\n" }
        if lhs.w != rhs.w { diffs += "\(label).w: \(lhs.w) != \(rhs.w)\n" }
        if lhs.h != rhs.h { diffs += "\(label).h: \(lhs.h) != \(rhs.h)\n" }
        return diffs
    }

    /// Compare two Rectangle instances field by field.
    ///
    /// - Parameters:
    ///   - lhs: The first rectangle to compare.
    ///   - rhs: The second rectangle to compare.
    ///   - label: A label to prefix difference messages.
    /// - Returns: A string describing all differences (empty if rectangles are equal).
    func compareRectangle(_ lhs: Rectangle, _ rhs: Rectangle, label: String) -> String {
        var diffs = ""
        if lhs.x != rhs.x { diffs += "\(label).x: \(lhs.x) != \(rhs.x)\n" }
        if lhs.y != rhs.y { diffs += "\(label).y: \(lhs.y) != \(rhs.y)\n" }
        if lhs.w != rhs.w { diffs += "\(label).w: \(lhs.w) != \(rhs.w)\n" }
        if lhs.h != rhs.h { diffs += "\(label).h: \(lhs.h) != \(rhs.h)\n" }
        return diffs
    }

    /// Compare all points of TransitionLayout and return a string diff (empty if equal)
    func compareTransitionLayout(_ lhs: TransitionLayout, _ rhs: TransitionLayout) -> String {
        let lp = lhs.points
        let rp = rhs.points
        if lp.count != rp.count {
            return "points count: \(lp.count) != \(rp.count)"
        }
        for (i, (l, r)) in zip(lp, rp).enumerated() {
            let pointDiff = comparePoint2D(l, r)
            if !pointDiff.isEmpty {
                return "point[\(i)]: \(pointDiff)"
            }
        }
        return ""
    }

    /// Compare two Point2D instances field by field.
    ///
    /// - Parameters:
    ///   - lhs: The first point to compare.
    ///   - rhs: The second point to compare.
    /// - Returns: A string describing all differences (empty if points are equal).
    func comparePoint2D(_ lhs: Point2D, _ rhs: Point2D) -> String {
        var diffs = ""
        if lhs.x != rhs.x { diffs += "x: \(lhs.x) != \(rhs.x); " }
        if lhs.y != rhs.y { diffs += "y: \(lhs.y) != \(rhs.y); " }
        return diffs
    }

    /// Test round-trip serialisation/deserialisation of an empty StateNameLayouts dictionary.
    ///
    /// Verifies that an empty layouts dictionary serialises to a dictionary and deserialises back to an empty dictionary.
    func testEmptyLayoutsRoundTrip() throws {
        let layouts: StateNameLayouts = [:]
        let dict = dictionary(from: layouts)
        let statesDict = try XCTUnwrap(dict["States"] as? NSDictionary, "States key must be an NSDictionary")
        let roundTripped = stateNameLayouts(from: statesDict)
        if !roundTripped.isEmpty {
            XCTFail("Expected empty round-tripped dictionary, got: \(roundTripped)")
        }
    }

    /// Test round-trip serialisation/deserialisation of a single state with no transitions.
    ///
    /// Verifies that a StateNameLayouts dictionary containing a single state with an empty transitions array
    /// serialises and deserialises correctly, preserving all state layout properties.
    func testSingleStateNoTransitionsRoundTrip() throws {
        let stateName = "StateA"
        let layout = StateLayout(index: 0)
        let layouts: StateNameLayouts = [stateName: (state: layout, transitions: [])]
        let dict = dictionary(from: layouts)
        let statesDict = try XCTUnwrap(dict["States"] as? NSDictionary, "States key must be an NSDictionary")
        let roundTripped = stateNameLayouts(from: statesDict)
        if roundTripped[stateName] == nil {
            XCTFail("State \(stateName) missing in round-tripped dictionary. Keys: \(roundTripped.keys)")
            return
        }
        assertStateNameLayoutsEqual(layouts, roundTripped)
    }

    /// Test round-trip serialisation/deserialisation of a single state with multiple transitions.
    ///
    /// Verifies that a StateNameLayouts dictionary containing a single state with multiple transition layouts
    /// serialises and deserialises correctly, preserving both state properties and all transition point sequences.
    func testSingleStateWithTransitionsRoundTrip() throws {
        let stateName = "StateA"
        let layout = StateLayout(index: 0)
        let tLayout1 = TransitionLayout([Point2D(0,0), Point2D(1,1)])
        let tLayout2 = TransitionLayout([Point2D(2,2), Point2D(3,3)])
        let layouts: StateNameLayouts = [stateName: (state: layout, transitions: [tLayout1, tLayout2])]
        let dict = dictionary(from: layouts)
        let statesDict = try XCTUnwrap(dict["States"] as? NSDictionary, "States key must be an NSDictionary")
        let roundTripped = stateNameLayouts(from: statesDict)
        if roundTripped[stateName] == nil {
            XCTFail("State \(stateName) missing in round-tripped dictionary. Keys: \(roundTripped.keys)")
            return
        }
        assertStateNameLayoutsEqual(layouts, roundTripped)
    }

    /// Test round-trip serialisation/deserialisation of multiple states with varying transitions.
    ///
    /// Verifies that a StateNameLayouts dictionary containing multiple states (some with transitions, some without)
    /// serialises and deserialises correctly, preserving all state layouts and transition data for each state.
    func testMultipleStatesRoundTrip() throws {
        let layoutA = StateLayout(index: 0)
        let layoutB = StateLayout(index: 1)
        let tLayout = TransitionLayout([Point2D(0,0), Point2D(1,1)])
        let layouts: StateNameLayouts = [
            "StateA": (state: layoutA, transitions: [tLayout]),
            "StateB": (state: layoutB, transitions: [])
        ]
        let dict = dictionary(from: layouts)
        let statesDict = try XCTUnwrap(dict["States"] as? NSDictionary, "States key must be an NSDictionary")
        let roundTripped = stateNameLayouts(from: statesDict)
        if roundTripped.count != 2 {
            XCTFail("Expected 2 states in round-tripped dictionary, got: \(roundTripped.keys)")
        }
        assertStateNameLayoutsEqual(layouts, roundTripped)
    }

    /// Test round-trip serialisation/deserialisation of state names containing special Unicode characters.
    ///
    /// Verifies that StateNameLayouts correctly handles non-ASCII state names (such as Chinese characters)
    /// during serialisation and deserialisation, ensuring proper Unicode string preservation.
    func testSpecialCharactersInStateNames() throws {
        let stateName = "特殊字符"
        let layout = StateLayout(index: 0)
        let layouts: StateNameLayouts = [stateName: (state: layout, transitions: [])]
        let dict = dictionary(from: layouts)
        let statesDict = try XCTUnwrap(dict["States"] as? NSDictionary, "States key must be an NSDictionary")
        let roundTripped = stateNameLayouts(from: statesDict)
        if roundTripped[stateName] == nil {
            XCTFail("Special character state missing in round-tripped dictionary. Keys: \(roundTripped.keys)")
            return
        }
        assertStateNameLayoutsEqual(layouts, roundTripped)
    }
}

// MARK: - StateLayout Height Comparison

/// Extension providing height field comparison for StateLayout.
private extension StateNameLayoutsRoundTripTests {
    /// Compare the boolean and height fields of two StateLayout instances.
    ///
    /// This helper reduces cyclomatic complexity of `compareStateLayout(_:_:)`
    /// by extracting the scalar field comparisons.
    ///
    /// - Parameters:
    ///   - lhs: The first state layout to compare.
    ///   - rhs: The second state layout to compare.
    /// - Returns: A string describing all differences (empty if all fields are equal).
    func compareStateLayoutHeights(_ lhs: StateLayout, _ rhs: StateLayout) -> String {
        var diffs = ""
        if lhs.isOpen != rhs.isOpen { diffs += "isOpen: \(lhs.isOpen) != \(rhs.isOpen)\n" }
        if lhs.onEntryHeight != rhs.onEntryHeight { diffs += "onEntryHeight: \(lhs.onEntryHeight) != \(rhs.onEntryHeight)\n" }
        if lhs.onExitHeight != rhs.onExitHeight { diffs += "onExitHeight: \(lhs.onExitHeight) != \(rhs.onExitHeight)\n" }
        if lhs.internalHeight != rhs.internalHeight { diffs += "internalHeight: \(lhs.internalHeight) != \(rhs.internalHeight)\n" }
        if lhs.onSuspendHeight != rhs.onSuspendHeight { diffs += "onSuspendHeight: \(lhs.onSuspendHeight) != \(rhs.onSuspendHeight)\n" }
        if lhs.onResumeHeight != rhs.onResumeHeight { diffs += "onResumeHeight: \(lhs.onResumeHeight) != \(rhs.onResumeHeight)\n" }
        diffs += compareZoomedHeights(lhs, rhs)
        return diffs
    }

    /// Compare the zoomed height fields of two StateLayout instances.
    ///
    /// - Parameters:
    ///   - lhs: The first state layout to compare.
    ///   - rhs: The second state layout to compare.
    /// - Returns: A string describing zoomed height differences (empty if all fields are equal).
    func compareZoomedHeights(_ lhs: StateLayout, _ rhs: StateLayout) -> String {
        var diffs = ""
        if lhs.zoomedOnEntryHeight != rhs.zoomedOnEntryHeight { diffs += "zoomedOnEntryHeight: \(lhs.zoomedOnEntryHeight) != \(rhs.zoomedOnEntryHeight)\n" }
        if lhs.zoomedOnExitHeight != rhs.zoomedOnExitHeight { diffs += "zoomedOnExitHeight: \(lhs.zoomedOnExitHeight) != \(rhs.zoomedOnExitHeight)\n" }
        if lhs.zoomedInternalHeight != rhs.zoomedInternalHeight { diffs += "zoomedInternalHeight: \(lhs.zoomedInternalHeight) != \(rhs.zoomedInternalHeight)\n" }
        if lhs.zoomedOnSuspendHeight != rhs.zoomedOnSuspendHeight { diffs += "zoomedOnSuspendHeight: \(lhs.zoomedOnSuspendHeight) != \(rhs.zoomedOnSuspendHeight)\n" }
        if lhs.zoomedOnResumeHeight != rhs.zoomedOnResumeHeight { diffs += "zoomedOnResumeHeight: \(lhs.zoomedOnResumeHeight) != \(rhs.zoomedOnResumeHeight)\n" }
        return diffs
    }
}
