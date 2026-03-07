import XCTest
@testable import FSM
@testable import FSMEcore
import ECore

final class MachineEcoreCodecTests: XCTestCase {
    func testMachineRoundTripPreservesTransitionsAndStateLayouts() async throws {
        let metamodel = try await LLFSMMetamodel()
        let codec = MachineEcoreCodec(metamodel: metamodel)
        let resource = Resource(uri: "memory:/TrafficLight.xmi")

        let initialState = State(name: "Initial")
        let readyState = State(name: "Ready")
        let transition = Transition(label: "ready()", source: initialState.id, target: readyState.id)

        let layout = StateLayout(
            isOpen: true,
            openLayout: Rectangle(centre: Coordinate2D(180, 90), dimensions: Dimensions2D(220, 140)),
            closedLayout: Ellipse(centre: Coordinate2D(60, 40), dimensions: Dimensions2D(120, 80)),
            onEntryHeight: 11,
            onExitHeight: 12,
            onSuspendHeight: 13,
            onResumeHeight: 14,
            internalHeight: 15,
            zoomedOnEntryHeight: 21,
            zoomedOnExitHeight: 22,
            zoomedInternalHeight: 23,
            zoomedOnSuspendHeight: 24,
            zoomedOnResumeHeight: 25,
            extraProperties: ["bgColour": "green"]
        )

        let machine = Machine()
        machine.llfsm = LLFSM(states: [initialState, readyState], transitions: [transition])
        machine.stateLayout = [initialState.id: layout]
        machine.transitionLayout = [transition.id: TransitionLayout([Point2D(1, 2), Point2D(3, 4)])]
        machine.boilerplate = CBoilerplate()
        machine.setStateActivities(
            [
                .onEntry: "enter();",
                .internal: "step();"
            ],
            for: initialState.id
        )

        let machineObject = await codec.encode(machine, name: "TrafficLight", into: resource)
        let decoded = try await codec.decode(machineObject, from: resource)

        XCTAssertEqual(decoded.name, "TrafficLight")
        XCTAssertEqual(decoded.machine.llfsm.states.count, 2)
        XCTAssertEqual(decoded.machine.llfsm.transitions.count, 1)

        let decodedTransitionID = try XCTUnwrap(decoded.machine.llfsm.transitions.first)
        let decodedTransition = try XCTUnwrap(decoded.machine.llfsm.transition(for: decodedTransitionID))
        XCTAssertEqual(decodedTransition.label, "ready()")

        let decodedSourceName = decoded.machine.llfsm.stateName(for: decodedTransition.source)
        let decodedTargetName = decoded.machine.llfsm.stateName(for: decodedTransition.target)
        XCTAssertEqual(decodedSourceName, "Initial")
        XCTAssertEqual(decodedTargetName, "Ready")

        let decodedInitialID = try XCTUnwrap(
            decoded.machine.llfsm.states.first(where: { decoded.machine.llfsm.stateName(for: $0) == "Initial" })
        )
        let decodedLayout = try XCTUnwrap(decoded.machine.stateLayout[decodedInitialID])
        XCTAssertTrue(decodedLayout.isOpen)
        XCTAssertEqual(decodedLayout.openLayout.w, 220, accuracy: 0.001)
        XCTAssertEqual(decodedLayout.closedLayout.h, 80, accuracy: 0.001)
        XCTAssertEqual(decodedLayout.extraProperties["bgColour"] as? String, "green")

        let decodedActivities = decoded.machine.stateActivities(for: decodedInitialID)
        XCTAssertEqual(decodedActivities[.onEntry], "enter();")
        XCTAssertEqual(decodedActivities[.internal], "step();")
    }
}
