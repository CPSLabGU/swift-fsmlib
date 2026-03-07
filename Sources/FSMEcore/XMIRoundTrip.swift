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

/// Convenience functions for XMI round-tripping of machines and arrangements.
///
/// This struct provides high-level methods for serialising `Machine` and
/// `Arrangement` instances to XMI files and deserialising them back,
/// enabling persistent storage in the EMF XMI format.
public struct XMIRoundTrip {
    /// The metamodel used for encoding and decoding.
    public let metamodel: LLFSMMetamodel

    /// Create an XMI round-trip helper with the given metamodel.
    ///
    /// - Parameter metamodel: The loaded LLFSMStructural metamodel.
    public init(metamodel: LLFSMMetamodel) {
        self.metamodel = metamodel
    }

    /// Write a machine to an XMI file.
    ///
    /// - Parameters:
    ///   - machine: The machine to serialise.
    ///   - name: The name for the machine.
    ///   - url: The URL to write the XMI file to.
    /// - Throws: An error if serialisation fails.
    public func write(machine: Machine, name: String, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = MachineEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(machine, name: name, into: resource)
        let serialiser = XMISerializer()
        let xmiString = try await serialiser.serialize(resource)
        try xmiString.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Read a machine from an XMI file.
    ///
    /// - Parameter url: The URL of the XMI file to read.
    /// - Returns: A tuple of the machine name and the decoded machine.
    /// - Throws: An error if parsing or decoding fails.
    public func readMachine(from url: URL) async throws -> (name: String, machine: Machine) {
        let parser = XMIParser()
        let resource = try await parser.parse(url)
        let roots = await resource.getRootObjects()
        guard let machineObj = roots.first as? DynamicEObject else {
            throw LLFSMMetamodelError.missingFeature("root Machine object")
        }
        let codec = MachineEcoreCodec(metamodel: metamodel)
        return try await codec.decode(machineObj, from: resource)
    }

    /// Write an arrangement to an XMI file.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to serialise.
    ///   - url: The URL to write the XMI file to.
    /// - Throws: An error if serialisation fails.
    public func write(arrangement: Arrangement, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(arrangement, into: resource)
        let serialiser = XMISerializer()
        let xmiString = try await serialiser.serialize(resource)
        try xmiString.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Read an arrangement from an XMI file.
    ///
    /// - Parameter url: The URL of the XMI file to read.
    /// - Returns: A decoded `Arrangement` instance.
    /// - Throws: An error if parsing or decoding fails.
    public func readArrangement(from url: URL) async throws -> Arrangement {
        let parser = XMIParser()
        let resource = try await parser.parse(url)
        let roots = await resource.getRootObjects()
        guard let arrangementObj = roots.first as? DynamicEObject else {
            throw LLFSMMetamodelError.missingFeature("root Arrangement object")
        }
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        return try await codec.decode(arrangementObj, from: resource)
    }
}
