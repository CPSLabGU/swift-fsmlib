//
//  TransformationDiagnostics.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// A condition under which a transformation between LLFSM levels could not
/// keep all information or all of the execution semantics.
///
/// Transformations record a warning wherever they fall back to a less
/// faithful representation instead of failing.
public struct TransformationWarning: Sendable, Hashable, CustomStringConvertible {
    /// The kinds of lossy transformation.
    public enum Kind: Sendable, Hashable {
        /// A kernel machine carries no origin records and was mapped flatly.
        ///
        /// Actions became entry sections and pass-through states became
        /// ordinary states, so the sectioned machine executes differently.
        ///
        /// - Parameter machine: The name of the machine.
        case flatMapping(machine: String)

        /// Suspension was not encoded for a machine with a suspend state.
        ///
        /// The suspend state designation, the control statements and the
        /// suspend and resume sections were dropped.
        ///
        /// - Parameter machine: The name of the machine.
        case suspensionOmitted(machine: String)

        /// Several instances of a suspensible machine share one suspension request.
        ///
        /// - Parameters:
        ///   - machine: The name of the machine.
        ///   - instances: The names of its instances, in arrangement order.
        case sharedSuspension(machine: String, instances: [String])

        /// A machine control statement could not be encoded and was dropped.
        ///
        /// Restarts are not encoded, and suspending or resuming an instance
        /// has no effect where its suspension is not encoded.
        ///
        /// - Parameters:
        ///   - operation: The name of the control operation.
        ///   - instance: The name of the controlled instance.
        case controlDropped(operation: String, instance: String)

        /// Host-language text that has no place at the target level was left out.
        ///
        /// - Parameters:
        ///   - section: The name of the section that held the text.
        ///   - owner: The name of the machine or state that held the section.
        case droppedText(section: String, owner: String)

        /// Structural information that the source level does not keep could not be recovered.
        ///
        /// - Parameters:
        ///   - information: What could not be recovered.
        ///   - owner: The name of the machine, arrangement or instance concerned.
        case notRecovered(StructuralInformation, owner: String)
    }

    /// The information of structural models that the sectioned and kernel levels do not keep.
    public enum StructuralInformation: String, CaseIterable, Sendable, Hashable {
        /// The include path of a machine.
        case includePath
        /// The layout of the states and transitions of a machine and the window layout of its editor.
        case layout
        /// The boilerplate of the states of a machine, which the kernel holds as host declarations of the
        /// machine.
        case stateBoilerplate
        /// The layout and comments of the variable declarations that the typing pass recognised.
        case declarationFormatting
        /// The shared types, variables, functions and host declarations of an arrangement.
        case sharedDeclarations
        /// The instance-specific initial values of an instance.
        case instanceBindings
        /// A machine without instances, which a structural arrangement cannot hold.
        case uninstantiatedMachine
    }

    /// What was lost.
    public let kind: Kind

    /// Create a warning.
    ///
    /// - Parameter kind: What was lost.
    public init(_ kind: Kind) {
        self.kind = kind
    }

    /// A sentence that describes the warning to a person.
    public var message: String {
        switch kind {
        case .flatMapping(let machine):
            return "Machine '\(machine)' has no origin records and was mapped flatly; its execution semantics differ"
        case .suspensionOmitted(let machine):
            return "Suspension of machine '\(machine)' was omitted with its suspend and resume sections"
        case .sharedSuspension(let machine, let instances):
            return "The instances \(instances.joined(separator: ", ")) of machine '\(machine)' share one suspension request"
        case .controlDropped(let operation, let instance):
            return "The \(operation) control of instance '\(instance)' cannot be encoded and was dropped"
        case .droppedText(let section, let owner):
            return "The \(section) text of '\(owner)' has no place at the target level and was left out"
        case .notRecovered(let information, let owner):
            return Self.message(notRecovering: information, owner: owner)
        }
    }

    /// The ``message`` of the warning.
    public var description: String { message }

    /// The sentence for structural information that could not be recovered.
    private static func message(notRecovering information: StructuralInformation, owner: String) -> String {
        switch information {
        case .includePath:
            return "The include path of '\(owner)' is not kept by the source level and was left empty"
        case .layout:
            return "The layout of '\(owner)' is not kept by the source level and was left out"
        case .stateBoilerplate:
            return "The state boilerplate of '\(owner)' was merged into its machine boilerplate"
        case .declarationFormatting:
            return "The variable declarations of '\(owner)' are written in canonical form without their comments"
        case .sharedDeclarations:
            return "The shared declarations of '\(owner)' have no place in structural models and were left out"
        case .instanceBindings:
            return "The bindings of instance '\(owner)' have no place in structural models and were left out"
        case .uninstantiatedMachine:
            return "Machine '\(owner)' has no instance and has no place in a structural arrangement"
        }
    }
}

/// The warnings collected while a transformation ran.
///
/// Each distinct warning is kept once, in the order in which it was first recorded.
public struct TransformationDiagnostics: Sendable, Equatable {
    /// The distinct warnings in the order in which they were first recorded.
    public private(set) var warnings: [TransformationWarning] = []

    /// The warnings recorded so far, for detecting repetitions.
    private var recorded: Set<TransformationWarning> = []

    /// Create an empty collection of warnings.
    public init() {}

    /// Whether no warning has been recorded.
    public var isEmpty: Bool { warnings.isEmpty }

    /// Record a warning unless the same warning has been recorded before.
    ///
    /// - Parameter kind: What was lost.
    public mutating func record(_ kind: TransformationWarning.Kind) {
        let warning = TransformationWarning(kind)
        guard recorded.insert(warning).inserted else { return }
        warnings.append(warning)
    }

    /// Record the warnings of another collection that have not been recorded before.
    ///
    /// - Parameter other: The warnings to add, in their order.
    mutating func merge(_ other: TransformationDiagnostics) {
        for warning in other.warnings { record(warning.kind) }
    }
}

/// The model that a transformation produced, with its diagnostics.
public struct TransformationResult: Sendable {
    /// The resource that holds the produced model.
    public let resource: Resource

    /// The warnings recorded while the model was produced.
    public let diagnostics: TransformationDiagnostics

    /// Create a result.
    ///
    /// - Parameters:
    ///   - resource: The resource that holds the produced model.
    ///   - diagnostics: The warnings recorded while the model was produced.
    public init(resource: Resource, diagnostics: TransformationDiagnostics) {
        self.resource = resource
        self.diagnostics = diagnostics
    }
}
