//
//  MachineEcoreCodec.swift
//  FSMEcore
//
//  Created by Rene Hexel on 8/3/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import FSM
import Foundation

/// Machine codec for the structural metamodel.
///
/// `MachineEcoreCodec` converts between `Machine` values from `swift-fsmlib`
/// and dynamic object graphs backed by `swift-ecore`. It preserves LLFSM
/// structure, boilerplate sections, state activities, visual layout data, and
/// optional window layout bytes so machines can move between native Swift
/// storage and XMI-based workflows.
public struct MachineEcoreCodec {
    /// Metamodel used to resolve machine classifiers.
    ///
    /// This value provides the classifier definitions needed to construct and
    /// decode machine-related dynamic objects.
    public let metamodel: LLFSMMetamodel

    /// Create the machine codec.
    ///
    /// This initialiser stores the supplied metamodel for later encode and
    /// decode operations.
    ///
    /// - Parameter metamodel: Loaded structural metamodel to use for conversion.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
    }

    // MARK: - Encode

    /// Encode a machine into a resource-backed object graph.
    ///
    /// This method creates the dynamic objects required by the structural
    /// metamodel, registers contained objects with the resource, and optionally
    /// adds the resulting machine object as a root. Callers can disable root
    /// insertion when the machine will be contained inside another encoded
    /// object such as an arrangement instance.
    ///
    /// - Parameters:
    ///   - machine: Machine value to encode.
    ///   - name: Machine name to store in the structural model.
    ///   - resource: Resource that will own the encoded objects.
    ///   - addAsRoot: Whether to add the resulting machine object as a resource root.
    /// - Returns: Root dynamic object representing the machine.
    public func encode(
        _ machine: Machine,
        name: String,
        into resource: Resource,
        addAsRoot: Bool = true
    ) async -> DynamicEObject {
        let stateObjects = await encodeStates(of: machine, into: resource)
        let transitionObjects = await encodeTransitions(of: machine, stateObjects: stateObjects, into: resource)

        // Build LLFSM object
        var llfsmObj = DynamicEObject(eClass: metamodel.llfsmClass)
        let stateIDs: [EUUID] = machine.llfsm.states.compactMap { stateObjects[$0]?.id }
        llfsmObj.eSet("states", value: stateIDs)
        let transIDs: [EUUID] = machine.llfsm.transitions.compactMap { transitionObjects[$0]?.id }
        llfsmObj.eSet("transitions", value: transIDs)
        if let suspendStateID = machine.llfsm.suspendState,
           let suspendObj = stateObjects[suspendStateID] {
            llfsmObj.eSet("suspendState", value: suspendObj.id)
        }
        await resource.register(llfsmObj)

        // Build machine boilerplate
        let bpObj = encodeBoilerplate(machine.boilerplate, language: machine.language)
        await resource.register(bpObj)

        let stateBoilerplateEntries = await encodeStateBoilerplateEntries(
            of: machine,
            stateObjects: stateObjects,
            into: resource
        )
        let stateLayoutEntries = await encodeStateLayoutEntries(
            of: machine,
            stateObjects: stateObjects,
            into: resource
        )
        let transitionLayoutEntries = await encodeTransitionLayoutEntries(
            of: machine,
            transitionObjects: transitionObjects,
            into: resource
        )

        // Build Machine object
        var machineObj = DynamicEObject(eClass: metamodel.machineClass)
        machineObj.eSet("name", value: name)
        machineObj.eSet("language", value: machine.language.name)
        machineObj.eSet("llfsm", value: llfsmObj.id)
        machineObj.eSet("boilerplate", value: bpObj.id)
        if !stateBoilerplateEntries.isEmpty {
            machineObj.eSet("stateBoilerplates", value: stateBoilerplateEntries)
        }
        if !stateLayoutEntries.isEmpty {
            machineObj.eSet("stateLayouts", value: stateLayoutEntries)
        }
        if !transitionLayoutEntries.isEmpty {
            machineObj.eSet("transitionLayouts", value: transitionLayoutEntries)
        }
        if let windowData = machine.windowLayout {
            machineObj.eSet("windowLayout", value: windowData.base64EncodedString())
        }
        if addAsRoot {
            await resource.add(machineObj)
        } else {
            await resource.register(machineObj)
        }

        return machineObj
    }

    // MARK: - Decode

    /// Decode a dynamic machine object back into a `Machine`.
    ///
    /// This method resolves the encoded LLFSM graph, machine and state
    /// boilerplate, layouts, and optional window layout payload before
    /// rebuilding the `Machine` value expected by the rest of the package.
    ///
    /// - Parameters:
    ///   - machineObj: Dynamic object representing the machine root.
    ///   - resource: Resource containing the object graph.
    /// - Returns: Decoded machine name and machine value.
    /// - Throws: Throw an error if required structural features are missing.
    public func decode(_ machineObj: DynamicEObject, from resource: Resource) async throws -> (name: String, machine: Machine) {
        let machineName = await resource.eGet(objectId: machineObj.id, feature: "name") as? String ?? ""
        let languageName = await resource.eGet(objectId: machineObj.id, feature: "language") as? String ?? ""
        let language: any LanguageBinding = languageBinding(for: languageName)

        // Decode LLFSM
        guard let llfsmID = ModelReferences.identifier(
            from: await resource.eGet(objectId: machineObj.id, feature: "llfsm")
        ) else {
            throw LLFSMMetamodelError.missingFeature("llfsm")
        }

        // Decode states
        let stateIDs = ModelReferences.identifiers(
            from: await resource.eGet(objectId: llfsmID, feature: "states")
        )
        guard !stateIDs.isEmpty else {
            throw LLFSMMetamodelError.missingFeature("states")
        }
        var eobjectToStateID = [EUUID: StateID]()
        var stateArray = [State]()
        for eID in stateIDs {
            let stateName = await resource.eGet(objectId: eID, feature: "name") as? String ?? ""
            let state = State(name: stateName)
            eobjectToStateID[eID] = state.id
            stateArray.append(state)
        }

        // Decode transitions
        let transIDs = ModelReferences.identifiers(
            from: await resource.eGet(objectId: llfsmID, feature: "transitions")
        )
        var eobjectToTransID = [EUUID: TransitionID]()
        var transitionArray = [Transition]()
        for eID in transIDs {
            let label = await stringValue(ofFeature: "label", for: eID, in: resource)
            let srcEID = ModelReferences.identifier(from: await resource.eGet(objectId: eID, feature: "source"))
            let tgtEID = ModelReferences.identifier(from: await resource.eGet(objectId: eID, feature: "target"))
            let sourceID = srcEID.flatMap { eobjectToStateID[$0] } ?? StateID(uuid: UUID_NULL)
            let targetID = tgtEID.flatMap { eobjectToStateID[$0] } ?? StateID(uuid: UUID_NULL)
            let transition = Transition(label: label, source: sourceID, target: targetID)
            eobjectToTransID[eID] = transition.id
            transitionArray.append(transition)
        }

        // Decode suspend state
        let suspendEID = ModelReferences.identifier(from: await resource.eGet(objectId: llfsmID, feature: "suspendState"))
        let suspendStateID = suspendEID.flatMap { eobjectToStateID[$0] }

        let llfsm = LLFSM(states: stateArray, transitions: transitionArray, suspendState: suspendStateID)

        // Decode machine boilerplate
        let bpID = ModelReferences.identifier(from: await resource.eGet(objectId: machineObj.id, feature: "boilerplate"))
        let boilerplate: any Boilerplate
        if let bpID = bpID {
            boilerplate = await decodeBoilerplate(bpID, from: resource, language: language)
        } else {
            boilerplate = CBoilerplate()
        }

        let stateBoilerplate = await decodeStateBoilerplate(
            of: machineObj,
            states: eobjectToStateID,
            llfsm: llfsm,
            language: language,
            from: resource
        )

        // Decode state layouts
        var stateLayouts = StateLayouts()
        let slEntryIDs = ModelReferences.identifiers(
            from: await resource.eGet(objectId: machineObj.id, feature: "stateLayouts")
        )
        for entryID in slEntryIDs {
            guard let stateEID = ModelReferences.identifier(from: await resource.eGet(objectId: entryID, feature: "state")),
                  let stateID = eobjectToStateID[stateEID],
                  let layoutID = ModelReferences.identifier(from: await resource.eGet(objectId: entryID, feature: "layout")) else { continue }
            stateLayouts[stateID] = await decodeStateLayout(layoutID, from: resource)
        }

        // Decode transition layouts
        var transitionLayouts = TransitionLayouts()
        let tlEntryIDs = ModelReferences.identifiers(
            from: await resource.eGet(objectId: machineObj.id, feature: "transitionLayouts")
        )
        for entryID in tlEntryIDs {
            guard let transEID = ModelReferences.identifier(from: await resource.eGet(objectId: entryID, feature: "transition")),
                  let transID = eobjectToTransID[transEID],
                  let layoutID = ModelReferences.identifier(from: await resource.eGet(objectId: entryID, feature: "layout")) else { continue }
            transitionLayouts[transID] = await decodeTransitionLayout(layoutID, from: resource)
        }

        // Decode window layout
        var windowLayout: Data?
        if let windowStr = await resource.eGet(objectId: machineObj.id, feature: "windowLayout") as? String,
           !windowStr.isEmpty {
            windowLayout = Data(base64Encoded: windowStr)
        }

        // Assemble machine
        let machine = Machine()
        machine.language = language
        machine.llfsm = llfsm
        machine.boilerplate = boilerplate
        machine.stateBoilerplate = stateBoilerplate
        machine.stateLayout = stateLayouts
        machine.transitionLayout = transitionLayouts
        machine.windowLayout = windowLayout

        return (name: machineName, machine: machine)
    }

    // MARK: - Private Helpers

    /// Encode boilerplate sections as a dynamic object.
    ///
    /// This helper normalises machine-level boilerplate into the structural
    /// metamodel representation used during serialisation.
    ///
    /// - Parameters:
    ///   - bp: Boilerplate value to encode.
    ///   - language: Language binding used to extract normalised sections.
    /// - Returns: Dynamic object representing the boilerplate value.
    private func encodeBoilerplate(_ bp: any Boilerplate, language: any LanguageBinding) -> DynamicEObject {
        boilerplateObject(for: language.extractSections(from: bp))
    }

    /// The boilerplate sections and the features that hold them.
    static let boilerplateFeatures: [(StandardBoilerplateSection, String)] = [
        (.includePath, "includePath"),
        (.includes, "includes"),
        (.variables, "variables"),
        (.functions, "functions"),
    ]

    /// The state activity sections and the features that hold them.
    static let activityFeatures: [(StandardBoilerplateSection, String)] = [
        (.onEntry, "onEntry"),
        (.onExit, "onExit"),
        (.internal, "internal"),
        (.onSuspend, "onSuspend"),
        (.onResume, "onResume"),
    ]

    /// Create a boilerplate object holding the given sections.
    ///
    /// Only the sections that are present are set, so that a section a
    /// machine does not have remains distinguishable from an empty one.
    ///
    /// - Parameter sections: Boilerplate sections to store.
    /// - Returns: Dynamic object representing the boilerplate value.
    private func boilerplateObject(for sections: [StandardBoilerplateSection: String]) -> DynamicEObject {
        var obj = DynamicEObject(eClass: metamodel.boilerplateClass)
        for (section, feature) in Self.boilerplateFeatures {
            if let code = sections[section] { obj.eSet(feature, value: code) }
        }
        return obj
    }

    /// Encode a state layout as a dynamic object.
    ///
    /// This helper copies all state geometry and section height values into the
    /// structural metamodel representation, including any preserved extra
    /// properties, which keep their property list value types.
    ///
    /// - Parameters:
    ///   - layout: State layout value to encode.
    ///   - resource: Resource that will own the objects of the extra properties.
    /// - Returns: Dynamic object representing the state layout.
    private func encodeStateLayout(_ layout: StateLayout, into resource: Resource) async -> DynamicEObject {
        var obj = DynamicEObject(eClass: metamodel.stateLayoutClass)
        obj.eSet("isOpen", value: layout.isOpen)
        obj.eSet("closedX", value: layout.closedLayout.x)
        obj.eSet("closedY", value: layout.closedLayout.y)
        obj.eSet("closedW", value: layout.closedLayout.w)
        obj.eSet("closedH", value: layout.closedLayout.h)
        obj.eSet("openX", value: layout.openLayout.x)
        obj.eSet("openY", value: layout.openLayout.y)
        obj.eSet("openW", value: layout.openLayout.w)
        obj.eSet("openH", value: layout.openLayout.h)
        obj.eSet("onEntryHeight", value: layout.onEntryHeight)
        obj.eSet("onExitHeight", value: layout.onExitHeight)
        obj.eSet("internalHeight", value: layout.internalHeight)
        obj.eSet("onSuspendHeight", value: layout.onSuspendHeight)
        obj.eSet("onResumeHeight", value: layout.onResumeHeight)
        obj.eSet("zoomedOnEntryHeight", value: layout.zoomedOnEntryHeight)
        obj.eSet("zoomedOnExitHeight", value: layout.zoomedOnExitHeight)
        obj.eSet("zoomedInternalHeight", value: layout.zoomedInternalHeight)
        obj.eSet("zoomedOnSuspendHeight", value: layout.zoomedOnSuspendHeight)
        obj.eSet("zoomedOnResumeHeight", value: layout.zoomedOnResumeHeight)
        if !layout.extraProperties.isEmpty {
            let entries = await PropertyListEcoreCodec(metamodel: metamodel)
                .encodeEntries(layout.extraProperties, into: resource)
            obj.eSet("properties", value: entries)
        }
        return obj
    }

    /// Decode boilerplate sections from a dynamic object.
    ///
    /// This helper reads the normalised boilerplate fields stored in the
    /// structural model and returns them in the section dictionary expected by
    /// `LanguageBinding`.
    ///
    /// - Parameters:
    ///   - bpID: Identifier of the encoded boilerplate object.
    ///   - resource: Resource containing the encoded object.
    /// - Returns: Normalised boilerplate sections.
    private func decodeBoilerplateSections(_ bpID: EUUID, from resource: Resource) async -> [StandardBoilerplateSection: String] {
        var sections = [StandardBoilerplateSection: String]()
        sections[.includePath] = await resource.eGet(objectId: bpID, feature: "includePath") as? String ?? ""
        sections[.includes] = await resource.eGet(objectId: bpID, feature: "includes") as? String ?? ""
        sections[.variables] = await resource.eGet(objectId: bpID, feature: "variables") as? String ?? ""
        sections[.functions] = await resource.eGet(objectId: bpID, feature: "functions") as? String ?? ""
        return sections
    }

    /// Decode a boilerplate value from a dynamic object.
    ///
    /// This helper reconstructs a language-specific boilerplate value from the
    /// normalised sections stored in the structural model.
    ///
    /// - Parameters:
    ///   - bpID: Identifier of the encoded boilerplate object.
    ///   - resource: Resource containing the encoded object.
    ///   - language: Language binding used to rebuild the boilerplate value.
    /// - Returns: Decoded boilerplate value.
    private func decodeBoilerplate(_ bpID: EUUID, from resource: Resource, language: any LanguageBinding) async -> any Boilerplate {
        let sections = await decodeBoilerplateSections(bpID, from: resource)
        return language.createBoilerplate(from: sections)
    }

    /// Decode a state layout from a dynamic object.
    ///
    /// This helper reconstructs the concrete `StateLayout` value used by
    /// `swift-fsmlib` from the geometric attributes stored in the structural
    /// model.
    ///
    /// - Parameters:
    ///   - layoutID: Identifier of the encoded layout object.
    ///   - resource: Resource containing the encoded object.
    /// - Returns: Decoded state layout value.
    private func decodeStateLayout(_ layoutID: EUUID, from resource: Resource) async -> StateLayout {
        let isOpen = await resource.eGet(objectId: layoutID, feature: "isOpen") as? Bool ?? false
        let cx = await resource.eGet(objectId: layoutID, feature: "closedX") as? Double ?? 0
        let cy = await resource.eGet(objectId: layoutID, feature: "closedY") as? Double ?? 0
        let cw = await resource.eGet(objectId: layoutID, feature: "closedW") as? Double ?? 100
        let ch = await resource.eGet(objectId: layoutID, feature: "closedH") as? Double ?? 50
        let ox = await resource.eGet(objectId: layoutID, feature: "openX") as? Double ?? 0
        let oy = await resource.eGet(objectId: layoutID, feature: "openY") as? Double ?? 0
        let ow = await resource.eGet(objectId: layoutID, feature: "openW") as? Double ?? 200
        let oh = await resource.eGet(objectId: layoutID, feature: "openH") as? Double ?? 100
        let closedLayout = Ellipse(centre: Coordinate2D(cx, cy), dimensions: Dimensions2D(cw, ch))
        let openLayout = Rectangle(centre: Coordinate2D(ox, oy), dimensions: Dimensions2D(ow, oh))

        let onEntryH = await resource.eGet(objectId: layoutID, feature: "onEntryHeight") as? Double ?? 0
        let onExitH = await resource.eGet(objectId: layoutID, feature: "onExitHeight") as? Double ?? 0
        let internalH = await resource.eGet(objectId: layoutID, feature: "internalHeight") as? Double ?? 0
        let onSuspendH = await resource.eGet(objectId: layoutID, feature: "onSuspendHeight") as? Double ?? 0
        let onResumeH = await resource.eGet(objectId: layoutID, feature: "onResumeHeight") as? Double ?? 0
        let zOnEntryH = await resource.eGet(objectId: layoutID, feature: "zoomedOnEntryHeight") as? Double ?? 0
        let zOnExitH = await resource.eGet(objectId: layoutID, feature: "zoomedOnExitHeight") as? Double ?? 0
        let zInternalH = await resource.eGet(objectId: layoutID, feature: "zoomedInternalHeight") as? Double ?? 0
        let zOnSuspendH = await resource.eGet(objectId: layoutID, feature: "zoomedOnSuspendHeight") as? Double ?? 0
        let zOnResumeH = await resource.eGet(objectId: layoutID, feature: "zoomedOnResumeHeight") as? Double ?? 0

        var extraProps = [String: Any]()
        let propertyEntries = ModelReferences.identifiers(
            from: await resource.eGet(objectId: layoutID, feature: "properties"))
        if !propertyEntries.isEmpty {
            extraProps = await PropertyListEcoreCodec(metamodel: metamodel)
                .decodeEntries(propertyEntries, from: resource)
        } else if let extraStr = await resource.eGet(objectId: layoutID, feature: "extraProperties") as? String,
           !extraStr.isEmpty,
           let data = extraStr.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            extraProps = json
        }

        return StateLayout(
            isOpen: isOpen,
            openLayout: openLayout,
            closedLayout: closedLayout,
            onEntryHeight: onEntryH,
            onExitHeight: onExitH,
            onSuspendHeight: onSuspendH,
            onResumeHeight: onResumeH,
            internalHeight: internalH,
            zoomedOnEntryHeight: zOnEntryH,
            zoomedOnExitHeight: zOnExitH,
            zoomedInternalHeight: zInternalH,
            zoomedOnSuspendHeight: zOnSuspendH,
            zoomedOnResumeHeight: zOnResumeH,
            extraProperties: extraProps
        )
    }

    /// Decode a transition layout from a dynamic object.
    ///
    /// This helper reads the encoded point list and rebuilds the path-based
    /// `TransitionLayout` value used by `swift-fsmlib`.
    ///
    /// - Parameters:
    ///   - layoutID: Identifier of the encoded layout object.
    ///   - resource: Resource containing the encoded object.
    /// - Returns: Decoded transition layout value.
    private func decodeTransitionLayout(_ layoutID: EUUID, from resource: Resource) async -> TransitionLayout {
        let pointIDs = ModelReferences.identifiers(from: await resource.eGet(objectId: layoutID, feature: "points"))
        var points = [Point2D]()
        for pID in pointIDs {
            let x = await resource.eGet(objectId: pID, feature: "x") as? Double ?? 0
            let y = await resource.eGet(objectId: pID, feature: "y") as? Double ?? 0
            points.append(Point2D(x, y))
        }
        return TransitionLayout(points)
    }

    /// Convert a primitive feature value into an FSM string.
    ///
    /// XMI parsing may infer booleans or numbers for primitive attributes. FSM
    /// transition labels are stored as strings, so this helper converts parsed
    /// primitive values back into the string form expected by the model layer.
    ///
    /// - Parameters:
    ///   - feature: Feature name to read.
    ///   - objectID: Identifier of the dynamic object to inspect.
    ///   - resource: Resource containing the parsed object.
    /// - Returns: String form of the stored primitive value, or an empty string.
    private func stringValue(ofFeature feature: String, for objectID: EUUID, in resource: Resource) async -> String {
        let value = await resource.eGet(objectId: objectID, feature: feature)
        switch value {
        case let string as String:
            return string
        case let bool as Bool:
            return bool ? "true" : "false"
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        default:
            return ""
        }
    }
}

/// The steps by which a machine is encoded into and decoded from a resource.
extension MachineEcoreCodec {
    /// Encode the states of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine whose states are encoded.
    ///   - resource: The resource that will own the encoded objects.
    /// - Returns: The state objects, keyed by the identifiers of their states.
    private func encodeStates(of machine: Machine, into resource: Resource) async -> [StateID: DynamicEObject] {
        var stateObjects = [StateID: DynamicEObject]()
        for stateID in machine.llfsm.states {
            guard let stateName = machine.llfsm.stateName(for: stateID) else { continue }
            var stateObj = DynamicEObject(eClass: metamodel.stateClass)
            stateObj.eSet("name", value: stateName)

            // Encode state activities
            let sections = machine.stateActivities(for: stateID)
            if !sections.isEmpty {
                var activitiesObj = DynamicEObject(eClass: metamodel.stateActivitiesClass)
                for (section, feature) in Self.activityFeatures {
                    if let code = sections[section] { activitiesObj.eSet(feature, value: code) }
                }
                await resource.register(activitiesObj)
                stateObj.eSet("activities", value: activitiesObj.id)
            }

            await resource.register(stateObj)
            stateObjects[stateID] = stateObj
        }
        return stateObjects
    }

    /// Encode the transitions of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine whose transitions are encoded.
    ///   - stateObjects: The encoded states, keyed by the identifiers of their states.
    ///   - resource: The resource that will own the encoded objects.
    /// - Returns: The transition objects, keyed by the identifiers of their transitions.
    private func encodeTransitions(
        of machine: Machine,
        stateObjects: [StateID: DynamicEObject],
        into resource: Resource
    ) async -> [TransitionID: DynamicEObject] {
        var transitionObjects = [TransitionID: DynamicEObject]()
        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transition(for: transitionID) else { continue }
            var transObj = DynamicEObject(eClass: metamodel.transitionClass)
            transObj.eSet("label", value: transition.label)
            if let srcObj = stateObjects[transition.source] {
                transObj.eSet("source", value: srcObj.id)
            }
            if let tgtObj = stateObjects[transition.target] {
                transObj.eSet("target", value: tgtObj.id)
            }
            await resource.register(transObj)
            transitionObjects[transitionID] = transObj
        }
        return transitionObjects
    }

    /// Encode the per-state boilerplate of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine whose state boilerplate is encoded.
    ///   - stateObjects: The encoded states, keyed by the identifiers of their states.
    ///   - resource: The resource that will own the encoded objects.
    /// - Returns: The identifiers of the boilerplate entry objects.
    private func encodeStateBoilerplateEntries(
        of machine: Machine,
        stateObjects: [StateID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var stateBoilerplateEntries = [EUUID]()
        for stateID in machine.llfsm.states {
            guard let stateObj = stateObjects[stateID],
                  let bp = machine.stateBoilerplate[stateID] else { continue }
            let bpSections = machine.language.extractSections(from: bp)
            let entryBpObj = boilerplateObject(for: bpSections)
            await resource.register(entryBpObj)

            var entryObj = DynamicEObject(eClass: metamodel.stateBoilerplateEntryClass)
            entryObj.eSet("state", value: stateObj.id)
            entryObj.eSet("boilerplate", value: entryBpObj.id)
            await resource.register(entryObj)
            stateBoilerplateEntries.append(entryObj.id)
        }
        return stateBoilerplateEntries
    }

    /// Encode the state layouts of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine whose state layouts are encoded.
    ///   - stateObjects: The encoded states, keyed by the identifiers of their states.
    ///   - resource: The resource that will own the encoded objects.
    /// - Returns: The identifiers of the state layout entry objects.
    private func encodeStateLayoutEntries(
        of machine: Machine,
        stateObjects: [StateID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var stateLayoutEntries = [EUUID]()
        for (stateID, layout) in machine.stateLayout {
            guard let stateObj = stateObjects[stateID] else { continue }
            let layoutObj = await encodeStateLayout(layout, into: resource)
            await resource.register(layoutObj)

            var entryObj = DynamicEObject(eClass: metamodel.stateLayoutEntryClass)
            entryObj.eSet("state", value: stateObj.id)
            entryObj.eSet("layout", value: layoutObj.id)
            await resource.register(entryObj)
            stateLayoutEntries.append(entryObj.id)
        }
        return stateLayoutEntries
    }

    /// Encode the transition layouts of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine whose transition layouts are encoded.
    ///   - transitionObjects: The encoded transitions, keyed by the identifiers of their transitions.
    ///   - resource: The resource that will own the encoded objects.
    /// - Returns: The identifiers of the transition layout entry objects.
    private func encodeTransitionLayoutEntries(
        of machine: Machine,
        transitionObjects: [TransitionID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var transitionLayoutEntries = [EUUID]()
        for (transitionID, layout) in machine.transitionLayout {
            guard let transObj = transitionObjects[transitionID] else { continue }
            var pointIDs = [EUUID]()
            for point in layout.path.points {
                var pointObj = DynamicEObject(eClass: metamodel.point2DClass)
                pointObj.eSet("x", value: point.x)
                pointObj.eSet("y", value: point.y)
                await resource.register(pointObj)
                pointIDs.append(pointObj.id)
            }
            var tlObj = DynamicEObject(eClass: metamodel.transitionLayoutClass)
            tlObj.eSet("points", value: pointIDs)
            await resource.register(tlObj)

            var entryObj = DynamicEObject(eClass: metamodel.transitionLayoutEntryClass)
            entryObj.eSet("transition", value: transObj.id)
            entryObj.eSet("layout", value: tlObj.id)
            await resource.register(entryObj)
            transitionLayoutEntries.append(entryObj.id)
        }
        return transitionLayoutEntries
    }

    /// Decode the per-state boilerplate of a machine, including the state activities.
    ///
    /// - Parameters:
    ///   - machineObj: The dynamic object that represents the machine.
    ///   - states: The decoded state identifiers, keyed by the identifiers of their objects.
    ///   - llfsm: The decoded state graph, which names the states.
    ///   - language: The language binding that builds the boilerplate.
    ///   - resource: The resource that contains the object graph.
    /// - Returns: The boilerplate of every state that has an entry.
    private func decodeStateBoilerplate(
        of machineObj: DynamicEObject,
        states eobjectToStateID: [EUUID: StateID],
        llfsm: LLFSM,
        language: any LanguageBinding,
        from resource: Resource
    ) async -> [StateID: any Boilerplate] {
        var stateBoilerplate = [StateID: any Boilerplate]()
        let sbpEntryIDs = ModelReferences.identifiers(
            from: await resource.eGet(objectId: machineObj.id, feature: "stateBoilerplates")
        )
        for entryID in sbpEntryIDs {
            guard let stateEID = ModelReferences.identifier(from: await resource.eGet(objectId: entryID, feature: "state")),
                  let stateID = eobjectToStateID[stateEID],
                  let entryBpID = ModelReferences.identifier(
                      from: await resource.eGet(objectId: entryID, feature: "boilerplate")
                  ) else { continue }

            // Reconstruct state boilerplate from boilerplate sections + activities
            let bpSections = await decodeBoilerplateSections(entryBpID, from: resource)
            let stateName = llfsm.stateName(for: stateID) ?? ""

            // Also get activities from the state object
            var allSections = bpSections
            if let activitiesID = ModelReferences.identifier(from: await resource.eGet(objectId: stateEID, feature: "activities")) {
                let onEntry = await resource.eGet(objectId: activitiesID, feature: "onEntry") as? String ?? ""
                let onExit = await resource.eGet(objectId: activitiesID, feature: "onExit") as? String ?? ""
                let internalCode = await resource.eGet(objectId: activitiesID, feature: "internal") as? String ?? ""
                let onSuspend = await resource.eGet(objectId: activitiesID, feature: "onSuspend") as? String ?? ""
                let onResume = await resource.eGet(objectId: activitiesID, feature: "onResume") as? String ?? ""
                allSections[.onEntry] = onEntry
                allSections[.onExit] = onExit
                allSections[.internal] = internalCode
                allSections[.onSuspend] = onSuspend
                allSections[.onResume] = onResume
            }
            stateBoilerplate[stateID] = language.createStateBoilerplate(from: allSections, stateName: stateName)
        }
        return stateBoilerplate
    }
}
