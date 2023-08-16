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

/// Mapping from transition ID to transition layout
public typealias TransitionLayouts = [TransitionID : TransitionLayout]

/// Mapping from state name to state/transitions layout
public typealias StateNameLayouts = [StateName : (state: StateLayout, transitions: [TransitionLayout])]

/// A finite-state machine.
///
/// This class represents a finite-state machine in a given language.
public class Machine {
    /// Programming language binding
    public var language: LanguageBinding
    /// The actual finite state machine
    public var llfsm: LLFSM
    /// Graphical layout of the states
    public var stateLayout: StateLayouts
    /// Graphical layout of the transitions
    public var transitionLayout: TransitionLayouts
    /// Window layout
    public var windowLayout: Data?
    /// Machine boilerplate
    public var boilerplate: any Boilerplate
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
        language = languageBinding(for: url)
        boilerplate = language.boilerplate(url)
        windowLayout = language.windowLayout(for: url)
        activities = StateActivitiesSourceCode()
        let names = try stateNames(from: url.fileURL(for: .states))
        let states = names.map { State(id: StateID(), name: $0) }
        let susp = language.suspendState(url, states)
        var transitionMap = [StateID : [TransitionID]]()
        let transitionsForState = transitionsFor(machine: url, with: states, using: language)
        let transitions = states.flatMap {
            let transitions = transitionsForState($0)
            transitionMap[$0.id] = transitions.map(\.id)
            return transitions
        }
        llfsm = LLFSM(states: states, transitions: transitions, suspendState: susp)
        
        let layoutURL = url.fileURL(for: .layout)
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
        transitionLayout = [:]
        stateLayout = [:]
        for si in states.enumerated() {
            let state = si.element
            let gridLayout = StateLayout(index: si.offset)
            let layoutsForName = namesLayout[state.name]
            var layout = layoutsForName?.state ?? gridLayout
            if layout.closedLayout.x == 0 && layout.closedLayout.y == 0 {
                layout.closedLayout.x = gridLayout.closedLayout.x
                layout.closedLayout.y = gridLayout.closedLayout.y
            }
            if layout.openLayout.x == 0 && layout.openLayout.y == 0 {
                layout.openLayout.x = gridLayout.openLayout.x
                layout.openLayout.y = gridLayout.openLayout.y
            }
            stateLayout[state.id] = layout
            let stateTransitionIDs = transitionMap[state.id] ?? []
            for te in (layoutsForName?.transitions ?? []).enumerated() {
                guard stateTransitionIDs.count > te.offset else {
                    fputs("Layout \(te.offset + 1) ignored: State \(state.name) only has \(stateTransitionIDs.count) transitions\n", stderr)
                    continue
                }
                let transitionID = stateTransitionIDs[te.offset]
                transitionLayout[transitionID] = te.element
            }
        }
    }

    /// Write the FSM to the given URL.
    ///
    /// This method will write the FSM to the
    /// filesystem location denoted by the given URL.
    /// Optionally, a language binding can be specified,
    /// that will write the FSM using the given binding.
    ///
    /// - Parameters:
    ///   - url: The filesystem URL to write the FSM to.
    ///   - targetLanguage: The language to use (defaults to the original language).
    ///   - isSuspensible: Whether the FSM code will allow suspension.
    public func write(to url: URL, language targetLanguage: LanguageBinding? = nil, isSuspensible: Bool) throws {
        guard let destination = (targetLanguage ?? language) as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        try destination.create(at: url)
        try destination.writeLanguage(to: url)
        try destination.write(boilerplate: boilerplate, to: url)
        try destination.write(windowLayout: windowLayout, to: url)
        try destination.write(stateNames: llfsm.states.map { llfsm.stateMap[$0]!.name }, to: url)
        try destination.writeInterface(for: llfsm, to: url, isSuspensible: isSuspensible)
        try destination.writeStateInterface(for: llfsm, to: url, isSuspensible: isSuspensible)
    }

    /// Write the FSM to the given URL in the given format..
    ///
    /// This method will write the FSM to the
    /// filesystem location denoted by the given URL.
    /// Optionally, an output format can be specified,
    /// that will write the FSM in the given format.
    ///
    /// - Parameters:
    ///   - url: The filesystem URL to write the FSM to.
    ///   - format: The format to use (defaults to the original format).
    ///   - isSuspensible: Whether the FSM allows suspension.
    @inlinable
    public func write(to url: URL, format: Format?, isSuspensible: Bool = true) throws {
        try write(to: url, language: format.flatMap { formatToLanguageBinding[$0] }, isSuspensible: isSuspensible)
    }
}

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
    (NSDictionary(contentsOf: url)?[String.states] as? NSDictionary).flatMap {
        stateNameLayouts(from: $0)
    } ?? [:]
}

/// Read the layout of state names from the given dictionary.
///
/// This function reads the state layout from the given dictionary
/// (the property list representation of the layout).
///
/// - Parameter dict: Dictionary containing the layout.
/// - Returns: A mapping from state names to state layouts.
@inlinable
public func stateNameLayouts(from dict: NSDictionary) -> StateNameLayouts {
    var layouts = StateNameLayouts()
    for (state, layoutDict) in dict {
        guard let s = state as? StateName,
              let d = layoutDict as? NSDictionary else { continue }
        let transitionLayouts = d[TransitionLayoutKey.transitions.rawValue] as? [NSDictionary] ?? []
        let ts = transitionLayouts.map { TransitionLayout($0) }
        layouts[s] = (StateLayout(d), ts)
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
            return Transition(id: TransitionID(), label: expression(i), source: sourceID, target: targetID)
        }
        return transitions
    }
}
