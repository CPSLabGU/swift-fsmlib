//
//  StructuralLayoutOverlay.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

extension LLFSMTransformations {
    /// Copy the layouts of an original structural model into a model rebuilt from it.
    ///
    /// The sectioned and kernel levels keep no layouts, so a structural
    /// model that ``sectionedToStructural(_:uri:)`` rebuilds has none. A
    /// caller that still has the structural model the sectioned model was
    /// made from can lay the rebuilt model out as the original was: the
    /// overlay copies the state layouts, the transition layouts and the
    /// window layout of every original machine into the rebuilt machine
    /// that corresponds to it.
    ///
    /// A single machine corresponds to the single machine of the rebuilt
    /// model; the machine of an instance corresponds to the machine of the
    /// rebuilt instance of the same name. Within corresponding machines,
    /// states correspond by name, and a transition corresponds to the
    /// transition with the same position among the transitions that leave
    /// the corresponding state, provided that it leads to the state of the
    /// same name. The layouts of a rebuilt machine are replaced by the copies.
    ///
    /// The overlay copies layouts only: a state that was renamed, a
    /// transition that was moved or retargeted and a machine or instance
    /// without a counterpart keep no layout.
    ///
    /// ```swift
    /// let sectioned = try await transformations.structuralToSectioned(original)
    /// let rebuilt = try await transformations.sectionedToStructural(sectioned.resource)
    /// await transformations.restoreLayouts(into: rebuilt.resource, from: original)
    /// ```
    ///
    /// - Parameters:
    ///   - structural: The resource that holds the rebuilt structural machine or arrangement.
    ///   - original: The resource that holds the original structural machine or arrangement.
    public func restoreLayouts(into structural: Resource, from original: Resource) async {
        let overlay = StructuralLayoutOverlay(metamodel: self.structural, source: original, target: structural)
        await overlay.run()
    }
}

/// Copies the layouts of the machines of one structural model into the
/// corresponding machines of another.
struct StructuralLayoutOverlay {
    /// The structural metamodel that types the copies.
    let metamodel: LLFSMMetamodel

    /// The resource that holds the original model.
    let source: Resource

    /// The resource that holds the rebuilt model.
    let target: Resource

    /// The names of the structural features that the overlay reads and writes.
    enum Feature: String {
        case name, instances, machine, llfsm, states, transitions, source, target
        case stateLayouts, transitionLayouts, windowLayout, state, transition, layout
    }

    /// Copy the layouts of every original machine into its counterpart.
    func run() async {
        let sourceMachines = await machines(in: source)
        let targetMachines = await machines(in: target)
        for (key, targetMachine) in targetMachines {
            guard let sourceMachine = sourceMachines.first(where: { $0.key == key })?.machine else { continue }
            await copyLayouts(of: sourceMachine, into: targetMachine)
        }
    }

    /// The machines of a structural model with the keys that pair them.
    ///
    /// The key of a single machine is empty; the key of the machine of an
    /// instance is the name of the instance.
    private func machines(in resource: Resource) async -> [(key: String, machine: EUUID)] {
        var machines: [(key: String, machine: EUUID)] = []
        for case let root as DynamicEObject in await resource.getRootObjects() {
            if StructuralDeclarations.matches(root.eClass, metamodel.machineClass) {
                machines.append(("", root.id))
            } else if StructuralDeclarations.matches(root.eClass, metamodel.arrangementClass) {
                for instance in await references(.instances, of: root.id, in: resource) {
                    guard let machine = await references(.machine, of: instance, in: resource).first else { continue }
                    machines.append((await string(.name, of: instance, in: resource) ?? "", machine))
                }
            }
        }
        return machines
    }

    /// Replace the layouts of a rebuilt machine by copies of those of the original machine.
    private func copyLayouts(of sourceMachine: EUUID, into targetMachine: EUUID) async {
        let sourceStates = await states(of: sourceMachine, in: source)
        let targetStates = await states(of: targetMachine, in: target)
        let stateMap = sourceStates.reduce(into: [EUUID: EUUID]()) { map, entry in
            if let match = targetStates.first(where: { $0.name == entry.name }) { map[entry.id] = match.id }
        }
        let transitionMap = await transitionMap(
            from: sourceMachine, to: targetMachine, sourceStates: sourceStates, targetStates: targetStates)
        for feature in [Feature.stateLayouts, .transitionLayouts] {
            for entry in await references(feature, of: targetMachine, in: target) {
                await removeTree(entry)
            }
        }
        var stateEntries: [EUUID] = []
        for entry in await references(.stateLayouts, of: sourceMachine, in: source) {
            guard let state = await references(.state, of: entry, in: source).first.flatMap({ stateMap[$0] }),
                  let copy = await copyEntry(entry, element: .state, to: state) else { continue }
            stateEntries.append(copy)
        }
        var transitionEntries: [EUUID] = []
        for entry in await references(.transitionLayouts, of: sourceMachine, in: source) {
            guard let transition = await references(.transition, of: entry, in: source).first
                    .flatMap({ transitionMap[$0] }),
                  let copy = await copyEntry(entry, element: .transition, to: transition) else { continue }
            transitionEntries.append(copy)
        }
        _ = await target.eSet(objectId: targetMachine, feature: Feature.stateLayouts.rawValue,
                              value: stateEntries.isEmpty ? nil : stateEntries)
        _ = await target.eSet(objectId: targetMachine, feature: Feature.transitionLayouts.rawValue,
                              value: transitionEntries.isEmpty ? nil : transitionEntries)
        let window = await source.eGet(objectId: sourceMachine, feature: Feature.windowLayout.rawValue)
        _ = await target.eSet(objectId: targetMachine, feature: Feature.windowLayout.rawValue, value: window)
    }

    /// The states of a machine with their names, in order.
    private func states(of machine: EUUID, in resource: Resource) async -> [(id: EUUID, name: String)] {
        guard let llfsm = await references(.llfsm, of: machine, in: resource).first else { return [] }
        var states: [(id: EUUID, name: String)] = []
        for state in await references(.states, of: llfsm, in: resource) {
            states.append((state, await string(.name, of: state, in: resource) ?? ""))
        }
        return states
    }

    /// The rebuilt transition that corresponds to each original transition.
    private func transitionMap(
        from sourceMachine: EUUID,
        to targetMachine: EUUID,
        sourceStates: [(id: EUUID, name: String)],
        targetStates: [(id: EUUID, name: String)]
    ) async -> [EUUID: EUUID] {
        let sourceTransitions = await transitions(of: sourceMachine, in: source, states: sourceStates)
        let targetTransitions = await transitions(of: targetMachine, in: target, states: targetStates)
        var map: [EUUID: EUUID] = [:]
        for (key, transition) in sourceTransitions {
            guard let match = targetTransitions.first(where: { $0.key == key }) else { continue }
            map[transition] = match.transition
        }
        return map
    }

    /// The position of a transition: the names of its source and target and its index among the transitions
    /// that leave its source.
    private struct TransitionKey: Equatable {
        /// The name of the source state.
        var source: String
        /// The index of the transition among the transitions that leave the source state.
        var index: Int
        /// The name of the target state.
        var target: String
    }

    /// The transitions of a machine with their positions.
    private func transitions(
        of machine: EUUID,
        in resource: Resource,
        states: [(id: EUUID, name: String)]
    ) async -> [(key: TransitionKey, transition: EUUID)] {
        guard let llfsm = await references(.llfsm, of: machine, in: resource).first else { return [] }
        var counts: [String: Int] = [:]
        var transitions: [(key: TransitionKey, transition: EUUID)] = []
        for transition in await references(.transitions, of: llfsm, in: resource) {
            let sourceID = await references(.source, of: transition, in: resource).first
            let targetID = await references(.target, of: transition, in: resource).first
            guard let sourceName = states.first(where: { $0.id == sourceID })?.name,
                  let targetName = states.first(where: { $0.id == targetID })?.name else { continue }
            let index = counts[sourceName, default: 0]
            counts[sourceName] = index + 1
            transitions.append((TransitionKey(source: sourceName, index: index, target: targetName), transition))
        }
        return transitions
    }

    /// Copy a layout entry, pointing the copy at an element of the rebuilt model.
    private func copyEntry(_ entry: EUUID, element feature: Feature, to element: EUUID) async -> EUUID? {
        guard let object = await object(entry, in: source),
              let layout = await contained(await source.eGet(objectId: entry, feature: Feature.layout.rawValue)).first
        else { return nil }
        var copy = DynamicEObject(eClass: counterpart(of: object.eClass))
        copy.eSet(feature.rawValue, value: element)
        copy.eSet(Feature.layout.rawValue, value: await copyTree(layout))
        await target.register(copy)
        return copy.id
    }

    /// Copy an original object and everything it contains into the rebuilt model.
    private func copyTree(_ object: DynamicEObject) async -> EUUID {
        var copy = DynamicEObject(eClass: counterpart(of: object.eClass))
        for feature in object.eClass.eAllStructuralFeatures {
            guard let value = object.eGet(feature.name) else { continue }
            guard let reference = feature as? EReference, reference.containment else {
                copy.eSet(feature.name, value: value)
                continue
            }
            var children: [EUUID] = []
            for child in await contained(value) { children.append(await copyTree(child)) }
            copy.eSet(feature.name, value: reference.isMany ? children : children.first)
        }
        await target.register(copy)
        return copy.id
    }

    /// The original objects that a containment value holds, whether they are referenced or nested.
    private func contained(_ value: (any EcoreValue)?) async -> [DynamicEObject] {
        guard let value else { return [] }
        var objects: [DynamicEObject] = []
        for element in (value as? [Any]) ?? [value] {
            if let nested = element as? DynamicEObject {
                objects.append(await object(nested.id, in: source) ?? nested)
            } else if let identifier = element as? EUUID, let referenced = await object(identifier, in: source) {
                objects.append(referenced)
            }
        }
        return objects
    }

    /// Remove a rebuilt object and everything it contains.
    private func removeTree(_ identifier: EUUID) async {
        guard let object = await object(identifier, in: target) else { return }
        for case let reference as EReference in object.eClass.eAllStructuralFeatures where reference.containment {
            for child in ModelReferences.identifiers(from: await target.eGet(objectId: identifier, feature: reference.name)) {
                await removeTree(child)
            }
        }
        _ = await target.remove(id: identifier)
    }

    /// The class of the rebuilt model's metamodel that has the name of a class.
    private func counterpart(of eClass: EClass) -> EClass {
        metamodel.package.getEClass(eClass.name) ?? eClass
    }

    /// The object with an identifier.
    private func object(_ identifier: EUUID, in resource: Resource) async -> DynamicEObject? {
        await resource.resolve(identifier) as? DynamicEObject
    }

    /// The identifiers that a reference of an object holds.
    private func references(_ feature: Feature, of identifier: EUUID, in resource: Resource) async -> [EUUID] {
        ModelReferences.identifiers(from: await resource.eGet(objectId: identifier, feature: feature.rawValue))
    }

    /// The string value of an attribute of an object.
    private func string(_ feature: Feature, of identifier: EUUID, in resource: Resource) async -> String? {
        await resource.eGet(objectId: identifier, feature: feature.rawValue) as? String
    }
}
