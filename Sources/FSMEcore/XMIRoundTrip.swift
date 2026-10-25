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
        var diagnostics = ConversionDiagnostics()
        try await write(machine: machine, name: name, to: url, diagnostics: &diagnostics)
    }

    /// Write a machine to an XMI document, collecting conversion diagnostics.
    ///
    /// This method behaves like ``write(machine:name:to:)`` and additionally
    /// records any warnings that the XMI serialiser reports, for example
    /// content that the document could not represent faithfully.
    ///
    /// - Parameters:
    ///   - machine: Machine value to serialise.
    ///   - name: Machine name to store in the structural model.
    ///   - url: Destination URL for the XMI document.
    ///   - diagnostics: Receives the serialiser warnings, in the order in
    ///     which they first occur.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(
        machine: Machine,
        name: String,
        to url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws {
        let resourceSet = ResourceSet()
        let resource = await makeResource(for: url, in: resourceSet)
        let codec = MachineEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(machine, name: name, into: resource)
        try await serialise(resource, to: url, diagnostics: &diagnostics)
        await resourceSet.removeResource(resource)
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
        var diagnostics = ConversionDiagnostics()
        return try await readMachine(from: url, diagnostics: &diagnostics)
    }

    /// Read a machine from an XMI document, collecting conversion diagnostics.
    ///
    /// This method behaves like ``readMachine(from:)`` and additionally
    /// records the warnings that the XMI parser reports, such as elements
    /// whose classes the structural metamodel does not define.
    ///
    /// - Parameters:
    ///   - url: URL of the XMI document to read.
    ///   - diagnostics: Receives the parser warnings, in the order in which
    ///     they first occur. Warnings are recorded even if decoding fails.
    /// - Returns: Decoded machine name and machine value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readMachine(
        from url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws -> (name: String, machine: Machine) {
        let resource = try await loadResource(from: url, diagnostics: &diagnostics)
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
        var diagnostics = ConversionDiagnostics()
        try await write(arrangement: arrangement, to: url, diagnostics: &diagnostics)
    }

    /// Write an arrangement to an XMI document, collecting conversion diagnostics.
    ///
    /// This method behaves like ``write(arrangement:to:)`` and additionally
    /// records any warnings that the XMI serialiser reports.
    ///
    /// - Parameters:
    ///   - arrangement: Arrangement value to serialise.
    ///   - url: Destination URL for the XMI document.
    ///   - diagnostics: Receives the serialiser warnings, in the order in
    ///     which they first occur.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(
        arrangement: Arrangement,
        to url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws {
        let resourceSet = ResourceSet()
        let resource = await makeResource(for: url, in: resourceSet)
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        _ = await codec.encode(arrangement, into: resource)
        try await serialise(resource, to: url, diagnostics: &diagnostics)
        await resourceSet.removeResource(resource)
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
        var diagnostics = ConversionDiagnostics()
        return try await readArrangement(from: url, diagnostics: &diagnostics)
    }

    /// Read an arrangement from an XMI document, collecting conversion diagnostics.
    ///
    /// This method behaves like ``readArrangement(from:)`` and additionally
    /// records the warnings that the XMI parser reports.
    ///
    /// - Parameters:
    ///   - url: URL of the XMI document to read.
    ///   - diagnostics: Receives the parser warnings, in the order in which
    ///     they first occur. Warnings are recorded even if decoding fails.
    /// - Returns: Decoded arrangement value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readArrangement(
        from url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws -> Arrangement {
        let resource = try await loadResource(from: url, diagnostics: &diagnostics)
        guard let arrangementObj = await findObject(
            named: metamodel.arrangementClass.name,
            in: resource
        ) else {
            throw LLFSMMetamodelError.missingFeature("root Arrangement object")
        }
        let codec = ArrangementEcoreCodec(metamodel: metamodel)
        return try await codec.decode(arrangementObj, from: resource)
    }

    /// Parse an XMI document against the structural metamodel.
    ///
    /// The document is read into a resource set in which the structural
    /// metamodel is registered, so that its elements are typed by the
    /// classifiers of ``metamodel`` rather than by classes inferred from the
    /// document. Use this method when you need the reflective object graph,
    /// for example to inspect it or to decode it with ``MachineEcoreCodec`` or
    /// ``ArrangementEcoreCodec``.
    ///
    /// - Parameters:
    ///   - url: URL of the XMI document to read.
    ///   - diagnostics: Receives the parser warnings, in the order in which
    ///     they first occur.
    /// - Returns: The resource holding the parsed object graph.
    /// - Throws: Throw an error if the document cannot be read or parsed.
    public func loadResource(
        from url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws -> Resource {
        let resourceSet = ResourceSet()
        await metamodel.register(in: resourceSet)
        let parser = XMIParser(resourceSet: resourceSet)
        let resource = try await parser.parse(url)
        diagnostics.merge(await parser.diagnostics)
        return resource
    }

    /// Create an empty resource in a resource set that knows the metamodel.
    ///
    /// Encoding into such a resource lets the serialiser qualify every
    /// element with the namespace of the structural metamodel.
    ///
    /// - Parameters:
    ///   - url: Destination URL that names the resource.
    ///   - resourceSet: Resource set that will own the resource.
    /// - Returns: The new, empty resource.
    private func makeResource(for url: URL, in resourceSet: ResourceSet) async -> Resource {
        await metamodel.register(in: resourceSet)
        return await resourceSet.createResource(uri: url.absoluteString)
    }

    /// Serialise a resource to a file with the established XMI layout.
    ///
    /// - Parameters:
    ///   - resource: Resource holding the encoded object graph.
    ///   - url: Destination URL for the XMI document.
    ///   - diagnostics: Receives the serialiser warnings.
    /// - Throws: Throw an error if serialisation or file output fails.
    private func serialise(
        _ resource: Resource,
        to url: URL,
        diagnostics: inout ConversionDiagnostics
    ) async throws {
        let serialiser = XMISerializer(options: .legacy)
        let xmiString = try await serialiser.serialize(resource, diagnostics: &diagnostics)
        try xmiString.write(to: url, atomically: FileWritingSupport.writesAtomically, encoding: .utf8)
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
