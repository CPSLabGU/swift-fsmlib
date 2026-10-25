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

    /// Whether two types are known to be incompatible.
    ///
    /// Types are never incompatible while either of them is unknown.
    ///
    /// - Parameter other: The type to compare with.
    /// - Returns: Whether values of the two types can be neither compared nor assigned.
    func isIncompatible(with other: KernelValueType) -> Bool {
        switch (self, other) {
        case (.unknown, _), (_, .unknown):
            return false
        case (.boolean, .boolean), (.integer, .integer):
            return false
        case let (.enumeration(lhs), .enumeration(rhs)), let (.array(lhs), .array(rhs)):
            return lhs != rhs
        default:
            return true
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

/// The type and range checks for the expressions of a kernel model.
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
                if type.isIncompatible(with: targetType) {
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
        if type.isIncompatible(with: declared) {
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
        if isKind(expression, kernel.booleanLiteralClass) { return .boolean }
        if isKind(expression, kernel.integerLiteralClass) {
            let value = expression.int(.value) ?? 0
            return .integer(value...value)
        }
        if isKind(expression, kernel.enumerationLiteralClass) {
            return typeOfEnumerationLiteral(expression, issues: &issues)
        }
        if isKind(expression, kernel.variableReferenceClass) {
            return typeOfVariableReference(expression, issues: &issues)
        }
        if isKind(expression, kernel.unaryExpressionClass) { return typeOfUnary(expression, issues: &issues) }
        if isKind(expression, kernel.binaryExpressionClass) { return typeOfBinary(expression, issues: &issues) }
        if isKind(expression, kernel.conditionalExpressionClass) {
            return typeOfConditional(expression, issues: &issues)
        }
        if isKind(expression, kernel.inStateExpressionClass) { return typeOfInState(expression, issues: &issues) }
        if isKind(expression, kernel.callExpressionClass) { return typeOfCall(expression, issues: &issues) }
        if isKind(expression, kernel.opaqueExpressionClass) {
            return declaredType(index.target(.type, of: expression))
        }
        return .unknown
    }

    /// Record a type error.
    ///
    /// - Parameters:
    ///   - message: A sentence that explains the error.
    ///   - expression: The offending expression.
    ///   - issues: Receives the type error.
    private func record(_ message: String, at expression: DynamicEObject, in issues: inout [KernelTypeIssue]) {
        issues.append(KernelTypeIssue(object: expression, message: message))
    }

    /// The type of an operand of an expression.
    ///
    /// - Parameters:
    ///   - feature: The feature that holds the operand.
    ///   - expression: The expression that owns the operand.
    ///   - issues: Receives the type errors found in the operand.
    /// - Returns: The type of the operand, or ``KernelValueType/unknown`` if it is missing.
    private func operandType(
        _ feature: LLFSMFeature,
        of expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) -> KernelValueType {
        index.target(feature, of: expression).map { typeOf($0, issues: &issues) } ?? .unknown
    }

    /// The type that an operand must have.
    private enum Expectation {
        /// A Boolean operand.
        case boolean

        /// An integer operand.
        case integer

        /// The description of the expected type in messages.
        var description: String {
            switch self {
            case .boolean:
                return "a Boolean"
            case .integer:
                return "an integer"
            }
        }

        /// Whether a type is the expected one.
        ///
        /// - Parameter type: The type of the operand.
        /// - Returns: Whether the type matches the expectation.
        func isSatisfied(by type: KernelValueType) -> Bool {
            switch self {
            case .boolean:
                return type == .boolean
            case .integer:
                return type.isInteger
            }
        }
    }

    /// Record a type error unless a known type satisfies an expectation.
    ///
    /// - Parameters:
    ///   - type: The type of the operand.
    ///   - expectation: The type that the operand must have.
    ///   - role: The description of the operand's role.
    ///   - expression: The expression that owns the operand.
    ///   - issues: Receives the type error.
    private func require(
        _ type: KernelValueType,
        as expectation: Expectation,
        _ role: String,
        of expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) {
        if type.isKnown && !expectation.isSatisfied(by: type) {
            record("The \(role) is \(describe(type)), not \(expectation.description)", at: expression, in: &issues)
        }
    }

    /// The type of an enumeration literal, recording a literal that its enumeration lacks.
    private func typeOfEnumerationLiteral(
        _ expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) -> KernelValueType {
        guard let enumeration = index.target(.type, of: expression) else { return .unknown }
        let literal = expression.string(.literal) ?? ""
        if !enumeration.strings(.literals).contains(literal) {
            record("'\(literal)' is not a literal of enumeration \(label(enumeration))", at: expression, in: &issues)
        }
        return .enumeration(enumeration.id)
    }

    /// The type of a variable reference, recording the misuse of an index.
    private func typeOfVariableReference(
        _ expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) -> KernelValueType {
        guard let variable = index.target(.variable, of: expression) else { return .unknown }
        let variableType = index.target(.type, of: variable)
        guard expression.identifier(.index) != nil else { return declaredType(variableType) }
        let indexType = operandType(.index, of: expression, issues: &issues)
        require(indexType, as: .integer, "array index", of: expression, issues: &issues)
        guard let variableType, isKind(variableType, kernel.arrayTypeClass) else {
            if declaredType(variableType).isKnown {
                record("The variable \(label(variable)) is indexed but is not an array", at: expression, in: &issues)
            }
            return .unknown
        }
        return declaredType(index.target(.element, of: variableType))
    }

    /// The type of a unary expression, recording an operand of the wrong type.
    private func typeOfUnary(_ expression: DynamicEObject, issues: inout [KernelTypeIssue]) -> KernelValueType {
        let type = operandType(.operand, of: expression, issues: &issues)
        switch KernelUnaryOperation(rawValue: expression.string(.operation) ?? "") {
        case .negation:
            require(type, as: .boolean, "operand of the negation", of: expression, issues: &issues)
            return .boolean
        case .minus:
            require(type, as: .integer, "operand of the minus", of: expression, issues: &issues)
            return .integer(nil)
        case nil:
            return .unknown
        }
    }

    /// The type of a binary expression, recording operands of the wrong type.
    private func typeOfBinary(_ expression: DynamicEObject, issues: inout [KernelTypeIssue]) -> KernelValueType {
        let left = operandType(.left, of: expression, issues: &issues)
        let right = operandType(.right, of: expression, issues: &issues)
        guard let operation = KernelBinaryOperation(rawValue: expression.string(.operation) ?? "") else {
            return .unknown
        }
        let name = operation.rawValue
        if operation.isLogical {
            require(left, as: .boolean, "left operand of the \(name)", of: expression, issues: &issues)
            require(right, as: .boolean, "right operand of the \(name)", of: expression, issues: &issues)
            return .boolean
        }
        if operation.isEquality {
            if left.isIncompatible(with: right) {
                record("The \(name) compares \(describe(left)) with \(describe(right))", at: expression, in: &issues)
            }
            return .boolean
        }
        require(left, as: .integer, "left operand of the \(name)", of: expression, issues: &issues)
        require(right, as: .integer, "right operand of the \(name)", of: expression, issues: &issues)
        return operation.isComparison ? .boolean : .integer(nil)
    }

    /// The type of a conditional expression, recording a condition or branches of the wrong type.
    private func typeOfConditional(
        _ expression: DynamicEObject,
        issues: inout [KernelTypeIssue]
    ) -> KernelValueType {
        let condition = operandType(.condition, of: expression, issues: &issues)
        require(condition, as: .boolean, "condition", of: expression, issues: &issues)
        let whenTrue = operandType(.whenTrue, of: expression, issues: &issues)
        let whenFalse = operandType(.whenFalse, of: expression, issues: &issues)
        if whenTrue.isIncompatible(with: whenFalse) {
            record("The branches are \(describe(whenTrue)) and \(describe(whenFalse))", at: expression, in: &issues)
        }
        return whenTrue.isKnown ? whenTrue : whenFalse
    }

    /// The type of a state test, recording a state that its machine lacks.
    private func typeOfInState(_ expression: DynamicEObject, issues: inout [KernelTypeIssue]) -> KernelValueType {
        if let instance = index.target(.instance, of: expression),
           let state = index.target(.state, of: expression),
           let machine = index.target(.machine, of: instance),
           !machine.identifiers(.states).contains(state.id) {
            record(
                "The state \(label(state)) is not a state of machine \(label(machine)) "
                    + "of instance \(label(instance))",
                at: expression,
                in: &issues
            )
        }
        return .boolean
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
            if argumentType.isIncompatible(with: parameterType) {
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
                if receiverType.isIncompatible(with: expected) {
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
        case .boolean:
            return "a Boolean"
        case .integer:
            return "an integer"
        case .enumeration(let identifier):
            return "a value of enumeration \(label(index.object(identifier)))"
        case .array(let identifier):
            return "an array of type \(label(index.object(identifier)))"
        case .void:
            return "no value"
        case .unknown:
            return "of unknown type"
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
            checkRange(
                of: value,
                against: index.target(.type, of: variable),
                variable: variable,
                role: "bound",
                at: binding
            )
        }
        let divisions: Set<KernelBinaryOperation> = [.division, .modulo]
        for expression in objects(of: kernel.binaryExpressionClass) {
            guard let operation = KernelBinaryOperation(rawValue: expression.string(.operation) ?? ""),
                  divisions.contains(operation),
                  let divisor = index.target(.right, of: expression) else { continue }
            var ignored: [KernelTypeIssue] = []
            guard typeOf(divisor, issues: &ignored).isKnown, !isProvablyNonNegative(divisor) else { continue }
            report(
                .unprovenDivisor,
                expression,
                "The right operand of the \(operation.rawValue) is not provably non-negative",
                severity: .warning
            )
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
        report(
            .range,
            object,
            "The value \(constant) \(role) to \(label(variable)) lies outside "
                + "\(range.lowerBound)...\(range.upperBound)"
        )
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
