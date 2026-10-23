//
//  SectionedEncodingDiagnostics.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// Determines what the encoding of a sectioned model into the kernel cannot keep.
struct SectionedEncodingDiagnostics {
    /// The metamodels that type the sectioned model.
    let metamodels: LLFSMMetamodels

    /// The warnings that the encoding of a sectioned model under some options incurs.
    ///
    /// - Parameters:
    ///   - resource: The resource whose root is a sectioned arrangement.
    ///   - options: The options of the encoding.
    /// - Returns: The warnings, in model order.
    func diagnose(_ resource: Resource, options: SectionedToKernelOptions) async -> TransformationDiagnostics {
        var diagnostics = TransformationDiagnostics()
        let index = await KernelModelIndex(resource: resource)
        let sectioned = metamodels.sectioned
        let objects = index.order.compactMap { index.object($0) }
        let machines = objects.filter { $0.eClass.id == sectioned.machineClass.id }
        let instances = objects.filter { $0.eClass.id == sectioned.instanceClass.id }
        for machine in machines where index.objects(.states, of: machine).contains(where: {
            !index.objects(.hostDeclarations, of: $0).isEmpty
        }) {
            diagnostics.record(.notRecovered(.stateBoilerplate, owner: machine.string(.name) ?? ""))
        }
        var suspensible = Set<EUUID>()
        for machine in machines where machine.identifier(.suspendState) != nil {
            let name = machine.string(.name) ?? ""
            guard options.suspension == .encode else {
                diagnostics.record(.suspensionOmitted(machine: name))
                continue
            }
            suspensible.insert(machine.id)
            let names = instances.filter { $0.identifier(.machine) == machine.id }.compactMap { $0.string(.name) }
            if names.count > 1 {
                diagnostics.record(.sharedSuspension(machine: name, instances: names))
            }
        }
        for control in objects where control.eClass.id == sectioned.machineControlStatementClass.id {
            let operation = control.string(.operation) ?? SectionedControlOperation.suspend.rawValue
            let instance = index.object(control.identifier(.instance))
            let isEncoded = operation != SectionedControlOperation.restart.rawValue
                && instance.flatMap { $0.identifier(.machine) }.map(suspensible.contains) == true
            if !isEncoded {
                diagnostics.record(.controlDropped(operation: operation, instance: instance?.string(.name) ?? ""))
            }
        }
        return diagnostics
    }
}
