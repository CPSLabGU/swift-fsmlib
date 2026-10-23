//
//  ArrangementEcoreCodec.swift
//  FSMEcore
//
//  Created by Rene Hexel on 8/3/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import FSM
import Foundation

/// Arrangement codec for the structural metamodel.
///
/// `ArrangementEcoreCodec` converts between `Arrangement` values from
/// `swift-fsmlib` and reflective object graphs backed by `swift-ecore`. It
/// delegates machine-level work to `MachineEcoreCodec` and is responsible for
/// preserving arrangement instance names, type files, and containment
/// structure.
public struct ArrangementEcoreCodec {
    /// Metamodel used to resolve arrangement classifiers.
    ///
    /// This value provides the classifier definitions needed to construct and
    /// decode arrangement-related dynamic objects.
    public let metamodel: LLFSMMetamodel

    /// Machine codec used for instance payloads.
    ///
    /// Each arrangement instance contains a nested machine model, so this codec
    /// delegates per-machine work to `MachineEcoreCodec`.
    public let machineCodec: MachineEcoreCodec

    /// Create the arrangement codec.
    ///
    /// This initialiser stores the supplied metamodel and prepares a matching
    /// machine codec for nested machine values.
    ///
    /// - Parameter metamodel: Loaded structural metamodel to use for conversion.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
        self.machineCodec = MachineEcoreCodec(metamodel: metamodel)
    }

    /// Encode an arrangement into a resource-backed object graph.
    ///
    /// This method creates a dynamic arrangement object, encodes each named
    /// machine instance as a contained object graph, and returns the resulting
    /// root object ready for XMI serialisation.
    ///
    /// - Parameters:
    ///   - arrangement: Arrangement value to encode.
    ///   - resource: Resource that will own the encoded objects.
    /// - Returns: Root dynamic object representing the arrangement.
    public func encode(_ arrangement: Arrangement, into resource: Resource) async -> DynamicEObject {
        var instanceIDs = [EUUID]()
        for instance in arrangement.namedInstances {
            let machineObj = await machineCodec.encode(
                instance.machine,
                name: String(instance.typeName),
                into: resource,
                addAsRoot: false
            )
            var instanceObj = DynamicEObject(eClass: metamodel.instanceClass)
            instanceObj.eSet("name", value: instance.name)
            instanceObj.eSet("typeFile", value: instance.typeFile)
            instanceObj.eSet("machine", value: machineObj.id)
            await resource.register(instanceObj)
            instanceIDs.append(instanceObj.id)
        }

        var arrangementObj = DynamicEObject(eClass: metamodel.arrangementClass)
        arrangementObj.eSet("instances", value: instanceIDs)
        await resource.add(arrangementObj)
        return arrangementObj
    }

    /// Decode a dynamic arrangement object back into an `Arrangement`.
    ///
    /// This method resolves each encoded instance entry, decodes its nested
    /// machine, and rebuilds the arrangement value used by `swift-fsmlib`.
    ///
    /// - Parameters:
    ///   - arrangementObj: Dynamic object representing the arrangement root.
    ///   - resource: Resource containing the object graph.
    /// - Returns: Decoded arrangement value.
    /// - Throws: Throw an error if nested machine decoding fails.
    public func decode(_ arrangementObj: DynamicEObject, from resource: Resource) async throws -> Arrangement {
        let instanceIDs = ModelReferences.identifiers(from: await resource.eGet(objectId: arrangementObj.id, feature: "instances"))
        var instances = [Instance]()
        for instID in instanceIDs {
            let name = await resource.eGet(objectId: instID, feature: "name") as? String ?? ""
            let typeFile = await resource.eGet(objectId: instID, feature: "typeFile") as? String ?? ""
            guard let machineID = ModelReferences.identifier(from: await resource.eGet(objectId: instID, feature: "machine")),
                  let machineObj = await resource.resolve(machineID) as? DynamicEObject else { continue }
            let (_, machine) = try await machineCodec.decode(machineObj, from: resource)
            instances.append(Instance(name: name, typeFile: typeFile, machine: machine))
        }
        return Arrangement(namedInstances: instances)
    }
}
