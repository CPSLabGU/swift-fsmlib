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
    case name, boilerplate, stateBoilerplates, state
}

/// Reads the machine declarations of a structural model that the typing
/// pass needs, and the boilerplate that no sectioned element holds.
struct StructuralDeclarations {
    /// The structural metamodel.
    let metamodel: LLFSMMetamodel

    /// What a structural model declares.
    struct Declarations {
        /// The variable declarations of each machine, by machine name.
        var variables: [String: String] = [:]
        /// The warnings for boilerplate that is left out.
        var diagnostics = TransformationDiagnostics()
    }

    /// The feature of a boilerplate that holds its variable declarations.
    private static let variablesFeature = feature(of: .variables)

    /// The feature of a boilerplate that holds its include path.
    private static let includePathFeature = feature(of: .includePath)

    /// The name of the feature that holds a boilerplate section.
    private static func feature(of section: StandardBoilerplateSection) -> String {
        MachineEcoreCodec.boilerplateFeatures.first { $0.0 == section }?.1 ?? section.rawValue
    }

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

    /// Read the declarations of the machines of a structural model.
    ///
    /// Only the first machine of each name is read, as the transformation
    /// keeps one machine per name.
    ///
    /// - Parameter resource: The resource that holds the structural model.
    /// - Returns: The variable declarations and the warnings.
    func read(_ resource: Resource) async -> Declarations {
        var declarations = Declarations()
        for case let machine as DynamicEObject in await resource.getAllObjectsIncludingContents()
        where Self.matches(machine.eClass, metamodel.machineClass) {
            guard let name = await resource.eGet(objectId: machine.id, feature: StructuralFeature.name.rawValue)
                    as? String, declarations.variables[name] == nil else { continue }
            let boilerplate = ModelReferences.identifier(
                from: await resource.eGet(objectId: machine.id, feature: StructuralFeature.boilerplate.rawValue))
            var variables = ""
            if let boilerplate {
                variables = await resource.eGet(objectId: boilerplate, feature: Self.variablesFeature) as? String ?? ""
                await diagnoseIncludePath(of: boilerplate, owner: name, in: resource, into: &declarations.diagnostics)
            }
            declarations.variables[name] = variables
            let entries = ModelReferences.identifiers(
                from: await resource.eGet(objectId: machine.id, feature: StructuralFeature.stateBoilerplates.rawValue))
            for entry in entries {
                guard let stateBoilerplate = ModelReferences.identifier(
                    from: await resource.eGet(objectId: entry, feature: StructuralFeature.boilerplate.rawValue))
                else { continue }
                let state = ModelReferences.identifier(
                    from: await resource.eGet(objectId: entry, feature: StructuralFeature.state.rawValue))
                let stateName = await state.asyncMap {
                    await resource.eGet(objectId: $0, feature: StructuralFeature.name.rawValue) as? String
                } ?? nil
                await diagnoseIncludePath(
                    of: stateBoilerplate, owner: stateName ?? name, in: resource, into: &declarations.diagnostics)
            }
        }
        return declarations
    }

    /// Record a warning if a boilerplate has an include path, which no sectioned element holds.
    private func diagnoseIncludePath(
        of boilerplate: EUUID,
        owner: String,
        in resource: Resource,
        into diagnostics: inout TransformationDiagnostics
    ) async {
        let path = await resource.eGet(objectId: boilerplate, feature: Self.includePathFeature) as? String ?? ""
        if !path.isEmpty {
            diagnostics.record(.droppedText(section: Self.includePathFeature, owner: owner))
        }
    }
}

private extension Optional {
    /// The result of an asynchronous transformation of the wrapped value.
    func asyncMap<T>(_ transform: (Wrapped) async -> T) async -> T? {
        guard let value = self else { return nil }
        return await transform(value)
    }
}
