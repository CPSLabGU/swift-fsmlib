//
//  StateActivities.swift
//
//  Created by Rene Hexel on 21/10/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable fallthrough

/// Protocol for state activities (OnEntry, OnExit, Internal)
public protocol StateActivities {
    /// Abstract representation of a state action
    ///
    /// This type represents one action of a state
    /// (e.g, OnEntry, OnExit, or Internal).
    associatedtype StateAction

    /// Abstract representation of a state activity
    ///
    /// This type represents the activity of a state
    /// (e.g, OnEntry, OnExit, and Internal actions).
    typealias StateActivity = [StateAction]

    /// Mapping from a state to a particular action (OnEntry, OnExit, Internal)
    typealias StateActionsMapping = Dictionary<StateID, StateActivity>

    /// Mapping of states to their actions.
    var actions: StateActionsMapping { get mutating set }
}

/// Extension providing convenience properties for accessing and mutating
/// canonical state activity actions (onEntry, onExit, internal, onSuspend,
/// onResume) in arrays of string-like elements. This enables easy access
/// and modification of state activity code sections in a type-safe and
/// readable manner.
extension StateActivities {
    /// Return the activity for a given state.
    ///
    /// This method returns the array of actions for a given state.
    ///
    /// - Parameter stateID: ID of the state to return the actions for.
    /// - Returns: Actions for the given state.
    @inlinable
    public func actions(for stateID: StateID) -> StateActivity {
        actions[stateID] ?? []
    }
}

/// Concrete implementation for source code representation of state activities
public struct StateActivitiesSourceCode: StateActivities {
    /// The source code for a state action.
    public typealias StateAction = String
    /// The array of actions associated with the state.
    public typealias StateActions = [StateAction]

    /// Mapping of states to their actions.
    public var actions = StateActionsMapping()

    /// Designated initialiser.
    @inlinable
    public init() {}
}

/// Name of a state activity.
///
/// This represents the cannonical state activities
/// in the order in which they are stored in the array.
public enum StateActivityName: String, RawRepresentable, CaseIterable, Codable {
    /// The OnEntry activity, executed when entering a state.
    case onEntry
    /// The OnExit activity, executed when exiting a state.
    case onExit
    /// The Internal activity, executed while in a state.
    case `internal`
    /// The OnSuspend activity, executed when suspending a state.
    case onSuspend
    /// The OnResume activity, executed when resuming a state.
    case onResume
}

/// Order of state actions.
///
/// This represents the array index of cannonical state activities
/// in the order in which they are stored in the array.
public enum StateActionIndex: Int, RawRepresentable, CaseIterable, Codable {
    /// Index for the OnEntry activity in the state activity array.
    case onEntry
    /// Index for the OnExit activity in the state activity array.
    case onExit
    /// Index for the Internal activity in the state activity array.
    case `internal`
    /// Index for the OnSuspend activity in the state activity array.
    case onSuspend
    /// Index for the OnResume activity in the state activity array.
    case onResume
}

/// Extension providing convenience properties for accessing and mutating
/// canonical state activity actions (onEntry, onExit, internal, onSuspend,
/// onResume) in arrays of string-like elements. This enables easy access
/// and modification of state activity code sections in a type-safe and
/// readable manner.
extension Array where Element: StringProtocol {
    /// The `onEntry` action of a state.
    ///
    /// This property interprets the first element of the array
    /// as the `onEntry` action of a state.
    @inlinable var onEntry: Element {
        get { first ?? "" }
        set {
            if isEmpty {
                append(newValue)
            } else {
                self[StateActionIndex.onEntry.rawValue] = newValue
            }
        }
    }

    /// The `onExit` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `onExit` action of a state.
    @inlinable var onExit: Element {
        get { count > StateActionIndex.onExit.rawValue ? self[StateActionIndex.onExit.rawValue] : "" }
        set {
            switch count {
            case StateActionIndex.onEntry.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onExit.rawValue:
                append(newValue)
            default:
                self[StateActionIndex.onExit.rawValue] = newValue
            }
        }
    }

    /// The `internal` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `internal` action of a state.
    @inlinable var `internal`: Element {
        get { count > StateActionIndex.internal.rawValue ? self[StateActionIndex.internal.rawValue] : "" }
        set {
            switch count {
            case StateActionIndex.onEntry.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onExit.rawValue:
                append("")
                fallthrough
            case StateActionIndex.internal.rawValue:
                append(newValue)
            default:
                self[2] = newValue
            }
        }
    }

    /// The `onSuspend` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `onSuspend` action of a state.
    @inlinable var onSuspend: Element {
        get { count > StateActionIndex.onSuspend.rawValue ? self[StateActionIndex.onSuspend.rawValue] : "" }
        set {
            switch count {
            case StateActionIndex.onEntry.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onExit.rawValue:
                append("")
                fallthrough
            case StateActionIndex.internal.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onSuspend.rawValue:
                append(newValue)
            default:
                self[StateActionIndex.onSuspend.rawValue] = newValue
            }
        }
    }

    /// The `onResume` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `onSuspend` action of a state.
    @inlinable var onResume: Element {
        get { count > StateActionIndex.onResume.rawValue ? self[StateActionIndex.onResume.rawValue] : "" }
        set {
            switch count {
            case StateActionIndex.onEntry.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onExit.rawValue:
                append("")
                fallthrough
            case StateActionIndex.internal.rawValue:
                append("")
                fallthrough
            case StateActionIndex.onSuspend.rawValue:
                append(newValue)
                fallthrough
            case StateActionIndex.onResume.rawValue:
                append(newValue)
            default:
                self[StateActionIndex.onResume.rawValue] = newValue
            }
        }
    }
}
