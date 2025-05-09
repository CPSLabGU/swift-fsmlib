import XCTest
import Foundation
@testable import FSM

final class MachineSerialisationTests: XCTestCase {

    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMSerializationTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }()

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    func testBasicMachineSerialization() throws {
        // Create a simple machine
        let state1 = State(name: "Initial")
        let state2 = State(name: "Running")
        let state3 = State(name: "Final")
        let states = [state1, state2, state3]

        let transition1 = Transition(label: "start", source: state1.id, target: state2.id)
        let transition2 = Transition(label: "finish", source: state2.id, target: state3.id)
        let transitions = [transition1, transition2]

        let llfsm = LLFSM(states: states,
                         transitions: transitions,
                         suspendState: nil)

        XCTAssertEqual(llfsm.states.count, states.count)
        XCTAssertEqual(llfsm.transitions.count, transitions.count)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        XCTAssertEqual(machine.llfsm.states.count, states.count)
        XCTAssertEqual(machine.llfsm.transitions.count, transitions.count)

        // Create state layouts
        var stateLayouts = StateLayouts()
        for state in [state1, state2, state3] {
            stateLayouts[state.id] = StateLayout(index: 0)
        }
        machine.stateLayout = stateLayouts

        // Create transition layouts
        var transitionLayouts = TransitionLayouts()
        for transition in [transition1, transition2] {
            let srcPoint = Point2D(0, 0)
            let dstPoint = Point2D(100, 100)
            let path = Path([srcPoint, Point2D(50, 50), dstPoint])
            transitionLayouts[transition.id] = TransitionLayout(path: path)
        }
        machine.transitionLayout = transitionLayouts

        // Serialize to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("BasicMachine.machine")
        try machine.write(to: machineURL, isSuspensible: false)

        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: machineURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: machineURL.appendingPathComponent(Filename.states).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: machineURL.appendingPathComponent(Filename.layout).path))

        // Deserialize and verify
        let loadedMachine = try Machine(from: machineURL)

        XCTAssertEqual(loadedMachine.llfsm.states.count, states.count)
        XCTAssertEqual(loadedMachine.llfsm.transitions.count, transitions.count)

        // Verify state names
        let stateNames = loadedMachine.llfsm.states.compactMap { loadedMachine.llfsm.stateName(for: $0) }
        XCTAssertTrue(stateNames.contains(state1.name))
        XCTAssertTrue(stateNames.contains(state2.name))
        XCTAssertTrue(stateNames.contains(state3.name))
    }

    func testLayoutSerialisation() throws {
        // Create a machine with specific layout
        let state = State(name: "TestState")
        let llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        // Create a specific layout for the state
        let stateLayout = StateLayout(
            isOpen: true,
            openLayout: Rectangle(topLeft: Coordinate2D(100, 100), dimensions: Dimensions2D(200, 150)),
            closedLayout: Ellipse(topLeft: Coordinate2D(120, 120), dimensions: Dimensions2D(100, 80)),
            onEntryHeight: 30,
            onExitHeight: 25,
            onSuspendHeight: 20,
            onResumeHeight: 20,
            internalHeight: 50,
            zoomedOnEntryHeight: 60,
            zoomedOnExitHeight: 50,
            zoomedInternalHeight: 100,
            zoomedOnSuspendHeight: 40,
            zoomedOnResumeHeight: 40
        )
        machine.stateLayout = [state.id: stateLayout]

        // Serialize to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("LayoutMachine.machine")
        try machine.write(to: machineURL, isSuspensible: false)

        // Deserialize and verify layout
        let loadedMachine = try Machine(from: machineURL)

        XCTAssertEqual(loadedMachine.llfsm.states.count, 1)

        guard let stateID = loadedMachine.llfsm.states.first,
              let loadedLayout = loadedMachine.stateLayout[stateID] else {
            XCTFail("State layout not found after deserialization")
            return
        }

        // Verify layout properties
        XCTAssertEqual(loadedLayout.isOpen, true)
        XCTAssertEqual(loadedLayout.openLayout.dimensions.w, stateLayout.openLayout.dimensions.w)
        XCTAssertEqual(loadedLayout.openLayout.dimensions.h, stateLayout.openLayout.dimensions.h)
        XCTAssertEqual(loadedLayout.closedLayout.dimensions.w, stateLayout.closedLayout.dimensions.w)
        XCTAssertEqual(loadedLayout.closedLayout.dimensions.h, stateLayout.closedLayout.dimensions.h)
        XCTAssertEqual(loadedLayout.onEntryHeight, stateLayout.onEntryHeight)
        XCTAssertEqual(loadedLayout.onExitHeight, stateLayout.onExitHeight)
        XCTAssertEqual(loadedLayout.internalHeight, stateLayout.internalHeight)
    }

    func testTransitionLayoutSerialisation() throws {
        // Create a machine with transition layout
        let state1 = State(name: "Source")
        let state2 = State(name: "Target")

        let transition = Transition(label: "condition", source: state1.id, target: state2.id)

        let llfsm = LLFSM(states: [state1, state2], transitions: [transition], suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        // Create a state layout as we cannot have orphaned transition layouts
        let stateLayout = StateLayout(
            isOpen: true,
            openLayout: Rectangle(topLeft: Coordinate2D(100, 100), dimensions: Dimensions2D(200, 150)),
            closedLayout: Ellipse(topLeft: Coordinate2D(120, 120), dimensions: Dimensions2D(100, 80)),
            onEntryHeight: 30,
            onExitHeight: 25,
            onSuspendHeight: 20,
            onResumeHeight: 20,
            internalHeight: 50,
            zoomedOnEntryHeight: 60,
            zoomedOnExitHeight: 50,
            zoomedInternalHeight: 100,
            zoomedOnSuspendHeight: 40,
            zoomedOnResumeHeight: 40
        )
        machine.stateLayout = [state1.id: stateLayout]

        // Create specific bezier path for transition
        let srcPoint = Point2D(10, 20)
        let cp1 = Point2D(50, 60)
        let cp2 = Point2D(80, 90)
        let dstPoint = Point2D(100, 50)

        let path = Path([srcPoint, cp1, cp2, dstPoint])
        let transitionLayout = TransitionLayout(path: path)

        machine.transitionLayout = [transition.id: transitionLayout]

        // Serialize to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("TransitionMachine.machine")
        try machine.write(to: machineURL, isSuspensible: false)

        // Deserialize and verify layout
        let loadedMachine = try Machine(from: machineURL)

        XCTAssertEqual(loadedMachine.llfsm.transitions.count, 1)

        guard let transitionID = loadedMachine.llfsm.transitions.first,
              let loadedLayout = loadedMachine.transitionLayout[transitionID] else {
            XCTFail("Transition layout not found after deserialization")
            return
        }

        // Verify transition path points
        XCTAssertEqual(loadedLayout.path.points.count, 4)
        XCTAssertEqual(loadedLayout.path.beg.x, srcPoint.x)
        XCTAssertEqual(loadedLayout.path.beg.y, srcPoint.y)
        XCTAssertEqual(loadedLayout.path.cp1.x, cp1.x)
        XCTAssertEqual(loadedLayout.path.cp1.y, cp1.y)
        XCTAssertEqual(loadedLayout.path.cp2.x, cp2.x)
        XCTAssertEqual(loadedLayout.path.cp2.y, cp2.y)
        XCTAssertEqual(loadedLayout.path.end.x, dstPoint.x)
        XCTAssertEqual(loadedLayout.path.end.y, dstPoint.y)
    }

    func testWindowLayoutSerialisation() throws {
        // Create a machine with window layout
        let state = State(name: "TestState")
        let llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        // Create mock window layout data
        let windowLayout = "Window Layout Data".data(using: .utf8)!
        machine.windowLayout = windowLayout

        // Serialize to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("WindowLayoutMachine.machine")
        try machine.write(to: machineURL, isSuspensible: false)

        // Verify window layout file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: machineURL.appendingPathComponent(Filename.windowLayout).path))

        // Deserialize and verify
        let loadedMachine = try Machine(from: machineURL)
        XCTAssertNotNil(loadedMachine.windowLayout)
        XCTAssertEqual(loadedMachine.windowLayout, windowLayout)
    }

    func testSuspensibleMachineSerialisation() throws {
        // Create a suspensible machine
        let state1 = State(name: "Normal")
        let state2 = State(name: "Suspended")

        let llfsm = LLFSM(states: [state1, state2], transitions: [], suspendState: state2.id)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        // Serialize to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("SuspensibleMachine.machine")
        try machine.write(to: machineURL, isSuspensible: true)

        // Deserialize and verify
        let loadedMachine = try Machine(from: machineURL)

        XCTAssertEqual(loadedMachine.llfsm.states.count, 2)
        XCTAssertNotNil(loadedMachine.llfsm.suspendState)

        // Check if suspend state matches
        let suspendStateName = loadedMachine.llfsm.suspendState.flatMap { loadedMachine.llfsm.stateName(for: $0) }
        XCTAssertEqual(suspendStateName, "Suspended")
    }
}
