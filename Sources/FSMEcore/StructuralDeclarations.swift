//
//  StructuralDeclarations.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import FSM

/// The names of the structural features that the transformations read in Swift.
///
/// The raw values are the names declared in `LLFSMStructural.ecore`.
enum StructuralFeature: String, Sendable {
    /// The `name` structural feature.
    case name
    /// The `boilerplate` structural feature.
    case boilerplate
    /// The `stateBoilerplates` structural feature.
    case stateBoilerplates
    /// The `state` structural feature.
    case state
}

/// Reads the machine declarations of a structural model that the typing
/// pass needs.
struct StructuralDeclarations {
    /// The structural metamodel.
    let metamodel: LLFSMMetamodel

    /// The feature of a boilerplate that holds its variable declarations.
    private static let variablesFeature =
        MachineEcoreCodec.boilerplateFeatures.first { $0.0 == .variables }?.1 ?? StandardBoilerplateSection.variables.rawValue

    /// Whether a class is a structural class, possibly from another load of the metamodel.
    ///
    /// - Parameters:
    ///   - eClass: The class of a model object.
    ///   - structuralClass: The structural class to compare with.
    /// - Returns: `true` if both classes have the same name and features.
    static func matches(_ eClass: EClass, _ structuralClass: EClass) -> Bool {
        eClass.id == structuralClass.id || (eClass.name == structuralClass.name
            && Set(eClass.eAllStructuralFeatures.map(\.name)) == Set(structuralClass.eAllStructuralFeatures.map(\.name)))
    }

    /// Read the variable declarations of the machines of a structural model.
    ///
    /// Only the first machine of each name is read, as the transformation
    /// keeps one machine per name.
    ///
    /// - Parameter resource: The resource that holds the structural model.
    /// - Returns: The variable declarations of each machine, by machine name.
    func variables(of resource: Resource) async -> [String: String] {
        var variables: [String: String] = [:]
        for case let machine as DynamicEObject in await resource.getAllObjectsIncludingContents()
        where Self.matches(machine.eClass, metamodel.machineClass) {
            guard let name = await resource.eGet(objectId: machine.id, feature: StructuralFeature.name.rawValue)
                    as? String, variables[name] == nil else { continue }
            let boilerplate = ModelReferences.identifier(
                from: await resource.eGet(objectId: machine.id, feature: StructuralFeature.boilerplate.rawValue))
            var text = ""
            if let boilerplate {
                text = await resource.eGet(objectId: boilerplate, feature: Self.variablesFeature) as? String ?? ""
            }
            variables[name] = text
        }
        return variables
    }
}
