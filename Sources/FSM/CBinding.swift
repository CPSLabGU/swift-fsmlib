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
        let machineCode = cMachineInterface(for: llfsm, named: name, numberOfStates: llfsm.states.count, isSupensible: isSuspensible)
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
            let transitions = fsm.transitionsFrom(stateID)
            let stateCode = cStateInterface(for: state, llfsm: fsm, named: name, numberOfTransitions: transitions.count, isSupensible: isSuspensible)
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
    @inlinable
    func writeCode(for llfsm: LLFSM, to url: URL) throws {
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

/// Create the C include file for an LLFSM.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the LLFSM.
///   - numberOfStates: The number of states the LLFSM contains.
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns:
public func cMachineInterface(for llfsm: LLFSM, named name: String, numberOfStates: Int, isSupensible: Bool) -> Code {
    let upperName = name.uppercased()
    return .includeFile(named: "LLFSM_MACHINE_" + name + "_h") {
        "#include <stdbool.h>"
        ""
        "#define MACHINE_\(upperName)_NUMBER_OF_STATES \(numberOfStates)"
        ""
        "#undef IS_SUSPENDED"
        "#undef IS_SUSPENSIBLE"
        if isSupensible {
            "#define IS_SUSPENSIBLE(m) (!!(m)->suspend_state)"
            "#define IS_SUSPENDED(m) ((m)->suspend_state == (m)->current_state)"
            "#define MACHINE_\(name.uppercased())_IS_SUSPENSIBLE true"
        } else {
            "#define IS_SUSPENSIBLE(m) false"
            "#define IS_SUSPENDED(m)   false"
            "#define MACHINE_\(name.uppercased())_IS_SUSPENSIBLE false"
        }
        ""
        "struct Machine_" + name
        Code.bracedBlock {
            "struct LLFSMState *current_state;"
            "struct LLFSMState *previous_state;"
            "unsigned long      state_time;"
            if isSupensible {
                "struct LLFSMState *suspend_state;"
                "struct LLFSMState *resume_state;"
            }
            "struct LLFSMState *states[MACHINE_\(upperName)_NUMBER_OF_STATES];"
        } + ";"
    }
}

/// Create the C include file for a State.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the State.
///   - numberOfTransitions: The number of transitions state has.
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns:
public func cStateInterface(for state: State, llfsm: LLFSM, named name: String, numberOfTransitions: Int, isSupensible: Bool) -> Code {
    let upperName = name.uppercased()
    return .includeFile(named: "LLFSM_" + name + "_" + state.name + "_h") {
        "#include <stdbool.h>"
        ""
        "#define MACHINE_\(upperName)_NUMBER_OF_TRANSITIONS \(numberOfTransitions)"
        ""
        "struct FSM\(name)_State_\(state.name)" + name
        Code.bracedBlock {
            "void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);"
            "void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);"
            "void (*internal)(struct LLFSMachine *, struct LLFSMState *);"
            if isSupensible {
                "void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);"
                "void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);"
            }
        } + ";"
        ""
        "struct LLFSMState *fsm_" + name + "_" + state.name + "_check_transitions();"
    }
}
