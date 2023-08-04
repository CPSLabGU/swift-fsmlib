//
//  Machine.swift
//
//  Created by Rene Hexel on 23/9/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Array of state names
public typealias StateNames = [StateName]

/// Mapping from state ID to state layout
public typealias StateLayouts = [StateID : StateLayout]

/// Mapping from state name to state layout
public typealias StateNameLayouts = [StateName : StateLayout]

/// Read the names of states from the given URL.
///
/// This reads the content of the given URL and interprets
/// each line as a state name.
///
/// - Parameter url: URL of the state names file.
/// - Throws: `NSError` if the file cannot be read.
/// - Returns: An array of state names.
@inlinable
public func stateNames(from url: URL) throws -> StateNames {
    let content = try String(contentsOf: url, encoding: .utf8)
    return content.lines.map(trimmed).filter(nonempty)
}

/// Read the layout of state names from the given URL.
///
/// This function reads the state layout from the given URL
/// (the property list representation of the layout).
///
/// - Parameter url: URL of the layout file
/// - Throws: `NSError` if the file cannot be read.
/// - Returns: A mapping from state names to state layouts.
@inlinable
public func stateNameLayouts(from url: URL) throws -> StateNameLayouts {
    guard let dict = NSDictionary(contentsOf: url) else { return [:] }
    var layouts = StateNameLayouts()
    for (state, layoutDict) in dict {
        guard let s = state as? StateName,
              let d = layoutDict as? NSDictionary else { continue }
        layouts[s] = StateLayout(d)
    }
    return layouts
}

/// Return an array of transitions for a given source state.
///
/// This function returns a function that takes a state and
/// reads in the transitions for that state from the given machine
/// file wrapper.
///
/// - Parameters:
///   - url: The URL of the machine FileWrapper.
///   - states: The array of states.
///   - language: The language binding to use (defaults to ObjCPPBinding).
/// - Returns: A function that returns an array of transitions for a given source state.
@inlinable
func transitionsFor(machine url: URL, with states: [State], using language: LanguageBinding = ObjCPPBinding()) -> (State) -> [Transition] {
    return { (state: State) -> [Transition] in
        let sourceID = state.id
        let expression = language.expressionOfTransition(url, state.name)
        let target = language.targetOfTransition(url, states, state.name)
        let n = language.numberOfTransitions(url, state.name)
        let transitionIndices = (0..<n).enumerated()
        let transitions = transitionIndices.map { i, _ -> Transition in
            let targetID = target(i) ?? StateID(uuid: UUID_NULL)
            return Transition(id: StateID(), label: expression(i), source: sourceID, target: targetID)
        }
        return transitions
    }
}


public class Machine {
    /// Programming language binding
    public var language: LanguageBinding
    /// The actual finite state machine
    public var llfsm: LLFSM
    /// Graphical layout of the states
    public var layout: StateLayouts
    /// Source code of OnEntry/OnExit/Internal actions of states
    public var activities: StateActivitiesSourceCode

    /// Constructor for reading an FSM from a given URL.
    ///
    /// This initialiser will read the states and transitions from
    /// the FileWrapper at the given URL.
    ///
    /// - Note: The URL is expected to point to a directory containing the machine.
    /// - Parameter url: The URL to read the FSM from.
    public init(from url: URL) throws {
        language = ObjCPPBinding()
        activities = StateActivitiesSourceCode()
        let names = try stateNames(from: url.forFile(.states))
        let states = names.map { State(id: StateID(), name: $0) }
        let susp = language.suspendState(url, states)
        let transitions = states.flatMap(transitionsFor(machine: url, with: states, using: language))
        llfsm = LLFSM(states: states, transitions: transitions, suspendState: susp)

        let layoutURL = url.forFile(.layout)
        let namesLayout: StateNameLayouts
        do {
            try namesLayout = stateNameLayouts(from: layoutURL)
        } catch {
            fputs("Cannot open '\(layoutURL.path): \(error.localizedDescription)'\n", stderr)
            namesLayout = [:]
        }
        //
        // convert mapping from name ot layout to mapping from ID to layout
        // using default grid layout for states at position (0,0)
        //
        layout = states.enumerated().reduce([:]) {
            var layouts = $0
            let gridLayout = StateLayout(index: $1.offset)
            var layout = namesLayout[$1.element.name] ?? gridLayout
            if layout.closedLayout.x == 0 && layout.closedLayout.y == 0 {
                layout.closedLayout.x = gridLayout.closedLayout.x
                layout.closedLayout.y = gridLayout.closedLayout.y
            }
            if layout.openLayout.x == 0 && layout.openLayout.y == 0 {
                layout.openLayout.x = gridLayout.openLayout.x
                layout.openLayout.y = gridLayout.openLayout.y
            }
            layouts[$1.element.id] = layout
            return layouts
        }
    }
}

