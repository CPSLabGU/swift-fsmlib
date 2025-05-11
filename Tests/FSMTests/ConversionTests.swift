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
        XCTAssertEqual(machine.language.name, "c")
        XCTAssertEqual(machine.llfsm.states.count, 4)

        // Test state names
        let stateNames = machine.llfsm.states.compactMap { machine.llfsm.stateName(for: $0) }
        XCTAssertTrue(stateNames.contains("Red"))
        XCTAssertTrue(stateNames.contains("Yellow"))
        XCTAssertTrue(stateNames.contains("Green"))
        XCTAssertTrue(stateNames.contains("YellowToRed"))

        // Convert to ObjC++
        let objcppMachineURL = tempDirectoryURL.appendingPathComponent("TrafficLight_ObjCPP.machine")
        // swiftlint:disable:next force_unwrapping
        try machine.write(to: objcppMachineURL, language: outputLanguage(for: .objCX)!, isSuspensible: true)

        // Read back converted machine
        let convertedMachine = try Machine(from: objcppMachineURL)
        XCTAssertEqual(convertedMachine.language.name, "objc++")
        XCTAssertEqual(convertedMachine.llfsm.states.count, 4)
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

//        // Convert to ObjC++
//        readWrapper.language = ObjCPPBinding()
//        let objcppArrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement_ObjCPP.arrangement")
//        try readWrapper.write(to: objcppArrangementURL)
//
//        // Read back the converted arrangement
//        let convertedWrapper = try ArrangementWrapper(url: objcppArrangementURL)
//
//        // Verify language binding changed
//        XCTAssertEqual(convertedWrapper.language.name, "objc++")
//
//        // Verify instances preservation
//        XCTAssertEqual(convertedWrapper.arrangement.namedInstances.count, 2)
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

//        // Create wrapper for ObjC++ language
//        let objcppWrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")
//        objcppWrapper.language = ObjCPPBinding()
//
//        // Generate ObjC++ code
//        let objcppMachineURL = tempDirectoryURL.appendingPathComponent("TestMachine_ObjCPP.machine")
//        try objcppWrapper.write(to: objcppMachineURL)
//
//        // Verify language file
//        let languageFilePath = objcppMachineURL.appendingPathComponent(Filename.language)
//        XCTAssertTrue(FileManager.default.fileExists(atPath: languageFilePath.path))
//
//        let languageContent = try String(contentsOf: languageFilePath)
//        XCTAssertEqual(languageContent, "objc++")
    }
}
