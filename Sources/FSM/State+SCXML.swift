//
//  State+SCXML.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// SCXML-specific metadata for states.
///
/// This structure stores SCXML-specific state properties including
/// hierarchy information, state type flags, and initial state references.
/// It is stored separately from the core State structure to maintain
/// backward compatibility while enabling SCXML features.
public struct SCXMLStateMetadata: Equatable, Hashable, Codable {
    // MARK: - Hierarchy

    /// Parent state ID for compound states.
    ///
    /// `nil` for top-level states.
    public var parentState: StateID?

    /// Child state IDs for compound states.
    ///
    /// `nil` for atomic (leaf) states.
    /// Contains IDs of direct children only (not nested descendants).
    public var childStates: [StateID]?

    /// Initial child state for compound states.
    ///
    /// Specifies which child state should be entered by default.
    /// Only applicable for compound states (childStates != nil).
    public var initialChild: StateID?

    // MARK: - State Type Flags

    /// Parallel state flag.
    ///
    /// When `true`, all child states are active simultaneously.
    /// When `false`, only one child state is active at a time (XOR semantics).
    public var isParallel: Bool

    /// Final state flag.
    ///
    /// Final states generate `done.state.<id>` events when entered.
    /// A state machine reaches completion when the top-level state
    /// configuration contains only final states.
    public var isFinal: Bool

    /// History state type.
    ///
    /// `nil` for non-history states.
    /// `.shallow` to remember direct child state.
    /// `.deep` to remember nested descendant states.
    public var historyType: HistoryType?

    /// Default history target for history states.
    ///
    /// Specifies which state to enter if history is empty
    /// (i.e., first time entering parent state).
    public var historyDefault: StateID?

    // MARK: - Initialization

    /// Designated initializer for SCXML state metadata.
    ///
    /// - Parameters:
    ///   - parentState: Parent state ID (default: nil)
    ///   - childStates: Child state IDs (default: nil)
    ///   - initialChild: Initial child state (default: nil)
    ///   - isParallel: Parallel state flag (default: false)
    ///   - isFinal: Final state flag (default: false)
    ///   - historyType: History state type (default: nil)
    ///   - historyDefault: Default history target (default: nil)
    public init(
        parentState: StateID? = nil,
        childStates: [StateID]? = nil,
        initialChild: StateID? = nil,
        isParallel: Bool = false,
        isFinal: Bool = false,
        historyType: HistoryType? = nil,
        historyDefault: StateID? = nil
    ) {
        self.parentState = parentState
        self.childStates = childStates
        self.initialChild = initialChild
        self.isParallel = isParallel
        self.isFinal = isFinal
        self.historyType = historyType
        self.historyDefault = historyDefault
    }
}

/// Extension providing SCXML metadata access and utilities.
extension SCXMLStateMetadata {
    /// Check if this is an atomic (leaf) state.
    public var isAtomic: Bool {
        childStates == nil || childStates?.isEmpty == true
    }

    /// Check if this is a compound state (has children).
    public var isCompound: Bool {
        !isAtomic
    }

    /// Check if this is a history state.
    public var isHistory: Bool {
        historyType != nil
    }

    /// Get the number of child states.
    public var childCount: Int {
        childStates?.count ?? 0
    }

    /// Add a child state.
    ///
    /// - Parameter stateID: Child state ID to add
    public mutating func addChild(_ stateID: StateID) {
        if childStates == nil {
            childStates = [stateID]
        } else {
            childStates?.append(stateID)
        }
    }

    /// Remove a child state.
    ///
    /// - Parameter stateID: Child state ID to remove
    /// - Returns: true if child was removed, false if not found
    @discardableResult
    public mutating func removeChild(_ stateID: StateID) -> Bool {
        guard let index = childStates?.firstIndex(of: stateID) else {
            return false
        }
        childStates?.remove(at: index)
        return true
    }

    /// Check if a state is a child of this state.
    ///
    /// - Parameter stateID: State ID to check
    /// - Returns: true if stateID is in childStates
    public func hasChild(_ stateID: StateID) -> Bool {
        childStates?.contains(stateID) ?? false
    }
}

/// Global mapping of state IDs to SCXML metadata.
///
/// This dictionary stores SCXML-specific metadata for states that require it.
/// States without SCXML metadata are treated as simple atomic states.
public typealias SCXMLStateMetadataMap = [StateID: SCXMLStateMetadata]
