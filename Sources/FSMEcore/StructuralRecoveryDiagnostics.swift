//
//  StructuralRecoveryDiagnostics.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// Diagnoses the structural information that a sectioned model cannot give back.
///
/// The sectioned level keeps no layouts. A machine whose host declarations
/// carry no include paths gets an empty include path; several host
/// declarations of one machine, as left by the encoding into the kernel,
/// are merged into one boilerplate; and variables without a declaration
/// text in the language of the machine are declared in canonical form. A
/// structural model has no place for the shared declarations of an
/// arrangement, for instance bindings or for machines without instances.
struct StructuralRecoveryDiagnostics {
    /// The metamodels that type the sectioned model.
    let metamodels: LLFSMMetamodels

    /// The warnings for a sectioned model that is transformed into a structural model.
    ///
    /// - Parameter resource: The resource whose root is the sectioned arrangement.
    /// - Returns: The warnings, machine by machine, then for the arrangement and its instances.
    func diagnose(_ resource: Resource) async -> TransformationDiagnostics {
        var diagnostics = TransformationDiagnostics()
        let index = await KernelModelIndex(resource: resource)
        guard let arrangement = index.roots.first.flatMap(index.object) else { return diagnostics }
        let instances = index.objects(.instances, of: arrangement)
        let instantiated = Set(instances.compactMap { index.target(.machine, of: $0)?.id })
        for machine in index.objects(.machines, of: arrangement) {
            let name = machine.string(.name) ?? ""
            guard instantiated.contains(machine.id) else {
                diagnostics.record(.notRecovered(.uninstantiatedMachine, owner: name))
                continue
            }
            let hosts = index.objects(.hostDeclarations, of: machine)
            let stateHosts = index.objects(.states, of: machine).flatMap { index.objects(.hostDeclarations, of: $0) }
            if !(hosts + stateHosts).contains(where: { $0.isSet(.includePaths) }) {
                diagnostics.record(.notRecovered(.includePath, owner: name))
            }
            diagnostics.record(.notRecovered(.layout, owner: name))
            if hosts.count > 1 {
                diagnostics.record(.notRecovered(.stateBoilerplate, owner: name))
            }
            let language = Self.language(of: machine, in: arrangement)
            let keepsTexts = hosts.first?.string(.language).map { $0.isEmpty || $0 == language } ?? true
            if index.objects(.variables, of: machine).contains(where: { !keepsTexts || !$0.isSet(.declarationText) }) {
                diagnostics.record(.notRecovered(.declarationFormatting, owner: name))
            }
        }
        let shared: [LLFSMFeature] = [.variables, .functions, .hostDeclarations]
        if shared.contains(where: { !index.objects($0, of: arrangement).isEmpty }) {
            diagnostics.record(.notRecovered(.sharedDeclarations, owner: arrangement.string(.name) ?? ""))
        }
        for instance in instances where !index.objects(.bindings, of: instance).isEmpty {
            diagnostics.record(.notRecovered(.instanceBindings, owner: instance.string(.name) ?? ""))
        }
        return diagnostics
    }

    /// The language in which the host text of a machine is written.
    ///
    /// - Parameters:
    ///   - machine: The sectioned machine.
    ///   - arrangement: The arrangement that holds the machine.
    /// - Returns: The language of the machine, else of the arrangement, else the default language.
    static func language(of machine: DynamicEObject, in arrangement: DynamicEObject) -> String {
        for owner in [machine, arrangement] {
            if let language = owner.string(.language), !language.isEmpty { return language }
        }
        return LLFSMTransformationNames.defaultLanguage
    }
}
