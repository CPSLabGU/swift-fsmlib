//
//  KernelModelBuilder.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// Builds kernel and sectioned models as dynamic objects for tests.
///
/// Every method creates objects from the class handles of the metamodels,
/// attaches them to their container and returns their identifiers. Nothing
/// is derived or computed: the builder records exactly what a test states.
/// ``resource(in:uri:)`` registers the objects with a new resource.
final class KernelModelBuilder {
    /// The kernel metamodel whose classes are instantiated.
    let kernel: KernelMetamodel

    /// The sectioned metamodel whose classes are instantiated.
    let sectioned: SectionedMetamodel

    /// The objects created so far, by identifier.
    private(set) var objects: [EUUID: DynamicEObject] = [:]

    /// The identifiers of the objects in creation order.
    private var order: [EUUID] = []

    /// The identifier of the root object, set by the first arrangement created.
    private(set) var root: EUUID?

    /// Create a builder for the metamodel family.
    init(metamodels: LLFSMMetamodels) {
        kernel = metamodels.kernel
        sectioned = metamodels.sectioned
    }

    /// Create a builder with freshly loaded metamodels.
    static func make() async throws -> KernelModelBuilder {
        KernelModelBuilder(metamodels: try await LLFSMMetamodels())
    }

    // MARK: - Primitive Operations

    /// Create an object of a class with the given feature values.
    @discardableResult
    func make(_ eClass: EClass, _ values: [(LLFSMFeature, any EcoreValue)] = []) -> EUUID {
        var object = DynamicEObject(eClass: eClass)
        for (feature, value) in values { object.eSet(feature.rawValue, value: value) }
        objects[object.id] = object
        order.append(object.id)
        return object.id
    }

    /// Set a feature of an object.
    func set(_ identifier: EUUID, _ feature: LLFSMFeature, _ value: (any EcoreValue)?) {
        objects[identifier]?.eSet(feature.rawValue, value: value)
    }

    /// Remove the value of a feature of an object.
    func unset(_ identifier: EUUID, _ feature: LLFSMFeature) {
        objects[identifier]?.eUnset(feature.rawValue)
    }

    /// Append an identifier to a many-valued reference of an object.
    func append(_ identifier: EUUID, _ feature: LLFSMFeature, _ child: EUUID) {
        let current = objects[identifier]?.identifiers(feature) ?? []
        set(identifier, feature, current + [child])
    }

    /// Register the objects with a new resource whose root is the first arrangement.
    func resource(in resourceSet: ResourceSet, uri: String = "memory:/model.xmi") async -> Resource {
        let resource = await resourceSet.createResource(uri: uri)
        for identifier in order where identifier != root {
            if let object = objects[identifier] { await resource.register(object) }
        }
        if let root, let object = objects[root] { await resource.add(object) }
        return resource
    }

    /// Register the objects with a new resource in a resource set that knows the metamodels.
    func resource(uri: String = "memory:/model.xmi") async -> Resource {
        let resourceSet = ResourceSet()
        await kernel.register(in: resourceSet)
        return await resource(in: resourceSet, uri: uri)
    }

    // MARK: - Structure

    /// Create the kernel arrangement, which becomes the root.
    @discardableResult
    func arrangement(_ name: String) -> EUUID {
        let identifier = make(kernel.arrangementClass, [(.name, name)])
        if root == nil { root = identifier }
        return identifier
    }

    /// Create a machine definition in an arrangement.
    @discardableResult
    func machine(_ name: String, in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.machineClass, [(.name, name)])
        append(arrangement, .machines, identifier)
        return identifier
    }

    /// Create a kernel state in a machine.
    @discardableResult
    func state(_ name: String, in machine: EUUID, passThrough: Bool = false) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.name, name)]
        if passThrough { values.append((.passThrough, true)) }
        let identifier = make(kernel.stateClass, values)
        append(machine, .states, identifier)
        return identifier
    }

    /// Set the initial state of a machine.
    func initial(_ state: EUUID, of machine: EUUID) {
        set(machine, .initial, state)
    }

    /// Create a transition of a state with a label.
    @discardableResult
    func transition(from state: EUUID, to target: EUUID, when label: EUUID) -> EUUID {
        let identifier = make(kernel.transitionClass, [(.label, label), (.target, target)])
        append(state, .transitions, identifier)
        return identifier
    }

    /// Append statements to the action of a kernel state.
    func action(_ state: EUUID, _ statements: EUUID...) {
        for statement in statements { append(state, .actions, statement) }
    }

    /// Create an instance of a machine in an arrangement.
    @discardableResult
    func instance(_ name: String, of machine: EUUID, in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.instanceClass, [(.name, name), (.machine, machine)])
        append(arrangement, .instances, identifier)
        return identifier
    }

    /// Create a binding of a variable to a value for an instance.
    @discardableResult
    func binding(_ variable: EUUID, to value: EUUID, for instance: EUUID) -> EUUID {
        let identifier = make(kernel.bindingClass, [(.variable, variable), (.value, value)])
        append(instance, .bindings, identifier)
        return identifier
    }

    // MARK: - Types, Variables and Functions

    /// Create the Boolean type in an arrangement.
    @discardableResult
    func booleanType(_ name: String = "Bool", in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.booleanTypeClass, [(.name, name)])
        append(arrangement, .types, identifier)
        return identifier
    }

    /// Create a bounded integer type in an arrangement.
    @discardableResult
    func integerType(_ name: String, _ range: ClosedRange<Int>, in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.integerTypeClass, [
            (.name, name), (.lower, range.lowerBound), (.upper, range.upperBound),
        ])
        append(arrangement, .types, identifier)
        return identifier
    }

    /// Create an enumeration type in an arrangement.
    @discardableResult
    func enumerationType(_ name: String, _ literals: [String], in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.enumerationTypeClass, [(.name, name), (.literals, literals)])
        append(arrangement, .types, identifier)
        return identifier
    }

    /// Create an array type in an arrangement.
    @discardableResult
    func arrayType(_ name: String, of element: EUUID, size: Int, in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.arrayTypeClass, [(.name, name), (.element, element), (.size, size)])
        append(arrangement, .types, identifier)
        return identifier
    }

    /// Create an opaque host-language type in an arrangement.
    @discardableResult
    func opaqueType(_ name: String, text: String, in arrangement: EUUID) -> EUUID {
        let identifier = make(kernel.opaqueTypeClass, [(.name, name), (.text, text)])
        append(arrangement, .types, identifier)
        return identifier
    }

    /// Create a variable in an arrangement (shared) or a machine (local).
    @discardableResult
    func variable(
        _ name: String,
        _ type: EUUID,
        in owner: EUUID,
        external: Bool = false,
        initialValue: EUUID? = nil
    ) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.name, name), (.type, type)]
        if external { values.append((.external, true)) }
        if let initialValue { values.append((.initialValue, initialValue)) }
        let identifier = make(kernel.variableClass, values)
        append(owner, .variables, identifier)
        return identifier
    }

    /// Create a function declaration in an arrangement or a machine.
    @discardableResult
    func function(
        _ name: String,
        in owner: EUUID,
        pure: Bool = false,
        parameters: [(String, EUUID)] = [],
        result: EUUID? = nil,
        receiverType: EUUID? = nil
    ) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.name, name)]
        if pure { values.append((.pure, true)) }
        if let result { values.append((.result, result)) }
        if let receiverType { values.append((.receiverType, receiverType)) }
        let identifier = make(kernel.functionDeclarationClass, values)
        for (parameterName, type) in parameters {
            append(identifier, .parameters, make(kernel.parameterClass, [(.name, parameterName), (.type, type)]))
        }
        append(owner, .functions, identifier)
        return identifier
    }

    /// Create host declarations in an arrangement or a machine.
    @discardableResult
    func hostDeclarations(in owner: EUUID, language: String, includes: String, declarations: String = "") -> EUUID {
        let identifier = make(kernel.hostDeclarationsClass, [
            (.language, language), (.includes, includes), (.declarations, declarations),
        ])
        append(owner, .hostDeclarations, identifier)
        return identifier
    }

    // MARK: - Expressions

    /// Create a Boolean literal.
    func bool(_ value: Bool) -> EUUID {
        make(kernel.booleanLiteralClass, [(.value, value)])
    }

    /// Create an integer literal.
    func int(_ value: Int) -> EUUID {
        make(kernel.integerLiteralClass, [(.value, value)])
    }

    /// Create an enumeration literal.
    func literal(_ literal: String, of type: EUUID) -> EUUID {
        make(kernel.enumerationLiteralClass, [(.type, type), (.literal, literal)])
    }

    /// Create a variable reference, optionally indexed.
    func ref(_ variable: EUUID, index: EUUID? = nil) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.variable, variable)]
        if let index { values.append((.index, index)) }
        return make(kernel.variableReferenceClass, values)
    }

    /// Create a unary expression.
    func unary(_ operation: KernelUnaryOperation, _ operand: EUUID) -> EUUID {
        make(kernel.unaryExpressionClass, [(.operation, operation.rawValue), (.operand, operand)])
    }

    /// Create a binary expression.
    func binary(_ operation: KernelBinaryOperation, _ left: EUUID, _ right: EUUID) -> EUUID {
        make(kernel.binaryExpressionClass, [(.operation, operation.rawValue), (.left, left), (.right, right)])
    }

    /// Create a conditional expression.
    func conditional(_ condition: EUUID, _ whenTrue: EUUID, _ whenFalse: EUUID) -> EUUID {
        make(kernel.conditionalExpressionClass, [
            (.condition, condition), (.whenTrue, whenTrue), (.whenFalse, whenFalse),
        ])
    }

    /// Create an observation that an instance occupies a kernel state.
    func inState(_ instance: EUUID, _ state: EUUID) -> EUUID {
        make(kernel.inStateExpressionClass, [(.instance, instance), (.state, state)])
    }

    /// Create a call of a declared function.
    func call(_ function: EUUID, _ arguments: [EUUID] = [], receiver: EUUID? = nil) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.function, function)]
        if !arguments.isEmpty { values.append((.arguments, arguments)) }
        if let receiver { values.append((.receiver, receiver)) }
        return make(kernel.callExpressionClass, values)
    }

    /// Create an opaque host-language expression.
    func opaqueExpression(_ text: String, type: EUUID? = nil) -> EUUID {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.text, text)]
        if let type { values.append((.type, type)) }
        return make(kernel.opaqueExpressionClass, values)
    }

    // MARK: - Statements

    /// Create an assignment.
    func assign(_ target: EUUID, _ value: EUUID) -> EUUID {
        make(kernel.assignmentClass, [(.target, target), (.value, value)])
    }

    /// Create a print statement.
    func printLine(_ text: String, _ values: [EUUID] = []) -> EUUID {
        var features: [(LLFSMFeature, any EcoreValue)] = [(.text, text)]
        if !values.isEmpty { features.append((.values, values)) }
        return make(kernel.printClass, features)
    }

    /// Create a call statement.
    func perform(_ call: EUUID) -> EUUID {
        make(kernel.callStatementClass, [(.call, call)])
    }

    /// Create an opaque host-language statement.
    func opaqueStatement(_ text: String) -> EUUID {
        make(kernel.opaqueStatementClass, [(.text, text)])
    }

    // MARK: - Sectioned Models

    /// Create the sectioned arrangement, which becomes the root.
    @discardableResult
    func sectionedArrangement(_ name: String) -> EUUID {
        let identifier = make(sectioned.arrangementClass, [(.name, name)])
        if root == nil { root = identifier }
        return identifier
    }

    /// Create a sectioned machine in a sectioned arrangement.
    @discardableResult
    func sectionedMachine(_ name: String, in arrangement: EUUID) -> EUUID {
        let identifier = make(sectioned.machineClass, [(.name, name)])
        append(arrangement, .machines, identifier)
        return identifier
    }

    /// Create a sectioned state in a sectioned machine.
    @discardableResult
    func sectionedState(_ name: String, in machine: EUUID) -> EUUID {
        let identifier = make(sectioned.stateClass, [(.name, name)])
        append(machine, .states, identifier)
        return identifier
    }

    /// Append statements to a section of a sectioned state.
    func section(_ section: LLFSMFeature, of state: EUUID, _ statements: EUUID...) {
        for statement in statements { append(state, section, statement) }
    }

    /// Create a transition between sectioned states.
    @discardableResult
    func sectionedTransition(from state: EUUID, to target: EUUID, when label: EUUID) -> EUUID {
        let identifier = make(sectioned.transitionClass, [(.label, label), (.target, target)])
        append(state, .transitions, identifier)
        return identifier
    }

    /// Create an instance of a sectioned machine.
    @discardableResult
    func sectionedInstance(_ name: String, of machine: EUUID, in arrangement: EUUID) -> EUUID {
        let identifier = make(sectioned.instanceClass, [(.name, name), (.machine, machine)])
        append(arrangement, .instances, identifier)
        return identifier
    }

    /// Create a state-time expression.
    func stateTime(_ unit: SectionedTimeUnit) -> EUUID {
        make(sectioned.stateTimeExpressionClass, [(.unit, unit.rawValue)])
    }

    /// Create an observation that an instance occupies a sectioned state.
    func sectionedInState(_ instance: EUUID, _ state: EUUID) -> EUUID {
        make(sectioned.inStateExpressionClass, [(.instance, instance), (.state, state)])
    }

    /// Create a machine control statement.
    func control(_ operation: SectionedControlOperation, _ instance: EUUID) -> EUUID {
        make(sectioned.machineControlStatementClass, [(.operation, operation.rawValue), (.instance, instance)])
    }
}
