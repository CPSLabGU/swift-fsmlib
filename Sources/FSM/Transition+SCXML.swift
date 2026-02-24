//
//  Transition+SCXML.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Transition type enumeration for SCXML.
///
/// Specifies whether a transition performs full exit/entry semantics
/// (external) or minimal processing (internal for self-transitions).
public enum TransitionType: String, Equatable, Hashable, Codable {
    /// External transition: full exit/entry processing.
    ///
    /// The transition causes the source state to be exited and the target
    /// state to be entered, even if source and target are the same state.
    case external

    /// Internal transition: minimal processing for self-transitions.
    ///
    /// When source and target are the same state, the state is not exited
    /// and re-entered. OnEntry/OnExit actions are not executed.
    ///
    /// - Note: for LLFSMs, the `onExit` action gets executed, whenever
    ///   a transition is taken, regardless of whether the transition
    ///   is marked `internal` or `external`.
    case `internal`
}

/// Executable action types for SCXML transitions and states.
///
/// Represents the various executable content elements that can appear in
/// SCXML onentry, onexit, and transition blocks.
public enum ExecutableAction: Equatable, Hashable, Codable {
    /// Execute script content.
    case script(String)

    /// Assign value to data model location.
    case assign(location: String, expr: String)

    /// Raise internal event.
    case raise(event: String)

    /// Send event to external system/machine.
    case send(event: String, target: String?, delay: String?)

    /// Log message (for debugging/monitoring).
    case log(expr: String, label: String?)

    /// Conditional execution block.
    case `if`(condition: String, actions: [ExecutableAction], elseActions: [ExecutableAction]?)

    /// Iterate over collection.
    case forEach(array: String, item: String, index: String?, actions: [ExecutableAction])

    /// Cancel delayed send.
    case cancel(sendId: String)
}

/// SCXML-specific metadata for transitions.
///
/// This structure stores SCXML-specific transition properties including
/// event triggers, guard conditions, transition type, and executable actions.
/// It is stored separately from the core Transition structure to maintain
/// backward compatibility while enabling SCXML features.
public struct SCXMLTransitionMetadata: Equatable, Hashable, Codable {
    // MARK: - Event and Condition

    /// Event name that triggers this transition.
    ///
    /// Format: "event.name" or space-separated list "event1 event2".
    /// "*" matches all events.
    /// `nil` means eventless transition (taken immediately if condition is true).
    public var event: String?

    /// Guard condition expression.
    ///
    /// Boolean expression evaluated in datamodel language (ECMAScript, etc.).
    /// Transition is only taken if condition evaluates to `true`.
    /// `nil` means no condition (always taken when event matches).
    public var condition: String?

    // MARK: - Transition Type

    /// Transition type (internal vs external).
    ///
    /// Determines whether exit/entry processing occurs.
    public var type: TransitionType

    // MARK: - Executable Content

    /// Actions to execute during transition.
    ///
    /// Executed in document order after exiting source state
    /// and before entering target state.
    public var actions: [ExecutableAction]

    // MARK: - Target Configuration

    /// Multiple target states for parallel transitions.
    ///
    /// Used when transition has multiple target states (rare).
    /// If non-nil and non-empty, this overrides the main transition target.
    public var multipleTargets: [StateID]?

    // MARK: - Initialization

    /// Designated initializer for SCXML transition metadata.
    ///
    /// - Parameters:
    ///   - event: Event trigger name (default: nil for eventless)
    ///   - condition: Guard condition expression (default: nil for always true)
    ///   - type: Transition type (default: .external)
    ///   - actions: Executable actions (default: empty)
    ///   - multipleTargets: Multiple target states (default: nil)
    public init(
        event: String? = nil,
        condition: String? = nil,
        type: TransitionType = .external,
        actions: [ExecutableAction] = [],
        multipleTargets: [StateID]? = nil
    ) {
        self.event = event
        self.condition = condition
        self.type = type
        self.actions = actions
        self.multipleTargets = multipleTargets
    }
}

/// Extension providing SCXML metadata access and utilities.
extension SCXMLTransitionMetadata {
    /// Check if transition is eventless (spontaneous).
    public var isEventless: Bool {
        event == nil
    }

    /// Check if transition is unconditional.
    public var isUnconditional: Bool {
        condition == nil
    }

    /// Check if transition matches all events (wildcard).
    public var isWildcard: Bool {
        event == "*"
    }

    /// Check if transition has executable actions.
    public var hasActions: Bool {
        !actions.isEmpty
    }

    /// Parse event names into array (handles space-separated lists).
    ///
    /// - Returns: Array of event names, or empty if no event specified
    public var eventNames: [String] {
        guard let event = event else { return [] }
        return event.split(separator: " ").map(String.init)
    }

    /// Add an executable action.
    ///
    /// - Parameter action: Action to add
    public mutating func addAction(_ action: ExecutableAction) {
        actions.append(action)
    }

    /// Remove all actions.
    public mutating func clearActions() {
        actions.removeAll()
    }
}

/// Global mapping of transition IDs to SCXML metadata.
///
/// This dictionary stores SCXML-specific metadata for transitions that require it.
/// Transitions without SCXML metadata are treated as simple unconditional transitions.
public typealias SCXMLTransitionMetadataMap = [TransitionID: SCXMLTransitionMetadata]

/// Extension providing convenience methods for working with executable actions.
extension ExecutableAction {
    /// Check if action is a script action.
    public var isScript: Bool {
        if case .script = self { return true }
        return false
    }

    /// Check if action is an assignment.
    public var isAssign: Bool {
        if case .assign = self { return true }
        return false
    }

    /// Check if action raises an event.
    public var isRaise: Bool {
        if case .raise = self { return true }
        return false
    }

    /// Check if action sends an event.
    public var isSend: Bool {
        if case .send = self { return true }
        return false
    }

    /// Get script content if this is a script action.
    public var scriptContent: String? {
        if case .script(let content) = self { return content }
        return nil
    }

    /// Get assign location and expression if this is an assignment.
    public var assignDetails: (location: String, expr: String)? {
        if case .assign(let location, let expr) = self {
            return (location, expr)
        }
        return nil
    }

    /// Get raised event name if this is a raise action.
    public var raisedEvent: String? {
        if case .raise(let event) = self { return event }
        return nil
    }

    /// Details of a send action.
    ///
    /// Groups the event name, optional target, and optional delay for a send action.
    public struct SendDetails {
        /// The event name to send.
        public var event: String
        /// Optional target recipient of the event.
        public var target: String?
        /// Optional delay before sending the event.
        public var delay: String?
    }

    /// Get send details if this is a send action.
    public var sendDetails: SendDetails? {
        if case .send(let event, let target, let delay) = self {
            return SendDetails(event: event, target: target, delay: delay)
        }
        return nil
    }
}
