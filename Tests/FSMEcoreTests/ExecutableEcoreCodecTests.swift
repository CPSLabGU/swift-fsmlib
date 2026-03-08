import XCTest
@testable import FSM
@testable import FSMEcore
import ECore

final class ExecutableEcoreCodecTests: XCTestCase {
    func testExecutableMachineRoundTripPreservesTypedSectionsAndSuspendState() async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let codec = ExecutableMachineCodec(metamodel: metamodel)
        let resource = Resource(uri: "memory:/TypedMachine.xmi")

        let initial = State(name: "Initial")
        let running = State(name: "Running")
        let suspended = State(name: "Suspended")
        let start = Transition(label: "ready && count < 5", source: initial.id, target: running.id)
        let pause = Transition(label: "true", source: running.id, target: suspended.id)

        let machine = Machine()
        machine.language = CBinding()
        machine.llfsm = LLFSM(
            states: [initial, running, suspended],
            transitions: [start, pause],
            suspendState: suspended.id
        )
        machine.setStateActivities(
            [
                .onEntry: """
                count = 1;
                ready = true;
                print("start");
                """,
                .internal: "count = count + 1;"
            ],
            for: initial.id
        )

        let arrangementObject = await codec.encode(
            machine,
            name: "TypedMachine",
            arrangementName: "TypedMachineArrangement",
            into: resource
        )
        let dynamicObjects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }

        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.assignmentIntegerClass.name })
        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.assignmentBooleanClass.name })
        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.outputLineClass.name })
        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.andExpressionClass.name })
        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.lessThanExpressionClass.name })

        let decoded = try await codec.decode(arrangementObject, from: resource)
        XCTAssertEqual(decoded.name, "TypedMachine")

        let decodedSuspendState = try XCTUnwrap(decoded.machine.llfsm.suspendState)
        XCTAssertEqual(decoded.machine.llfsm.stateName(for: decodedSuspendState), "Suspended")

        let decodedInitialState = try XCTUnwrap(
            decoded.machine.llfsm.states.first(where: { decoded.machine.llfsm.stateName(for: $0) == "Initial" })
        )
        let decodedActivities = decoded.machine.stateActivities(for: decodedInitialState)
        XCTAssertEqual(
            decodedActivities[.onEntry],
            """
            count = 1;
            ready = true;
            print("start");
            """
        )
        XCTAssertEqual(decodedActivities[.internal], "count = (count + 1);")

        let decodedStartTransitionID = try XCTUnwrap(
            decoded.machine.llfsm.transitions.first(where: {
                decoded.machine.llfsm.transition(for: $0)?.target == decoded.machine.llfsm.states[1]
            })
        )
        let decodedStartTransition = try XCTUnwrap(decoded.machine.llfsm.transition(for: decodedStartTransitionID))
        XCTAssertEqual(decodedStartTransition.label, "(ready && (count < 5))")
    }

    func testExecutableMachineEncodingFallsBackToOpaqueNodesForUnsupportedSource() async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let codec = ExecutableMachineCodec(metamodel: metamodel)
        let resource = Resource(uri: "memory:/OpaqueMachine.xmi")

        let idle = State(name: "Idle")
        let active = State(name: "Active")
        let transition = Transition(label: "ready()", source: idle.id, target: active.id)

        let machine = Machine()
        machine.language = CBinding()
        machine.llfsm = LLFSM(states: [idle, active], transitions: [transition], suspendState: nil)
        machine.setStateActivities([.onEntry: "callCustom();"], for: idle.id)

        let arrangementObject = await codec.encode(
            machine,
            name: "OpaqueMachine",
            arrangementName: "OpaqueMachineArrangement",
            into: resource
        )
        let dynamicObjects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }

        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.opaqueStatementClass.name })
        XCTAssertTrue(dynamicObjects.contains { $0.eClass.name == metamodel.opaqueExpressionClass.name })

        let decoded = try await codec.decode(arrangementObject, from: resource)
        let decodedIdleState = try XCTUnwrap(
            decoded.machine.llfsm.states.first(where: { decoded.machine.llfsm.stateName(for: $0) == "Idle" })
        )
        XCTAssertEqual(decoded.machine.stateActivities(for: decodedIdleState)[.onEntry], "callCustom();")

        let decodedTransitionID = try XCTUnwrap(decoded.machine.llfsm.transitions.first)
        let decodedTransition = try XCTUnwrap(decoded.machine.llfsm.transition(for: decodedTransitionID))
        XCTAssertEqual(decodedTransition.label, "ready()")
    }
}
