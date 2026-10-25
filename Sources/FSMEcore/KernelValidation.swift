//
//  KernelValidation.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// One validation run over an indexed kernel model.
///
/// The rules are checked in the order of ``KernelRule``, each over the
/// objects of the model in containment order.
struct KernelValidation {
    /// The kernel metamodel that types the model.
    let kernel: KernelMetamodel

    /// The profile whose rules apply.
    let profile: ValidationProfile

    /// The containment index of the model.
    let index: KernelModelIndex

    /// The diagnostics reported so far.
    private(set) var diagnostics: [KernelDiagnostic] = []

    /// Create a validation run.
    ///
    /// - Parameters:
    ///   - metamodel: The kernel metamodel that types the model.
    ///   - profile: The profile whose rules apply.
    ///   - index: The containment index of the model.
    init(metamodel: KernelMetamodel, profile: ValidationProfile, index: KernelModelIndex) {
        self.kernel = metamodel
        self.profile = profile
        self.index = index
    }

    /// Check every rule of the profile.
    mutating func run() {
        checkStructure()
        checkNames()
        checkInitialStates()
        checkPassThroughCycles()
        checkExternalVariables()
        checkTyping()
        checkSingleAssignment()
        checkRanges()
        checkBindingLiterals()
        checkPurity()
        if profile == .strict { checkStrictProfile() }
    }

    // MARK: - Reporting and Navigation

    /// Record a diagnostic for an object.
    ///
    /// - Parameters:
    ///   - rule: The violated rule.
    ///   - object: The offending object.
    ///   - message: A sentence that explains the violation.
    ///   - severity: How serious the violation is (default error).
    mutating func report(
        _ rule: KernelRule,
        _ object: DynamicEObject,
        _ message: String,
        severity: KernelDiagnostic.Severity = .error
    ) {
        diagnostics.append(KernelDiagnostic(
            rule: rule,
            severity: severity,
            path: index.path(of: object.id),
            message: message
        ))
    }

    /// Whether an object is an instance of a kernel class or one of its subclasses.
    func isKind(_ object: DynamicEObject?, _ eClass: EClass) -> Bool {
        guard let object else { return false }
        return kernel.isKind(object.eClass, of: eClass)
    }

    /// The objects of the model that are instances of a class, in containment order.
    func objects(of eClass: EClass) -> [DynamicEObject] {
        index.order.compactMap { index.object($0) }.filter { isKind($0, eClass) }
    }

    /// The name of an object for messages, or its class name if it has none.
    func label(_ object: DynamicEObject?) -> String {
        guard let object else { return "?" }
        return object.string(.name).map { "'\($0)'" } ?? object.eClass.name
    }

    /// The machine that contains an object, directly or indirectly.
    func machine(containing object: DynamicEObject) -> DynamicEObject? {
        index.ancestor(of: object.id) { isKind($0, kernel.machineClass) }
    }

    // MARK: - STRUCT

    /// Check mandatory features, reference resolution and containment-dependent references.
    mutating func checkStructure() {
        for root in index.roots.compactMap({ index.object($0) }) where !isKind(root, kernel.arrangementClass) {
            report(.structure, root, "The root object is a \(root.eClass.name), not a kernel Arrangement")
        }
        for missing in index.missingChildren {
            if let owner = index.object(missing.owner) {
                report(.structure, owner, "An object contained by \(missing.feature) is not part of the resource")
            }
        }
        for identifier in index.order {
            guard let object = index.object(identifier) else { continue }
            checkFeatures(of: object)
        }
        checkTransitionTargets()
        checkBindingVariables()
    }

    /// Check that the source and the target of every transition belong to one machine.
    private mutating func checkTransitionTargets() {
        for transition in objects(of: kernel.transitionClass) {
            guard let target = index.target(.target, of: transition) else { continue }
            let source = machine(containing: transition)
            let destination = machine(containing: target)
            if source?.id != destination?.id {
                report(
                    .structure,
                    transition,
                    "The target state \(label(target)) belongs to machine \(label(destination)), "
                        + "not to machine \(label(source))"
                )
            }
        }
    }

    /// Check that every binding binds a local variable of the machine of its instance.
    private mutating func checkBindingVariables() {
        for binding in objects(of: kernel.bindingClass) {
            guard let variable = index.target(.variable, of: binding) else { continue }
            let instance = index.container(of: binding.id)
            let machine = instance.flatMap { index.target(.machine, of: $0) }
            if let machine, !machine.identifiers(.variables).contains(variable.id) {
                report(
                    .structure,
                    binding,
                    "The bound variable \(label(variable)) is not a local variable of machine \(label(machine))"
                )
            }
        }
    }

    /// Check the multiplicities, literals and references of one object.
    private mutating func checkFeatures(of object: DynamicEObject) {
        checkAttributes(of: object)
        checkReferences(of: object)
    }

    /// Check the multiplicities and literals of the attributes of one object.
    private mutating func checkAttributes(of object: DynamicEObject) {
        for attribute in object.eClass.eAllAttributes {
            if attribute.lowerBound > 0 {
                let missing = attribute.isMany
                    ? manyAttributeCount(object.eGet(attribute.name)) < attribute.lowerBound
                    : object.eGetWithDefault(attribute.name) == nil
                if missing { reportMissing(attribute.name, lowerBound: attribute.lowerBound, on: object) }
            }
            if let eEnum = attribute.eType as? EEnum,
               let literal = object.eGet(attribute.name) as? String, eEnum.getLiteral(name: literal) == nil {
                report(
                    .structure,
                    object,
                    "The value \(literal) of \(attribute.name) is not a literal of \(eEnum.name)"
                )
            }
        }
    }

    /// Check the multiplicities and targets of the references of one object.
    private mutating func checkReferences(of object: DynamicEObject) {
        for reference in object.eClass.eAllReferences {
            let identifiers = object.identifiers(named: reference.name)
            if reference.lowerBound > 0 && identifiers.count < reference.lowerBound {
                reportMissing(reference.name, lowerBound: reference.lowerBound, on: object)
            }
            guard let expected = reference.eType as? EClass else { continue }
            for identifier in identifiers {
                guard let target = index.object(identifier) else {
                    if !reference.containment {
                        report(.structure, object, "The reference \(reference.name) does not resolve")
                    }
                    continue
                }
                if !kernel.isKind(target.eClass, of: expected) {
                    report(
                        .structure,
                        object,
                        "The reference \(reference.name) refers to a \(target.eClass.name), "
                            + "not to a \(expected.name)"
                    )
                }
            }
        }
    }

    /// Report a mandatory feature that has too few values.
    private mutating func reportMissing(_ feature: String, lowerBound: Int, on object: DynamicEObject) {
        let message = lowerBound > 1
            ? "The feature \(feature) requires at least \(lowerBound) values"
            : "The mandatory feature \(feature) is missing"
        report(.structure, object, message)
    }

    /// The number of values of a many-valued attribute.
    private func manyAttributeCount(_ value: (any EcoreValue)?) -> Int {
        switch value {
        case nil:
            return 0
        case let strings as [String]:
            return strings.count
        case let ints as [Int]:
            return ints.count
        case let bools as [Bool]:
            return bools.count
        case let doubles as [Double]:
            return doubles.count
        default:
            return 1
        }
    }

    // MARK: - W1

    /// Check that names are identifiers, unique per containment feature, and
    /// that enumeration literals are unique.
    mutating func checkNames() {
        for identifier in index.order {
            guard let object = index.object(identifier) else { continue }
            if object.eClass.getEAttribute(name: LLFSMFeature.name.rawValue) != nil,
               let name = object.eGet(LLFSMFeature.name.rawValue) as? String,
               !Self.isIdentifier(name) {
                report(.names, object, "The name '\(name)' is not an identifier")
            }
            for reference in object.eClass.eAllContainments where reference.isMany {
                var seen = Set<String>()
                for child in index.objects(named: reference.name, of: object) {
                    guard let name = child.eGet(LLFSMFeature.name.rawValue) as? String else { continue }
                    if !seen.insert(name).inserted {
                        report(.names, child, "The name '\(name)' is used more than once in \(reference.name)")
                    }
                }
            }
            if isKind(object, kernel.enumerationTypeClass) {
                var seen = Set<String>()
                for literal in object.strings(.literals) where !seen.insert(literal).inserted {
                    report(.names, object, "The literal '\(literal)' appears more than once")
                }
            }
        }
    }

    /// Whether a name matches `[A-Za-z_][A-Za-z0-9_]*`.
    static func isIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first else { return false }
        func isLetter(_ scalar: Unicode.Scalar) -> Bool {
            ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar) || scalar == "_"
        }
        return isLetter(first) && name.unicodeScalars.dropFirst().allSatisfy {
            isLetter($0) || ("0"..."9").contains($0)
        }
    }

    // MARK: - W2

    /// Check that every initial state is a non-pass-through state of its machine.
    mutating func checkInitialStates() {
        for machine in objects(of: kernel.machineClass) {
            guard let initial = index.target(.initial, of: machine) else { continue }
            if !machine.identifiers(.states).contains(initial.id) {
                report(
                    .initialState,
                    machine,
                    "The initial state \(label(initial)) is not a state of machine \(label(machine))"
                )
            } else if initial.bool(.passThrough) {
                report(.initialState, machine, "The initial state \(label(initial)) is pass-through")
            }
        }
    }

    // MARK: - W3

    /// Check that the transitions between pass-through states form no cycle.
    mutating func checkPassThroughCycles() {
        for machine in objects(of: kernel.machineClass) {
            let states = index.objects(.states, of: machine)
            let passThrough = Set(states.filter { $0.bool(.passThrough) }.map(\.id))
            var successors: [EUUID: [EUUID]] = [:]
            for state in states where passThrough.contains(state.id) {
                successors[state.id] = index.objects(.transitions, of: state)
                    .compactMap { $0.identifier(.target) }
                    .filter { passThrough.contains($0) }
            }
            var finished = Set<EUUID>()
            var stack: [EUUID] = []
            func visit(_ state: EUUID, cycles: inout [[EUUID]]) {
                stack.append(state)
                for next in successors[state] ?? [] where !finished.contains(next) {
                    if let start = stack.firstIndex(of: next) {
                        cycles.append(Array(stack[start...]) + [next])
                    } else {
                        visit(next, cycles: &cycles)
                    }
                }
                stack.removeLast()
                finished.insert(state)
            }
            var cycles: [[EUUID]] = []
            for state in states where passThrough.contains(state.id) && !finished.contains(state.id) {
                visit(state.id, cycles: &cycles)
            }
            for cycle in cycles {
                guard let first = index.object(cycle.first) else { continue }
                let names = cycle.map { label(index.object($0)) }.joined(separator: " → ")
                report(.passThroughCycle, first, "The pass-through states form a cycle: \(names)")
            }
        }
    }

    // MARK: - W4

    /// Check that external variables are shared and never assigned.
    mutating func checkExternalVariables() {
        for variable in objects(of: kernel.variableClass) where variable.bool(.external) {
            let container = index.container(of: variable.id)
            if !isKind(container, kernel.arrangementClass)
                || index.feature(of: variable.id) != LLFSMFeature.variables.rawValue {
                report(
                    .externalVariables,
                    variable,
                    "The external variable \(label(variable)) is not a shared variable of the arrangement"
                )
            }
        }
        for assignment in objects(of: kernel.assignmentClass) {
            guard let target = index.target(.target, of: assignment),
                  let variable = index.target(.variable, of: target),
                  variable.bool(.external) else { continue }
            report(.externalVariables, assignment, "The external variable \(label(variable)) is assigned")
        }
    }

    // MARK: - W8

    /// Check that binding values are literals.
    mutating func checkBindingLiterals() {
        let literalClasses = [kernel.booleanLiteralClass, kernel.integerLiteralClass, kernel.enumerationLiteralClass]
        for binding in objects(of: kernel.bindingClass) {
            guard let value = index.target(.value, of: binding) else { continue }
            if !literalClasses.contains(where: { isKind(value, $0) }) {
                report(.bindingLiteral, binding, "The bound value is a \(value.eClass.name), not a literal")
            }
        }
    }

    // MARK: - W9

    /// A kind of object with an expression that may call only pure functions.
    private struct PurityRoot {
        /// The class of the objects that own the expression.
        let owner: EClass

        /// The feature that holds the expression.
        let feature: LLFSMFeature

        /// The description of the expression in reports.
        let role: String
    }

    /// Check that labels, binding values and initial values call only pure functions.
    mutating func checkPurity() {
        let roots = [
            PurityRoot(owner: kernel.transitionClass, feature: .label, role: "label"),
            PurityRoot(owner: kernel.bindingClass, feature: .value, role: "bound value"),
            PurityRoot(owner: kernel.variableClass, feature: .initialValue, role: "initial value"),
        ]
        for root in roots {
            for owner in objects(of: root.owner) {
                guard let expression = index.target(root.feature, of: owner) else { continue }
                for call in index.subtree(of: expression) where isKind(call, kernel.callExpressionClass) {
                    guard let function = index.target(.function, of: call), !function.bool(.pure) else { continue }
                    report(.purity, call, "The \(root.role) calls the impure function \(label(function))")
                }
            }
        }
    }

    // MARK: - STRICT

    /// Check that the model contains no opaque nodes and no host declarations.
    mutating func checkStrictProfile() {
        let excluded = [
            kernel.opaqueExpressionClass, kernel.opaqueStatementClass,
            kernel.opaqueTypeClass, kernel.hostDeclarationsClass,
        ]
        for identifier in index.order {
            guard let object = index.object(identifier),
                  let eClass = excluded.first(where: { isKind(object, $0) }) else { continue }
            report(.strictProfile, object, "The strict profile admits no \(eClass.name)")
        }
    }
}
