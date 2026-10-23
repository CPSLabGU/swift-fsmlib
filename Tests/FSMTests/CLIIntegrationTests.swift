import Foundation
import XCTest
@testable import FSM
@testable import FSMEcore

/// End-to-end tests for the `fsmconvert` executable.
///
/// These tests build the command-line tool once in a scratch build directory
/// and then invoke it through `Process` so the metamodel-backed conversion
/// paths are exercised exactly as users run them.
///
/// The scratch build directory is ``defaultBuildPath`` unless the environment
/// variable named by ``buildPathVariable`` names another one, for example the
/// scratch path of the test run itself, so that the tool is built against the
/// same dependency checkouts as the tests.
final class CLIIntegrationTests: XCTestCase {
    /// The scratch build directory used when the environment names none.
    static let defaultBuildPath = "/tmp/build-swift-fsmlib-cli-tests"

    /// The environment variable that overrides the scratch build directory.
    static let buildPathVariable = "FSMCONVERT_BUILD_PATH"

    /// The scratch build directory named by the environment, if any.
    static var overriddenBuildPath: String? {
        let path = ProcessInfo.processInfo.environment[buildPathVariable] ?? ""
        return path.isEmpty ? nil : path
    }

    /// The scratch build directory in which the command-line tool is built.
    static var buildPath: String { overriddenBuildPath ?? defaultBuildPath }

    private let tempDirectoryURL: URL = {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSMCLIIntegrationTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    override class func setUp() {
        super.setUp()

        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "swift", "build",
            "--product", "fsmconvert",
            "--build-path", buildPath,
        ]
        if overriddenBuildPath != nil {
            // The running test command holds the lock of its own scratch path while the
            // tests execute, so a build into that path has to proceed without it.
            process.arguments?.append("--ignore-lock")
        }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try? process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            XCTFail("Failed to build fsmconvert:\n\(output)\n\(error)")
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    func testMetamodelMachineRoundTripViaXMI() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let xmiURL = tempDirectoryURL.appendingPathComponent("TrafficLight.xmi")
        let roundTripURL = tempDirectoryURL.appendingPathComponent("TrafficLightRoundTrip.machine")

        try runCLI(arguments: [
            sourceMachineURL.path,
            "--metamodel", "structural",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])
        try runCLI(arguments: [
            xmiURL.path,
            "--metamodel", "structural",
            "--output", roundTripURL.path,
        ])

        let original = try Machine(from: sourceMachineURL)
        let roundTripped = try Machine(from: roundTripURL)
        assertMachinesEquivalent(original, roundTripped, includeSuspendState: false)
    }

    func testMetamodelCrossFormatViaSCXML() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let xmiURL = tempDirectoryURL.appendingPathComponent("TrafficLight.xmi")
        let scxmlURL = tempDirectoryURL.appendingPathComponent("TrafficLight.scxml")
        let roundTripURL = tempDirectoryURL.appendingPathComponent("TrafficLightFromSCXML.machine")

        try runCLI(arguments: [
            sourceMachineURL.path,
            "--metamodel", "structural",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])
        try runCLI(arguments: [
            xmiURL.path,
            "--metamodel", "structural",
            "--format", "scxml",
            "--output", scxmlURL.path,
        ])
        try runCLI(arguments: [
            scxmlURL.path,
            "--output", roundTripURL.path,
        ])

        let original = try Machine(from: sourceMachineURL)
        let roundTripped = try Machine(from: roundTripURL)
        assertMachinesEquivalent(original, roundTripped, includeSuspendState: false)
    }

    func testStructuralSCXMLRoundTripViaXMI() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let sourceSCXMLURL = tempDirectoryURL.appendingPathComponent("TrafficLightSource.scxml")
        let xmiURL = tempDirectoryURL.appendingPathComponent("TrafficLightFromSCXML.xmi")
        let roundTripSCXMLURL = tempDirectoryURL.appendingPathComponent("TrafficLightRoundTrip.scxml")

        let machine = try Machine(from: sourceMachineURL)
        let sourceStorage = MachineStorageFactory.create(for: machine, format: .scxml, at: sourceSCXMLURL)
        try sourceStorage.write(to: sourceSCXMLURL)

        try runCLI(arguments: [
            sourceSCXMLURL.path,
            "--metamodel", "structural",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])
        try runCLI(arguments: [
            xmiURL.path,
            "--metamodel", "structural",
            "--format", "scxml",
            "--output", roundTripSCXMLURL.path,
        ])

        let original = try MachineStorageFactory.read(from: sourceSCXMLURL).machine
        let roundTripped = try MachineStorageFactory.read(from: roundTripSCXMLURL).machine
        assertMachinesEquivalent(original, roundTripped, includeSuspendState: false)
    }

    func testMetamodelArrangementRoundTripViaXMI() async throws {
        let firstMachineURL = try copyTrafficLightMachine(named: "TrafficLightOne.machine")
        let secondMachineURL = try copyTrafficLightMachine(named: "TrafficLightTwo.machine")
        let arrangementXMIURL = tempDirectoryURL.appendingPathComponent("TrafficLights.xmi")

        try runCLI(arguments: [
            firstMachineURL.path,
            secondMachineURL.path,
            "--arrangement",
            "--metamodel", "structural",
            "--format", "xmi",
            "--output", arrangementXMIURL.path,
        ])

        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let arrangement = try await roundTrip.readArrangement(from: arrangementXMIURL)
        XCTAssertEqual(arrangement.namedInstances.count, 2)
        XCTAssertEqual(
            Set(arrangement.namedInstances.map(\.name)),
            ["TrafficLightOne", "TrafficLightTwo"]
        )
    }

    func testMetamodelArrangementRoundTripBackToDirectory() throws {
        let firstMachineURL = try copyTrafficLightMachine(named: "TrafficLightOne.machine")
        let secondMachineURL = try copyTrafficLightMachine(named: "TrafficLightTwo.machine")
        let arrangementXMIURL = tempDirectoryURL.appendingPathComponent("TrafficLights.xmi")
        let roundTripDirectoryURL = tempDirectoryURL.appendingPathComponent("TrafficLights.arrangement", isDirectory: true)

        try runCLI(arguments: [
            firstMachineURL.path,
            secondMachineURL.path,
            "--arrangement",
            "--metamodel", "structural",
            "--format", "xmi",
            "--output", arrangementXMIURL.path,
        ])
        try runCLI(arguments: [
            arrangementXMIURL.path,
            "--metamodel", "structural",
            "--output", roundTripDirectoryURL.path,
        ])

        let arrangement = try Arrangement(from: roundTripDirectoryURL)
        XCTAssertEqual(arrangement.namedInstances.count, 2)
        XCTAssertEqual(
            Set(arrangement.namedInstances.map(\.name)),
            ["TrafficLightOne.machine", "TrafficLightTwo.machine"]
        )
    }

    func testStructuralTemplateGenerationViaCLIProducesSCXML() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let renderedURL = tempDirectoryURL.appendingPathComponent("TrafficLight.scxml")
        let expectedURL = tempDirectoryURL.appendingPathComponent("ExpectedTrafficLight.scxml")

        try runCLI(arguments: [
            sourceMachineURL.path,
            "--metamodel", "structural",
            "--transform", "structural2scxml",
            "--output", renderedURL.path,
        ])

        let machine = try Machine(from: sourceMachineURL)
        let storage = MachineStorageFactory.create(for: machine, format: .scxml, at: expectedURL)
        try storage.write(to: expectedURL)

        let renderedMachine = try MachineStorageFactory.read(from: renderedURL).machine
        let expectedMachine = try MachineStorageFactory.read(from: expectedURL).machine
        assertMachinesEquivalent(renderedMachine, expectedMachine, includeSuspendState: false)
    }

    func testDeprecatedExecutableLevelReportsUnavailableSectionedLevel() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let xmiURL = tempDirectoryURL.appendingPathComponent("TrafficLight.xmi")

        let result = try runCLIExpectingFailure(arguments: [
            sourceMachineURL.path,
            "--metamodel", "executable",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.standardError.contains("deprecated"), result.standardError)
        XCTAssertTrue(result.standardError.contains("sectioned"), result.standardError)
        XCTAssertTrue(result.standardError.contains("not yet available"), result.standardError)
        XCTAssertFalse(FileManager.default.fileExists(atPath: xmiURL.path))
    }

    func testSectionedLevelIsNotYetAvailable() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let xmiURL = tempDirectoryURL.appendingPathComponent("TrafficLight.xmi")

        let result = try runCLIExpectingFailure(arguments: [
            sourceMachineURL.path,
            "--metamodel", "sectioned",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertFalse(result.standardError.contains("deprecated"), result.standardError)
        XCTAssertTrue(result.standardError.contains("not yet available"), result.standardError)
        XCTAssertFalse(FileManager.default.fileExists(atPath: xmiURL.path))
    }

    func testTransformRequiresStructuralMetamodel() throws {
        let sourceMachineURL = try copyTrafficLightMachine(named: "TrafficLight.machine")
        let renderedURL = tempDirectoryURL.appendingPathComponent("TrafficLight.scxml")

        let result = try runCLIExpectingFailure(arguments: [
            sourceMachineURL.path,
            "--transform", "structural2scxml",
            "--output", renderedURL.path,
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.standardError.contains("--metamodel structural"), result.standardError)
        XCTAssertFalse(FileManager.default.fileExists(atPath: renderedURL.path))
    }

    private func runCLI(arguments: [String]) throws {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        process.executableURL = URL(fileURLWithPath: CLIExecutable.binaryPath)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            XCTFail("fsmconvert failed with status \(process.terminationStatus):\n\(output)\n\(error)")
        }
    }

    private func runCLIExpectingFailure(arguments: [String]) throws -> (status: Int32, standardError: String) {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        process.executableURL = URL(fileURLWithPath: CLIExecutable.binaryPath)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        _ = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return (process.terminationStatus, String(data: errorData, encoding: .utf8) ?? "")
    }

    private func copyTrafficLightMachine(named name: String) throws -> URL {
        guard let resourceURL = Bundle.module.url(
            forResource: "TrafficLight",
            withExtension: "machine",
            subdirectory: "Resources"
        ) else {
            XCTFail("Missing TrafficLight.machine resource")
            throw NSError(domain: "CLIIntegrationTests", code: 1)
        }

        let destinationURL = tempDirectoryURL.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.copyItem(at: resourceURL, to: destinationURL)
        return destinationURL
    }

    private func assertMachinesEquivalent(
        _ lhs: Machine,
        _ rhs: Machine,
        includeSuspendState: Bool = true
    ) {
        XCTAssertEqual(lhs.llfsm.stateNames, rhs.llfsm.stateNames)

        if includeSuspendState {
            let lhsSuspendState = lhs.llfsm.suspendState.flatMap { lhs.llfsm.stateName(for: $0) }
            let rhsSuspendState = rhs.llfsm.suspendState.flatMap { rhs.llfsm.stateName(for: $0) }
            XCTAssertEqual(lhsSuspendState, rhsSuspendState)
        }

        let lhsTransitions = lhs.llfsm.transitions.compactMap { id -> String? in
            guard let transition = lhs.llfsm.transition(for: id) else { return nil }
            let source = lhs.llfsm.stateName(for: transition.source) ?? ""
            let target = lhs.llfsm.stateName(for: transition.target) ?? ""
            return "\(source)|\(transition.label)|\(target)"
        }
        let rhsTransitions = rhs.llfsm.transitions.compactMap { id -> String? in
            guard let transition = rhs.llfsm.transition(for: id) else { return nil }
            let source = rhs.llfsm.stateName(for: transition.source) ?? ""
            let target = rhs.llfsm.stateName(for: transition.target) ?? ""
            return "\(source)|\(transition.label)|\(target)"
        }
        XCTAssertEqual(lhsTransitions, rhsTransitions)
    }
}

private enum CLIExecutable {
    static var binaryPath: String {
        CLIIntegrationTests.buildPath + "/debug/fsmconvert"
    }
}
