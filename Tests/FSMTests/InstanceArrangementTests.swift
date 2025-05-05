import XCTest
import Foundation
@testable import FSM

final class InstanceArrangementTests: XCTestCase {

    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMInstanceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }()

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    func testInstanceCreation() {
        // Create a machine
        let machine = Machine()
        let state = State(name: "Test")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)

        // Create an instance
        let instance = Instance(name: "instance1", typeFile: "TestMachine.machine", machine: machine)

        // Test properties
        XCTAssertEqual(instance.name, "instance1")
        XCTAssertEqual(instance.typeFile, "TestMachine.machine")
        XCTAssertEqual(instance.typeName, "TestMachine")
        XCTAssertEqual(instance.machine.llfsm.states.count, 1)
    }

    func testInstanceEquality() {
        // Create a machine
        let machine1 = Machine()
        let state1 = State(name: "Test")
        machine1.llfsm = LLFSM(states: [state1], transitions: [], suspendState: nil)

        // Create identical machine
        let machine2 = Machine()
        let state2 = State(name: "Test")
        machine2.llfsm = LLFSM(states: [state2], transitions: [], suspendState: nil)

        // Create different machine
        let machine3 = Machine()
        let state3 = State(name: "Different")
        machine3.llfsm = LLFSM(states: [state3], transitions: [], suspendState: nil)

        // Create instances
        let instance1 = Instance(name: "instance1", typeFile: "Machine.machine", machine: machine1)
        let instance2 = Instance(name: "instance1", typeFile: "Machine.machine", machine: machine2)
        let instance3 = Instance(name: "instance2", typeFile: "Machine.machine", machine: machine1)
        let instance4 = Instance(name: "instance1", typeFile: "DifferentMachine.machine", machine: machine1)
        let instance5 = Instance(name: "instance1", typeFile: "Machine.machine", machine: machine3)

        // Test equality
        XCTAssertEqual(instance1, instance2) // Same name, type, and equivalent machines
        XCTAssertNotEqual(instance1, instance3) // Different names
        XCTAssertNotEqual(instance1, instance4) // Different type files
        XCTAssertNotEqual(instance1, instance5) // Different machine states

        // Test hash
        var hasher1 = Hasher()
        var hasher2 = Hasher()
        instance1.hash(into: &hasher1)
        instance2.hash(into: &hasher2)
        // The hash values should be consistent with equality
        XCTAssertEqual(instance1, instance2)
    }

    func testArrangementCreation() {
        // Create machines
        let machine1 = Machine()
        let state1 = State(name: "State1")
        machine1.llfsm = LLFSM(states: [state1], transitions: [], suspendState: nil)

        let machine2 = Machine()
        let state2 = State(name: "State2")
        machine2.llfsm = LLFSM(states: [state2], transitions: [], suspendState: nil)

        // Create instances
        let instance1 = Instance(name: "instance1", typeFile: "Machine1.machine", machine: machine1)
        let instance2 = Instance(name: "instance2", typeFile: "Machine2.machine", machine: machine2)

        // Create arrangement
        let arrangement = Arrangement(namedInstances: [instance1, instance2])

        // Test properties
        XCTAssertEqual(arrangement.namedInstances.count, 2)
        XCTAssertEqual(arrangement.namedInstances[0].name, "instance1")
        XCTAssertEqual(arrangement.namedInstances[1].name, "instance2")
    }

    func testArrangementWrapper() throws {
        // Create machines
        let machine1 = Machine()
        let state1 = State(name: "State1")
        machine1.llfsm = LLFSM(states: [state1], transitions: [], suspendState: nil)
        machine1.language = CBinding()

        let machine2 = Machine()
        let state2 = State(name: "State2")
        machine2.llfsm = LLFSM(states: [state2], transitions: [], suspendState: nil)
        machine2.language = CBinding()

        // Create instances
        let instance1 = Instance(name: "instance1", typeFile: "Machine1.machine", machine: machine1)
        let instance2 = Instance(name: "instance2", typeFile: "Machine2.machine", machine: machine2)

        // Create arrangement
        let arrangement = Arrangement(namedInstances: [instance1, instance2])

        // Create wrapper
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: arrangement)

        // Test properties
        XCTAssertEqual(wrapper.arrangement.namedInstances.count, 2)
        XCTAssertEqual(wrapper.language.name, "c")
    }

    func testArrangementSerialization() throws {
        // Create machines
        let machine1 = Machine()
        let state1 = State(name: "State1")
        machine1.llfsm = LLFSM(states: [state1], transitions: [], suspendState: nil)
        machine1.language = CBinding()

        let machine2 = Machine()
        let state2 = State(name: "State2")
        machine2.llfsm = LLFSM(states: [state2], transitions: [], suspendState: nil)
        machine2.language = CBinding()

        // Create instances
        let instance1 = Instance(name: "instance1", typeFile: "Machine1.machine", machine: machine1)
        let instance2 = Instance(name: "instance2", typeFile: "Machine2.machine", machine: machine2)

        // Create arrangement
        let arrangement = Arrangement(namedInstances: [instance1, instance2])

        // Create wrapper
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: arrangement, named: "TestArrangement")

        // Write arrangement to disk
        let arrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement.arrangement")
        try wrapper.write(to: arrangementURL)

        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: arrangementURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: arrangementURL.appendingPathComponent(Filename.machines).path))

        // Check machine names file
        let machinesContent = try String(contentsOf: arrangementURL.appendingPathComponent(Filename.machines))
        XCTAssertTrue(machinesContent.contains("instance1"))
        XCTAssertTrue(machinesContent.contains("instance2"))

        // Read arrangement back
        let readWrapper = try ArrangementWrapper(url: arrangementURL)

        // Verify loaded arrangement
        XCTAssertEqual(readWrapper.arrangement.namedInstances.count, 2)
        XCTAssertEqual(readWrapper.arrangement.namedInstances[0].name, "instance1")
        XCTAssertEqual(readWrapper.arrangement.namedInstances[1].name, "instance2")
    }

    func testArrangementFromURL() throws {
        // Create machines
        let machine = Machine()
        let state = State(name: "State")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = CBinding()

        // Write machine to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("Machine.machine")
        try machine.write(to: machineURL, isSuspensible: false)

        // Create a directory for the arrangement
        let arrangementURL = tempDirectoryURL.appendingPathComponent("FromURLArrangement.arrangement")
        try FileManager.default.createDirectory(at: arrangementURL, withIntermediateDirectories: true)

        // Add machine to arrangement directory
        let machineDirURL = arrangementURL.appendingPathComponent("Machine.machine")
        try FileManager.default.copyItem(at: machineURL, to: machineDirURL)

        // Create machines file
        let machinesContent = "Machine\n"
        try machinesContent.write(to: arrangementURL.appendingPathComponent(Filename.machines), atomically: true, encoding: .utf8)

        // Create language file
        try "c".write(to: arrangementURL.appendingPathComponent(Filename.language), atomically: true, encoding: .utf8)

        // Load arrangement from URL
        let arrangement = try Arrangement(from: arrangementURL)

        // Verify loaded arrangement
        XCTAssertEqual(arrangement.namedInstances.count, 1)
        XCTAssertEqual(arrangement.namedInstances[0].name, "Machine")
        XCTAssertEqual(arrangement.namedInstances[0].typeName, "Machine")
    }

    func testAddingMachinesToArrangement() throws {
        // Create a machine
        let machine = Machine()
        let state = State(name: "State")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = CBinding()

        // Create an instance
        let instance = Instance(name: "instance", typeFile: "Machine.machine", machine: machine)

        // Create arrangement
        let arrangement = Arrangement(namedInstances: [instance])

        // Create wrapper
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: arrangement, named: "TestArrangement")

        // Write arrangement to disk
        let arrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement.arrangement")
        try wrapper.write(to: arrangementURL)

        // Verify machine filename was added to wrapper
        let machinesContent = try String(contentsOf: arrangementURL.appendingPathComponent(Filename.machines))
        XCTAssertTrue(machinesContent.contains("instance"))
    }
}
