//
//  SectionedMetamodel.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// The sectioned level of the LLFSM metamodel family.
///
/// `SectionedMetamodel` resolves the `sectioned` subpackage of the bundled
/// `LLFSM.ecore` document and keeps typed handles for its classes and
/// enumerations. Sectioned models reuse the kernel's types, variables,
/// functions, expressions and statements, so the kernel level is available
/// as ``kernel``.
///
/// ```swift
/// let sectioned = try await SectionedMetamodel()
/// var state = DynamicEObject(eClass: sectioned.stateClass)
/// state.eSet("name", value: "Waiting")
/// ```
public struct SectionedMetamodel: Sendable {
    /// The root package `llfsm` that contains the sectioned subpackage.
    ///
    /// The root package also contains the kernel subpackage, so registering
    /// it makes both levels known to a resource set.
    public let rootPackage: EPackage

    /// The `sectioned` subpackage.
    ///
    /// Its namespace URI is ``LLFSMMetamodels/sectionedNamespaceURI``.
    public let package: EPackage

    /// The kernel level whose elements sectioned models contain.
    ///
    /// Use it to create the types, variables, expressions and statements of
    /// a sectioned model.
    public let kernel: KernelMetamodel

    /// The sectioned `Arrangement` class: a closed system of sectioned machine instances.
    ///
    /// The types, variables, functions and host declarations are kernel elements; machines and
    /// instances are sectioned.
    public let arrangementClass: EClass

    /// The sectioned `Machine` class: a sectioned machine definition.
    ///
    /// A sectioned machine may name a suspend state that suspended instances occupy.
    public let machineClass: EClass

    /// The sectioned `Instance` class: a named occurrence of a sectioned machine.
    ///
    /// Its bindings are kernel bindings of local variables of its machine.
    public let instanceClass: EClass

    /// The sectioned `State` class: a sectioned state.
    ///
    /// A sectioned state has entry, exit, internal, suspend and resume sections of kernel
    /// statements, and may hold kernel host declarations of its own.
    public let stateClass: EClass

    /// The sectioned `Transition` class: a labelled transition between sectioned states.
    ///
    /// Its label is a kernel expression.
    public let transitionClass: EClass

    /// The sectioned `StateTimeExpression` class: the time elapsed since the current state was
    /// entered.
    ///
    /// The unit is one of ``SectionedTimeUnit``; the class extends the kernel expression class.
    public let stateTimeExpressionClass: EClass

    /// The sectioned `InStateExpression` class: an observation that an instance occupies a
    /// sectioned state.
    ///
    /// The class extends the kernel expression class.
    public let inStateExpressionClass: EClass

    /// The sectioned `MachineControlStatement` class: a request to suspend, resume or restart
    /// another instance.
    ///
    /// The operation is one of ``SectionedControlOperation``; the class extends the kernel
    /// statement class.
    public let machineControlStatementClass: EClass

    /// The `TimeUnit` enumeration: the enumeration of time units.
    ///
    /// Its literals are those of ``SectionedTimeUnit``.
    public let timeUnitEnum: EEnum

    /// The `ControlOperation` enumeration: the enumeration of machine control operations.
    ///
    /// Its literals are those of ``SectionedControlOperation``.
    public let controlOperationEnum: EEnum

    /// Load the sectioned level from the bundled metamodel document.
    ///
    /// The document is loaded once per program and shared with
    /// ``KernelMetamodel`` and ``LLFSMMetamodels``.
    ///
    /// - Throws: An error if the document cannot be found or parsed, or
    ///   ``LLFSMMetamodelsError`` if it lacks a required classifier or literal.
    public init() async throws {
        try self.init(rootPackage: try await LLFSMMetamodels.loadBundledRootPackage())
    }

    /// Resolve the sectioned level within a loaded root package.
    ///
    /// - Parameter rootPackage: The root package `llfsm` of the metamodel family.
    /// - Throws: ``LLFSMMetamodelsError`` if the sectioned or kernel
    ///   subpackage, one of their classes, or a literal of one of their
    ///   enumerations is missing.
    public init(rootPackage: EPackage) throws {
        self.rootPackage = rootPackage
        kernel = try KernelMetamodel(rootPackage: rootPackage)
        package = try LLFSMMetamodels.subpackage(
            named: "sectioned",
            nsURI: LLFSMMetamodels.sectionedNamespaceURI,
            of: rootPackage
        )
        let lookup = LLFSMClassifierLookup(package: package)
        arrangementClass = try lookup.eClass("Arrangement")
        machineClass = try lookup.eClass("Machine")
        instanceClass = try lookup.eClass("Instance")
        stateClass = try lookup.eClass("State")
        transitionClass = try lookup.eClass("Transition")
        stateTimeExpressionClass = try lookup.eClass("StateTimeExpression")
        inStateExpressionClass = try lookup.eClass("InStateExpression")
        machineControlStatementClass = try lookup.eClass("MachineControlStatement")
        timeUnitEnum = try lookup.eEnum("TimeUnit", literals: SectionedTimeUnit.self)
        controlOperationEnum = try lookup.eEnum("ControlOperation", literals: SectionedControlOperation.self)
    }

    /// Register the metamodel family with a resource set.
    ///
    /// The root package is registered under its namespace URI, which also
    /// makes the kernel and sectioned subpackages available under theirs.
    ///
    /// - Parameter resourceSet: The resource set that should know the metamodels.
    public func register(in resourceSet: ResourceSet) async {
        await LLFSMMetamodels.register(rootPackage, in: resourceSet)
    }
}

/// The units of sectioned state-time expressions.
///
/// The raw values are the literal names of the `TimeUnit` enumeration of
/// the sectioned metamodel.
public enum SectionedTimeUnit: String, CaseIterable, Sendable {
    /// Microseconds, the default unit.
    case microseconds
    /// Milliseconds.
    case milliseconds
    /// Seconds.
    case seconds
    /// Rounds of the arrangement, as counted by a clock machine.
    case ticks
}

/// The operations of sectioned machine control statements.
///
/// The raw values are the literal names of the `ControlOperation`
/// enumeration of the sectioned metamodel.
public enum SectionedControlOperation: String, CaseIterable, Sendable {
    /// Suspend the controlled instance.
    case suspend
    /// Resume the controlled instance.
    case resume
    /// Restart the controlled instance in its initial state.
    case restart
}
