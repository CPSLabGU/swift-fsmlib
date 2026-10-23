//
//  KernelTarget.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// A bundled template set that generates text from a kernel model.
///
/// Execution targets generate a program that runs the arrangement and
/// prints its canonical trace, verification targets generate a model for a
/// model checker, and the diagram target draws the arrangement. The raw
/// value of each target is its identifier, which is also the `name` of its
/// template set.
public enum KernelTarget: String, CaseIterable, Sendable, Codable {
    /// A C11 program.
    case c = "kernel-c"
    /// A C++20 program.
    case cpp = "kernel-cpp"
    /// A Swift 6 program.
    case swift = "kernel-swift"
    /// A Java 17 program.
    case java = "kernel-java"
    /// A nuXmv or NuSMV model.
    case smv
    /// A TLA+ specification with a TLC configuration.
    case tla
    /// A Graphviz drawing.
    case dot

    /// The name of the directory below the bundled `kernel` templates that holds the template set.
    public var templateDirectory: String {
        switch self {
        case .c: return "c"
        case .cpp: return "cpp"
        case .swift: return "swift"
        case .java: return "java"
        case .smv: return "smv"
        case .tla: return "tla"
        case .dot: return "dot"
        }
    }

    /// Whether the target generates a program that executes the arrangement.
    public var isExecutionTarget: Bool {
        switch self {
        case .c, .cpp, .swift, .java: return true
        case .smv, .tla, .dot: return false
        }
    }

    /// Whether the target generates a model for a model checker.
    public var isVerificationTarget: Bool {
        self == .smv || self == .tla
    }

    /// The validation profile that a model must satisfy before the target generates it.
    ///
    /// Verification targets require the strict profile, unless the template parameter
    /// ``KernelTemplateParameter/opaque`` asks them to havoc opaque nodes; every other target
    /// accepts the relaxed profile.
    ///
    /// - Parameter parameters: The template parameters of the generation run.
    /// - Returns: The profile under which the model is validated.
    public func validationProfile(parameters: [String: String]) -> ValidationProfile {
        guard isVerificationTarget else { return .relaxed }
        return parameters[KernelTemplateParameter.opaque] == KernelOpaqueTreatment.havoc.rawValue ? .relaxed : .strict
    }
}

/// The names of the template parameters of the kernel targets.
///
/// Parameters are passed to ``KernelTemplateGenerator`` as text and reach the
/// templates as `name=value` parameters.
public enum KernelTemplateParameter {
    /// The bound of the round counter of the verification targets (default 0: no counter).
    public static let maxRounds = "maxRounds"

    /// When a state's action runs in the verification targets; see ``KernelEntryMode``.
    public static let entry = "entry"

    /// Whether the verification targets add sanity properties (`true` or `false`, the default).
    public static let sanity = "sanity"

    /// How the verification targets treat opaque nodes; see ``KernelOpaqueTreatment``.
    public static let opaque = "opaque"
}

/// When the verification targets run the action of a state, the value of
/// ``KernelTemplateParameter/entry``.
public enum KernelEntryMode: String, CaseIterable, Sendable {
    /// The action runs in a micro-step of its own at the start of the next ringlet (the default).
    case ringlet
    /// The action runs in the micro-step of the transition that enters the state.
    case fused
}

/// How the verification targets treat opaque nodes, the value of
/// ``KernelTemplateParameter/opaque``.
public enum KernelOpaqueTreatment: String, CaseIterable, Sendable {
    /// Opaque nodes and calls of functions that are not pure in expressions are
    /// generation errors (the default).
    case reject
    /// Opaque values are unconstrained, opaque statements do nothing, and the generated
    /// file says so in its header.
    case havoc
}
