//
//  LLFSM.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//

/// LLFSM value type.
///
/// `LLFSM` stores the state graph for a low-level finite-state machine. It
/// keeps stable identifiers for states and transitions while also maintaining
/// lookup dictionaries used by higher-level machine storage, layout handling,
/// and code generation code.
public struct LLFSM: SuspensibleFSM, Equatable, Hashable {
    /// State identifiers in declaration order.
    ///
    /// This array preserves the machine's state order while the internal state
    /// dictionary provides efficient lookup by identifier.
    public var states: StateArray

    /// Suspend state identifier.
    ///
    /// This optional identifier points to the machine's suspend state when the
    /// model supports suspension.
    public var suspendState: StateID?

    /// Transition identifiers in declaration order.
    ///
    /// This array preserves the machine's transition order while the internal
    /// transition dictionary provides efficient lookup by identifier.
    public var transitions: TransitionArray

    /// Mapping from state IDs to states
    @usableFromInline var stateMap: StateDictionary

    /// Mapping from transition IDs to transitions
    @usableFromInline var transitionMap: TransitionDictionary

    /// Return transitions whose source is the given state.
    ///
    /// This helper filters the ordered transition list using the internal
    /// transition lookup table, preserving transition order in the result.
    ///
    /// - Parameter s: State identifier to inspect.
    /// - Returns: Transition identifiers whose source matches `s`.
    @inlinable
    public func transitionsFrom(_ s: StateID) -> TransitionArray {
        return transitions.filter { transitionMap[$0]?.source == s }
    }

    /// Get the name of the given state.
    ///
    /// This returns the name of the given state,
    /// or the `nil` if the state is not found.
    /// - Parameter stateID: the ID of the state
    /// - Returns: The name of the state, or `nil` if the state is not found.
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
    public mutating func set(name: StateName, for stateID: StateID) {
        if var state = stateMap[stateID] {
            state.name = name
            stateMap[stateID] = state
        } else {
            states.append(stateID)
            stateMap[stateID] = State(id: stateID, name: name)
        }
    }

    /// Get the label of the given transition.
    ///
    /// This returns the label of the given transition,
    /// or the `nil` if the transition is not found.
    ///
    /// - Parameter transitionID: the ID of the transition
    /// - Returns: The label of the transition, or `nil` if the transition is not found.
    @inlinable
    public func label(for transitionID: TransitionID) -> Expression? {
        return transitionMap[transitionID]?.label
    }

    /// Return a transition value for an identifier.
    ///
    /// Use this accessor when code outside the `FSM` module needs the full
    /// stored transition rather than only its label, source, or target.
    ///
    /// - Parameter transitionID: Transition identifier to resolve.
    /// - Returns: Stored transition value, or `nil` if it does not exist.
    @inlinable
    public func transition(for transitionID: TransitionID) -> Transition? {
        transitionMap[transitionID]
    }

    /// Set the label of a given transition.
    ///
    /// - Parameters:
    ///   - label: The label to set.
    ///   - transitionID: The ID of the transition whose label should be set.
    @inlinable
    public mutating func set(label: Expression, for transitionID: TransitionID) {
        if var transition = transitionMap[transitionID] {
            transition.label = label
            transitionMap[transitionID] = transition
        } else {
            transitions.append(transitionID)
            let stateID: StateID
            if let lastStateID = states.last {
                stateID = lastStateID
            } else {
                let state = State(name: "Initial")
                stateID = state.id
                states.append(stateID)
                stateMap[stateID] = state
            }
            transitionMap[transitionID] = Transition(id: transitionID, label: label, source: stateID)
        }
    }

    /// Return the source state for the given transition.
    ///
    /// This function returns the ID of the source state
    /// for the given transition, or `nil` if the transition
    /// does not exist.
    ///
    /// - Parameter transitionID: The ID of the transition.
    /// - Returns: The ID of the source state, or `nil` if the transition does not exist.
    @inlinable
    public func sourceState(for transitionID: TransitionID) -> StateID? {
        transitionMap[transitionID]?.source
    }

    /// Set the source state for the given transition.
    ///
    /// This function sets the source state for the given transition.
    ///
    /// - Parameters:
    ///   - transitionID: The ID of the transition.
    ///   - stateID: The ID of the source state.
    @inlinable
    public mutating func setSourceState(for transitionID: TransitionID, to stateID: StateID) {
        transitionMap[transitionID]?.source = stateID
    }

    /// Return the target state for the given transition, or `nil` if the transition
    /// does not exist.
    ///
    /// - Parameter transitionID: The ID of the transition.
    /// - Returns: The ID of the target state, or `nil` if the transition does not exist.
    @inlinable
    public func targetState(for transitionID: TransitionID) -> StateID? {
        transitionMap[transitionID]?.target
    }

    /// Set the target state for the given transition.
    ///
    /// This function sets the target state for the given transition.
    ///
    /// - Parameters:
    ///   - transitionID: The ID of the transition.
    ///   - stateID: The ID of the target state.
    @inlinable
    public mutating func setTargetState(for transitionID: TransitionID, to stateID: StateID) {
        transitionMap[transitionID]?.target = stateID
    }
}

/// Extension providing state name utilities for LLFSM.
///
/// This extension adds a computed property for retrieving the names of all
/// states in the LLFSM, in the order they appear. If a state has no name,
/// its UUID string is used instead.
///
/// - Note: This is useful for serialisation, debugging, and code generation.
public extension LLFSM {
    /// Return the state names of this LLFSM.
    ///
    /// This function returns an array of strings
    /// reprsesenting the names of the machine's states
    /// in the order these states appear in the machine.
    ///
    /// - Note: if a state has no name, a uuidString will be inserted instead.
    ///
    var stateNames: [String] {
        states.map {
            stateMap[$0]?.name ?? $0.uuidString
        }
    }

    /// Designated initialiser for an LLFSM.
    ///
    /// This initialiser constructs an LLFSM from arrays of states and transitions,
    /// and an optional suspend state. It builds the internal state and transition
    /// maps for efficient lookup.
    ///
    /// - Parameters:
    ///   - states: The array of states for the machine.
    ///   - transitions: The array of transitions for the machine.
    ///   - suspendState: The optional suspend state ID.
    init(states: [State], transitions: [Transition], suspendState: StateID? = nil) {
        self.states = states.map { $0.id }
        self.transitions = transitions.map { $0.id }
        self.transitionMap = dictionary(transitions)
        self.stateMap = dictionary(states)
        self.suspendState = suspendState
    }
}

/// Extension providing Hashable conformance for LLFSM.
///
/// This extension implements the hash function for LLFSM, combining all
/// relevant properties to ensure correct hashing behaviour for use in
/// collections.
///
/// - Note: Hashing includes states, suspend state, transitions, and their maps.
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
