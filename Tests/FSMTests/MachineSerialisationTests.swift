import XCTest
import Foundation
@testable import FSM

/// Unit tests for machine serialisation and deserialisation.
///
/// This test case verifies the correct serialisation and deserialisation of
/// finite-state machines (FSMs), including state and transition layouts, to
/// and from disk. It ensures that all file operations, layouts, and machine
/// properties are preserved across the serialisation process.
///
/// - Note: These tests use a temporary directory for file operations and
///         clean up after each test run.
final class MachineSerialisationTests: XCTestCase {

    /// Temporary directory for test file operations.
    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMSerializationTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }()

    /// Remove the temporary directory after each test.
    ///
    /// This method ensures that the temporary directory used for test file
    /// operations is deleted after each test, preventing resource leaks and
    /// clutter.
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    /// Test basic machine serialisation and deserialisation.
    ///
    /// This test creates a simple FSM, serialises it to disk, and verifies
    /// that all states, transitions, and layouts are correctly written and
    /// read back.
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

    /// Test state layout serialisation and deserialisation.
    ///
    /// This test creates a machine with a specific state layout, serialises
    /// it to disk, and verifies that the layout is preserved after
    /// deserialisation.
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
        // swiftlint:disable:next xct_specific_matcher
        XCTAssertTrue(loadedLayout.isOpen)
        XCTAssertEqual(loadedLayout.openLayout.dimensions.w, stateLayout.openLayout.dimensions.w)
        XCTAssertEqual(loadedLayout.openLayout.dimensions.h, stateLayout.openLayout.dimensions.h)
        XCTAssertEqual(loadedLayout.closedLayout.dimensions.w, stateLayout.closedLayout.dimensions.w)
        XCTAssertEqual(loadedLayout.closedLayout.dimensions.h, stateLayout.closedLayout.dimensions.h)
        XCTAssertEqual(loadedLayout.onEntryHeight, stateLayout.onEntryHeight)
        XCTAssertEqual(loadedLayout.onExitHeight, stateLayout.onExitHeight)
        XCTAssertEqual(loadedLayout.internalHeight, stateLayout.internalHeight)
    }

    /// Test transition layout serialisation and deserialisation.
    ///
    /// This test creates a machine with a specific transition layout,
    /// serialises it to disk, and verifies that the layout is preserved after
    /// deserialisation.
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

    /// Test window layout serialisation and deserialisation.
    ///
    /// This test creates a machine with a window layout, serialises it to disk,
    /// and verifies that the window layout is preserved after deserialisation.
    func testWindowLayoutSerialisation() throws {
        // Create a machine with window layout
        let state = State(name: "TestState")
        let llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        // Create mock window layout data
        // swiftlint:disable:next force_unwrapping
        let windowLayout = Data("Window Layout Data".utf8)
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

    /// Test suspensible machine serialisation and deserialisation.
    ///
    /// This test creates a machine with a suspend state, serialises it to disk,
    /// and verifies that the suspend state is preserved after deserialisation.
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

    /// Test all Filename constants for correct values.
    ///
    /// This test ensures that all filename constants used for machine serialisation
    /// have the expected values, matching the documented filenames and keys.
    func testFilenameConstants() {
        XCTAssertEqual(Filename.language, "Language")
        XCTAssertEqual(Filename.states, "States")
        XCTAssertEqual(Filename.layout, "Layout.plist")
        XCTAssertEqual(Filename.windowLayout, "WindowLayout.plist")
        XCTAssertEqual(Filename.includePath, "IncludePath")
        XCTAssertEqual(Filename.fileVersionKey, "Version")
        XCTAssertEqual(Filename.fileVersion, "1.3")
        XCTAssertEqual(Filename.graph, "net.mipal.micase.graph")
        XCTAssertEqual(Filename.metaData, "net.mipal.micase.metadata")
    }

    /// Test the URL extension methods for file operations.
    ///
    /// This test verifies the correct behaviour of fileURL(for:), contents(of:),
    /// stringContents(of:), write(_:to:), and write(content:to:) methods, including
    /// edge cases such as non-existent files and empty data.
    func testURLExtensionFileOperations() throws {
        let tempDir = tempDirectoryURL
        let testFile = "TestFile.txt"
        let testURL = tempDir.fileURL(for: testFile)
        let testData = "Hello, FSM!".data(using: .utf8)
        let testString = "Hello, FSM!"

        // fileURL(for:) should append the file name
        XCTAssertEqual(testURL, tempDir.appendingPathComponent(testFile))

        // contents(of:) should return nil for non-existent file
        XCTAssertNil(tempDir.contents(of: "NoSuchFile.txt"))

        // stringContents(of:) should return empty string for non-existent file
        XCTAssertEqual(tempDir.stringContents(of: "NoSuchFile.txt"), "")

        // write(_:to:) should write data to file
        try tempDir.write(testData, to: testFile)
        let readData = tempDir.contents(of: testFile)
        XCTAssertEqual(readData, testData)

        // stringContents(of:) should return correct string
        XCTAssertEqual(tempDir.stringContents(of: testFile), testString)

        // write(content:to:) should overwrite file with new content
        let newString = "Updated content"
        try tempDir.write(content: newString, to: testFile)
        XCTAssertEqual(tempDir.stringContents(of: testFile), newString)

        // write(_:to:) with nil should not throw or write
        XCTAssertNoThrow(try tempDir.write(nil, to: "NilFile.txt"))
        XCTAssertNil(tempDir.contents(of: "NilFile.txt"))
    }
}
