//
//  TypeResolver.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The static type of a typed host-language expression.
enum TypedValue: Equatable, Sendable {
    /// A Boolean value.
    case boolean
    /// An integer value.
    case integer
    /// A value of the enumeration with the given declaration.
    case enumeration(EUUID)
    /// A value of the opaque type with the given declaration.
    case opaque(EUUID)

    /// The value type of a declared scalar type, or `nil` for an array.
    init?(_ type: ExpressionTyper.ValueType) {
        switch type {
        case .boolean:
            self = .boolean
        case .integer:
            self = .integer
        case .enumeration(let identifier):
            self = .enumeration(identifier)
        case .opaque(let identifier):
            self = .opaque(identifier)
        case .array:
            return nil
        }
    }

    /// Whether values of the type can be compared, assigned and passed to each other.
    var isComparable: Bool {
        if case .opaque = self { return false }
        return true
    }
}

/// A resolved and well-typed expression, ready to become kernel objects.
indirect enum TypedNode: Equatable, Sendable {
    /// A Boolean literal.
    case boolean(Bool)
    /// An integer literal.
    case integer(Int)
    /// A read of a variable, optionally of one element.
    case variable(EUUID, index: TypedNode?)
    /// A prefix operation.
    case unary(KernelUnaryOperation, TypedNode)
    /// A binary operation.
    case binary(KernelBinaryOperation, TypedNode, TypedNode)
    /// A conditional expression.
    case conditional(TypedNode, TypedNode, TypedNode)
    /// The time elapsed since the current state was entered.
    case stateTime(SectionedTimeUnit)
    /// A call of a declared function.
    case call(EUUID, receiver: TypedNode?, arguments: [TypedNode])
}

/// A resolved and well-typed statement, ready to become kernel objects.
enum TypedStatement: Equatable, Sendable {
    /// An assignment of a value to a variable or an element.
    case assignment(target: TypedNode, value: TypedNode)
    /// A call of a declared function for its effect.
    case call(TypedNode)
    /// A line of literal output.
    case print(String)
}

/// Resolves the names of host-language expressions and checks their types.
///
/// The checks mirror the typing rule of the kernel, so that a typed result
/// is well typed in the kernel; anything that the rule rejects, or that the
/// subset cannot express, makes resolution fail.
struct TypeResolver {
    /// The syntax table of the language.
    let syntax: HostSyntax

    /// The declarations that names resolve to.
    let scope: ExpressionTyper.Scope

    /// Resolve an expression.
    ///
    /// - Parameters:
    ///   - expression: The parsed expression.
    ///   - inLabel: Whether the expression is part of a label, where only
    ///     pure functions may be called.
    /// - Returns: The typed expression and its type, or `nil`.
    func resolve(_ expression: HostExpression, inLabel: Bool) -> (TypedNode, TypedValue)? {
        switch expression {
        case .boolean(let value):
            return (.boolean(value), .boolean)
        case .integer(let value):
            return (.integer(value), .integer)
        case .name(let name, let index):
            guard let variable = scope.variable(named: name) else { return nil }
            return reference(variable, index: index, inLabel: inLabel)
        case .unary(let operation, let operand):
            guard let (node, type) = resolve(operand, inLabel: inLabel) else { return nil }
            switch operation {
            case .negation:
                return type == .boolean ? (.unary(operation, node), .boolean) : nil
            case .minus:
                return type == .integer ? (.unary(operation, node), .integer) : nil
            }
        case .binary(let operation, let left, let right):
            guard let (leftNode, leftType) = resolve(left, inLabel: inLabel),
                  let (rightNode, rightType) = resolve(right, inLabel: inLabel) else { return nil }
            let node = TypedNode.binary(operation, leftNode, rightNode)
            if operation.isLogical {
                return leftType == .boolean && rightType == .boolean ? (node, .boolean) : nil
            }
            if operation.isEquality {
                return leftType == rightType && leftType.isComparable ? (node, .boolean) : nil
            }
            guard leftType == .integer, rightType == .integer else { return nil }
            return (node, operation.isComparison ? .boolean : .integer)
        case .conditional(let condition, let whenTrue, let whenFalse):
            guard let (conditionNode, conditionType) = resolve(condition, inLabel: inLabel),
                  conditionType == .boolean,
                  let (trueNode, trueType) = resolve(whenTrue, inLabel: inLabel),
                  let (falseNode, falseType) = resolve(whenFalse, inLabel: inLabel),
                  trueType == falseType, trueType.isComparable else { return nil }
            return (.conditional(conditionNode, trueNode, falseNode), trueType)
        case .call(let name, let receiver, let arguments):
            if receiver == nil, scope.function(named: name) == nil, let unit = syntax.timeHelpers[name] {
                guard arguments.count == 1, let (limit, type) = resolve(arguments[0], inLabel: inLabel),
                      type == .integer else { return nil }
                return (.binary(.greaterThan, .stateTime(unit), limit), .boolean)
            }
            guard let (node, result) = call(name, receiver: receiver, arguments: arguments, inLabel: inLabel),
                  let result else { return nil }
            return (node, result)
        }
    }

    /// Resolve a statement.
    ///
    /// - Parameter statement: The parsed statement.
    /// - Returns: The typed statement, or `nil`.
    func resolve(_ statement: HostStatement) -> TypedStatement? {
        switch statement {
        case .print(let text):
            return .print(text)
        case .call(let expression):
            guard case .call(let name, let receiver, let arguments) = expression,
                  let (node, _) = call(name, receiver: receiver, arguments: arguments, inLabel: false)
            else { return nil }
            return .call(node)
        case .assignment(let name, let index, let value):
            guard let variable = scope.variable(named: name),
                  let (target, targetType) = reference(variable, index: index, inLabel: false),
                  targetType.isComparable,
                  let (valueNode, valueType) = resolve(value, inLabel: false),
                  valueType == targetType else { return nil }
            return .assignment(target: target, value: valueNode)
        }
    }

    /// Resolve a read of a variable or of one of its elements.
    private func reference(
        _ variable: ExpressionTyper.Variable,
        index: HostExpression?,
        inLabel: Bool
    ) -> (TypedNode, TypedValue)? {
        guard let index else {
            guard let type = TypedValue(variable.type), type.isComparable else { return nil }
            return (.variable(variable.identifier, index: nil), type)
        }
        guard case .array(_, let element) = variable.type, let elementType = TypedValue(element),
              let (indexNode, indexType) = resolve(index, inLabel: inLabel), indexType == .integer
        else { return nil }
        return (.variable(variable.identifier, index: indexNode), elementType)
    }

    /// Resolve a call of a declared function.
    ///
    /// - Returns: The call and the type of its result (`nil` inside the
    ///   pair for a function without a result), or `nil` if the call does
    ///   not resolve.
    private func call(
        _ name: String,
        receiver: HostExpression?,
        arguments: [HostExpression],
        inLabel: Bool
    ) -> (TypedNode, TypedValue?)? {
        guard let function = scope.function(named: name), !inLabel || function.isPure,
              function.parameters.count == arguments.count else { return nil }
        var argumentNodes: [TypedNode] = []
        for (argument, parameter) in zip(arguments, function.parameters) {
            guard let parameterType = TypedValue(parameter), parameterType.isComparable,
                  let (node, type) = resolve(argument, inLabel: inLabel), type == parameterType
            else { return nil }
            argumentNodes.append(node)
        }
        var receiverNode: TypedNode?
        switch (receiver, function.receiverType) {
        case (nil, nil):
            break
        case (.name(let receiverName, nil), let expected?):
            guard let variable = scope.variable(named: receiverName), variable.type == expected else { return nil }
            receiverNode = .variable(variable.identifier, index: nil)
        default:
            return nil
        }
        var result: TypedValue?
        if let declared = function.result {
            guard let value = TypedValue(declared), value.isComparable else { return nil }
            result = value
        }
        return (.call(function.identifier, receiver: receiverNode, arguments: argumentNodes), result)
    }
}

/// Creates the kernel objects of typed and opaque nodes in a resource.
struct TypedNodeBuilder {
    /// The sectioned metamodel whose classes are instantiated.
    let metamodel: SectionedMetamodel

    /// The resource that registers the created objects.
    let resource: Resource

    /// The kernel level of the metamodel.
    private var kernel: KernelMetamodel { metamodel.kernel }

    /// Create and register an object with the given feature values.
    private func make(_ eClass: EClass, _ values: [(LLFSMFeature, any EcoreValue)]) async -> DynamicEObject {
        var object = DynamicEObject(eClass: eClass)
        for (feature, value) in values { object.eSet(feature.rawValue, value: value) }
        await resource.register(object)
        return object
    }

    /// Create the objects of a typed expression.
    ///
    /// - Parameter node: The typed expression.
    /// - Returns: The root object of the expression.
    func make(_ node: TypedNode) async -> DynamicEObject {
        switch node {
        case .boolean(let value):
            return await make(kernel.booleanLiteralClass, [(.value, value)])
        case .integer(let value):
            return await make(kernel.integerLiteralClass, [(.value, value)])
        case .variable(let variable, let index):
            var values: [(LLFSMFeature, any EcoreValue)] = [(.variable, variable)]
            if let index { values.append((.index, await make(index).id)) }
            return await make(kernel.variableReferenceClass, values)
        case .unary(let operation, let operand):
            let operandObject = await make(operand)
            return await make(kernel.unaryExpressionClass, [(.operation, operation.rawValue), (.operand, operandObject.id)])
        case .binary(let operation, let left, let right):
            let leftObject = await make(left)
            let rightObject = await make(right)
            return await make(kernel.binaryExpressionClass, [
                (.operation, operation.rawValue), (.left, leftObject.id), (.right, rightObject.id),
            ])
        case .conditional(let condition, let whenTrue, let whenFalse):
            let conditionObject = await make(condition)
            let trueObject = await make(whenTrue)
            let falseObject = await make(whenFalse)
            return await make(kernel.conditionalExpressionClass, [
                (.condition, conditionObject.id), (.whenTrue, trueObject.id), (.whenFalse, falseObject.id),
            ])
        case .stateTime(let unit):
            return await make(metamodel.stateTimeExpressionClass, [(.unit, unit.rawValue)])
        case .call(let function, let receiver, let arguments):
            var values: [(LLFSMFeature, any EcoreValue)] = [(.function, function)]
            if let receiver { values.append((.receiver, await make(receiver).id)) }
            var argumentIDs: [EUUID] = []
            for argument in arguments { argumentIDs.append(await make(argument).id) }
            if !argumentIDs.isEmpty { values.append((.arguments, argumentIDs)) }
            return await make(kernel.callExpressionClass, values)
        }
    }

    /// Create the objects of a typed statement.
    ///
    /// - Parameter statement: The typed statement.
    /// - Returns: The statement object.
    func make(_ statement: TypedStatement) async -> DynamicEObject {
        switch statement {
        case .assignment(let target, let value):
            let targetObject = await make(target)
            let valueObject = await make(value)
            return await make(kernel.assignmentClass, [(.target, targetObject.id), (.value, valueObject.id)])
        case .call(let call):
            let callObject = await make(call)
            return await make(kernel.callStatementClass, [(.call, callObject.id)])
        case .print(let text):
            return await make(kernel.printClass, [(.text, text)])
        }
    }

    /// Create an opaque expression.
    ///
    /// - Parameters:
    ///   - text: The exact host-language text.
    ///   - language: The language of the text.
    /// - Returns: The opaque expression.
    func opaqueExpression(_ text: String, language: String) async -> DynamicEObject {
        await make(kernel.opaqueExpressionClass, [(.text, text), (.language, language)])
    }

    /// Create an opaque statement.
    ///
    /// - Parameters:
    ///   - text: The exact host-language text.
    ///   - language: The language of the text.
    /// - Returns: The opaque statement.
    func opaqueStatement(_ text: String, language: String) async -> DynamicEObject {
        await make(kernel.opaqueStatementClass, [(.text, text), (.language, language)])
    }
}
