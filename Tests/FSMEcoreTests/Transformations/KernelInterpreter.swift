//
//  KernelInterpreter.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// A small interpreter of typed kernel arrangements for semantic tests.
///
/// A round runs one ringlet of every instance in arrangement order. A
/// ringlet takes the snapshot of the external variables, runs the action of
/// the current state if the state was entered since the previous ringlet,
/// and then follows the first transition whose label holds: a pass-through
/// target runs its action and continues the ringlet with its own
/// transitions, any other target becomes the current state and ends the
/// ringlet. Writes to shared variables are visible at once, and an in-state
/// observation reads the current state of the observed instance. Print
/// statements append their text and values to the trace.
struct KernelInterpreter {
    /// A run-time value.
    enum Value: Equatable, CustomStringConvertible {
        /// A Boolean value.
        case boolean(Bool)
        /// An integer value.
        case integer(Int)
        /// An enumeration literal.
        case literal(String)
        /// An array of values.
        case array([Value])

        /// The text of the value, as printed by a print statement.
        var description: String {
            switch self {
            case .boolean(let value):
                return String(value)
            case .integer(let value):
                return String(value)
            case .literal(let value):
                return value
            case .array(let values):
                return "[" + values.map(\.description).joined(separator: ", ") + "]"
            }
        }

        /// The Boolean held by the value; any other kind of value is a programming error.
        var bool: Bool {
            guard case .boolean(let value) = self else { fatalError("not a Boolean: \(self)") }
            return value
        }

        /// The integer held by the value; any other kind of value is a programming error.
        var int: Int {
            guard case .integer(let value) = self else { fatalError("not an integer: \(self)") }
            return value
        }
    }

    /// The values of the external variables in a round, by variable name.
    typealias Environment = (_ round: Int, _ name: String) -> Value

    /// The model being interpreted.
    let index: KernelModelIndex

    /// The kernel metamodel.
    let kernel: KernelMetamodel

    /// The values of the external variables per round.
    let environment: Environment

    /// The instances in execution order.
    private let instances: [DynamicEObject]

    /// The values of the variables, by instance (nil for shared variables) and variable.
    private var values: [VariableKey: Value] = [:]

    /// The current state of each instance.
    private var current: [EUUID: EUUID] = [:]

    /// The instances whose current state was entered since their previous ringlet.
    private var entered: Set<EUUID> = []

    /// The snapshot of the external variables during the current ringlet.
    private var snapshot: [EUUID: Value] = [:]

    /// The printed lines, each prefixed with the round and the instance.
    private(set) var trace: [String] = []

    /// The key of a variable value.
    private struct VariableKey: Hashable {
        /// The instance owning the variable, or nil for a shared variable.
        let instance: EUUID?
        /// The variable.
        let variable: EUUID
    }

    /// Prepare an interpreter for a kernel model.
    ///
    /// - Parameters:
    ///   - resource: The resource whose root is a kernel arrangement.
    ///   - kernel: The kernel metamodel.
    ///   - environment: The values of the external variables per round.
    init(resource: Resource, kernel: KernelMetamodel, environment: @escaping Environment) async {
        index = await KernelModelIndex(resource: resource)
        self.kernel = kernel
        self.environment = environment
        guard let arrangement = index.roots.first.flatMap(index.object) else { fatalError("no arrangement") }
        instances = index.objects(.instances, of: arrangement)
        for variable in index.objects(.variables, of: arrangement) where !variable.bool(.external) {
            values[VariableKey(instance: nil, variable: variable.id)] = initialValue(of: variable)
        }
        for instance in instances {
            guard let machine = index.target(.machine, of: instance),
                  let initial = machine.identifier(.initial) else { fatalError("incomplete instance") }
            current[instance.id] = initial
            entered.insert(instance.id)
            for variable in index.objects(.variables, of: machine) {
                values[VariableKey(instance: instance.id, variable: variable.id)] = initialValue(of: variable)
            }
            for binding in index.objects(.bindings, of: instance) {
                guard let variable = binding.identifier(.variable),
                      let value = index.target(.value, of: binding) else { continue }
                values[VariableKey(instance: instance.id, variable: variable)] = evaluate(value, in: instance)
            }
        }
    }

    /// Run a number of rounds.
    ///
    /// - Parameter rounds: The number of rounds.
    mutating func run(rounds: Int) {
        for round in 0..<rounds {
            for instance in instances { ringlet(of: instance, in: round) }
        }
    }

    /// The name of the current state of an instance.
    func stateName(of instanceName: String) -> String? {
        guard let instance = instances.first(where: { $0.string(.name) == instanceName }) else { return nil }
        return index.object(current[instance.id])?.string(.name)
    }

    // MARK: - Ringlets

    /// Run one ringlet of an instance.
    ///
    /// - Parameters:
    ///   - instance: The instance to run.
    ///   - round: The number of the current round.
    private mutating func ringlet(of instance: DynamicEObject, in round: Int) {
        snapshot = [:]
        guard let arrangement = index.roots.first.flatMap(index.object) else { return }
        for variable in index.objects(.variables, of: arrangement) where variable.bool(.external) {
            snapshot[variable.id] = environment(round, variable.string(.name) ?? "")
        }
        guard var state = index.object(current[instance.id]) else { return }
        if entered.remove(instance.id) != nil {
            execute(index.objects(.actions, of: state), in: instance, round: round)
        }
        var steps = 0
        while let transition = index.objects(.transitions, of: state).first(where: { holds($0, in: instance) }) {
            guard let target = index.target(.target, of: transition) else { fatalError("dangling transition") }
            steps += 1
            precondition(steps < 1_000, "the pass-through states form a cycle")
            if target.bool(.passThrough) {
                state = target
                execute(index.objects(.actions, of: target), in: instance, round: round)
                continue
            }
            current[instance.id] = target.id
            entered.insert(instance.id)
            return
        }
        precondition(!state.bool(.passThrough), "a ringlet rests in pass-through state \(state.string(.name) ?? "")")
    }

    /// Whether the label of a transition holds.
    ///
    /// - Parameters:
    ///   - transition: The transition to check.
    ///   - instance: The instance that owns the transition.
    /// - Returns: True if the label evaluates to true.
    private func holds(_ transition: DynamicEObject, in instance: DynamicEObject) -> Bool {
        guard let label = index.target(.label, of: transition) else { fatalError("missing label") }
        return evaluate(label, in: instance).bool
    }

    // MARK: - Statements

    /// Execute a sequence of statements.
    ///
    /// - Parameters:
    ///   - statements: The statements to execute in order.
    ///   - instance: The instance executing the statements.
    ///   - round: The number of the current round.
    private mutating func execute(_ statements: [DynamicEObject], in instance: DynamicEObject, round: Int) {
        for statement in statements {
            if isKind(statement, kernel.assignmentClass) {
                guard let target = index.target(.target, of: statement),
                      let variable = target.identifier(.variable),
                      let valueExpression = index.target(.value, of: statement) else { fatalError("incomplete assignment") }
                let value = evaluate(valueExpression, in: instance)
                let key = key(for: variable, in: instance)
                if let indexExpression = index.target(.index, of: target) {
                    guard case .array(var elements) = values[key] else { fatalError("not an array") }
                    elements[evaluate(indexExpression, in: instance).int] = value
                    values[key] = .array(elements)
                } else {
                    values[key] = value
                }
            } else if isKind(statement, kernel.printClass) {
                let printed = index.objects(.values, of: statement).map { evaluate($0, in: instance).description }
                let line = ([statement.string(.text) ?? ""] + printed).joined(separator: " ")
                trace.append("r\(round) \(instance.string(.name) ?? ""): \(line)")
            } else {
                fatalError("statement \(statement.eClass.name) is not interpreted")
            }
        }
    }

    // MARK: - Expressions

    /// Evaluate an expression.
    ///
    /// - Parameters:
    ///   - expression: The expression to evaluate.
    ///   - instance: The instance in whose context the expression is evaluated.
    /// - Returns: The value of the expression.
    private func evaluate(_ expression: DynamicEObject, in instance: DynamicEObject) -> Value {
        if isKind(expression, kernel.booleanLiteralClass) { return .boolean(expression.bool(.value)) }
        if isKind(expression, kernel.integerLiteralClass) { return .integer(expression.int(.value) ?? 0) }
        if isKind(expression, kernel.enumerationLiteralClass) { return .literal(expression.string(.literal) ?? "") }
        if isKind(expression, kernel.variableReferenceClass) {
            return evaluateReference(expression, in: instance)
        }
        if isKind(expression, kernel.unaryExpressionClass) {
            return evaluateUnary(expression, in: instance)
        }
        if isKind(expression, kernel.binaryExpressionClass) {
            return evaluateBinary(expression, in: instance)
        }
        if isKind(expression, kernel.conditionalExpressionClass) {
            return operand(.condition, of: expression, in: instance).bool
                ? operand(.whenTrue, of: expression, in: instance)
                : operand(.whenFalse, of: expression, in: instance)
        }
        if isKind(expression, kernel.inStateExpressionClass) {
            guard let observed = expression.identifier(.instance) else { fatalError("unbound observation") }
            return .boolean(current[observed] == expression.identifier(.state))
        }
        fatalError("expression \(expression.eClass.name) is not interpreted")
    }

    /// Evaluate an operand of an expression.
    ///
    /// - Parameters:
    ///   - feature: The feature that holds the operand.
    ///   - expression: The expression that owns the operand.
    ///   - instance: The instance in whose context the operand is evaluated.
    /// - Returns: The value of the operand.
    private func operand(_ feature: LLFSMFeature, of expression: DynamicEObject, in instance: DynamicEObject) -> Value {
        guard let object = index.target(feature, of: expression) else { fatalError("missing \(feature)") }
        return evaluate(object, in: instance)
    }

    /// Evaluate a reference to a variable, with or without an array index.
    ///
    /// - Parameters:
    ///   - expression: The variable reference.
    ///   - instance: The instance in whose context the reference is evaluated.
    /// - Returns: The value of the variable or of the indexed element.
    private func evaluateReference(_ expression: DynamicEObject, in instance: DynamicEObject) -> Value {
        guard let variable = expression.identifier(.variable) else { fatalError("unbound reference") }
        let value = snapshot[variable] ?? values[key(for: variable, in: instance)]
        guard let value else { fatalError("unknown variable \(index.path(of: variable))") }
        guard let element = index.target(.index, of: expression) else { return value }
        guard case .array(let elements) = value else { fatalError("not an array") }
        return elements[evaluate(element, in: instance).int]
    }

    /// Evaluate a unary expression.
    ///
    /// - Parameters:
    ///   - expression: The unary expression.
    ///   - instance: The instance in whose context the expression is evaluated.
    /// - Returns: The result of the operation.
    private func evaluateUnary(_ expression: DynamicEObject, in instance: DynamicEObject) -> Value {
        let value = operand(.operand, of: expression, in: instance)
        switch KernelUnaryOperation(rawValue: expression.string(.operation) ?? "") {
        case .negation:
            return .boolean(!value.bool)
        case .minus:
            return .integer(-value.int)
        case nil:
            fatalError("unknown unary operation")
        }
    }

    /// Evaluate a binary expression.
    ///
    /// - Parameters:
    ///   - expression: The binary expression.
    ///   - instance: The instance in whose context the expression is evaluated.
    /// - Returns: The result of the operation.
    private func evaluateBinary(_ expression: DynamicEObject, in instance: DynamicEObject) -> Value {
        guard let operation = KernelBinaryOperation(rawValue: expression.string(.operation) ?? "") else {
            fatalError("unknown binary operation")
        }
        let left = operand(.left, of: expression, in: instance)
        let right = { operand(.right, of: expression, in: instance) }
        switch operation {
        case .conjunction:
            return .boolean(left.bool && right().bool)
        case .disjunction:
            return .boolean(left.bool || right().bool)
        case .equal:
            return .boolean(left == right())
        case .notEqual:
            return .boolean(left != right())
        default:
            return evaluateArithmetic(operation, left.int, right().int)
        }
    }

    /// Apply an integer operation.
    ///
    /// - Parameters:
    ///   - operation: The arithmetic or comparison operation.
    ///   - lhs: The left operand.
    ///   - rhs: The right operand.
    /// - Returns: The integer or Boolean result.
    private func evaluateArithmetic(_ operation: KernelBinaryOperation, _ lhs: Int, _ rhs: Int) -> Value {
        switch operation {
        case .addition:
            return .integer(lhs + rhs)
        case .subtraction:
            return .integer(lhs - rhs)
        case .multiplication:
            return .integer(lhs * rhs)
        case .division:
            return .integer(lhs / rhs)
        case .modulo:
            return .integer(lhs % rhs)
        case .lessThan:
            return .boolean(lhs < rhs)
        case .lessOrEqual:
            return .boolean(lhs <= rhs)
        case .greaterThan:
            return .boolean(lhs > rhs)
        case .greaterOrEqual:
            return .boolean(lhs >= rhs)
        default:
            fatalError("unreachable")
        }
    }

    /// The key under which a variable value is stored.
    ///
    /// - Parameters:
    ///   - variable: The variable.
    ///   - instance: The instance accessing the variable.
    /// - Returns: The key of the instance's own variable if it has one, the key of the shared variable otherwise.
    private func key(for variable: EUUID, in instance: DynamicEObject) -> VariableKey {
        let local = VariableKey(instance: instance.id, variable: variable)
        return values[local] != nil ? local : VariableKey(instance: nil, variable: variable)
    }

    /// The initial value of a variable.
    ///
    /// - Parameter variable: The variable.
    /// - Returns: The value of its initialiser, or the default value of its type.
    private func initialValue(of variable: DynamicEObject) -> Value {
        if let expression = index.target(.initialValue, of: variable) {
            return evaluate(expression, in: variable)
        }
        return defaultValue(of: index.target(.type, of: variable))
    }

    /// The default value of a type.
    ///
    /// - Parameter type: The type of a variable.
    /// - Returns: The value that a variable of that type holds before it is assigned.
    private func defaultValue(of type: DynamicEObject?) -> Value {
        guard let type else { fatalError("untyped variable") }
        if isKind(type, kernel.booleanTypeClass) { return .boolean(false) }
        if isKind(type, kernel.integerTypeClass) { return .integer(type.int(.lower) ?? 0) }
        if isKind(type, kernel.enumerationTypeClass) { return .literal(type.strings(.literals).first ?? "") }
        if isKind(type, kernel.arrayTypeClass) {
            return .array(Array(repeating: defaultValue(of: index.target(.element, of: type)), count: type.int(.size) ?? 0))
        }
        fatalError("type \(type.eClass.name) is not interpreted")
    }

    /// Whether an object is an instance of a kernel class or of one of its subclasses.
    ///
    /// - Parameters:
    ///   - object: The object to check.
    ///   - eClass: The class to check against.
    /// - Returns: True if the object conforms to the class.
    private func isKind(_ object: DynamicEObject, _ eClass: EClass) -> Bool {
        kernel.isKind(object.eClass, of: eClass)
    }
}
