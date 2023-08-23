//
//  Transition.swift
//
//  Created by Rene Hexel on 1/07/2015.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Unique ID of a transition
public typealias TransitionID = UUID

/// Representation of an expression that labels a transition
public typealias Expression = String

/// Abstract representation of a transition
public protocol TransitionLabel: CustomStringConvertible {
    /// Expression that labels this transition
    var label: Expression { get }
}
public extension TransitionLabel {
    /// Default description of a transition label
    var description: String { return label.description }
}

/// Abstract representation of a transition source
public protocol TransitionSource: CustomStringConvertible {
    /// Source state that this transition originates from
    var source: StateID { get }
}
public extension TransitionSource {
    /// Default description of a transition source
    var description: String { return source.description }
}


/// Abstract representation of a transition target
public protocol TransitionTarget: CustomStringConvertible {
    /// Target state that this transition originates from
    var target: StateID { get }
}
public extension TransitionTarget {
    /// Default description of a transition source
    var description: String { return target.description }
}

/// Abstract representation of a transition path
/// from a source to a target state
public protocol TransitionPath: TransitionSource, TransitionTarget {}
public extension TransitionPath {
    /// Default description of a transition label
    var description: String { return "( \(source) --> \(target))" }
}

/// Abstract representation of a transition leading to a target
public protocol TargetTransition: TransitionLabel, TransitionTarget {}
public extension TargetTransition {
    /// Default description of a transition to a specific target
    var description: String { return "( -- \(label) --> \(target))" }
}

/// Abstract representation of a full transition vertex
/// encapsulating a label as well as source and target states
public protocol TransitionVertex: TransitionSource, TargetTransition, Equatable {}
public extension TransitionVertex {
    /// Default description of a transition
    var description: String { return "( \(source) -- \(label) --> \(target))" }
}

/// Compare two transition vertices
public func==<T: TransitionVertex>(lhs: T, rhs: T) -> Bool {
    return lhs.source == rhs.source &&
    lhs.target == rhs.target &&
    lhs.label  == rhs.label
}


/// Concrete State Transition implementation
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
public func==(lhs: Transition, rhs: Transition) -> Bool {
    return lhs.id     == rhs.id     &&
    lhs.source == rhs.source &&
    lhs.target == rhs.target &&
    lhs.label  == rhs.label
}


/// Array of state transitions
public typealias TransitionArray = [TransitionID]

/// Mapping from IDs to transitions
public typealias TransitionDictionary = [ TransitionID : Transition ]

/// return the mapping dictionary for a given array of transitions
func dictionary(_ transitions: [Transition]) -> TransitionDictionary {
    return transitions.reduce(TransitionDictionary()) {
        var dictionary = $0
        dictionary[$1.id] = $1
        return dictionary
    }
}

