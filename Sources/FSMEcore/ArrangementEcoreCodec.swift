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

/// Bidirectional codec between `Arrangement` and EObject representations.
///
/// This struct provides encoding of `Arrangement` instances to EObject
/// graphs and decoding of EObject graphs back to `Arrangement` instances,
/// enabling lossless round-tripping through the LLFSMStructural metamodel.
public struct ArrangementEcoreCodec {
    /// The metamodel providing EClass definitions.
    public let metamodel: LLFSMMetamodel

    /// The machine codec used for individual machine encoding/decoding.
    public let machineCodec: MachineEcoreCodec

    /// Create a codec with the given metamodel.
    ///
    /// - Parameter metamodel: The loaded LLFSMStructural metamodel.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
        self.machineCodec = MachineEcoreCodec(metamodel: metamodel)
    }

    /// Encode an `Arrangement` to an EObject graph within a `Resource`.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to encode.
    ///   - resource: The resource to add objects to.
    /// - Returns: The root `DynamicEObject` representing the arrangement.
    public func encode(_ arrangement: Arrangement, into resource: Resource) async -> DynamicEObject {
        var instanceIDs = [EUUID]()
        for instance in arrangement.namedInstances {
            let machineObj = await machineCodec.encode(
                instance.machine,
                name: String(instance.typeName),
                into: resource
            )
            var instanceObj = DynamicEObject(eClass: metamodel.instanceClass)
            instanceObj.eSet("name", value: instance.name)
            instanceObj.eSet("typeFile", value: instance.typeFile)
            instanceObj.eSet("machine", value: machineObj.id)
            await resource.add(instanceObj)
            instanceIDs.append(instanceObj.id)
        }

        var arrangementObj = DynamicEObject(eClass: metamodel.arrangementClass)
        arrangementObj.eSet("instances", value: instanceIDs)
        await resource.add(arrangementObj)
        return arrangementObj
    }

    /// Decode an EObject graph back to an `Arrangement`.
    ///
    /// - Parameters:
    ///   - arrangementObj: The root EObject representing an arrangement.
    ///   - resource: The resource containing the object graph.
    /// - Returns: A decoded `Arrangement` instance.
    /// - Throws: `LLFSMMetamodelError` if required features are missing.
    public func decode(_ arrangementObj: DynamicEObject, from resource: Resource) async throws -> Arrangement {
        let instanceIDs = await resource.eGet(objectId: arrangementObj.id, feature: "instances") as? [EUUID] ?? []
        var instances = [Instance]()
        for instID in instanceIDs {
            let name = await resource.eGet(objectId: instID, feature: "name") as? String ?? ""
            let typeFile = await resource.eGet(objectId: instID, feature: "typeFile") as? String ?? ""
            guard let machineID = await resource.eGet(objectId: instID, feature: "machine") as? EUUID,
                  let machineObj = await resource.resolve(machineID) as? DynamicEObject else { continue }
            let (_, machine) = try await machineCodec.decode(machineObj, from: resource)
            instances.append(Instance(name: name, typeFile: typeFile, machine: machine))
        }
        return Arrangement(namedInstances: instances)
    }
}
