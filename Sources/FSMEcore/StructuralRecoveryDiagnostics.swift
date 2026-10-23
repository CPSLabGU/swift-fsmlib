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
/// The sectioned level keeps neither include paths nor layouts, merges the
/// boilerplate of states into the host declarations of their machine, and
/// keeps recognised variable declarations without their layout or comments.
/// A structural model has no place for the shared declarations of an
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
            diagnostics.record(.notRecovered(.includePath, owner: name))
            diagnostics.record(.notRecovered(.layout, owner: name))
            let hosts = index.objects(.hostDeclarations, of: machine)
            let withIncludes = hosts.filter { $0.string(.includes) != nil }.count
            if withIncludes > 1 || hosts.count - withIncludes > 1 {
                diagnostics.record(.notRecovered(.stateBoilerplate, owner: name))
            }
            if !index.objects(.variables, of: machine).isEmpty {
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
}
