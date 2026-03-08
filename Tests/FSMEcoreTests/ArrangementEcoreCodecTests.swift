import XCTest
@testable import FSM
@testable import FSMEcore
import ECore

final class ArrangementEcoreCodecTests: XCTestCase {
    func testArrangementRoundTripPreservesInstances() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()

        let arrangement = Arrangement(
            namedInstances: [
                Instance(name: "northSouth", typeFile: "TrafficLight.machine", machine: machine),
                Instance(name: "eastWest", typeFile: "TrafficLight.machine", machine: Machine(copying: machine))
            ]
        )

        let metamodel = try await LLFSMMetamodel()
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        let resource = Resource(uri: "memory:/TrafficLights.xmi")

        let arrangementObject = await codec.encode(arrangement, into: resource)
        let decoded = try await codec.decode(arrangementObject, from: resource)

        XCTAssertEqual(decoded.namedInstances.count, 2)
        XCTAssertEqual(decoded.namedInstances.map(\.name), ["northSouth", "eastWest"])
        XCTAssertEqual(decoded.namedInstances.map(\.typeFile), ["TrafficLight.machine", "TrafficLight.machine"])

        for (lhs, rhs) in zip(arrangement.namedInstances, decoded.namedInstances) {
            FSMEcoreTestSupport.assertMachinesEqual(lhs.machine, rhs.machine)
        }
    }
}
