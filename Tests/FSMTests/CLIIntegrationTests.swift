import Foundation
import XCTest
@testable import FSM
@testable import FSMEcore

/// End-to-end tests for the `fsmconvert` executable.
///
/// These tests build the command-line tool once in a scratch build directory
/// and then invoke it through `Process` so the metamodel-backed conversion
/// paths are exercised exactly as users run them.
final class CLIIntegrationTests: XCTestCase {
    static let buildPath = "/tmp/build-swift-fsmlib-cli-tests"

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
            "--metamodel",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])
        try runCLI(arguments: [
            xmiURL.path,
            "--metamodel",
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
            "--metamodel",
            "--format", "xmi",
            "--output", xmiURL.path,
        ])
        try runCLI(arguments: [
            xmiURL.path,
            "--metamodel",
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

    func testMetamodelArrangementRoundTripViaXMI() async throws {
        let firstMachineURL = try copyTrafficLightMachine(named: "TrafficLightOne.machine")
        let secondMachineURL = try copyTrafficLightMachine(named: "TrafficLightTwo.machine")
        let arrangementXMIURL = tempDirectoryURL.appendingPathComponent("TrafficLights.xmi")

        try runCLI(arguments: [
            firstMachineURL.path,
            secondMachineURL.path,
            "--arrangement",
            "--metamodel",
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
