//
//  StateActivities.swift
//
//  Created by Rene Hexel on 21/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//

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
}

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
                self[0] = newValue
            }
        }
    }

    /// The `onExit` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `onExit` action of a state.
    @inlinable var onExit: Element {
        get { count >= 2 ? self[1] : "" }
        set {
            switch count {
            case 0:
                append("")
                fallthrough
            case 1:
                append(newValue)
            default:
                self[1] = newValue
            }
        }
    }

    /// The `internal` action of a state.
    ///
    /// This property interprets the second element of the array
    /// as the `internal` action of a state.
    @inlinable var `internal`: Element {
        get { count >= 3 ? self[2] : "" }
        set {
            switch count {
            case 0:
                append("")
                fallthrough
            case 1:
                append("")
                fallthrough
            case 2:
                append(newValue)
            default:
                self[2] = newValue
            }
        }
    }
}

