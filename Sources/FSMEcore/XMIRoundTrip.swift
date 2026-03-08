//
//  XMIRoundTrip.swift
//  FSMEcore
//
//  Created by Rene Hexel on 8/3/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import FSM
import Foundation

/// XMI round-trip helper for structural models.
///
/// `XMIRoundTrip` wraps the lower-level codecs and `swift-ecore` XMI support
/// behind file-oriented operations. Use it when you want to write a machine or
/// arrangement as XMI and read it back without manually managing `Resource`,
/// `XMIParser`, or `XMISerializer` instances.
public struct XMIRoundTrip {
    /// Metamodel used for XMI conversion.
    ///
    /// This value is shared by the encode and decode paths so that both
    /// directions resolve the same structural classifiers.
    public let metamodel: LLFSMMetamodel

    /// Create the XMI round-trip helper.
    ///
    /// This initialiser stores the supplied metamodel for later use by the
    /// machine and arrangement codecs.
    ///
    /// - Parameter metamodel: Loaded structural metamodel to use for conversion.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
    }

    /// Write a machine to an XMI document.
    ///
    /// This method encodes the machine into an intermediate resource and then
    /// serialises that resource to the destination URL.
    ///
    /// - Parameters:
    ///   - machine: Machine value to serialise.
    ///   - name: Machine name to store in the structural model.
    ///   - url: Destination URL for the XMI document.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(machine: Machine, name: String, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = MachineEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(machine, name: name, into: resource)
        let serialiser = XMISerializer()
        let xmiString = try await serialiser.serialize(resource)
        try xmiString.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Read a machine from an XMI document.
    ///
    /// This method parses the XMI file into a resource, finds the structural
    /// machine object within that resource, and decodes it back into a
    /// `swift-fsmlib` machine.
    ///
    /// - Parameter url: URL of the XMI document to read.
    /// - Returns: Decoded machine name and machine value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readMachine(from url: URL) async throws -> (name: String, machine: Machine) {
        let parser = XMIParser()
        let resource = try await parser.parse(url)
        guard let machineObj = await findObject(
            named: metamodel.machineClass.name,
            in: resource
        ) else {
            throw LLFSMMetamodelError.missingFeature("root Machine object")
        }
        let codec = MachineEcoreCodec(metamodel: metamodel)
        return try await codec.decode(machineObj, from: resource)
    }

    /// Write an arrangement to an XMI document.
    ///
    /// This method encodes the arrangement into a resource and then serialises
    /// the resulting object graph to the destination URL.
    ///
    /// - Parameters:
    ///   - arrangement: Arrangement value to serialise.
    ///   - url: Destination URL for the XMI document.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(arrangement: Arrangement, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(arrangement, into: resource)
        let serialiser = XMISerializer()
        let xmiString = try await serialiser.serialize(resource)
        try xmiString.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Read an arrangement from an XMI document.
    ///
    /// This method parses the XMI file into a resource, finds the structural
    /// arrangement object within that resource, and decodes it back into an
    /// `Arrangement`.
    ///
    /// - Parameter url: URL of the XMI document to read.
    /// - Returns: Decoded arrangement value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readArrangement(from url: URL) async throws -> Arrangement {
        let parser = XMIParser()
        let resource = try await parser.parse(url)
        guard let arrangementObj = await findObject(
            named: metamodel.arrangementClass.name,
            in: resource
        ) else {
            throw LLFSMMetamodelError.missingFeature("root Arrangement object")
        }
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        return try await codec.decode(arrangementObj, from: resource)
    }

    /// Find the first dynamic object matching a classifier name.
    ///
    /// This helper checks root objects first and then falls back to all objects
    /// in the resource. That makes the reader resilient to parser behaviour that
    /// may expose contained objects alongside the intended root object.
    ///
    /// - Parameters:
    ///   - className: EClass name to search for.
    ///   - resource: Resource containing the parsed objects.
    /// - Returns: First matching dynamic object, or `nil` if none is found.
    private func findObject(named className: String, in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let rootMatch = roots.first(where: { $0.eClass.name == className }) {
            return rootMatch
        }
        let allObjects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return allObjects.first(where: { $0.eClass.name == className })
    }
}
