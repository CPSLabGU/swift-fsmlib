import XCTest
@testable import FSM
@testable import FSMEcore

final class XMIRoundTripTests: XCTestCase {
    func testMachineXmiRoundTripPreservesTrafficLightMachine() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLight.xmi")

        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL)
        let decoded = try await roundTrip.readMachine(from: xmiURL)

        XCTAssertEqual(decoded.name, "TrafficLight")
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.machine)
    }

    func testArrangementXmiRoundTripPreservesInstances() async throws {
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let arrangement = Arrangement(
            namedInstances: [
                Instance(name: "alpha", typeFile: "TrafficLight.machine", machine: machine),
                Instance(name: "beta", typeFile: "TrafficLight.machine", machine: Machine(copying: machine))
            ]
        )

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLights.xmi")

        try await roundTrip.write(arrangement: arrangement, to: xmiURL)
        let decoded = try await roundTrip.readArrangement(from: xmiURL)

        XCTAssertEqual(decoded.namedInstances.map(\.name), ["alpha", "beta"])
        XCTAssertEqual(decoded.namedInstances.map(\.typeFile), ["TrafficLight.machine", "TrafficLight.machine"])
        for (lhs, rhs) in zip(arrangement.namedInstances, decoded.namedInstances) {
            FSMEcoreTestSupport.assertMachinesEqual(lhs.machine, rhs.machine)
        }
    }
}
