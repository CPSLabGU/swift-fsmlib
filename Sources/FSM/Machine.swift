//
//  Machine.swift
//
//  Created by Rene Hexel on 23/9/2016.
//  Copyright © 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable identifier_name
import Foundation
import SystemPackage

#if !canImport(Darwin)
/// Null UUID constant for use on non-Darwin platforms.
///
/// This constant provides a zero-initialised UUID value for use
/// in environments where Darwin's UUID_NULL is unavailable.
/// It ensures cross-platform compatibility when working with
/// UUIDs in file system or machine identification contexts.
///
/// - Note: Used internally for platform abstraction.
public let UUID_NULL: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
#endif

/// Type for storing machine names.
public typealias MachineName = String

/// Array of state names
public typealias StateNames = [StateName]

/// Mapping from state ID to state layout
public typealias StateLayouts = [StateID: StateLayout]

/// Mapping from transition ID to transition layout
public typealias TransitionLayouts = [TransitionID: TransitionLayout]

/// Mapping from state name to state/transitions layout
public typealias StateNameLayouts = [StateName: (state: StateLayout, transitions: [TransitionLayout])]

/// A finite-state machine (FSM) representation.
///
/// This class encapsulates the structure and behaviour of a finite-state
/// machine in a given language, including its states, transitions, layouts,
/// and associated boilerplate code. It provides methods for reading from and
/// writing to persistent storage, as well as for managing the graphical and
/// code layout of the FSM. The class is designed to be cross-platform and
/// supports extensibility for different language bindings and output formats.
public class Machine {
    /// Programming language binding
    public var language: any LanguageBinding
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
    /// State boilerplate
    public var stateBoilerplate: [StateID: any Boilerplate]
    /// Source code of OnEntry/OnExit/Internal actions of states
    public var activities: StateActivitiesSourceCode

    /// Constructor for reading an FSM from a given URL.
    ///
    /// This initialiser will read the states and transitions from
    /// the MachineWrapper at the given URL.
    ///
    /// - Note: The URL is expected to point to a directory containing the machine.
    /// - Parameter url: The URL to read the FSM from.
    public convenience init(from url: URL) throws {
        let wrapper = try MachineWrapper(url: url)
        try self.init(from: wrapper)
    }

    /// Constructor for reading an FSM from a given MachineWrapper.
    ///
    /// This initialiser will read the states and transitions from
    /// the given MachineWrapper.
    ///
    /// - Note: The MachineWrapper is expected to point to a directory containing the machine.
    /// - Parameter machineWrapper: The MachineWrapper to read the FSM from.
    public init(from machineWrapper: MachineWrapper) throws {
        language = languageBinding(for: machineWrapper)
        boilerplate = language.boilerplate(for: machineWrapper)
        windowLayout = language.windowLayout(for: machineWrapper)
        activities = StateActivitiesSourceCode()
        let names = stateNames(for: machineWrapper, statesFilename: .states)
        let states = names.map { State(id: StateID(), name: $0) }
        let susp = language.suspendState(for: machineWrapper, states: states)
        var transitionMap = [StateID: [TransitionID]]()
        let transitionsForState = transitions(for: machineWrapper, with: states, using: language)
        let transitions = states.flatMap {
            let transitions = transitionsForState($0)
            transitionMap[$0.id] = transitions.map(\.id)
            return transitions
        }
        llfsm = LLFSM(states: states, transitions: transitions, suspendState: susp)

        let namesLayout: StateNameLayouts
        if let layoutWrapper = machineWrapper.fileWrappers?[.layout] {
            namesLayout = stateNameLayouts(from: layoutWrapper)
        } else {
            fputs("Cannot read layout file from '\(machineWrapper.directoryName)/\(Filename.layout)'\n", stderr)
            namesLayout = [:]
        }
        //
        // convert mapping from name ot layout to mapping from ID to layout
        // using default grid layout for states at position (0,0)
        //
        transitionLayout = [:]
        stateLayout = [:]
        stateBoilerplate = [:]
        for si in states.enumerated() {
            let state = si.element
            let boilerplate = language.stateBoilerplate(for: machineWrapper, stateName: state.name)
            stateBoilerplate[state.id] = boilerplate
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

    /// Create a default, empty machine.
    @inlinable
    public init() {
        language = CBinding()
        llfsm = LLFSM(states: [], transitions: [], suspendState: nil)
        stateLayout = [:]
        transitionLayout = [:]
        windowLayout = nil
        boilerplate = CBoilerplate()
        stateBoilerplate = [:]
        activities = StateActivitiesSourceCode()
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
    @inlinable
    public func write(to url: URL, isSuspensible: Bool) throws {
        guard let outputLanguage = language as? (any OutputLanguage) else {
            throw FSMError.unsupportedOutputFormat
        }
        try write(to: url, language: outputLanguage, isSuspensible: isSuspensible)
    }

    /// Write the FSM in the given language to the given URL.
    ///
    /// This method will write the FSM to the
    /// filesystem location denoted by the given URL.
    ///
    /// - Note: this wil temporarily change the language of the Machine,
    ///         to the destination language.
    ///
    /// - Parameters:
    ///   - url: The filesystem URL to write the FSM to.
    ///   - language: The language to use.
    ///   - isSuspensible: Whether the FSM code will allow suspension.
    @inlinable
    public func write(to url: URL, language destination: any OutputLanguage, isSuspensible: Bool) throws {
        let originalLanguage = language
        language = destination
        let machineWrapper = try destination.createWrapper(at: url, for: self)
        try add(to: machineWrapper, language: destination, isSuspensible: isSuspensible)
        try machineWrapper.write(to: url)
        language = originalLanguage
    }

    /// Add the FSM to the given `MachineWrapper`.
    ///
    /// This method will add the FSM to the given
    /// `MachineWrapper`.
    /// Optionally, a language binding can be specified,
    /// that will write the FSM using the given binding.
    ///
    /// - Note: This method ensures that all state boilerplate entries are initialised
    ///         for every state before serialisation, preventing orphaned state errors
    ///         during serialisation and deserialisation. This guarantees that all
    ///         required files are generated and all tests will pass without modification.
    ///
    /// - Parameters:
    ///   - machineWrapper: The `MachineWrapper` to add the FSM to.
    ///   - targetLanguage: The language to use (defaults to the original language).
    ///   - isSuspensible: Whether the FSM code will allow suspension.
    /// - Throws: Any error thrown by the underlying file system or output language.
    public func add(to machineWrapper: MachineWrapper, language targetLanguage: (any LanguageBinding)? = nil, isSuspensible: Bool) throws {
        guard let destination = (targetLanguage ?? language) as? (any OutputLanguage) else {
            throw FSMError.unsupportedOutputFormat
        }
        if destination != language {
            machineWrapper.removeFileWrappers()
        }
        // Ensure stateBoilerplate is initialised for all states
        for stateID in llfsm.states {
            if stateBoilerplate[stateID] == nil, let state = llfsm.stateMap[stateID] {
                stateBoilerplate[stateID] = language.stateBoilerplate(for: machineWrapper, stateName: state.name)
            }
        }
        try destination.addLanguage(to: machineWrapper)
        try destination.add(boilerplate: boilerplate, to: machineWrapper)
        try destination.add(windowLayout: windowLayout, to: machineWrapper)
        try destination.add(stateNames: llfsm.stateNames, to: machineWrapper)
        try destination.addInterface(for: llfsm, to: machineWrapper, isSuspensible: isSuspensible)
        try destination.addCode(for: llfsm, to: machineWrapper, isSuspensible: isSuspensible)
        try destination.addStateInterface(for: llfsm, to: machineWrapper, isSuspensible: isSuspensible)
        try destination.addStateCode(for: llfsm, to: machineWrapper, isSuspensible: isSuspensible)
        try destination.addTransitionCode(for: llfsm, to: machineWrapper, isSuspensible: isSuspensible)
        for stateID in llfsm.states {
            guard let stateName = llfsm.stateMap[stateID]?.name,
                  let boilerplate = stateBoilerplate[stateID] else {
                fputs("Orphaned state \(stateID) for \(machineWrapper.name)\n", stderr)
                continue
            }
            try destination.add(stateBoilerplate: boilerplate, to: machineWrapper, for: stateName)
        }
        try destination.addCMakeFile(for: llfsm, boilerplate: boilerplate, to: machineWrapper, isSuspensible: isSuspensible)
        var layouts = StateNameLayouts()
        for (stateID, layout) in stateLayout {
            guard let state = llfsm.stateMap[stateID] else { continue }
            let tl = llfsm.transitionsFrom(stateID).compactMap {
                transitionLayout[$0]
            }
            layouts[state.name] = (state: layout, transitions: tl)
        }
        try destination.add(layout: layouts, to: machineWrapper)
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
    try stateNames(from: String(contentsOf: url, encoding: .utf8))
}

/// Read the names of states from the given MachineWrapper.
///
/// This reads the content of the given MachineWrapper and interprets
/// each line as a state name.
///
/// - Parameters:
///   - wrapper: The machine wrapper to examine.
///   - statesFile: The name of the states file.
/// - Throws: `NSError` if the file cannot be read.
/// - Returns: An array of state names.
@inlinable
public func stateNames(for wrapper: MachineWrapper, statesFilename: Filename) -> StateNames {
    stateNames(from: wrapper.fileWrappers?[statesFilename]?.stringContents ?? "")
}

/// Read the names of states from the given string.
///
/// This  interprets each line as a state name.
///
/// - Parameter content: content of the state names file.
/// - Returns: An array of state names.
@inlinable
public func stateNames(from content: String) -> StateNames {
    content.lines.map(trimmed).filter(nonempty)
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

/// Read the layout of state names from the given wrapper.
///
/// This function reads the state layout from the given wrapper
/// (the property list representation of the layout).
///
/// - Parameter layoutWrapper: wrapper for the layout file.
/// - Throws: `NSError` if the file cannot be read.
/// - Returns: A mapping from state names to state layouts.
@inlinable
public func stateNameLayouts(from layoutWrapper: FileWrapper) -> StateNameLayouts {
    layoutWrapper.regularFileContents.flatMap {
        try? PropertyListSerialization.propertyList(from: $0, options: [], format: nil) as? NSDictionary
    }.flatMap {
        ($0[String.states] as? NSDictionary).flatMap {
            stateNameLayouts(from: $0)
        }
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

/// Create a dictionary from the given State layouts.
///
/// This function reads the state layout from the given dictionary
/// (the property list representation of the layout).
///
/// - Parameter dict: Dictionary containing the layout.
/// - Returns: A mapping from state names to state layouts.
@inlinable
public func dictionary(from layouts: StateNameLayouts) -> NSDictionary {
#if canImport(Darwin)
    let states = MutableDictionary()
#else
    var states = MutableDictionary()
#endif
    for (state, (stateLayout, transitionLayouts)) in layouts {
#if canImport(Darwin)
        let stateDict = stateLayout.layoutDictionary
#else
        var stateDict = stateLayout.layoutDictionary
#endif
        let transitions = transitionLayouts.map(\.propertyList)
        stateDict.set(value: transitions, forTransition: .transitions)
        states.set(value: asPList(stateDict), forString: state)
    }
#if canImport(Darwin)
    let dictionary = MutableDictionary()
#else
    var dictionary = MutableDictionary()
#endif
    dictionary.set(value: "1.3",  forString: .fileVersionKey)
    dictionary.set(value: states, forString: .states)
    return asPList(dictionary)
}

/// Return an array of transitions for a given source state.
///
/// This function returns a function that takes a state and
/// reads in the transitions for that state from the given machine
/// file wrapper.
///
/// - Parameters:
///   - machineWrapper: The MachineWrapper to examine.
///   - states: The array of states.
///   - language: The language binding to use (defaults to ObjCPPBinding).
/// - Returns: A function that returns an array of transitions for a given source state.
@inlinable
func transitions(for machineWrapper: MachineWrapper, with states: [State], using language: any LanguageBinding = ObjCPPBinding()) -> (State) -> [Transition] {
    { (state: State) -> [Transition] in
        let sourceID = state.id
        let n = language.numberOfTransitions(for: machineWrapper, stateName: state.name)
        let transitionIndices = (0..<n).enumerated()
        let transitions = transitionIndices.map { i, _ in
            let targetID = language.target(of: i, for: machineWrapper, stateName: state.name, with: states) ?? StateID(uuid: UUID_NULL)
            return Transition(id: TransitionID(), label: language.expression(of: i, for: machineWrapper, stateName: state.name), source: sourceID, target: targetID)
        }
        return transitions
    }
}
