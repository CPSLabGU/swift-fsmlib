//
//  FSM.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Abstract representation of a finite-state machine
public protocol FSM: CustomStringConvertible {
    /// The states this machine is made up of
    var states: StateArray { get mutating set }

    /// Initial state for the machine
    var initialState: StateID { get mutating set }

    /// Transitions for the machine
    var transitions: TransitionArray { get mutating set }

    /// Return the transitions whose source is the given state
    func transitionsFrom(_ s: StateID) -> TransitionArray
}

extension FSM {
    /// By default the initial state is the first state
    @inlinable public var initialState: StateID {
        get { states[0] }
        set {
            if states.isEmpty {
                states.append(newValue)
            } else {
                states[0] = newValue
            }
        }
    }

    /// Default description of an FSM
    @inlinable public var description: String {
        states.map { $0.description }.joined(separator: "\n")
    }
}


/// Abstract protocol for a suspensible State
public protocol Suspensible: CustomStringConvertible {
    /// Suspend state for the machine
    var suspendState: StateID? { get mutating set }
}

extension Suspensible {
    /// Default description returning the name of the suspend state
    @inlinable public var description: String {
        suspendState?.description ?? "(none)"
    }
}


/// Abstract representation of a suspensible FSM
public protocol SuspensibleFSM: FSM, Suspensible {}

extension SuspensibleFSM {
    /// Default description of a suspensible FSM
    @inlinable public var description: String {
        states.map { $0.description }.joined(separator: "\n") +
        (suspendState?.description ?? "(none)")
    }
}
