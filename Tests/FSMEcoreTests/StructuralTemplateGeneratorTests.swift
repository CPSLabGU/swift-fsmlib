import XCTest
@testable import FSM
@testable import FSMEcore

/// Tests that the structural templates reproduce the output of the Swift writers.
final class StructuralTemplateGeneratorTests: XCTestCase {
    /// Verify that the machine template writes the same bundle as the Swift writer.
    @MainActor
    func testStructuralMachineTemplateReproducesMachineBundle() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let generator = StructuralTemplateGenerator()
        let outputDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "structural-machine")
        let expectedDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "expected-machine")

        try await generator.generateMachineBundle(for: machine, named: "TrafficLight", to: outputDirectory)
        let expectedBundle = expectedDirectory.appendingPathComponent("TrafficLight.machine", isDirectory: true)
        try machine.write(to: expectedBundle, isSuspensible: true)

        let renderedBundle = outputDirectory.appendingPathComponent("TrafficLight.machine", isDirectory: true)
        try FSMEcoreTestSupport.assertDirectoryContentsEqual(renderedBundle, expectedBundle)
    }

    /// Verify that the SCXML template writes the same text as the Swift writer.
    @MainActor
    func testStructuralSCXMLTemplateReproducesSCXMLOutput() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let generator = StructuralTemplateGenerator()
        let outputDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "structural-scxml")
        let renderedFile = outputDirectory.appendingPathComponent("TrafficLight.scxml")
        let expectedFile = outputDirectory.appendingPathComponent("expected.scxml")

        try await generator.generateSCXML(for: machine, named: "TrafficLight", to: renderedFile)

        let expectedStorage = MachineStorageFactory.create(for: machine, format: .scxml, at: expectedFile)
        try expectedStorage.write(to: expectedFile)

        XCTAssertEqual(
            try String(contentsOf: renderedFile, encoding: .utf8),
            try String(contentsOf: expectedFile, encoding: .utf8)
        )
    }

    /// Verify that the CMake template writes the same file as the Swift writer.
    @MainActor
    func testStructuralCMakeTemplateReproducesCMakeLists() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let generator = StructuralTemplateGenerator()
        let outputDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "structural-cmake")
        let renderedFile = outputDirectory.appendingPathComponent("CMakeLists.txt")

        try await generator.generateCMakeLists(for: machine, named: "TrafficLight", to: renderedFile)

        let expectedDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "expected-machine")
        let expectedBundle = expectedDirectory.appendingPathComponent("TrafficLight.machine", isDirectory: true)
        try machine.write(to: expectedBundle, isSuspensible: true)
        let expectedFile = expectedBundle.appendingPathComponent("CMakeLists.txt")

        XCTAssertEqual(
            try String(contentsOf: renderedFile, encoding: .utf8),
            try String(contentsOf: expectedFile, encoding: .utf8)
        )
    }

    /// Verify that the layout templates write the same property lists as the Swift writer.
    @MainActor
    func testStructuralLayoutTemplateReproducesLayoutFiles() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let generator = StructuralTemplateGenerator()
        let outputDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "structural-layout")
        let expectedDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "expected-layout")

        try await generator.generateLayoutFiles(for: machine, named: "TrafficLight", to: outputDirectory)
        let expectedBundle = expectedDirectory.appendingPathComponent("TrafficLight.machine", isDirectory: true)
        try machine.write(to: expectedBundle, isSuspensible: true)

        try FSMEcoreTestSupport.assertPropertyListsEqual(
            outputDirectory.appendingPathComponent("Layout.plist"),
            expectedBundle.appendingPathComponent("Layout.plist")
        )
        try FSMEcoreTestSupport.assertPropertyListsEqual(
            outputDirectory.appendingPathComponent("WindowLayout.plist"),
            expectedBundle.appendingPathComponent("WindowLayout.plist")
        )
    }
}
