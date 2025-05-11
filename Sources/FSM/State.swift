//
//  State.swift
//
//  Created by Rene Hexel on 30/06/2015.
//  Copyright © 2015, 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Unique ID of a state
public typealias StateID = UUID

/// Abstract representation of a state
public protocol StateNode: CustomStringConvertible, Equatable {
    /// Unique ID of the state
    var id: StateID { get }

    /// Name of the state
    var name: String { get }
}

/// Default implementation of the description property for StateNode.
///
/// This extension provides a default implementation of the `description`
/// property for types conforming to the `StateNode` protocol. It returns the
/// name of the state.
public extension StateNode {
    /// Default description returning the name of the state
    var description: String { return name }
}

/// Compare two states
public func==<S: StateNode>(lhs: S, rhs: S) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
}

/// Concrete FSM State implementation.
///
/// This struct represents a concrete state in a finite-state machine (FSM),
/// uniquely identified by an ID and associated with a name. States are
/// fundamental building blocks of FSMs, representing distinct stages of system
/// behaviour. Each state can be compared for equality and used in hashed
/// collections.
///
/// - Note: States are used to model the different modes or configurations of
///         a system, and are referenced by transitions and layouts throughout
///         the FSM framework.
public struct State: StateNode, Equatable, Hashable {
    /// Unique ID of the state
    public var id: StateID

    /// Name of the state
    public var name: String

    /// Designated initialiser.
    @inlinable
    public init(id: StateID = StateID(), name: String) {
        self.id = id
        self.name = name
    }
}

/// Array of FSM states
public typealias StateArray = [StateID]

/// Mapping from IDs to states
public typealias StateDictionary = [StateID: State]

/// return the mapping dictionary for a given array of transitions
func dictionary(_ states: [State]) -> StateDictionary {
    return states.reduce(StateDictionary()) {
        var dictionary = $0
        dictionary[$1.id] = $1
        return dictionary
    }
}

/// Type for storing state names.
public typealias StateName = String
