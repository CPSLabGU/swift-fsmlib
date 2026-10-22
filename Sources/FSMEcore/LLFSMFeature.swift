//
//  LLFSMFeature.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The names of the structural features of the kernel and sectioned metamodels.
///
/// Every feature name that Swift code reads or writes is spelt once here;
/// the raw values are the names declared in `LLFSM.ecore`.
enum LLFSMFeature: String, CaseIterable, Sendable {
    case name, language, types, variables, functions, hostDeclarations
    case machines, instances, states, initial, machine, bindings
    case variable, value, passThrough, actions, transitions, label, target
    case origin, state, role, transition
    case type, external, initialValue
    case pure, parameters, result, receiverType, includes, declarations
    case lower, upper, literals, element, size, text, literal
    case index, operation, operand, left, right
    case condition, whenTrue, whenFalse, instance
    case function, receiver, arguments, values, call
    case onEntry, onExit, `internal`, onSuspend, onResume, suspendState, unit
}

extension DynamicEObject {
    /// The value of a feature, or its default while it is unset.
    ///
    /// - Parameter feature: The feature to read.
    /// - Returns: The stored or default value, or `nil` if there is neither.
    func value(_ feature: LLFSMFeature) -> (any EcoreValue)? {
        eGetWithDefault(feature.rawValue)
    }

    /// Whether a feature has been set explicitly.
    ///
    /// - Parameter feature: The feature to test.
    /// - Returns: `true` if a value is stored for the feature.
    func isSet(_ feature: LLFSMFeature) -> Bool {
        eGet(feature.rawValue) != nil
    }

    /// The string value of a feature.
    ///
    /// - Parameter feature: The feature to read.
    /// - Returns: The string, or `nil` if the feature holds no string.
    func string(_ feature: LLFSMFeature) -> String? {
        value(feature) as? String
    }

    /// The Boolean value of a feature, defaulting to `false`.
    ///
    /// - Parameter feature: The feature to read.
    /// - Returns: The Boolean, or `false` if the feature holds none.
    func bool(_ feature: LLFSMFeature) -> Bool {
        value(feature) as? Bool ?? false
    }

    /// The integer value of a feature.
    ///
    /// - Parameter feature: The feature to read.
    /// - Returns: The integer, or `nil` if the feature holds none.
    func int(_ feature: LLFSMFeature) -> Int? {
        value(feature) as? Int
    }

    /// The string values of a many-valued attribute.
    ///
    /// - Parameter feature: The feature to read.
    /// - Returns: The strings in order, or an empty array.
    func strings(_ feature: LLFSMFeature) -> [String] {
        switch value(feature) {
        case let values as [String]: return values
        case let value as String: return [value]
        default: return []
        }
    }

    /// The identifier held by a single-valued reference.
    ///
    /// - Parameter feature: The reference to read.
    /// - Returns: The identifier, or `nil` if the reference is unset.
    func identifier(_ feature: LLFSMFeature) -> EUUID? {
        switch eGet(feature.rawValue) {
        case let identifier as EUUID: return identifier
        case let identifiers as [EUUID]: return identifiers.first
        default: return nil
        }
    }

    /// The identifiers held by a reference, in order.
    ///
    /// - Parameter feature: The reference to read.
    /// - Returns: The identifiers, or an empty array if the reference is unset.
    func identifiers(_ feature: LLFSMFeature) -> [EUUID] {
        identifiers(named: feature.rawValue)
    }

    /// The identifiers held by a reference given by name, in order.
    ///
    /// - Parameter name: The name of the reference to read.
    /// - Returns: The identifiers, or an empty array if the reference is unset.
    func identifiers(named name: String) -> [EUUID] {
        switch eGet(name) {
        case let identifier as EUUID: return [identifier]
        case let identifiers as [EUUID]: return identifiers
        default: return []
        }
    }
}
