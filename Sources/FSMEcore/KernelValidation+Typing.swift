//
//  KernelValidation+Typing.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The static type of a kernel expression.
enum KernelValueType: Equatable {
    /// The Boolean type.
    case boolean
    /// An integer type, with its range where it is known.
    case integer(ClosedRange<Int>?)
    /// The enumeration type with the given declaration.
    case enumeration(EUUID)
    /// The array type with the given declaration.
    case array(EUUID)
    /// The result of a call of a function that returns nothing.
    case void
    /// A type that cannot be checked, such as an opaque type.
    case unknown

    /// Whether the type is known, so that checks involving it apply.
    var isKnown: Bool { self != .unknown }

    /// Whether the type is an integer type.
    var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    /// Whether two types are compatible, or `nil` if either is unknown.
    ///
    /// - Parameter other: The type to compare with.
    /// - Returns: Whether values of the two types can be compared or assigned.
    func isCompatible(with other: KernelValueType) -> Bool? {
        switch (self, other) {
        case (.unknown, _), (_, .unknown): return nil
        case (.boolean, .boolean), (.integer, .integer): return true
        case let (.enumeration(lhs), .enumeration(rhs)), let (.array(lhs), .array(rhs)): return lhs == rhs
        default: return false
        }
    }
}

/// A type error found in an expression.
struct KernelTypeIssue {
    /// The offending expression.
    let object: DynamicEObject
    /// A sentence that explains the error.
    let message: String
}

extension KernelValidation {
    // MARK: - W5

    /// Check that every expression of the model is well typed.
    mutating func checkTyping() {
        var issues: [KernelTypeIssue] = []
        for identifier in index.order {
            guard let expression = index.object(identifier), isKind(expression, kernel.expressionClass),
                  !isKind(index.container(of: identifier), kernel.expressionClass) else { continue }
            checkRootExpression(expression, issues: &issues)
        }
        for issue in issues { report(.typing, issue.object, issue.message) }
    }

    /// Check an expression that is not part of a larger expression against its context.
    private func checkRootExpression(_ expression: DynamicEObject, issues: inout [KernelTypeIssue]) {
        let owner = index.container(of: expression.id)
        let feature = index.feature(of: expression.id).flatMap(LLFSMFeature.init(rawValue:))
        let type = typeOf(expression, issues: &issues)
        switch feature {
        case .label where isKind(owner, kernel.transitionClass):
            if type.isKnown && type != .boolean {
                issues.append(KernelTypeIssue(object: expression,
                                              message: "The label is \(describe(type)), not a Boolean"))
            }
        case .initialValue where isKind(owner, kernel.variableClass):
            if let owner { expect(type, toMatch: owner, role: "initial value", at: expression, issues: &issues) }
        case .value where isKind(owner, kernel.bindingClass):
            if let variable = owner.flatMap({ index.target(.variable, of: $0) }) {
                expect(type, toMatch: variable, role: "bound value", at: expression, issues: &issues)
            }
        case .value where isKind(owner, kernel.assignmentClass):
            if let target = owner.flatMap({ index.target(.target, of: $0) }) {
                var ignored: [KernelTypeIssue] = []
                let targetType = typeOf(target, issues: &ignored)
                if type.isCompatible(with: targetType) == false {
                    issues.append(KernelTypeIssue(
                        object: expression,
                        message: "The assignment stores \(describe(type)) in \(describe(targetType))"))
                }
            }
        case .call where isKind(owner, kernel.callStatementClass):
            break
        default:
            if type == .void {
                issues.append(KernelTypeIssue(object: expression,
                                              message: "The expression calls a function that returns no value"))
            }
        }
    }

    /// Record an issue if a value type does not match the declared type of a variable.
    private func expect(
        _ type: KernelValueType,
        toMatch variable: DynamicEObject,
        role: String,
        at expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) {
        let declared = declaredType(index.target(.type, of: variable))
        if type.isCompatible(with: declared) == false {
            issues.append(KernelTypeIssue(
                object: expression,
                message: "The \(role) of \(label(variable)) is \(describe(type)), not \(describe(declared))"))
        }
    }

    /// The static type of an expression, recording the type errors within it.
    ///
    /// Operands of unknown type suspend the checks that involve them.
    ///
    /// - Parameters:
    ///   - expression: The expression to type.
    ///   - issues: Receives the type errors found in the expression.
    /// - Returns: The type of the expression.
    func typeOf(_ expression: DynamicEObject, issues: inout [KernelTypeIssue]) -> KernelValueType {
        func issue(_ message: String) { issues.append(KernelTypeIssue(object: expression, message: message)) }
        func operand(_ feature: LLFSMFeature) -> KernelValueType {
            index.target(feature, of: expression).map { typeOf($0, issues: &issues) } ?? .unknown
        }
        func require(_ type: KernelValueType, _ predicate: (KernelValueType) -> Bool, _ what: String, _ role: String) {
            if type.isKnown && !predicate(type) { issue("The \(role) is \(describe(type)), not \(what)") }
        }
        if isKind(expression, kernel.booleanLiteralClass) { return .boolean }
        if isKind(expression, kernel.integerLiteralClass) {
            let value = expression.int(.value) ?? 0
            return .integer(value...value)
        }
        if isKind(expression, kernel.enumerationLiteralClass) {
            guard let enumeration = index.target(.type, of: expression) else { return .unknown }
            let literal = expression.string(.literal) ?? ""
            if !enumeration.strings(.literals).contains(literal) {
                issue("'\(literal)' is not a literal of enumeration \(label(enumeration))")
            }
            return .enumeration(enumeration.id)
        }
        if isKind(expression, kernel.variableReferenceClass) {
            guard let variable = index.target(.variable, of: expression) else { return .unknown }
            let variableType = index.target(.type, of: variable)
            guard expression.identifier(.index) != nil else { return declaredType(variableType) }
            require(operand(.index), \.isInteger, "an integer", "array index")
            guard let variableType, isKind(variableType, kernel.arrayTypeClass) else {
                if declaredType(variableType).isKnown {
                    issue("The variable \(label(variable)) is indexed but is not an array")
                }
                return .unknown
            }
            return declaredType(index.target(.element, of: variableType))
        }
        if isKind(expression, kernel.unaryExpressionClass) {
            let type = operand(.operand)
            switch KernelUnaryOperation(rawValue: expression.string(.operation) ?? "") {
            case .negation:
                require(type, { $0 == .boolean }, "a Boolean", "operand of the negation")
                return .boolean
            case .minus:
                require(type, \.isInteger, "an integer", "operand of the minus")
                return .integer(nil)
            case nil:
                return .unknown
            }
        }
        if isKind(expression, kernel.binaryExpressionClass) {
            let left = operand(.left)
            let right = operand(.right)
            guard let operation = KernelBinaryOperation(rawValue: expression.string(.operation) ?? "") else {
                return .unknown
            }
            let name = operation.rawValue
            if operation.isLogical {
                require(left, { $0 == .boolean }, "a Boolean", "left operand of the \(name)")
                require(right, { $0 == .boolean }, "a Boolean", "right operand of the \(name)")
                return .boolean
            }
            if operation.isEquality {
                if left.isCompatible(with: right) == false {
                    issue("The \(name) compares \(describe(left)) with \(describe(right))")
                }
                return .boolean
            }
            require(left, \.isInteger, "an integer", "left operand of the \(name)")
            require(right, \.isInteger, "an integer", "right operand of the \(name)")
            return operation.isComparison ? .boolean : .integer(nil)
        }
        if isKind(expression, kernel.conditionalExpressionClass) {
            require(operand(.condition), { $0 == .boolean }, "a Boolean", "condition")
            let whenTrue = operand(.whenTrue)
            let whenFalse = operand(.whenFalse)
            if whenTrue.isCompatible(with: whenFalse) == false {
                issue("The branches are \(describe(whenTrue)) and \(describe(whenFalse))")
            }
            return whenTrue.isKnown ? whenTrue : whenFalse
        }
        if isKind(expression, kernel.inStateExpressionClass) {
            if let instance = index.target(.instance, of: expression),
               let state = index.target(.state, of: expression),
               let machine = index.target(.machine, of: instance),
               !machine.identifiers(.states).contains(state.id) {
                issue("The state \(label(state)) is not a state of machine \(label(machine)) "
                      + "of instance \(label(instance))")
            }
            return .boolean
        }
        if isKind(expression, kernel.callExpressionClass) {
            return typeOfCall(expression, issues: &issues)
        }
        if isKind(expression, kernel.opaqueExpressionClass) {
            return declaredType(index.target(.type, of: expression))
        }
        return .unknown
    }

    /// The result type of a call, recording argument and receiver errors.
    private func typeOfCall(_ call: DynamicEObject, issues: inout [KernelTypeIssue]) -> KernelValueType {
        guard let function = index.target(.function, of: call) else { return .unknown }
        let parameters = index.objects(.parameters, of: function)
        let arguments = index.objects(.arguments, of: call)
        if parameters.count != arguments.count {
            issues.append(KernelTypeIssue(
                object: call,
                message: "The call of \(label(function)) passes \(arguments.count) argument(s), "
                    + "but \(parameters.count) are declared"))
        }
        for (position, (argument, parameter)) in zip(arguments, parameters).enumerated() {
            let argumentType = typeOf(argument, issues: &issues)
            let parameterType = declaredType(index.target(.type, of: parameter))
            if argumentType.isCompatible(with: parameterType) == false {
                issues.append(KernelTypeIssue(
                    object: argument,
                    message: "Argument \(position + 1) of \(label(function)) is \(describe(argumentType)), "
                        + "not \(describe(parameterType))"))
            }
        }
        if let receiver = index.target(.receiver, of: call) {
            let receiverType = typeOf(receiver, issues: &issues)
            if let declared = index.target(.receiverType, of: function) {
                let expected = declaredType(declared)
                if receiverType.isCompatible(with: expected) == false {
                    issues.append(KernelTypeIssue(
                        object: receiver,
                        message: "The receiver of \(label(function)) is \(describe(receiverType)), "
                            + "not \(describe(expected))"))
                }
            } else {
                issues.append(KernelTypeIssue(
                    object: call,
                    message: "The call has a receiver, but \(label(function)) is not a method"))
            }
        }
        guard function.identifier(.result) != nil else { return .void }
        return declaredType(index.target(.result, of: function))
    }

    /// The value type that a type declaration denotes.
    ///
    /// - Parameter type: The type declaration, if it resolves.
    /// - Returns: The value type, or ``KernelValueType/unknown`` for opaque or missing types.
    func declaredType(_ type: DynamicEObject?) -> KernelValueType {
        guard let type else { return .unknown }
        if isKind(type, kernel.booleanTypeClass) { return .boolean }
        if isKind(type, kernel.integerTypeClass) {
            guard let lower = type.int(.lower), let upper = type.int(.upper), lower <= upper else {
                return .integer(nil)
            }
            return .integer(lower...upper)
        }
        if isKind(type, kernel.enumerationTypeClass) { return .enumeration(type.id) }
        if isKind(type, kernel.arrayTypeClass) { return .array(type.id) }
        return .unknown
    }

    /// A phrase that names a type in messages.
    func describe(_ type: KernelValueType) -> String {
        switch type {
        case .boolean: return "a Boolean"
        case .integer: return "an integer"
        case .enumeration(let identifier): return "a value of enumeration \(label(index.object(identifier)))"
        case .array(let identifier): return "an array of type \(label(index.object(identifier)))"
        case .void: return "no value"
        case .unknown: return "of unknown type"
        }
    }

    // MARK: - W7

    /// Check integer literals against variable ranges and the signs of divisors.
    mutating func checkRanges() {
        for assignment in objects(of: kernel.assignmentClass) {
            guard let target = index.target(.target, of: assignment),
                  let variable = index.target(.variable, of: target),
                  let value = index.target(.value, of: assignment) else { continue }
            var type = index.target(.type, of: variable)
            if target.identifier(.index) != nil {
                type = type.flatMap { isKind($0, kernel.arrayTypeClass) ? index.target(.element, of: $0) : nil }
            }
            checkRange(of: value, against: type, variable: variable, role: "assigned", at: assignment)
        }
        for binding in objects(of: kernel.bindingClass) {
            guard let variable = index.target(.variable, of: binding),
                  let value = index.target(.value, of: binding) else { continue }
            checkRange(of: value, against: index.target(.type, of: variable), variable: variable,
                       role: "bound", at: binding)
        }
        let divisions: Set<KernelBinaryOperation> = [.division, .modulo]
        for expression in objects(of: kernel.binaryExpressionClass) {
            guard let operation = KernelBinaryOperation(rawValue: expression.string(.operation) ?? ""),
                  divisions.contains(operation),
                  let divisor = index.target(.right, of: expression) else { continue }
            var ignored: [KernelTypeIssue] = []
            guard typeOf(divisor, issues: &ignored).isKnown, !isProvablyNonNegative(divisor) else { continue }
            report(.unprovenDivisor, expression,
                   "The right operand of the \(operation.rawValue) is not provably non-negative",
                   severity: .warning)
        }
    }

    /// Report a constant value that lies outside the range of an integer type.
    private mutating func checkRange(
        of value: DynamicEObject,
        against type: DynamicEObject?,
        variable: DynamicEObject,
        role: String,
        at object: DynamicEObject
    ) {
        guard let constant = constantValue(of: value),
              case .integer(let range?) = declaredType(type),
              !range.contains(constant) else { return }
        report(.range, object,
               "The value \(constant) \(role) to \(label(variable)) lies outside "
               + "\(range.lowerBound)...\(range.upperBound)")
    }

    /// The value of an integer literal, possibly negated by a minus.
    func constantValue(of expression: DynamicEObject) -> Int? {
        if isKind(expression, kernel.integerLiteralClass) { return expression.int(.value) ?? 0 }
        if isKind(expression, kernel.unaryExpressionClass),
           expression.string(.operation) == KernelUnaryOperation.minus.rawValue,
           let operand = index.target(.operand, of: expression),
           let value = constantValue(of: operand) {
            return -value
        }
        return nil
    }

    /// Whether an expression is a non-negative constant or reads a variable with a non-negative range.
    private func isProvablyNonNegative(_ expression: DynamicEObject) -> Bool {
        if let constant = constantValue(of: expression) { return constant >= 0 }
        var ignored: [KernelTypeIssue] = []
        guard isKind(expression, kernel.variableReferenceClass),
              case .integer(let range?) = typeOf(expression, issues: &ignored) else { return false }
        return range.lowerBound >= 0
    }
}
