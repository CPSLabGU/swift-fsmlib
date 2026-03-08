import XCTest
@testable import FSM
@testable import FSMEcore

final class ExecutableXMIRoundTripTests: XCTestCase {
    func testExecutableMachineXmiRoundTripPreservesTrafficLightMachine() async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let roundTrip = ExecutableXMIRoundTrip(metamodel: metamodel)
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let tempDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "executable-xmi-machine")
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLight.xmi")

        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL)
        let decoded = try await roundTrip.readMachine(from: xmiURL)

        XCTAssertEqual(decoded.name, "TrafficLight")
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.machine)
    }

    func testExecutableArrangementXmiRoundTripPreservesInstances() async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let roundTrip = ExecutableXMIRoundTrip(metamodel: metamodel)
        let trafficLight = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let arrangement = Arrangement(
            namedInstances: [
                Instance(name: "NorthSouth", typeFile: "NorthSouth.machine", machine: trafficLight),
                Instance(name: "EastWest", typeFile: "EastWest.machine", machine: Machine(copying: trafficLight))
            ]
        )
        let tempDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "executable-xmi-arrangement")
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLights.xmi")

        try await roundTrip.write(arrangement: arrangement, name: "TrafficLights", to: xmiURL)
        let decoded = try await roundTrip.readArrangement(from: xmiURL)

        XCTAssertEqual(decoded.namedInstances.map(\.name), ["NorthSouth", "EastWest"])
        XCTAssertEqual(decoded.namedInstances.map(\.typeFile), ["NorthSouth.machine", "EastWest.machine"])
        XCTAssertEqual(decoded.namedInstances.count, arrangement.namedInstances.count)

        for (source, roundTripped) in zip(arrangement.namedInstances, decoded.namedInstances) {
            FSMEcoreTestSupport.assertMachinesEqual(source.machine, roundTripped.machine)
        }
    }
}
