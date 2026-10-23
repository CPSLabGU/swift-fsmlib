//
//  StructuralRoundTripSupport.swift
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

/// Helpers that take structural examples through the sectioned level and back.
///
/// The bundles are written through the structural templates from models
/// that were read back from XMI documents, so that the original, the round
/// trip and the expectation all take the same path to their files.
@MainActor
enum StructuralRoundTrip {
    /// The structural model of an example, read with the Swift readers.
    enum Model {
        /// A single machine and its name.
        case machine(String, Machine)
        /// An arrangement of machines.
        case arrangement(Arrangement)
    }

    /// The model of an example bundle.
    ///
    /// - Parameter example: The example.
    /// - Returns: The machine or arrangement that the bundle holds.
    static func model(of example: ParityExample) throws -> Model {
        if example.url.pathExtension == TemplateParity.arrangementExtension {
            return .arrangement(try ArrangementWrapper(url: example.url).arrangement)
        }
        return .machine(example.name, try Machine(from: example.url))
    }

    /// The language of the machines of a model.
    static func language(of model: Model) -> any LanguageBinding {
        switch model {
        case .machine(_, let machine): return machine.language
        case .arrangement(let arrangement): return arrangement.namedInstances.first?.machine.language ?? CBinding()
        }
    }

    /// Write a model to an XMI document and read it back as a structural resource.
    ///
    /// - Parameter model: The model to write.
    /// - Returns: The resource read from the document.
    static func xmiResource(of model: Model) async throws -> Resource {
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "structural-xmi")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("model.xmi")
        switch model {
        case .machine(let name, let machine): try await roundTrip.write(machine: machine, name: name, to: url)
        case .arrangement(let arrangement): try await roundTrip.write(arrangement: arrangement, to: url)
        }
        var diagnostics = ConversionDiagnostics()
        return try await roundTrip.loadResource(from: url, diagnostics: &diagnostics)
    }

    /// Decode the structural model at the root of a resource.
    ///
    /// - Parameter resource: The resource that holds a structural machine or arrangement.
    /// - Returns: The decoded model.
    static func decode(_ resource: Resource) async throws -> Model {
        let metamodel = try await LLFSMMetamodel()
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let arrangement = roots.first(where: { $0.eClass.name == metamodel.arrangementClass.name }) {
            return .arrangement(try await ArrangementEcoreCodec(metamodel: metamodel).decode(arrangement, from: resource))
        }
        let machine = try #require(roots.first { $0.eClass.name == metamodel.machineClass.name })
        let decoded = try await MachineEcoreCodec(metamodel: metamodel).decode(machine, from: resource)
        return .machine(decoded.name, decoded.machine)
    }

    /// The files of the bundle that the structural templates write for a model.
    ///
    /// - Parameters:
    ///   - model: The model to write.
    ///   - name: The name of the bundle.
    ///   - format: The output format.
    /// - Returns: The file contents by path within the bundle.
    static func files(of model: Model, named name: String, format: Format) async throws -> [String: Data] {
        switch model {
        case .machine(_, let machine):
            return try await TemplateBinding.make(for: machine, named: name, format: format, isSuspensible: true).files
        case .arrangement(let arrangement):
            return try await TemplateBinding.make(
                for: arrangement, named: name, format: format, isSuspensible: true).files
        }
    }

    // MARK: - Expected Differences

    /// The names of the files of a machine bundle that hold its layouts.
    static let layoutFiles: Set<String> = ["Layout.plist", "WindowLayout.plist"]

    /// A model without the layouts of its machines, as the sectioned level gives it back.
    ///
    /// - Parameter model: The original model.
    /// - Returns: A copy of the model whose machines have no state, transition or window layouts.
    static func withoutLayouts(_ model: Model) -> Model {
        switch model {
        case .machine(let name, let machine):
            return .machine(name, withoutLayouts(machine))
        case .arrangement(let arrangement):
            let instances = arrangement.namedInstances.map {
                Instance(name: $0.name, typeFile: $0.typeFile, machine: withoutLayouts($0.machine))
            }
            return .arrangement(Arrangement(namedInstances: instances))
        }
    }

    /// A copy of a machine without its layouts.
    private static func withoutLayouts(_ machine: Machine) -> Machine {
        let result = Machine(copying: machine)
        result.stateLayout = [:]
        result.transitionLayout = [:]
        result.windowLayout = nil
        return result
    }
}
