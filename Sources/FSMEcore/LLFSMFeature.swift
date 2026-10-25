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
    /// The `name` feature.
    case name
    /// The `language` feature.
    case language
    /// The `types` feature.
    case types
    /// The `variables` feature.
    case variables
    /// The `functions` feature.
    case functions
    /// The `hostDeclarations` feature.
    case hostDeclarations
    /// The `machines` feature.
    case machines
    /// The `instances` feature.
    case instances
    /// The `states` feature.
    case states
    /// The `initial` feature.
    case initial
    /// The `machine` feature.
    case machine
    /// The `bindings` feature.
    case bindings
    /// The `variable` feature.
    case variable
    /// The `value` feature.
    case value
    /// The `passThrough` feature.
    case passThrough
    /// The `actions` feature.
    case actions
    /// The `transitions` feature.
    case transitions
    /// The `label` feature.
    case label
    /// The `target` feature.
    case target
    /// The `origin` feature.
    case origin
    /// The `state` feature.
    case state
    /// The `role` feature.
    case role
    /// The `transition` feature.
    case transition
    /// The `type` feature.
    case type
    /// The `external` feature.
    case external
    /// The `initialValue` feature.
    case initialValue
    /// The `pure` feature.
    case pure
    /// The `parameters` feature.
    case parameters
    /// The `result` feature.
    case result
    /// The `receiverType` feature.
    case receiverType
    /// The `includes` feature.
    case includes
    /// The `declarations` feature.
    case declarations
    /// The `includePaths` feature.
    case includePaths
    /// The `documentation` feature.
    case documentation
    /// The `declarationText` feature.
    case declarationText
    /// The `declarationLine` feature.
    case declarationLine
    /// The `lower` feature.
    case lower
    /// The `upper` feature.
    case upper
    /// The `literals` feature.
    case literals
    /// The `element` feature.
    case element
    /// The `size` feature.
    case size
    /// The `text` feature.
    case text
    /// The `literal` feature.
    case literal
    /// The `index` feature.
    case index
    /// The `operation` feature.
    case operation
    /// The `operand` feature.
    case operand
    /// The `left` feature.
    case left
    /// The `right` feature.
    case right
    /// The `condition` feature.
    case condition
    /// The `whenTrue` feature.
    case whenTrue
    /// The `whenFalse` feature.
    case whenFalse
    /// The `instance` feature.
    case instance
    /// The `function` feature.
    case function
    /// The `receiver` feature.
    case receiver
    /// The `arguments` feature.
    case arguments
    /// The `values` feature.
    case values
    /// The `call` feature.
    case call
    /// The `onEntry` feature.
    case onEntry
    /// The `onExit` feature.
    case onExit
    /// The `internal` feature.
    case `internal`
    /// The `onSuspend` feature.
    case onSuspend
    /// The `onResume` feature.
    case onResume
    /// The `suspendState` feature.
    case suspendState
    /// The `unit` feature.
    case unit
}

/// Reads of the LLFSM features of a dynamic object.
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
        case let values as [String]:
            return values
        case let value as String:
            return [value]
        default:
            return []
        }
    }

    /// The identifier held by a single-valued reference.
    ///
    /// - Parameter feature: The reference to read.
    /// - Returns: The identifier, or `nil` if the reference is unset.
    func identifier(_ feature: LLFSMFeature) -> EUUID? {
        switch eGet(feature.rawValue) {
        case let identifier as EUUID:
            return identifier
        case let identifiers as [EUUID]:
            return identifiers.first
        default:
            return nil
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
        case let identifier as EUUID:
            return [identifier]
        case let identifiers as [EUUID]:
            return identifiers
        default:
            return []
        }
    }
}
