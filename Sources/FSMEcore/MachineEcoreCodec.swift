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

/// Bidirectional codec between `Machine` and EObject representations.
///
/// This struct provides encoding of `Machine` instances to EObject graphs
/// (for XMI serialisation) and decoding of EObject graphs back to `Machine`
/// instances (for XMI deserialisation), enabling lossless round-tripping
/// through the LLFSMStructural metamodel.
public struct MachineEcoreCodec {
    /// The metamodel providing EClass definitions.
    public let metamodel: LLFSMMetamodel

    /// Create a codec with the given metamodel.
    ///
    /// - Parameter metamodel: The loaded LLFSMStructural metamodel.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
    }

    // MARK: - Encode

    /// Encode a `Machine` to an EObject graph within a `Resource`.
    ///
    /// - Parameters:
    ///   - machine: The machine to encode.
    ///   - name: The name for the machine.
    ///   - resource: The resource to add objects to.
    /// - Returns: The root `DynamicEObject` representing the machine.
    public func encode(_ machine: Machine, name: String, into resource: Resource) async -> DynamicEObject {
        // Build state objects and maintain ID mapping
        var stateObjects = [StateID: DynamicEObject]()
        for stateID in machine.llfsm.states {
            guard let stateName = machine.llfsm.stateName(for: stateID) else { continue }
            var stateObj = DynamicEObject(eClass: metamodel.stateClass)
            stateObj.eSet("name", value: stateName)

            // Encode state activities
            let sections = machine.stateActivities(for: stateID)
            if !sections.isEmpty {
                var activitiesObj = DynamicEObject(eClass: metamodel.stateActivitiesClass)
                activitiesObj.eSet("onEntry", value: sections[.onEntry] ?? "")
                activitiesObj.eSet("onExit", value: sections[.onExit] ?? "")
                activitiesObj.eSet("internal", value: sections[.internal] ?? "")
                activitiesObj.eSet("onSuspend", value: sections[.onSuspend] ?? "")
                activitiesObj.eSet("onResume", value: sections[.onResume] ?? "")
                await resource.add(activitiesObj)
                stateObj.eSet("activities", value: activitiesObj.id)
            }

            await resource.add(stateObj)
            stateObjects[stateID] = stateObj
        }

        // Build transition objects
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
            await resource.add(transObj)
            transitionObjects[transitionID] = transObj
        }

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
        await resource.add(llfsmObj)

        // Build machine boilerplate
        let bpObj = encodeBoilerplate(machine.boilerplate, language: machine.language)
        await resource.add(bpObj)

        // Build state boilerplate entries
        var stateBoilerplateEntries = [EUUID]()
        for stateID in machine.llfsm.states {
            guard let stateObj = stateObjects[stateID],
                  let bp = machine.stateBoilerplate[stateID] else { continue }
            let bpSections = machine.language.extractSections(from: bp)
            var entryBpObj = DynamicEObject(eClass: metamodel.boilerplateClass)
            entryBpObj.eSet("includePath", value: bpSections[.includePath] ?? "")
            entryBpObj.eSet("includes", value: bpSections[.includes] ?? "")
            entryBpObj.eSet("variables", value: bpSections[.variables] ?? "")
            entryBpObj.eSet("functions", value: bpSections[.functions] ?? "")
            await resource.add(entryBpObj)

            var entryObj = DynamicEObject(eClass: metamodel.stateBoilerplateEntryClass)
            entryObj.eSet("state", value: stateObj.id)
            entryObj.eSet("boilerplate", value: entryBpObj.id)
            await resource.add(entryObj)
            stateBoilerplateEntries.append(entryObj.id)
        }

        // Build state layout entries
        var stateLayoutEntries = [EUUID]()
        for (stateID, layout) in machine.stateLayout {
            guard let stateObj = stateObjects[stateID] else { continue }
            let layoutObj = encodeStateLayout(layout)
            await resource.add(layoutObj)

            var entryObj = DynamicEObject(eClass: metamodel.stateLayoutEntryClass)
            entryObj.eSet("state", value: stateObj.id)
            entryObj.eSet("layout", value: layoutObj.id)
            await resource.add(entryObj)
            stateLayoutEntries.append(entryObj.id)
        }

        // Build transition layout entries
        var transitionLayoutEntries = [EUUID]()
        for (transitionID, layout) in machine.transitionLayout {
            guard let transObj = transitionObjects[transitionID] else { continue }
            var pointIDs = [EUUID]()
            for point in layout.path.points {
                var pointObj = DynamicEObject(eClass: metamodel.point2DClass)
                pointObj.eSet("x", value: point.x)
                pointObj.eSet("y", value: point.y)
                await resource.add(pointObj)
                pointIDs.append(pointObj.id)
            }
            var tlObj = DynamicEObject(eClass: metamodel.transitionLayoutClass)
            tlObj.eSet("points", value: pointIDs)
            await resource.add(tlObj)

            var entryObj = DynamicEObject(eClass: metamodel.transitionLayoutEntryClass)
            entryObj.eSet("transition", value: transObj.id)
            entryObj.eSet("layout", value: tlObj.id)
            await resource.add(entryObj)
            transitionLayoutEntries.append(entryObj.id)
        }

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
        await resource.add(machineObj)

        return machineObj
    }

    // MARK: - Decode

    /// Decode an EObject graph back to a `Machine`.
    ///
    /// - Parameters:
    ///   - machineObj: The root EObject representing a machine.
    ///   - resource: The resource containing the object graph.
    /// - Returns: A decoded `Machine` instance.
    /// - Throws: `LLFSMMetamodelError` if required features are missing.
    public func decode(_ machineObj: DynamicEObject, from resource: Resource) async throws -> (name: String, machine: Machine) {
        let machineName = await resource.eGet(objectId: machineObj.id, feature: "name") as? String ?? ""
        let languageName = await resource.eGet(objectId: machineObj.id, feature: "language") as? String ?? ""
        let language: any LanguageBinding = languageBinding(for: languageName)

        // Decode LLFSM
        guard let llfsmID = await resource.eGet(objectId: machineObj.id, feature: "llfsm") as? EUUID else {
            throw LLFSMMetamodelError.missingFeature("llfsm")
        }

        // Decode states
        guard let stateIDs = await resource.eGet(objectId: llfsmID, feature: "states") as? [EUUID] else {
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
        let transIDs = await resource.eGet(objectId: llfsmID, feature: "transitions") as? [EUUID] ?? []
        var eobjectToTransID = [EUUID: TransitionID]()
        var transitionArray = [Transition]()
        for eID in transIDs {
            let label = await resource.eGet(objectId: eID, feature: "label") as? String ?? ""
            let srcEID = await resource.eGet(objectId: eID, feature: "source") as? EUUID
            let tgtEID = await resource.eGet(objectId: eID, feature: "target") as? EUUID
            let sourceID = srcEID.flatMap { eobjectToStateID[$0] } ?? StateID(uuid: UUID_NULL)
            let targetID = tgtEID.flatMap { eobjectToStateID[$0] } ?? StateID(uuid: UUID_NULL)
            let transition = Transition(label: label, source: sourceID, target: targetID)
            eobjectToTransID[eID] = transition.id
            transitionArray.append(transition)
        }

        // Decode suspend state
        let suspendEID = await resource.eGet(objectId: llfsmID, feature: "suspendState") as? EUUID
        let suspendStateID = suspendEID.flatMap { eobjectToStateID[$0] }

        let llfsm = LLFSM(states: stateArray, transitions: transitionArray, suspendState: suspendStateID)

        // Decode machine boilerplate
        let bpID = await resource.eGet(objectId: machineObj.id, feature: "boilerplate") as? EUUID
        let boilerplate: any Boilerplate
        if let bpID = bpID {
            boilerplate = await decodeBoilerplate(bpID, from: resource, language: language)
        } else {
            boilerplate = CBoilerplate()
        }

        // Decode state boilerplate entries
        var stateBoilerplate = [StateID: any Boilerplate]()
        let sbpEntryIDs = await resource.eGet(objectId: machineObj.id, feature: "stateBoilerplates") as? [EUUID] ?? []
        for entryID in sbpEntryIDs {
            guard let stateEID = await resource.eGet(objectId: entryID, feature: "state") as? EUUID,
                  let stateID = eobjectToStateID[stateEID],
                  let entryBpID = await resource.eGet(objectId: entryID, feature: "boilerplate") as? EUUID else { continue }

            // Reconstruct state boilerplate from boilerplate sections + activities
            let bpSections = await decodeBoilerplateSections(entryBpID, from: resource)
            let stateName = llfsm.stateName(for: stateID) ?? ""

            // Also get activities from the state object
            var allSections = bpSections
            if let activitiesID = await resource.eGet(objectId: stateEID, feature: "activities") as? EUUID {
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

        // Decode state layouts
        var stateLayouts = StateLayouts()
        let slEntryIDs = await resource.eGet(objectId: machineObj.id, feature: "stateLayouts") as? [EUUID] ?? []
        for entryID in slEntryIDs {
            guard let stateEID = await resource.eGet(objectId: entryID, feature: "state") as? EUUID,
                  let stateID = eobjectToStateID[stateEID],
                  let layoutID = await resource.eGet(objectId: entryID, feature: "layout") as? EUUID else { continue }
            stateLayouts[stateID] = await decodeStateLayout(layoutID, from: resource)
        }

        // Decode transition layouts
        var transitionLayouts = TransitionLayouts()
        let tlEntryIDs = await resource.eGet(objectId: machineObj.id, feature: "transitionLayouts") as? [EUUID] ?? []
        for entryID in tlEntryIDs {
            guard let transEID = await resource.eGet(objectId: entryID, feature: "transition") as? EUUID,
                  let transID = eobjectToTransID[transEID],
                  let layoutID = await resource.eGet(objectId: entryID, feature: "layout") as? EUUID else { continue }
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

    /// Encode a `Boilerplate` to a `DynamicEObject`.
    private func encodeBoilerplate(_ bp: any Boilerplate, language: any LanguageBinding) -> DynamicEObject {
        let sections = language.extractSections(from: bp)
        var obj = DynamicEObject(eClass: metamodel.boilerplateClass)
        obj.eSet("includePath", value: sections[.includePath] ?? "")
        obj.eSet("includes", value: sections[.includes] ?? "")
        obj.eSet("variables", value: sections[.variables] ?? "")
        obj.eSet("functions", value: sections[.functions] ?? "")
        return obj
    }

    /// Encode a `StateLayout` to a `DynamicEObject`.
    private func encodeStateLayout(_ layout: StateLayout) -> DynamicEObject {
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
        if !layout.extraProperties.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: layout.extraProperties),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            obj.eSet("extraProperties", value: jsonString)
        }
        return obj
    }

    /// Decode boilerplate sections from a resource.
    private func decodeBoilerplateSections(_ bpID: EUUID, from resource: Resource) async -> [StandardBoilerplateSection: String] {
        var sections = [StandardBoilerplateSection: String]()
        sections[.includePath] = await resource.eGet(objectId: bpID, feature: "includePath") as? String ?? ""
        sections[.includes] = await resource.eGet(objectId: bpID, feature: "includes") as? String ?? ""
        sections[.variables] = await resource.eGet(objectId: bpID, feature: "variables") as? String ?? ""
        sections[.functions] = await resource.eGet(objectId: bpID, feature: "functions") as? String ?? ""
        return sections
    }

    /// Decode a boilerplate object from a resource.
    private func decodeBoilerplate(_ bpID: EUUID, from resource: Resource, language: any LanguageBinding) async -> any Boilerplate {
        let sections = await decodeBoilerplateSections(bpID, from: resource)
        return language.createBoilerplate(from: sections)
    }

    /// Decode a state layout from a resource.
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
        if let extraStr = await resource.eGet(objectId: layoutID, feature: "extraProperties") as? String,
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

    /// Decode a transition layout from a resource.
    private func decodeTransitionLayout(_ layoutID: EUUID, from resource: Resource) async -> TransitionLayout {
        let pointIDs = await resource.eGet(objectId: layoutID, feature: "points") as? [EUUID] ?? []
        var points = [Point2D]()
        for pID in pointIDs {
            let x = await resource.eGet(objectId: pID, feature: "x") as? Double ?? 0
            let y = await resource.eGet(objectId: pID, feature: "y") as? Double ?? 0
            points.append(Point2D(x, y))
        }
        return TransitionLayout(points)
    }
}
