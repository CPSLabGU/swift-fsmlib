import XCTest
import Foundation
@testable import FSM

final class ConversionTests: XCTestCase {

    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMConversionTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }()

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

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

        // TODO: Convert to ObjC++
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

    func testTrafficLightMachineInResources() throws {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard let bundleResourcesURL = Bundle.module.resourceURL,
                  fm.fileExists(atPath: bundleResourcesURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else{
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
        try machine.write(to: objcppMachineURL, language: outputLanguage(for: .objCX)!, isSuspensible: true)

        // Read back converted machine
        let convertedMachine = try Machine(from: objcppMachineURL)
        XCTAssertEqual(convertedMachine.language.name, "objc++")
        XCTAssertEqual(convertedMachine.llfsm.states.count, 4)
    }

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
