import XCTest
import Foundation
@testable import FSM

/// Unit tests for FSM conversion between language bindings and arrangements.
///
/// This test case verifies the correct conversion of finite-state machines
/// (FSMs) between different language bindings (C, Objective-C++), as well as
/// arrangement serialisation, deserialisation, and code generation. It ensures
/// that all properties, layouts, and files are preserved across conversions.
///
/// - Note: These tests use a temporary directory for file operations and
///         clean up after each test run.
final class ConversionTests: XCTestCase {

    /// Temporary directory for test file operations.
    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMConversionTests-\(UUID().uuidString)")
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

    /// Create a simple test machine for conversion tests.
    ///
    /// This helper method creates a machine with three states and two
    /// transitions, and initialises empty layouts.
    func createTestMachine() -> Machine {
        // Create a simple test machine with three states and two transitions
        let machine = Machine()

        let initialState = State(name: "Initial")
        let processingState = State(name: "Processing")
        let finalState = State(name: "Final")

        let transition1 = Transition(label: "start", source: initialState.id, target: processingState.id)
        let transition2 = Transition(label: "finish", source: processingState.id, target: finalState.id)

        machine.llfsm = LLFSM(states: [initialState, processingState, finalState],
                             transitions: [transition1, transition2],
                             suspendState: initialState.id)

        // Initialize empty dictionaries for layouts
        machine.stateLayout = [:]
        machine.transitionLayout = [:]

        return machine
    }

    /// Test conversion from C to Objective-C++ language binding.
    ///
    /// This test creates a machine with C binding, serialises it, converts it
    /// to Objective-C++, and verifies that all properties and files are
    /// preserved.
    func testCToObjCPPConversion() throws {
        // Create a machine with C binding
        let machine = createTestMachine()
        machine.language = CBinding()

        // Write machine to file system in C language
        let cMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_C.machine")
        try machine.write(to: cMachineURL, isSuspensible: true)

        // Read back the machine
        let readMachine = try Machine(from: cMachineURL)

        // Verify language binding
        XCTAssertEqual(readMachine.language.name, "c")
        XCTAssertEqual(readMachine.llfsm.states.count, 3)

        // Convert to ObjC++
        let objcppMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_ObjCPP.machine")
        try readMachine.write(to: objcppMachineURL, language: ObjCPPBinding(), isSuspensible: true)

        // Read back the converted machine
        let convertedMachine = try Machine(from: objcppMachineURL)

        // Verify language binding changed
        XCTAssertEqual(convertedMachine.language.name, "objc++")

        // Verify state and transition preservation
        XCTAssertEqual(convertedMachine.llfsm.states.count, 3)
        XCTAssertEqual(convertedMachine.llfsm.transitions.count, 2)

        // Verify suspendState preservation
        XCTAssertNotNil(convertedMachine.llfsm.suspendState)

        // Check for language-specific files
        let languageFile = objcppMachineURL.appendingPathComponent(Filename.language)
        let languageContent = try String(contentsOf: languageFile)
        XCTAssertEqual(languageContent, "objc++")
    }

    /// Test conversion from Objective-C++ to C language binding.
    ///
    /// This test creates a machine with Objective-C++ binding, serialises it,
    /// converts it to C, and verifies that all properties and files are
    /// preserved.
    func testObjCPPToCConversion() throws {
        // Create a machine with ObjC++ binding
        let machine = createTestMachine()
        machine.language = ObjCPPBinding()

        // Write machine to file system in ObjC++ language
        let objcppMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_ObjCPP.machine")
        try machine.write(to: objcppMachineURL, isSuspensible: true)

        // Convert to C
        let cMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_C.machine")
        try machine.write(to: cMachineURL, language: CBinding(), isSuspensible: true)

        // Read back the converted machine
        let convertedMachine = try Machine(from: cMachineURL)

        // Verify language binding changed
        XCTAssertEqual(convertedMachine.language.name, "c")

        // Verify state and transition preservation
        XCTAssertEqual(convertedMachine.llfsm.states.count, 3)
        XCTAssertEqual(convertedMachine.llfsm.transitions.count, 2)
    }

    /// Test reading and converting a traffic light machine from resources.
    ///
    /// This test reads a traffic light machine from resources, verifies its
    /// properties, and converts it to Objective-C++.
    func testTrafficLightMachineInResources() throws {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard let bundleResourcesURL = Bundle.module.resourceURL,
                  fm.fileExists(atPath: bundleResourcesURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
            return
        }
        let testResourcesURL = bundleResourcesURL.appendingPathComponent("Resources")
        let baseTrafficLightURL = bundleResourcesURL.appendingPathComponent("TrafficLight.machine")
        let resourcesURL: URL
        if fm.fileExists(atPath: testResourcesURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            resourcesURL = testResourcesURL
        } else if fm.fileExists(atPath: baseTrafficLightURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            resourcesURL = bundleResourcesURL
        } else {
            return // Skip test if resource directory does not exist
        }

        let trafficLightURL = resourcesURL.appendingPathComponent("TrafficLight.machine")

        // Test reading the machine
        let machine = try Machine(from: trafficLightURL)

        // Verify machine properties
        XCTAssertEqual(machine.language.name, "objc++")
        XCTAssertEqual(machine.llfsm.states.count, 5)

        // Test state names
        let stateNames = machine.llfsm.states.compactMap { machine.llfsm.stateName(for: $0) }
        XCTAssertTrue(stateNames.contains("InitialPseudoState"))
        XCTAssertTrue(stateNames.contains("Red"))
        XCTAssertTrue(stateNames.contains("Yellow"))
        XCTAssertTrue(stateNames.contains("Green"))
        XCTAssertTrue(stateNames.contains("YellowRed"))

        // Verify Layouts
        let layouts = machine.stateLayout
        let transitionLayouts = machine.transitionLayout

        // Map state names to IDs
        var stateNameToID: [String: StateID] = [:]
        for state in machine.llfsm.states {
            if let name = machine.llfsm.stateName(for: state) {
                stateNameToID[name] = state
            }
        }
        // Check state layout and transitions for each real-world state
        func assertStateLayout(_ name: String, isOpen: Bool, x: Double, y: Double, w: Double, h: Double, internalHeight: Double? = nil, onEntryHeight: Double? = nil, onExitHeight: Double? = nil) {
            guard let id = stateNameToID[name], let layout = layouts[id] else {
                XCTFail("Missing layout for \(name)")
                return
            }
            XCTAssertEqual(layout.isOpen, isOpen, "State \(name) expected isOpen=\(isOpen), got \(layout.isOpen)")
            if isOpen {
                XCTAssertEqual(layout.openLayout.x, x, accuracy: 1e-6)
                XCTAssertEqual(layout.openLayout.y, y, accuracy: 1e-6)
                XCTAssertEqual(layout.openLayout.w, w, accuracy: 1e-6)
                XCTAssertEqual(layout.openLayout.h, h, accuracy: 1e-6)
            } else {
                XCTAssertEqual(layout.closedLayout.x, x, accuracy: 1e-6)
                XCTAssertEqual(layout.closedLayout.y, y, accuracy: 1e-6)
                XCTAssertEqual(layout.closedLayout.w, w, accuracy: 1e-6)
                XCTAssertEqual(layout.closedLayout.h, h, accuracy: 1e-6)
            }
            if let ih = internalHeight { XCTAssertEqual(layout.internalHeight, ih, accuracy: 1e-6) }
            if let eh = onEntryHeight { XCTAssertEqual(layout.onEntryHeight, eh, accuracy: 1e-6) }
            if let xh = onExitHeight { XCTAssertEqual(layout.onExitHeight, xh, accuracy: 1e-6) }
        }
        func assertTransitionPoints(_ name: String, expected: [(Double, Double)]) {
            guard let id = stateNameToID[name] else {
                XCTFail("No state ID for \(name)")
                return
            }
            // Find all outgoing transitions for this state
            let outgoing = machine.llfsm.transitionMap.values.filter { $0.source == id }
            guard outgoing.count == 1 else {
                XCTFail("Expected exactly 1 outgoing transition for \(name), got \(outgoing.count)")
                return
            }
            let tID = outgoing[0].id
            guard let tLayout = transitionLayouts[tID] else {
                XCTFail("No TransitionLayout for transition ID \(tID) of state \(name)")
                return
            }

            XCTAssertEqual(tLayout.points.count, expected.count)
            for i in 0..<expected.count {
                let (ex, ey) = expected[i]
                XCTAssertEqual(tLayout.points[i].x, ex, accuracy: 1e-6)
                XCTAssertEqual(tLayout.points[i].y, ey, accuracy: 1e-6)
            }
        }
        // Green
        assertStateLayout("Green", isOpen: false, x: 500, y: 100, w: 100, h: 50, internalHeight: 40, onEntryHeight: 20, onExitHeight: 20) // Set isOpen to true if this state is open in the plist
        assertTransitionPoints("Green", expected: [
            (461.91697426306109, 89.345533359129988),
            (435.79132935733372, 72.899930228890383),
            (364.80037484835981, 73.540663018355772),
            (338.43397345581457, 89.597439209879795)
        ])
        // InitialPseudoState
        assertStateLayout("InitialPseudoState", isOpen: false, x: 37.5, y: 81.25, w: 25, h: 25) // Set isOpen to true if this state is open in the plist
        assertTransitionPoints("InitialPseudoState", expected: [
            (37.5, 80.75), (37.5, 80.75), (56.897817165048188, 94.253042288673086), (56.897817165048188, 94.253042288673086)
        ])
        // Red
        assertStateLayout("Red", isOpen: false, x: 100, y: 100, w: 100, h: 50, internalHeight: 40, onEntryHeight: 20, onExitHeight: 20) // Set isOpen to true if this state is open in the plist
        assertTransitionPoints("Red", expected: [
            (99.75577968598067, 119.99970546172364),
            (99.433001858706206, 179.47382569295826),
            (195.54177030952403, 301.0404871605727),
            (255.01166917949769, 300.26184012870544)
        ])
        // Yellow
        assertStateLayout("Yellow", isOpen: false, x: 300, y: 100, w: 100, h: 50, internalHeight: 40, onEntryHeight: 20, onExitHeight: 20) // Set isOpen to true if this state is open in the plist
        assertTransitionPoints("Yellow", expected: [
            (261.57396671082358, 89.591646605869542),
            (235.22335769176277, 73.532234235533906),
            (164.29335261145596, 73.007760736915287),
            (138.13934189371224, 89.385399294779631)
        ])
        // YellowRed
        assertStateLayout("YellowRed", isOpen: false, x: 300, y: 300, w: 100, h: 50, internalHeight: 40, onEntryHeight: 20, onExitHeight: 20) // Set isOpen to true if this state is open in the plist
        assertTransitionPoints("YellowRed", expected: [
            (345.00568062344985, 300.19467698836939),
            (404.76436083631722, 300.77638654151804),
            (504.77272019018744, 179.67869482754736),
            (502.0501079609715, 119.97923394692222)
        ])

        // Convert to C
        let cMachineURL = tempDirectoryURL.appendingPathComponent("TrafficLight_C.machine")
        // swiftlint:disable:next force_unwrapping
        try machine.write(to: cMachineURL, language: outputLanguage(for: .c)!, isSuspensible: true)

        // Read back converted machine
        let convertedMachine = try Machine(from: cMachineURL)
        XCTAssertEqual(convertedMachine.language.name, "c")
        XCTAssertEqual(convertedMachine.llfsm.states.count, 5)

        // Build state name → layout/transition mapping for both original and converted machines
        let convertedLayouts = convertedMachine.stateLayout
        let convertedTransitions = convertedMachine.transitionLayout
        let origNameToLayout: [String: StateLayout] = Dictionary(uniqueKeysWithValues: machine.llfsm.states.compactMap { sid in
            guard let name = machine.llfsm.stateName(for: sid), let layout = layouts[sid] else { return nil }
            return (name, layout)
        })
        let convNameToLayout: [String: StateLayout] = Dictionary(uniqueKeysWithValues: convertedMachine.llfsm.states.compactMap { sid in
            guard let name = convertedMachine.llfsm.stateName(for: sid), let layout = convertedLayouts[sid] else { return nil }
            return (name, layout)
        })
        // Compare layouts by state name, checking all relevant layout fields
        for name in stateNameToID.keys {
            guard let orig = origNameToLayout[name], let conv = convNameToLayout[name] else {
                XCTFail("State layout for \(name) missing in original or converted layouts")
                continue
            }
            // isOpen
            XCTAssertEqual(orig.isOpen, conv.isOpen)
            // openLayout
            XCTAssertEqual(orig.openLayout.x, conv.openLayout.x, accuracy: 1e-6)
            XCTAssertEqual(orig.openLayout.y, conv.openLayout.y, accuracy: 1e-6)
            XCTAssertEqual(orig.openLayout.w, conv.openLayout.w, accuracy: 1e-6)
            XCTAssertEqual(orig.openLayout.h, conv.openLayout.h, accuracy: 1e-6)
            // closedLayout (Ellipse: x, y, w, h)
            XCTAssertEqual(orig.closedLayout.x, conv.closedLayout.x, accuracy: 1e-6)
            XCTAssertEqual(orig.closedLayout.y, conv.closedLayout.y, accuracy: 1e-6)
            XCTAssertEqual(orig.closedLayout.w, conv.closedLayout.w, accuracy: 1e-6)
            XCTAssertEqual(orig.closedLayout.h, conv.closedLayout.h, accuracy: 1e-6)
            // Heights
            XCTAssertEqual(orig.internalHeight, conv.internalHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.onEntryHeight, conv.onEntryHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.onExitHeight, conv.onExitHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.onSuspendHeight, conv.onSuspendHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.onResumeHeight, conv.onResumeHeight, accuracy: 1e-6)
            // Zoomed heights
            XCTAssertEqual(orig.zoomedOnEntryHeight, conv.zoomedOnEntryHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.zoomedOnExitHeight, conv.zoomedOnExitHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.zoomedInternalHeight, conv.zoomedInternalHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.zoomedOnSuspendHeight, conv.zoomedOnSuspendHeight, accuracy: 1e-6)
            XCTAssertEqual(orig.zoomedOnResumeHeight, conv.zoomedOnResumeHeight, accuracy: 1e-6)
        }
        // Compare transition points by state name
        let origNameToTransitions: [String: [TransitionLayout]] = Dictionary(uniqueKeysWithValues: machine.llfsm.states.compactMap { sid in
            guard let name = machine.llfsm.stateName(for: sid) else { return nil }
            // All outgoing transitions for this state
            let outgoing = machine.llfsm.transitionMap.values.filter { $0.source == sid }
            let layoutsArr = outgoing.compactMap { transitionLayouts[$0.id] as? TransitionLayout }
            return (name, layoutsArr)
        })
        let convNameToTransitions: [String: [TransitionLayout]] = Dictionary(uniqueKeysWithValues: convertedMachine.llfsm.states.compactMap { sid in
            guard let name = convertedMachine.llfsm.stateName(for: sid) else { return nil }
            let outgoing = convertedMachine.llfsm.transitionMap.values.filter { $0.source == sid }
            let layoutsArr = outgoing.compactMap { convertedTransitions[$0.id] as? TransitionLayout }
            return (name, layoutsArr)
        })
        for name in stateNameToID.keys {
            guard let origTransitions = origNameToTransitions[name], let convTransitions = convNameToTransitions[name] else {
                XCTFail("Transitions for \(name) missing in original or converted layouts")
                continue
            }
            XCTAssertEqual(origTransitions.count, convTransitions.count, "Transition count mismatch for state \(name)")
            for (o, c) in zip(origTransitions, convTransitions) {
                XCTAssertEqual(o.points.count, c.points.count, "Transition points count mismatch for state \(name)")
                for (op, cp) in zip(o.points, c.points) {
                    XCTAssertEqual(op.x, cp.x, accuracy: 1e-6)
                    XCTAssertEqual(op.y, cp.y, accuracy: 1e-6)
                }
            }
        }

    }

    /// Test arrangement conversion and serialisation.
    ///
    /// This test creates an arrangement, serialises it, and verifies that all
    /// instances and files are preserved.
    func testArrangementConversion() throws {
        // Create a machine
        let machine = createTestMachine()
        machine.language = CBinding()

        // Create instances
        let instance1 = Instance(name: "instance1", typeFile: "TestMachine.machine", machine: machine)
        let instance2 = Instance(name: "instance2", typeFile: "TestMachine.machine", machine: machine)

        // Create arrangement
        let arrangement = Arrangement(namedInstances: [instance1, instance2])

        // Create wrapper
        let cWrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: arrangement, named: "TestArrangement", language: CBinding())

        // Write arrangement to disk
        let cArrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement_C.arrangement")
        try cWrapper.write(to: cArrangementURL)

        // Read back the arrangement
        let readWrapper = try ArrangementWrapper(url: cArrangementURL)

        // Verify arrangement
        XCTAssertEqual(readWrapper.arrangement.namedInstances.count, 2)
        XCTAssertEqual(readWrapper.language.name, "c")

        // Convert to ObjC++
        readWrapper.language = ObjCPPBinding()
        let objcppArrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement_ObjCPP.arrangement")
        try readWrapper.write(to: objcppArrangementURL)

        // Read back the converted arrangement
        let convertedWrapper = try ArrangementWrapper(url: objcppArrangementURL)

        // Verify language binding changed
        XCTAssertEqual(convertedWrapper.language.name, "objc++")

        // Verify instances preservation
        XCTAssertEqual(convertedWrapper.arrangement.namedInstances.count, 2)
    }

    /// Test code generation verification for C language.
    ///
    /// This test creates a machine, generates C code, and verifies that the
    /// generated files and properties are correct.
    func testCodeGenerationVerification() throws {
        // Create a machine with C binding
        let machine = createTestMachine()

        // Create wrapper for C language
        let cWrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")
        cWrapper.language = CBinding()

        // Generate C code
        let cMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_C.machine")
        try cWrapper.write(to: cMachineURL)

        // Verify C code generation
        let cHeaderPath = cMachineURL.appendingPathComponent("Machine_TestMachine_C.h")
        XCTAssertTrue(FileManager.default.fileExists(atPath: cHeaderPath.path))

        let cHeaderContent = try String(contentsOf: cHeaderPath)
        XCTAssertTrue(cHeaderContent.contains("struct Machine_TestMachine_C"))
        XCTAssertTrue(cHeaderContent.contains("void fsm_testmachine_c_init"))

        // Create wrapper for ObjC++ language
        let objcppWrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")
        objcppWrapper.language = ObjCPPBinding()

        // Generate ObjC++ code
        let objcppMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_ObjCPP.machine")
        try objcppWrapper.write(to: objcppMachineURL)

        // Verify language file
        let languageFilePath = objcppMachineURL.appendingPathComponent(Filename.language)
        XCTAssertTrue(FileManager.default.fileExists(atPath: languageFilePath.path))

        let languageContent = try String(contentsOf: languageFilePath)
        XCTAssertEqual(languageContent, "objc++")
    }
}
