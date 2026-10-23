//
//  KernelValidator.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The profiles under which kernel models are validated.
///
/// The strict profile admits only typed kernel nodes, so that every target,
/// including verification targets, can process the model. The relaxed
/// profile also admits opaque host-language nodes for code targets and
/// suspends the type-dependent rules where opaque nodes are involved.
public enum ValidationProfile: String, CaseIterable, Sendable {
    /// Every rule applies, and opaque nodes and host declarations are rejected.
    case strict
    /// Opaque nodes and host declarations are admitted.
    ///
    /// The structural rules and rules W1 to W4, W8 and W9 always apply;
    /// rules W5 to W7 apply only where the types involved are typed kernel
    /// types, so an opaque operand suspends them for its subtree.
    case relaxed
}

/// The well-formedness rules of the kernel metamodel.
///
/// The raw value of each rule is the code reported in ``KernelDiagnostic/rule``.
public enum KernelRule: String, CaseIterable, Sendable {
    /// Mandatory features are present, references resolve to objects of the
    /// declared class, transitions target states of their own machine and
    /// bindings name local variables of the instance's machine.
    case structure = "STRUCT"
    /// Names are unique per containment feature and are identifiers, and
    /// enumeration literals are unique.
    case names = "W1"
    /// The initial state is one of the machine's states and is not pass-through.
    case initialState = "W2"
    /// Transitions into pass-through states form no cycle.
    case passThroughCycle = "W3"
    /// External variables are shared variables and are never assigned.
    case externalVariables = "W4"
    /// Expressions are well typed.
    case typing = "W5"
    /// Within one action a variable is assigned at most once and is not read
    /// after it has been assigned.
    case singleAssignment = "W6"
    /// Integer literals lie within the range of the variable they are
    /// assigned or bound to.
    case range = "W7"
    /// The right operand of a division or remainder is not provably non-negative.
    ///
    /// Diagnostics for this rule are warnings.
    case unprovenDivisor = "W7?"
    /// Binding values are literals.
    case bindingLiteral = "W8"
    /// Labels, binding values and initial values call pure functions only.
    case purity = "W9"
    /// The strict profile admits no opaque nodes and no host declarations.
    case strictProfile = "STRICT"
}

/// A violation of a kernel well-formedness rule.
///
/// A diagnostic names the rule, its severity, the path of the offending
/// object from the root of the model and a message that explains the
/// violation. Paths name objects by their `name` where they have one and by
/// their position otherwise, for example
/// `/Relay/machines[Pinger]/states[Ping]/transitions[0]/label`.
public struct KernelDiagnostic: Sendable, Hashable, CustomStringConvertible {
    /// How serious a diagnostic is.
    public enum Severity: String, Sendable, CaseIterable {
        /// The model is not well formed.
        case error
        /// The model may be well formed, but the rule could not prove it.
        case warning
    }

    /// The rule that the object violates.
    public let rule: KernelRule

    /// How serious the violation is.
    public let severity: Severity

    /// The path of the offending object from the root of the model.
    public let path: String

    /// A sentence that explains the violation.
    public let message: String

    /// Create a diagnostic.
    ///
    /// - Parameters:
    ///   - rule: The violated rule.
    ///   - severity: How serious the violation is.
    ///   - path: The path of the offending object.
    ///   - message: A sentence that explains the violation.
    public init(rule: KernelRule, severity: Severity, path: String, message: String) {
        self.rule = rule
        self.severity = severity
        self.path = path
        self.message = message
    }

    /// The code of the violated rule, such as `W5`.
    public var code: String { rule.rawValue }

    /// The diagnostic as one line: severity, code, path and message.
    public var description: String {
        "\(severity.rawValue) \(code) \(path): \(message)"
    }
}

/// Validates kernel models against the kernel well-formedness rules.
///
/// The validator checks a resource whose objects are typed by the classes
/// of ``metamodel``, as produced by parsing a document in a resource set in
/// which the metamodel is registered, or by building objects from its class
/// handles. The diagnostics are ordered by rule and, within a rule, by the
/// position of the offending object in the model.
///
/// ```swift
/// let validator = KernelValidator(metamodel: kernel, profile: .strict)
/// let diagnostics = await validator.validate(resource)
/// let isWellFormed = !diagnostics.contains { $0.severity == .error }
/// ```
public struct KernelValidator: Sendable {
    /// The kernel metamodel that types the validated models.
    public let metamodel: KernelMetamodel

    /// The profile whose rules apply.
    public let profile: ValidationProfile

    /// Create a validator.
    ///
    /// - Parameters:
    ///   - metamodel: The kernel metamodel that types the validated models.
    ///   - profile: The profile whose rules apply (default ``ValidationProfile/strict``).
    public init(metamodel: KernelMetamodel, profile: ValidationProfile = .strict) {
        self.metamodel = metamodel
        self.profile = profile
    }

    /// Validate the kernel model held by a resource.
    ///
    /// - Parameter resource: The resource whose root objects are kernel arrangements.
    /// - Returns: The diagnostics, empty if the model satisfies every rule of the profile.
    public func validate(_ resource: Resource) async -> [KernelDiagnostic] {
        let index = await KernelModelIndex(resource: resource)
        var validation = KernelValidation(metamodel: metamodel, profile: profile, index: index)
        validation.run()
        return validation.diagnostics
    }

    /// Whether a list of diagnostics contains an error.
    ///
    /// - Parameter diagnostics: Diagnostics returned by ``validate(_:)``.
    /// - Returns: `true` if at least one diagnostic has severity ``KernelDiagnostic/Severity/error``.
    public static func containsErrors(_ diagnostics: [KernelDiagnostic]) -> Bool {
        diagnostics.contains { $0.severity == .error }
    }
}
