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

    /// The model that a round trip is expected to give back.
    ///
    /// Each documented loss is applied to a copy of the original: include
    /// paths and layouts are dropped, sections and boilerplate that hold
    /// only white space become empty, the boilerplate of the states is
    /// merged into the machine boilerplate as host declarations are,
    /// recognised variable declarations are written in canonical form after
    /// the remaining declarations of the machine, the transitions are listed
    /// state by state, and every instance of an arrangement holds a copy of
    /// the first machine of its type.
    ///
    /// - Parameter model: The original model.
    /// - Returns: The expected model.
    static func expected(_ model: Model) -> Model {
        switch model {
        case .machine(let name, let machine):
            return .machine(name, expected(machine))
        case .arrangement(let arrangement):
            var definitions: [Substring: Machine] = [:]
            let instances = arrangement.namedInstances.map { instance -> Instance in
                let definition = definitions[instance.typeName] ?? expected(instance.machine)
                definitions[instance.typeName] = definition
                return Instance(name: instance.name, typeFile: instance.typeFile, machine: Machine(copying: definition))
            }
            return .arrangement(Arrangement(namedInstances: instances))
        }
    }

    /// Whether a text holds more than white space, as the transformations decide.
    private static func isPresent(_ text: String?) -> Bool {
        !(text ?? "").allSatisfy(\.isWhitespace)
    }

    /// Two texts one after the other, on separate lines unless the first ends a line.
    private static func joined(_ texts: [String]) -> String {
        texts.reduce("") { first, second in
            if first.isEmpty { return second }
            if second.isEmpty || first.hasSuffix("\n") { return first + second }
            return first + "\n" + second
        }
    }

    /// The canonical declaration of a recognised variable in the C family.
    private static func declaration(_ declaration: VariableDeclarationScanner.Declaration) -> String {
        switch declaration.type {
        case .array(let element, let size): return "\(element.name)\t\(declaration.name)[\(size)];\n"
        default: return "\(declaration.type.name)\t\(declaration.name);\n"
        }
    }

    /// The machine that a round trip of a structural machine is expected to give back.
    private static func expected(_ machine: Machine) -> Machine {
        let language = machine.language
        let result = Machine(copying: machine)
        result.stateLayout = [:]
        result.transitionLayout = [:]
        result.windowLayout = nil
        let states = machine.llfsm.states
        var boilerplates = [language.extractSections(from: machine.boilerplate)]
        for state in states {
            let name = machine.llfsm.stateName(for: state) ?? ""
            boilerplates.append(machine.stateBoilerplate[state].map {
                language.extractStateSections(from: $0, stateName: name)
            } ?? [:])
        }
        var hosts: [(includes: String?, declarations: String?)] = []
        for sections in boilerplates {
            if isPresent(sections[.includes]) || isPresent(sections[.variables]) {
                hosts.append((sections[.includes], sections[.variables]))
            }
            if isPresent(sections[.functions]) { hosts.append((nil, sections[.functions])) }
        }
        let variables = boilerplates[0][.variables] ?? ""
        let scan = VariableDeclarationScanner(language: language.name).scan(variables)
        if !scan.declarations.isEmpty, let first = hosts.firstIndex(where: { $0.declarations == variables }) {
            if scan.remainder.isEmpty && (hosts[first].includes ?? "").allSatisfy(\.isWhitespace) {
                hosts.remove(at: first)
            } else {
                hosts[first].declarations = scan.remainder.isEmpty ? nil : scan.remainder
            }
        }
        let declarations = scan.declarations.map(declaration).joined()
        let variableHosts = hosts.filter { $0.includes != nil }
        var machineSections: [StandardBoilerplateSection: String] = [:]
        machineSections[.includes] = joined(hosts.map { $0.includes ?? "" })
        if let first = variableHosts.first {
            machineSections[.variables] = joined(
                [first.declarations ?? "", declarations] + variableHosts.dropFirst().map { $0.declarations ?? "" })
        } else {
            machineSections[.variables] = declarations
        }
        machineSections[.functions] = joined(hosts.filter { $0.includes == nil }.map { $0.declarations ?? "" })
        result.boilerplate = language.createBoilerplate(from: machineSections)
        let activities: [StandardBoilerplateSection] = [.onEntry, .onExit, .internal, .onSuspend, .onResume]
        for state in states {
            let original = machine.stateActivities(for: state)
            var sections: [StandardBoilerplateSection: String] = [:]
            for activity in activities {
                let text = original[activity] ?? ""
                sections[activity] = isPresent(text) ? text : ""
            }
            result.setStateActivities(sections, for: state)
        }
        result.llfsm.transitions = states.flatMap { machine.llfsm.transitionsFrom($0) }
        return result
    }
}
