//
//  CBinding.swift
//
//  Created by Rene Hexel on 12/08/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Plain C language binding
public struct CBinding: OutputLanguage {
    /// The canonical name of the language binding.
    public let name = Format.c.rawValue

    /// C Language binding from URL and state name to number of transitions
    public let numberOfTransitions: (URL, StateName) -> Int = { url, s in
        numberOfCTransitionsFor(machine: url, state: s)
    }
    /// C Language binding from URL, state name, and transition to expression
    public let expressionOfTransition: (URL, StateName) -> (Int) -> String = {
        url, s in { number in
            expressionOfCTransitionFor(machine: url, state: s, transition: number)
        }
    }
    /// C Language binding from URL, states, source state name, and transition to target state ID
    public let targetOfTransition: (URL, [State], StateName) -> (Int) -> StateID? = { url, ss, s in
        { number in
            targetOfCTransitionFor(machine: url, states: ss, state: s, transition: number)
        }
    }
    /// C Language binding from URL, states to suspend state ID
    public let suspendState: (URL, [State]) -> StateID? = { url, ss in
        suspendStateOfCMachine(url, states: ss)
    }

    /// C Language binding from URL to machine boilerplate.
    public let boilerplate: (URL) -> any Boilerplate = { url in
        boilerplateofCMachine(at: url)
    }

    /// C Language binding from URL and state name to state boilerplate.
    public var stateBoilerplate: (URL, StateName) -> any Boilerplate = { url, stateName in
        boilerplateofCState(at: url, state: stateName)
    }
}

public extension CBinding {
    /// Write the given boilerplate to the given URL.
    ///
    /// This function tries to convert the given boilerplate
    /// to a C lanaguage boilerplate and then writes it
    /// to the given URL.
    ///
    /// - Parameters:
    ///   - boilerplate: The boilerplate to write.
    ///   - url: The machine URL to write to.
    @inlinable
    func write(boilerplate: any Boilerplate, to url: URL) throws {
        try CBoilerplate(boilerplate).write(to: url)
    }
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to write.
    ///   - url: The machine URL to write to.
    ///   - stateName: The name of the state to write the boilerplate for.
    func write(stateBoilerplate: any Boilerplate, to url: URL, for stateName: String) throws {
        try CBoilerplate(stateBoilerplate).write(state: stateName, to: url)
    }
    /// Write the interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeInterface(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let machineCode = cMachineInterface(for: llfsm, named: name, isSuspensible: isSuspensible)
        try url.write(content: machineCode, to: "Machine_" + name + ".h")
    }
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeStateInterface(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let stateCode = cStateInterface(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            try url.write(content: stateCode, to: "State_" + state.name + ".h")
        }
    }
    /// Write the code for the given LLFSM to the given URL.
    ///
    /// This method writes the implementation code
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeCode(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let machineCode = cMachineCode(for: llfsm, named: name, isSuspensible: isSuspensible)
        try url.write(content: machineCode, to: "Machine_" + name + ".c")
    }
    /// Write the state code for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeStateCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let stateCode = cStateCode(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            try url.write(content: stateCode, to: "State_" + state.name + ".c")
        }
    }
    /// Write the transition expressions for the given LLFSM to the given URL.
    ///
    /// This method writes the transition expressions
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeTransitionCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        for (i, stateID) in fsm.states.enumerated() {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state \(i) ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let transitions = fsm.transitionsFrom(stateID)
            try transitions.enumerated().forEach { number, transitionID in
                guard let transition = fsm.transitionMap[transitionID] else {
                    fputs("Warning: orphaned transition \(number) (\(transitionID)) for \(state.name)\n", stderr)
                    return
                }
                let file = "State_\(state.name)_Transition_\(number).expr"
                try url.write(content: transition.label + "\n", to: file)
            }
        }
    }
    /// Write a CMakefile for the given LLFSM to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - boilerplate: The boilerplate containing the include paths.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeCMakeFile(for fsm: LLFSM, boilerplate: any Boilerplate, to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let cmakeFragment = cMakeFragment(for: fsm, named: name, isSuspensible: isSuspensible)
        try url.write(content: cmakeFragment, to: "project.cmake")
        let cmakeLists = cMakeLists(for: fsm, named: name, boilerplate: boilerplate, isSuspensible: isSuspensible)
        try url.write(content: cmakeLists, to: "CMakeLists.txt")
    }
}

// Arrangments of C-language LLFSMs

public extension CBinding {
    /// Write the arrangment interface to the given URL.
    ///
    /// This method writes the arrangement interface (if any)
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - names: The names of the FSM instances.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeArrangementInterface(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let commonInterface = cArrangementMachineInterface(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: commonInterface, to: "Machine_Common.h")
        let arrangementInterface = cArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: arrangementInterface, to: "Arrangement_\(name).h")
        let staticInterface = cStaticArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: staticInterface, to: "Static_Arrangement_\(name).h")
    }
    /// Write the arrangment implementation to the given URL.
    ///
    /// This method writes the arrangement code
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeArrangementCode(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let commonCode = cArrangementMachineCode(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: commonCode, to: "Machine_Common.c")
        let arrangementCode = cArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: arrangementCode, to: "Arrangement_\(name).c")
        let staticCode = cStaticArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: staticCode, to: "Static_Arrangement_\(name).c")
        let mainCode = cStaticArrangementMainCode(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: mainCode, to: "static_main.c")
    }
    /// Write a CMakefile for the given LLFSM arrangement to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeArrangementCMakeFile(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {
        let name = url.deletingPathExtension().lastPathComponent
        let cmakeFragment = cArrangementCMakeFragment(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: cmakeFragment, to: "project.cmake")
        let cmakeLists = cArrangementCMakeLists(for: instances, named: name, isSuspensible: isSuspensible)
        try url.write(content: cmakeLists, to: "CMakeLists.txt")
    }
}

/// Return the number of transitions based on the content of the State.h file
/// - Parameter content: The content of the `State.h` file
/// - Returns: The number of transitions in the given state.
@inlinable
public func numberOfCTransitionsIn(header content: String) -> Int {
    guard let numString = string(containedIn: content, matching: #/numberOfTransitions.*return[^0-9]*([0-9][0-9]*)/#),
          let numberOfTransitions = Int(numString) else { return 0 }
    return numberOfTransitions
}


/// Return the target state index of the given transition
/// based on the content of the `State.h` file.
/// - Parameters:
///   - i: The transition number.
///   - content: The content of the `State.h` file.
/// - Returns:
@inlinable
public func targetStateIndexOfCTransition(_ i: Int, inHeader content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: try! Regex("Transition_\(i).*int.*toState.*=[^0-9]*([0-9]*)")),
          let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Read the content of the `State.h` file.
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file.
@inlinable
public func contentOfCStateFor(machine: URL, state: StateName) -> String? {
    let file = "State_\(state).h"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        return content
    } catch {
        fputs("Error: cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return nil
    }
}


/// Read the content of the State.h file and return the number of transitions
/// - Parameters:
///   - m: The machine URL.
///   - s: The name of the state to examine.
/// - Returns: The number of transitions leaving the given state.
@inlinable
public func numberOfCTransitionsFor(machine m: URL, state s: StateName) -> Int {
    guard let content = contentOfCStateFor(machine: m, state: s) else { return 0 }
    return numberOfCTransitionsIn(header: content)
}


/// Read State_%@_Transition_%ld.expr and return the transition expression
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
///   - number: The transition number.
/// - Returns: The transition expression.
@inlinable
public func expressionOfCTransitionFor(machine: URL, state: StateName, transition number: Int) -> String {
    let file = "State_\(state)_Transition_\(number).expr"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        return content.trimmingCharacters(in:.whitespacesAndNewlines)
    } catch {
        fputs("Warning: cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return "true"
    }
}


/// Return the target state ID for a given transition
/// - Parameters:
///   - m: URL for the machine in question.
///   - states: Array of states to examine.
///   - name: The name of the state to search for.
///   - number:The sequence number of the transition to examine.
/// - Returns: The State ID if found, `nil` otherwise.
@inlinable
public func targetOfCTransitionFor(machine m: URL, states: [State], state name: StateName, transition number: Int) -> StateID? {
    guard let content = contentOfCStateFor(machine: m, state: name),
          let i = targetStateIndexOfCTransition(number, inHeader: content),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}


/// Read the content of the <Machine>.mm file
/// - Parameter machine: The machine URL.
/// - Returns: The content of the machine, or `nil` if not found.
@inlinable
public func contentOfCImplementationFor(machine: URL) -> String? {
    let name = machine.deletingPathExtension().lastPathComponent
    let file = "\(name).c"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try NSString(contentsOf: url, usedEncoding: nil)
        return content as String
    } catch {
        fputs("Cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return nil
    }
}


/// Return the target state index of the given transition
/// based on the content of the State.h file
/// - Parameter content: The content to examine.
/// - Returns: The target state index.
@inlinable
public func suspendStateIndexOfCMachine(inImplementation content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: #/setSuspendState[^0-9]*([0-9]*)/#),
        let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Return the suspend state ID for a given machine
/// - Parameters:
///   - m: The machine URL.
///   - states: The states the machine is composed of.
/// - Returns: The suspend state ID, or `nil` if nonexistent.
@inlinable
public func suspendStateOfCMachine(_ m: URL, states: [State]) -> StateID? {
    guard let content = contentOfCImplementationFor(machine: m),
          let i = suspendStateIndexOfCMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}
