//
//  Transition.swift
//
//  Created by Rene Hexel on 1/07/2015.
//  Copyright © 2015, 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Unique ID of a transition
public typealias TransitionID = UUID

/// Representation of an expression that labels a transition
public typealias Expression = String

/// Abstract representation of a transition label.
///
/// This protocol defines the requirements for a transition label in an FSM,
/// requiring a label expression and a string description. Conforming types
/// provide the logic for how transitions are labelled and described.
///
/// - Note: Used for guard conditions, actions, or triggers on transitions.
/// Protocol for labelling transitions in FSMs.
///
public protocol TransitionLabel: CustomStringConvertible {
    /// Expression that labels this transition
    var label: Expression { get }
}

/// Extension providing convenience properties for accessing and mutating
/// transition label properties.
public extension TransitionLabel {
    /// Default description of a transition label
    var description: String { return label.description }
}

/// Abstract representation of a transition source.
///
/// This protocol defines the requirements for a transition source in an FSM,
/// requiring a source state and a string description. Conforming types
/// provide the logic for how transitions originate from states.
///
/// - Note: Used to identify the origin of a transition in the FSM graph.
/// Abstract representation of a transition source.
///
public protocol TransitionSource: CustomStringConvertible {
    /// Source state that this transition originates from
    var source: StateID { get }
}

/// Extension providing convenience properties for accessing and mutating
/// transition source properties.
public extension TransitionSource {
    /// Default description of a transition source
    var description: String { return source.description }
}

/// Abstract representation of a transition target.
///
/// This protocol defines the requirements for a transition target in an FSM,
/// requiring a target state and a string description. Conforming types
/// provide the logic for how transitions lead to target states.
///
/// - Note: Used to identify the destination of a transition in the FSM graph.
///
public protocol TransitionTarget: CustomStringConvertible {
    /// Target state that this transition originates from
    var target: StateID { get }
}

/// Extension providing convenience properties for accessing and mutating
/// transition target properties.
public extension TransitionTarget {
    /// Default description of a transition target
    var description: String { return target.description }
}

/// Abstract representation of a transition path from a source to a target state.
///
/// This protocol combines the requirements of TransitionSource and
/// TransitionTarget, representing a path between two states in an FSM.
///
/// - Note: Used for visualisation and analysis of FSM paths.
/// Abstract representation of a transition path from a source to a target state.
///
/// This protocol combines the requirements of TransitionSource and
/// TransitionTarget, representing a path between two states in an FSM.
///
/// - Note: Used for visualisation and analysis of FSM paths.
public protocol TransitionPath: TransitionSource, TransitionTarget {}

/// Extension providing convenience properties for accessing and mutating
/// transition path properties.
public extension TransitionPath {
    /// Default description of a transition path
    var description: String { return "( \(source) --> \(target))" }
}

/// Abstract representation of a transition leading to a target.
///
/// This protocol combines the requirements of TransitionLabel and
/// TransitionTarget, representing a transition with a label and a target
/// state.
///
/// - Note: Used for transitions that have both a label and a destination.
public protocol TargetTransition: TransitionLabel, TransitionTarget {}

/// Extension providing convenience properties for accessing and mutating
/// target transition properties.
public extension TargetTransition {
    /// Default description of a transition to a specific target
    var description: String { return "( -- \(label) --> \(target))" }
}

/// Abstract representation of a full transition vertex.
///
/// This protocol combines the requirements of TransitionSource,
/// TargetTransition, and Equatable, representing a complete transition in
/// an FSM with source, label, and target.
///
/// - Note: Used for defining and comparing full transitions in FSMs.
public protocol TransitionVertex: TransitionSource, TargetTransition, Equatable {}

/// Extension providing convenience properties for accessing and mutating
/// transition vertex properties.
public extension TransitionVertex {
    /// Default description of a transition
    var description: String { return "( \(source) -- \(label) --> \(target))" }
}

/// Compare two transition vertices
///
/// - Parameters:
///   - lhs: The left-hand side transition vertex to compare.
///   - rhs: The right-hand side transition vertex to compare.
/// - Returns: `true` if the two transition vertices are equal, `false` otherwise.
public func==<T: TransitionVertex>(lhs: T, rhs: T) -> Bool {
    return lhs.source == rhs.source &&
    lhs.target == rhs.target &&
    lhs.label  == rhs.label
}

/// Concrete State Transition implementation.
///
/// This struct represents a transition in a finite-state machine (FSM),
/// encapsulating a unique ID, label expression, source state, and target
/// state. Transitions are fundamental for defining the behaviour and flow
/// between states in an FSM.
///
/// - Note: Transitions can be compared for equality and used in hashed
///         collections. The label expression is used for guard conditions or
///         actions associated with the transition.
public struct Transition: TransitionVertex, Equatable, Hashable {
    /// Unique ID of this transition
    public var id: TransitionID

    /// Expression that labels this transition
    public var label: Expression = ""

    /// Source state that this transition originates from
    public var source: StateID

    /// Target state that this transition originates from
    public var target: StateID

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - id: The unique ID of this transition.
    ///   - label: The expression that labels this transition.
    ///   - source: The source state that this transition originates from.
    ///   - target: The target state that this transition leads to.
    @inlinable
    public init(id: TransitionID = TransitionID(), label: Expression = "", source: StateID, target: StateID = StateID(uuid: UUID_NULL)) {
        self.id = id
        self.label = label
        self.source = source
        self.target = target
    }
}

/// Compare two transitions
///
/// - Parameters:
///   - lhs: The left-hand side transition to compare.
///   - rhs: The right-hand side transition to compare.
/// - Returns: `true` if the two transitions are equal, `false` otherwise.
public func==(lhs: Transition, rhs: Transition) -> Bool {
    return lhs.id     == rhs.id     &&
    lhs.source == rhs.source &&
    lhs.target == rhs.target &&
    lhs.label  == rhs.label
}

/// Array of state transitions
public typealias TransitionArray = [TransitionID]

/// Mapping from IDs to transitions
public typealias TransitionDictionary = [TransitionID: Transition]

/// return the mapping dictionary for a given array of transitions
///
/// - Parameters:
///   - transitions: The array of transitions to convert into a dictionary.
/// - Returns: The created dictionary mapping transition IDs to transitions.
func dictionary(_ transitions: [Transition]) -> TransitionDictionary {
    return transitions.reduce(TransitionDictionary()) {
        var dictionary = $0
        dictionary[$1.id] = $1
        return dictionary
    }
}
