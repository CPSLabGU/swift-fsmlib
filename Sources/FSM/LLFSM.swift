//
//  LLFSM.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023, 2024 Rene Hexel. All rights reserved.
//

/// Generic implementation of an LLFSM
public struct LLFSM: SuspensibleFSM, Equatable, Hashable {
    /// The states this machine is made up of
    public var states: StateArray

    /// Suspend state for the machine
    public var suspendState: StateID?

    /// All transitions (including ones not (yet) linked to a state)
    public var transitions: TransitionArray

    /// Mapping from state IDs to states
    @usableFromInline var stateMap: StateDictionary

    /// Mapping from transition IDs to transitions
    @usableFromInline var transitionMap: TransitionDictionary

    /// Return the transitions whose source is the given state
    @inlinable
    public func transitionsFrom(_ s: StateID) -> TransitionArray {
        return transitions.filter { transitionMap[$0]?.source == s }
    }

    /// Get the name of the given state.
    ///
    /// This returns the name of the given state,
    /// or the `nil` if the state is not found.
    /// - Parameter stateID: the ID of the state
    /// - Returns:
    @inlinable
    public func stateName(for stateID: StateID) -> StateName? {
        return stateMap[stateID]?.name
    }

    /// Set the name of a given state.
    ///
    /// - Parameters:
    ///   - name: The name to set.
    ///   - stateID: The ID of the state whose name should be set.
    @inlinable
    mutating public func set(name: StateName, for stateID: StateID) {
        if var state = stateMap[stateID] {
            state.name = name
            stateMap[stateID] = state
        } else {
            stateMap[stateID] = State(id: stateID, name: name)
        }
    }
}

public extension LLFSM {
    init(states: [State], transitions: [Transition], suspendState: StateID?) {
        self.states = states.map { $0.id }
        self.transitions = transitions.map { $0.id }
        self.transitionMap = dictionary(transitions)
        self.stateMap = dictionary(states)
        self.suspendState = suspendState
    }
}

// Hashable conformance
public extension LLFSM {
    /// Hash function.
    /// - Parameter hasher: Hasher to use for hashing.
    func hash(into hasher: inout Hasher) {
        hasher.combine(states)
        hasher.combine(suspendState)
        hasher.combine(transitions)
        hasher.combine(stateMap)
        hasher.combine(transitionMap)
    }
}
