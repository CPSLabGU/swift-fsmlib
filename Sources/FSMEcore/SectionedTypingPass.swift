//
//  SectionedTypingPass.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The expression typing scopes that the typing pass builds from sectioned and kernel models.
extension ExpressionTyper.Scope {
    /// The scope of a sectioned or kernel machine.
    ///
    /// The scope lists the local variables and functions of the machine
    /// before the shared variables and functions of the arrangement that
    /// contains it, so that locals take precedence.
    ///
    /// - Parameters:
    ///   - machine: The identifier of the machine.
    ///   - resource: The resource that holds the machine and its arrangement.
    ///   - metamodel: The kernel metamodel that types the declarations.
    /// - Returns: The scope, empty if the machine is not part of the resource.
    public init(machine: EUUID, in resource: Resource, metamodel: KernelMetamodel) async {
        let index = await KernelModelIndex(resource: resource)
        self.init(machine: machine, index: index, metamodel: metamodel)
    }

    /// The scope of a machine within an indexed model.
    init(machine identifier: EUUID, index: KernelModelIndex, metamodel: KernelMetamodel) {
        self.init()
        guard let machine = index.object(identifier) else { return }
        let owners = [machine] + [index.container(of: identifier)].compactMap { $0 }
        for owner in owners {
            for variable in index.objects(.variables, of: owner) {
                guard let name = variable.string(.name),
                      let type = Self.valueType(of: index.target(.type, of: variable), index: index, metamodel: metamodel)
                else { continue }
                variables.append(ExpressionTyper.Variable(name: name, identifier: variable.id, type: type))
            }
            for function in index.objects(.functions, of: owner) {
                guard let typed = Self.typedFunction(function, index: index, metamodel: metamodel) else { continue }
                functions.append(typed)
            }
        }
    }

    /// The typed signature of a function declaration.
    ///
    /// - Parameters:
    ///   - function: The function declaration.
    ///   - index: The index of the model that holds the declaration.
    ///   - metamodel: The kernel metamodel that types the declaration.
    /// - Returns: The signature, or `nil` if the function is unnamed or any of its types is unsupported.
    private static func typedFunction(
        _ function: DynamicEObject,
        index: KernelModelIndex,
        metamodel: KernelMetamodel
    ) -> ExpressionTyper.Function? {
        guard let name = function.string(.name) else { return nil }
        var parameters: [ExpressionTyper.ValueType] = []
        for parameter in index.objects(.parameters, of: function) {
            guard let type = Self.valueType(
                of: index.target(.type, of: parameter),
                index: index,
                metamodel: metamodel
            ) else { return nil }
            parameters.append(type)
        }
        let resultObject = index.target(.result, of: function)
        let result = Self.valueType(of: resultObject, index: index, metamodel: metamodel)
        guard resultObject == nil || result != nil else { return nil }
        let receiverObject = index.target(.receiverType, of: function)
        let receiver = Self.valueType(of: receiverObject, index: index, metamodel: metamodel)
        guard receiverObject == nil || receiver != nil else { return nil }
        return ExpressionTyper.Function(
            name: name,
            identifier: function.id,
            parameters: parameters,
            result: result,
            receiverType: receiver,
            isPure: function.bool(.pure)
        )
    }

    /// The value type that a kernel type declaration denotes.
    static func valueType(
        of type: DynamicEObject?,
        index: KernelModelIndex,
        metamodel: KernelMetamodel
    ) -> ExpressionTyper.ValueType? {
        guard let type else { return nil }
        if metamodel.isKind(type.eClass, of: metamodel.booleanTypeClass) { return .boolean }
        if metamodel.isKind(type.eClass, of: metamodel.integerTypeClass) { return .integer }
        if metamodel.isKind(type.eClass, of: metamodel.enumerationTypeClass) { return .enumeration(type.id) }
        if metamodel.isKind(type.eClass, of: metamodel.opaqueTypeClass) { return .opaque(type.id) }
        if metamodel.isKind(type.eClass, of: metamodel.arrayTypeClass),
           let element = valueType(of: index.target(.element, of: type), index: index, metamodel: metamodel) {
            if case .array = element { return nil }
            return .array(type.id, element: element)
        }
        return nil
    }
}

/// Types the opaque labels and sections of a sectioned model that the
/// structural transformation produced.
///
/// The pass declares the variables that ``VariableDeclarationScanner``
/// recognises in the machine variables, records the line, text and comment
/// of each declaration in its variable, removes their lines from the host
/// declarations, and replaces every opaque label and section that
/// ``ExpressionTyper`` types. Sections that hold only white space stay
/// opaque, so that their text is kept.
struct SectionedTypingPass {
    /// The metamodels that type the sectioned model.
    let metamodels: LLFSMMetamodels

    /// The kernel level.
    private var kernel: KernelMetamodel { metamodels.kernel }

    /// The section features of sectioned states.
    static let sections: [LLFSMFeature] = [.onEntry, .onExit, .internal, .onSuspend, .onResume]

    /// Type a sectioned model.
    ///
    /// - Parameters:
    ///   - resource: The resource whose root is the sectioned arrangement.
    ///   - variables: The variable declarations of each machine, by machine name.
    func run(on resource: Resource, variables: [String: String]) async {
        var index = await KernelModelIndex(resource: resource)
        guard let arrangement = index.roots.first.flatMap(index.object) else { return }
        for machine in index.objects(.machines, of: arrangement) {
            if let text = machine.string(.name).flatMap({ variables[$0] }) {
                await declare(text, in: machine, of: arrangement, index: index, resource: resource)
            }
        }
        index = await KernelModelIndex(resource: resource)
        for machine in index.objects(.machines, of: arrangement) {
            let language = machine.string(.language) ?? ""
            let typer = ExpressionTyper(
                language: language, scope: ExpressionTyper.Scope(machine: machine.id, index: index, metamodel: kernel))
            for state in index.objects(.states, of: machine) {
                await type(state, with: typer, index: index, resource: resource)
            }
        }
    }

    /// Declare the variables recognised in the declarations of a machine.
    private func declare(
        _ text: String,
        in machine: DynamicEObject,
        of arrangement: DynamicEObject,
        index: KernelModelIndex,
        resource: Resource
    ) async {
        let language = machine.string(.language) ?? ""
        let scan = VariableDeclarationScanner(language: language).scan(text)
        guard !scan.declarations.isEmpty else { return }
        var types: [String: EUUID] = [:]
        var typeIDs = arrangement.identifiers(.types)
        for type in index.objects(.types, of: arrangement) {
            if let name = type.string(.name) { types[name] = type.id }
        }
        func typeID(for scanned: ScannedType) async -> EUUID {
            if let existing = types[scanned.name] { return existing }
            var type: DynamicEObject
            switch scanned {
            case .boolean(let name):
                type = DynamicEObject(eClass: kernel.booleanTypeClass)
                type.eSet(LLFSMFeature.name.rawValue, value: name)
            case .integer(let name, let range):
                type = DynamicEObject(eClass: kernel.integerTypeClass)
                type.eSet(LLFSMFeature.name.rawValue, value: name)
                type.eSet(LLFSMFeature.lower.rawValue, value: range.lowerBound)
                type.eSet(LLFSMFeature.upper.rawValue, value: range.upperBound)
            case .array(let element, let size):
                let elementID = await typeID(for: element)
                type = DynamicEObject(eClass: kernel.arrayTypeClass)
                type.eSet(LLFSMFeature.name.rawValue, value: scanned.name)
                type.eSet(LLFSMFeature.element.rawValue, value: elementID)
                type.eSet(LLFSMFeature.size.rawValue, value: size)
            }
            await resource.register(type)
            types[scanned.name] = type.id
            typeIDs.append(type.id)
            return type.id
        }
        var variableIDs = machine.identifiers(.variables)
        for (declaration, placement) in zip(scan.declarations, scan.placements) {
            var variable = DynamicEObject(eClass: kernel.variableClass)
            variable.eSet(LLFSMFeature.name.rawValue, value: declaration.name)
            variable.eSet(LLFSMFeature.type.rawValue, value: await typeID(for: declaration.type))
            variable.eSet(LLFSMFeature.documentation.rawValue, value: placement.documentation)
            variable.eSet(LLFSMFeature.declarationText.rawValue, value: placement.text)
            variable.eSet(LLFSMFeature.declarationLine.rawValue, value: placement.line)
            await resource.register(variable)
            variableIDs.append(variable.id)
        }
        _ = await resource.eSet(objectId: arrangement.id, feature: LLFSMFeature.types.rawValue, value: typeIDs)
        _ = await resource.eSet(objectId: machine.id, feature: LLFSMFeature.variables.rawValue, value: variableIDs)
        guard let host = index.objects(.hostDeclarations, of: machine)
            .first(where: { $0.string(.declarations) == text }) else { return }
        _ = await resource.eSet(
            objectId: host.id,
            feature: LLFSMFeature.declarations.rawValue,
            value: scan.remainderLineCount == 0 ? nil : scan.remainder
        )
    }

    /// Replace the opaque sections and labels of a state that the typer types.
    private func type(
        _ state: DynamicEObject,
        with typer: ExpressionTyper,
        index: KernelModelIndex,
        resource: Resource
    ) async {
        let builder = TypedNodeBuilder(metamodel: metamodels.sectioned, resource: resource)
        for section in Self.sections {
            let statements = index.objects(section, of: state)
            guard statements.count == 1, let opaque = statements.first,
                  opaque.eClass.id == kernel.opaqueStatementClass.id,
                  let text = opaque.string(.text), !text.allSatisfy(\.isWhitespace),
                  let typed = typer.typedStatements(from: text) else { continue }
            var identifiers: [EUUID] = []
            for statement in typed { identifiers.append(await builder.make(statement).id) }
            _ = await resource.eSet(
                objectId: state.id, feature: section.rawValue, value: identifiers.isEmpty ? nil : identifiers)
            await resource.remove(id: opaque.id)
        }
        for transition in index.objects(.transitions, of: state) {
            guard let label = index.target(.label, of: transition),
                  label.eClass.id == kernel.opaqueExpressionClass.id,
                  let typed = typer.typedCondition(from: label.string(.text) ?? "") else { continue }
            let replacement = await builder.make(typed)
            _ = await resource.eSet(objectId: transition.id, feature: LLFSMFeature.label.rawValue, value: replacement.id)
            await resource.remove(id: label.id)
        }
    }
}
