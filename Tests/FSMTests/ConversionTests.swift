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
        guard let resourcesURL = trafficLightResourcesURL() else { return }
        let trafficLightURL = resourcesURL.appendingPathComponent("TrafficLight.machine")
        let machine = try Machine(from: trafficLightURL)

        verifyTrafficLightProperties(machine)

        let layouts = machine.stateLayout
        let transitionLayouts = machine.transitionLayout
        let stateNameToID = buildStateNameToID(machine: machine)

        verifyTrafficLightStateLayouts(
            stateNameToID: stateNameToID,
            layouts: layouts,
            transitionLayouts: transitionLayouts,
            machine: machine)

        // Convert to C and verify layouts are preserved
        let cMachineURL = tempDirectoryURL.appendingPathComponent("TrafficLight_C.machine")
        let cLanguage = try XCTUnwrap(outputLanguage(for: .c), "C language binding must exist")
        try machine.write(to: cMachineURL, language: cLanguage, isSuspensible: true)
        let convertedMachine = try Machine(from: cMachineURL)
        XCTAssertEqual(convertedMachine.language.name, "c")
        XCTAssertEqual(convertedMachine.llfsm.states.count, 5)
        verifyConvertedLayouts(
            original: machine,
            converted: convertedMachine,
            stateNameToID: stateNameToID,
            originalLayouts: layouts,
            originalTransitions: transitionLayouts)
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
        let cWrapper = MachineDirectoryWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")
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
        let objcppWrapper = MachineDirectoryWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")
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

// MARK: - Traffic Light Test Helpers

/// Extension providing traffic light test helpers to reduce cyclomatic complexity.
extension ConversionTests {

    /// Parameters describing the expected layout for a state.
    struct StateLayoutExpectation {
        /// The state name to look up.
        var name: String
        /// Whether the state is expected to be in open (expanded) form.
        var isOpen: Bool
        /// Expected x coordinate.
        var x: Double
        /// Expected y coordinate.
        var y: Double
        /// Expected width.
        var w: Double
        /// Expected height.
        var h: Double
    }

    /// Locate the resources directory containing the traffic light machine.
    ///
    /// - Returns: The URL of the resources directory, or `nil` if not found.
    func trafficLightResourcesURL() -> URL? {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard let bundleResourcesURL = Bundle.module.resourceURL,
              fm.fileExists(atPath: bundleResourcesURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }
        let testResourcesURL = bundleResourcesURL.appendingPathComponent("Resources")
        let baseTrafficLightURL = bundleResourcesURL.appendingPathComponent("TrafficLight.machine")
        if fm.fileExists(atPath: testResourcesURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return testResourcesURL
        } else if fm.fileExists(atPath: baseTrafficLightURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue {
            return bundleResourcesURL
        }
        return nil
    }

    /// Verify basic properties of the traffic light machine.
    ///
    /// - Parameter machine: The machine to verify.
    func verifyTrafficLightProperties(_ machine: Machine) {
        XCTAssertEqual(machine.language.name, "objc++")
        XCTAssertEqual(machine.llfsm.states.count, 5)
        let stateNames = machine.llfsm.states.compactMap { machine.llfsm.stateName(for: $0) }
        XCTAssertTrue(stateNames.contains("InitialPseudoState"))
        XCTAssertTrue(stateNames.contains("Red"))
        XCTAssertTrue(stateNames.contains("Yellow"))
        XCTAssertTrue(stateNames.contains("Green"))
        XCTAssertTrue(stateNames.contains("YellowRed"))
    }

    /// Build a mapping from state names to state IDs for the given machine.
    ///
    /// - Parameter machine: The machine whose states to map.
    /// - Returns: A dictionary from state name strings to `StateID` values.
    func buildStateNameToID(machine: Machine) -> [String: StateID] {
        var map: [String: StateID] = [:]
        for state in machine.llfsm.states {
            if let name = machine.llfsm.stateName(for: state) {
                map[name] = state
            }
        }
        return map
    }

    /// Assert that the named state has the expected layout coordinates.
    ///
    /// - Parameters:
    ///   - expectation: The expected layout parameters.
    ///   - stateNameToID: Mapping from state names to IDs.
    ///   - layouts: The layout dictionary.
    func assertStateLayout(
        _ expectation: StateLayoutExpectation,
        stateNameToID: [String: StateID],
        layouts: StateLayouts
    ) {
        guard let id = stateNameToID[expectation.name], let layout = layouts[id] else {
            XCTFail("Missing layout for \(expectation.name)")
            return
        }
        XCTAssertEqual(
            layout.isOpen,
            expectation.isOpen,
            "State \(expectation.name) expected isOpen=\(expectation.isOpen)")
        if expectation.isOpen {
            XCTAssertEqual(layout.openLayout.x, expectation.x, accuracy: 1e-6)
            XCTAssertEqual(layout.openLayout.y, expectation.y, accuracy: 1e-6)
            XCTAssertEqual(layout.openLayout.w, expectation.w, accuracy: 1e-6)
            XCTAssertEqual(layout.openLayout.h, expectation.h, accuracy: 1e-6)
        } else {
            XCTAssertEqual(layout.closedLayout.x, expectation.x, accuracy: 1e-6)
            XCTAssertEqual(layout.closedLayout.y, expectation.y, accuracy: 1e-6)
            XCTAssertEqual(layout.closedLayout.w, expectation.w, accuracy: 1e-6)
            XCTAssertEqual(layout.closedLayout.h, expectation.h, accuracy: 1e-6)
        }
    }

    /// Assert that the named state's single outgoing transition has the expected points.
    ///
    /// - Parameters:
    ///   - name: The source state name.
    ///   - expected: The expected sequence of (x, y) point pairs.
    ///   - stateNameToID: Mapping from state names to IDs.
    ///   - machine: The machine containing the transitions.
    ///   - transitionLayouts: The layout dictionary for transitions.
    func assertTransitionPoints(
        _ name: String,
        expected: [(Double, Double)],
        stateNameToID: [String: StateID],
        machine: Machine,
        transitionLayouts: TransitionLayouts
    ) {
        guard let id = stateNameToID[name] else {
            XCTFail("No state ID for \(name)")
            return
        }
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
        for (point, (ex, ey)) in zip(tLayout.points, expected) {
            XCTAssertEqual(point.x, ex, accuracy: 1e-6)
            XCTAssertEqual(point.y, ey, accuracy: 1e-6)
        }
    }

    /// Verify that converting a machine preserves its state and transition layouts.
    ///
    /// Checks that every state in the original machine has a corresponding layout
    /// in the converted machine, and that transition point counts are preserved.
    ///
    /// - Parameters:
    ///   - original: The source machine before conversion.
    ///   - converted: The machine after conversion.
    ///   - stateNameToID: Mapping from state names to IDs in the original machine.
    ///   - originalLayouts: The state layout dictionary from the original machine.
    ///   - originalTransitions: The transition layout dictionary from the original machine.
    func verifyConvertedLayouts(
        original: Machine,
        converted: Machine,
        stateNameToID: [String: StateID],
        originalLayouts: StateLayouts,
        originalTransitions: TransitionLayouts
    ) {
        let convertedLayouts = converted.stateLayout
        let convertedTransitions = converted.transitionLayout
        // Build a name-to-ID map for the converted machine
        var convertedNameToID: [String: StateID] = [:]
        for state in converted.llfsm.states {
            if let name = converted.llfsm.stateName(for: state) {
                convertedNameToID[name] = state
            }
        }
        // Verify each state's layout is preserved after conversion
        for (name, originalID) in stateNameToID {
            guard let originalLayout = originalLayouts[originalID] else { continue }
            guard let convertedID = convertedNameToID[name] else {
                XCTFail("State \(name) missing in converted machine")
                continue
            }
            guard let convertedLayout = convertedLayouts[convertedID] else {
                XCTFail("No layout for state \(name) in converted machine")
                continue
            }
            XCTAssertEqual(
                convertedLayout.isOpen,
                originalLayout.isOpen,
                "State \(name) isOpen mismatch after conversion")
        }
        // Verify transition layout counts are preserved
        XCTAssertEqual(
            convertedTransitions.count,
            originalTransitions.count,
            "Transition layout count mismatch after conversion")
    }

    /// Verify state layout and transition points for all traffic light states.
    ///
    /// - Parameters:
    ///   - stateNameToID: Mapping from state names to IDs.
    ///   - layouts: The state layout dictionary.
    ///   - transitionLayouts: The transition layout dictionary.
    ///   - machine: The machine under test.
    func verifyTrafficLightStateLayouts(
        stateNameToID: [String: StateID],
        layouts: StateLayouts,
        transitionLayouts: TransitionLayouts,
        machine: Machine
    ) {
        let states: [StateLayoutExpectation] = [
            StateLayoutExpectation(name: "Green", isOpen: false, x: 500, y: 100, w: 100, h: 50),
            StateLayoutExpectation(name: "InitialPseudoState", isOpen: false, x: 37.5, y: 81.25, w: 25, h: 25),
            StateLayoutExpectation(name: "Red", isOpen: false, x: 100, y: 100, w: 100, h: 50),
            StateLayoutExpectation(name: "Yellow", isOpen: false, x: 300, y: 100, w: 100, h: 50),
            StateLayoutExpectation(name: "YellowRed", isOpen: false, x: 300, y: 300, w: 100, h: 50),
        ]
        for expectation in states {
            assertStateLayout(expectation, stateNameToID: stateNameToID, layouts: layouts)
        }
        assertTransitionPoints(
            "Green",
            expected: [
                (461.91697426306109, 89.345533359129988),
                (435.79132935733372, 72.899930228890383),
                (364.80037484835981, 73.540663018355772),
                (338.43397345581457, 89.597439209879795),
            ],
            stateNameToID: stateNameToID,
            machine: machine,
            transitionLayouts: transitionLayouts)
        assertTransitionPoints(
            "InitialPseudoState",
            expected: [
                (37.5, 80.75), (37.5, 80.75),
                (56.897817165048188, 94.253042288673086),
                (56.897817165048188, 94.253042288673086),
            ],
            stateNameToID: stateNameToID,
            machine: machine,
            transitionLayouts: transitionLayouts)
        assertTransitionPoints(
            "Red",
            expected: [
                (99.75577968598067, 119.99970546172364),
                (99.433001858706206, 179.47382569295826),
                (195.54177030952403, 301.0404871605727),
                (255.01166917949769, 300.26184012870544),
            ],
            stateNameToID: stateNameToID,
            machine: machine,
            transitionLayouts: transitionLayouts)
        assertTransitionPoints(
            "Yellow",
            expected: [
                (261.57396671082358, 89.591646605869542),
                (235.22335769176277, 73.532234235533906),
                (164.29335261145596, 73.007760736915287),
                (138.13934189371224, 89.385399294779631),
            ],
            stateNameToID: stateNameToID,
            machine: machine,
            transitionLayouts: transitionLayouts)
        assertTransitionPoints(
            "YellowRed",
            expected: [
                (345.00568062344985, 300.19467698836939),
                (404.76436083631722, 300.77638654151804),
                (504.77272019018744, 179.67869482754736),
                (502.0501079609715, 119.97923394692222),
            ],
            stateNameToID: stateNameToID,
            machine: machine,
            transitionLayouts: transitionLayouts)
    }
}
