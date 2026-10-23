//
//  StructuralLayoutOverlayTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

@Suite("Structural layout overlay")
@MainActor
struct StructuralLayoutOverlayTests {
    /// The structural resource of the traffic light, read back from an XMI document.
    private func trafficLight() async throws -> (model: StructuralRoundTrip.Model, resource: Resource) {
        let example = ParityExample(url: try FSMEcoreTestSupport.trafficLightMachineURL())
        let model = try StructuralRoundTrip.model(of: example)
        return (model, try await StructuralRoundTrip.xmiResource(of: model))
    }

    /// The single machine of a structural resource.
    private func machine(of resource: Resource) async throws -> Machine {
        guard case .machine(_, let machine) = try await StructuralRoundTrip.decode(resource) else {
            Issue.record("The resource does not hold a single machine")
            throw CancellationError()
        }
        return machine
    }

    /// The position of a transition: the names of its source and target and its index among the
    /// transitions that leave its source.
    private struct Position: Hashable {
        /// The name of the source state.
        var source: String
        /// The index among the transitions that leave the source state.
        var index: Int
        /// The name of the target state.
        var target: String
    }

    /// The property lists of the layouts of a machine by state name and by transition position.
    private func layouts(of machine: Machine) -> (states: [String: NSDictionary], transitions: [Position: NSDictionary]) {
        var states: [String: NSDictionary] = [:]
        var transitions: [Position: NSDictionary] = [:]
        for state in machine.llfsm.states {
            let name = machine.llfsm.stateName(for: state) ?? ""
            states[name] = machine.stateLayout[state]?.propertyList
            for (index, transitionID) in machine.llfsm.transitionsFrom(state).enumerated() {
                let target = machine.llfsm.transition(for: transitionID).flatMap { machine.llfsm.stateName(for: $0.target) }
                let position = Position(source: name, index: index, target: target ?? "")
                transitions[position] = machine.transitionLayout[transitionID]?.propertyList
            }
        }
        return (states, transitions)
    }

    /// Set a string attribute of the first object of a class whose attribute has a value.
    private func rename(_ className: String, from old: String, to new: String, in resource: Resource) async {
        for case let object as DynamicEObject in await resource.getAllObjectsIncludingContents()
        where object.eClass.name == className {
            guard await resource.eGet(objectId: object.id, feature: "name") as? String == old else { continue }
            _ = await resource.eSet(objectId: object.id, feature: "name", value: new)
            return
        }
    }

    @Test("the layouts of the original are laid over the rebuilt machine")
    func restores() async throws {
        let (model, source) = try await trafficLight()
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(source)
        let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
        #expect(try await machine(of: rebuilt.resource).stateLayout.isEmpty)
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        guard case .machine(_, let original) = model else { return }
        let restored = try await machine(of: rebuilt.resource)
        let expected = layouts(of: original)
        let actual = layouts(of: restored)
        #expect(!expected.states.isEmpty && !expected.transitions.isEmpty)
        #expect(actual.states == expected.states)
        #expect(actual.transitions == expected.transitions)
        #expect(restored.windowLayout == original.windowLayout)
    }

    @Test("restoring the layouts again replaces them")
    func replaces() async throws {
        let (_, source) = try await trafficLight()
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(source)
        let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        let count = await rebuilt.resource.count()
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        #expect(await rebuilt.resource.count() == count)
    }

    @Test("renamed states and the transitions to and from them keep no layout")
    func unmatched() async throws {
        let (model, source) = try await trafficLight()
        guard case .machine(_, let original) = model else { return }
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(source)
        await rename("State", from: "Yellow", to: "Amber", in: sectioned.resource)
        let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        let expected = layouts(of: original)
        let actual = layouts(of: try await machine(of: rebuilt.resource))
        #expect(actual.states["Amber"] == nil)
        #expect(actual.states.count == expected.states.count - 1)
        #expect(actual.states.allSatisfy { expected.states[$0.key] == $0.value })
        #expect(!actual.transitions.keys.contains { $0.source == "Amber" || $0.target == "Amber" })
        #expect(actual.transitions.allSatisfy { expected.transitions[$0.key] == $0.value })
        #expect(actual.transitions.count
            == expected.transitions.keys.filter { $0.source != "Yellow" && $0.target != "Yellow" }.count)
    }

    @Test("a retargeted transition keeps no layout")
    func retargeted() async throws {
        let (model, source) = try await trafficLight()
        guard case .machine(_, let original) = model else { return }
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(source)
        let index = await KernelModelIndex(resource: sectioned.resource)
        let green = try #require(await TransformationTestSupport.objects(named: "State", in: sectioned.resource)
            .first { $0.string(.name) == "Green" })
        let transition = try #require(index.objects(.transitions, of: green).first)
        let oldTarget = try #require(index.target(.target, of: transition)?.string(.name))
        _ = await sectioned.resource.eSet(objectId: transition.id, feature: LLFSMFeature.target.rawValue, value: green.id)
        let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        let expected = layouts(of: original)
        let actual = layouts(of: try await machine(of: rebuilt.resource))
        #expect(expected.transitions[Position(source: "Green", index: 0, target: oldTarget)] != nil)
        #expect(actual.transitions[Position(source: "Green", index: 0, target: "Green")] == nil)
        #expect(actual.transitions.count == expected.transitions.count - 1)
        #expect(actual.states == expected.states)
    }

    @Test("the machines of instances are matched by instance name")
    func arrangement() async throws {
        let example = ParityExample(url: TemplateParity.examplesDirectory.appendingPathComponent("Counter2.arrangement"))
        let model = try StructuralRoundTrip.model(of: example)
        guard case .arrangement(let original) = model else { return }
        let source = try await StructuralRoundTrip.xmiResource(of: model)
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(source, arrangementName: example.name)
        let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
        await transformations.restoreLayouts(into: rebuilt.resource, from: source)
        guard case .arrangement(let restored) = try await StructuralRoundTrip.decode(rebuilt.resource) else {
            Issue.record("The arrangement did not come back as an arrangement")
            return
        }
        #expect(restored.namedInstances.map(\.name) == original.namedInstances.map(\.name))
        for (back, instance) in zip(restored.namedInstances, original.namedInstances) {
            #expect(layouts(of: back.machine).states == layouts(of: instance.machine).states, "\(instance.name)")
            #expect(layouts(of: back.machine).transitions == layouts(of: instance.machine).transitions,
                    "\(instance.name)")
            #expect(back.machine.windowLayout == instance.machine.windowLayout, "\(instance.name)")
        }
    }
}
