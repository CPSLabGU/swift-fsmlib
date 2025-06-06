import XCTest
import Foundation
@testable import FSM

/// Unit tests for FSM file and directory wrappers.
///
/// This test case verifies the correct behaviour of file and directory wrappers
/// used for serialising and deserialising FSMs, machines, and arrangements. It
/// ensures that all file operations, wrapper properties, and content extraction
/// methods function as intended.
///
/// - Note: These tests cover a variety of file management scenarios for FSMs.
final class WrapperTests: XCTestCase {

    /// Temporary directory for test file operations.
    let tempDirectoryURL: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("FSMWrapperTests-\(UUID().uuidString)")
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

    /// Test regular file wrapper.
    ///
    /// This test creates a regular file wrapper with some test content and verifies that
    /// the properties are correctly set.
    func testFileWrapperBasicOperations() throws {
        // swiftlint:disable:next force_unwrapping
        let testData = Data("Test content".utf8)
        let fileWrapper = FileWrapper(regularFileWithContents: testData)
        fileWrapper.preferredFilename = "test.txt"

        // Check properties
        XCTAssertTrue(fileWrapper.isRegularFile)
        XCTAssertFalse(fileWrapper.isDirectory)
        XCTAssertFalse(fileWrapper.isSymbolicLink)
        XCTAssertEqual(fileWrapper.preferredFilename, "test.txt")
        XCTAssertEqual(fileWrapper.regularFileContents, testData)

        // Test writing and reading back
        let fileURL = tempDirectoryURL.appendingPathComponent("test.txt")
        try fileWrapper.write(to: fileURL, originalContentsURL: nil)

        let readWrapper = try FileWrapper(url: fileURL)
        XCTAssertEqual(readWrapper.regularFileContents, testData)
        XCTAssertEqual(readWrapper.stringContents, "Test content")
    }

    /// Test directory wrapper operations.
    ///
    /// This test creates a directory wrapper with some files and verifies that
    /// the properties are correctly set.
    func testDirectoryWrapperOperations() throws {
        // Create a directory wrapper with some files
        // swiftlint:disable:next force_unwrapping
        let file1 = FileWrapper(regularFileWithContents: Data("File 1 content".utf8))
        file1.preferredFilename = "file1.txt"

        // swiftlint:disable:next force_unwrapping
        let file2 = FileWrapper(regularFileWithContents: Data("File 2 content".utf8))
        file2.preferredFilename = "file2.txt"

        let dirWrapper = DirectoryWrapper(directoryWithFileWrappers: [
            "file1.txt": file1,
            "file2.txt": file2
        ])
        dirWrapper.preferredFilename = "testDir"

        // Verify properties
        XCTAssertTrue(dirWrapper.isDirectory)
        XCTAssertEqual(dirWrapper.fileWrappers?.count, 2)
        XCTAssertEqual(dirWrapper.preferredFilename, "testDir")
        XCTAssertEqual(dirWrapper.name, "testDir")

        // Write and read back
        let dirURL = tempDirectoryURL.appendingPathComponent("testDir")
        try dirWrapper.write(to: dirURL, originalContentsURL: nil)

        let readDirWrapper = try DirectoryWrapper(url: dirURL)
        XCTAssertEqual(readDirWrapper.fileWrappers?.count, 2)
        XCTAssertEqual(readDirWrapper.stringContents(of: "file1.txt"), "File 1 content")
    }

    /// Test creation of a machine wrapper.
    ///
    /// This test creates a simple test machine with two states and a transition.
    /// It then creates a machine wrapper with the machine and writes it to disk.
    /// Finally, it verifies that the machine filename was added to the wrapper.
    func testMachineWrapperCreation() throws {
        // Create a simple test machine
        let machine = Machine()
        let state1 = State(name: "Initial")
        let state2 = State(name: "Final")
        let transition = Transition(label: "finish", source: state1.id, target: state2.id)

        machine.llfsm = LLFSM(states: [state1, state2],
                             transitions: [transition],
                             suspendState: nil)
        machine.language = CBinding()

        // Create wrapper
        let wrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: "TestMachine")

        // Verify properties
        XCTAssertEqual(wrapper.name, "TestMachine")
        XCTAssertEqual(wrapper.machine.llfsm.states.count, 2)
        XCTAssertEqual(wrapper.language.name, "c")

        // Write the machine to disk
        let machineURL = tempDirectoryURL.appendingPathComponent("TestMachine.machine")
        try wrapper.write(to: machineURL)

        // Read it back
        let readWrapper = try MachineWrapper(url: machineURL)
        XCTAssertEqual(readWrapper.name, "TestMachine")
        XCTAssertEqual(readWrapper.machine.llfsm.states.count, 2)

        // Verify language file was created
        let langWrapper = readWrapper.fileWrappers?[Filename.language]
        XCTAssertNotNil(langWrapper)
        XCTAssertEqual(langWrapper?.stringContents, "c")
    }

    /// Test creation of an arrangement wrapper.
    ///
    /// This test creates a test machine, an instance with the machine, and an arrangement with the instance.
    /// It then creates a machine wrapper with the same name as the instance typeFile and adds it to the arrangement wrapper.
    /// Finally, it writes the arrangement to disk and verifies that the machine filename was added to the wrapper.
    func testArrangementWrapperCreation() throws {
        // Create test machine
        let machine = Machine()
        let state = State(name: "Initial")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        machine.language = CBinding()

        // Create arrangement with two instances
        let instance1 = Instance(name: "instance1", typeFile: "Machine.machine", machine: machine)
        let instance2 = Instance(name: "instance2", typeFile: "Machine.machine", machine: machine)
        let arrangement = Arrangement(namedInstances: [instance1, instance2])

        // Create wrapper
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: arrangement, named: "TestArrangement")

        // Verify properties
        XCTAssertEqual(wrapper.name, "TestArrangement")
        XCTAssertEqual(wrapper.arrangement.namedInstances.count, 2)

        // Write to disk
        let arrangementURL = tempDirectoryURL.appendingPathComponent("TestArrangement.arrangement")
        try wrapper.write(to: arrangementURL)

        // Verify Machines file
        let machinesPath = arrangementURL.appendingPathComponent(Filename.machines)
        XCTAssertTrue(FileManager.default.fileExists(atPath: machinesPath.path))

        let machinesContent = try String(contentsOf: machinesPath)
        XCTAssertTrue(machinesContent.contains("instance1"))
        XCTAssertTrue(machinesContent.contains("instance2"))
    }

    /// Test string contents extraction
    func testFileOperations() {
        // swiftlint:disable:next force_unwrapping
        let textData = Data("Hello, world!".utf8)
        let file = FileWrapper(regularFileWithContents: textData)
        XCTAssertEqual(file.stringContents, "Hello, world!")

        // Test replace file wrapper
        let dir = DirectoryWrapper(directoryWithFileWrappers: [:])
        let file1 = fileWrapper(named: "test.txt", from: "Original content")
        dir.addFileWrapper(file1)
        XCTAssertEqual(dir.stringContents(of: "test.txt"), "Original content")

        let file2 = fileWrapper(named: "test.txt", from: "Replaced content")
        dir.replaceFileWrapper(file2)
        XCTAssertEqual(dir.stringContents(of: "test.txt"), "Replaced content")

        // Test remove file wrapper
        dir.removeFileWrapper(file2)
        XCTAssertNil(dir.fileWrappers?["test.txt"])
    }
}
