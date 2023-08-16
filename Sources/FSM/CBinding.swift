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
        let machineCode = cMachineInterface(for: llfsm, named: name, isSupensible: isSuspensible)
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
            let stateCode = cStateInterface(for: state, llfsm: fsm, named: name, isSupensible: isSuspensible)
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
        let machineCode = cMachineCode(for: llfsm, named: name, isSupensible: isSuspensible)
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
            let stateCode = cStateCode(for: state, llfsm: fsm, named: name, isSupensible: isSuspensible)
            try url.write(content: stateCode, to: "State_" + state.name + ".c")
        }
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
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns:
public func cMachineInterface(for llfsm: LLFSM, named name: String, isSupensible: Bool) -> Code {
    let upperName = name.uppercased()
    return """
    //
    // Machine_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_MACHINE_" + name + "_h") {
        "#include <stdbool.h>"
        ""
        "#define MACHINE_\(upperName)_NUMBER_OF_STATES \(llfsm.states.count)"
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
        "/// A \(name) LLFSM."
        "struct Machine_" + name
        Code.bracketedBlock(openingBracket: "{\n", closingBracket: "") {
            "struct LLFSMState *current_state;"
            "struct LLFSMState *previous_state;"
            "unsigned long      state_time;"
            if isSupensible {
                "struct LLFSMState *suspend_state;"
                "struct LLFSMState *resume_state;"
            }
            "struct LLFSMState *states[MACHINE_\(upperName)_NUMBER_OF_STATES];"
        }
        "#   include \"Machine_\(name)_Variables.h\""
        "};"
        ""
        "/// Initialise a `Machine_" + name + "` LLFSM."
        "///"
        "/// - Parameter machine: The LLFSM to initialise."
        "void fsm_" + name + "_init(struct Machine_" + name + " *);"
        ""
        "/// Validate a `Machine_" + name + "` LLFSM."
        "///"
        "/// - Parameter machine: The LLFSM to initialise."
        "bool fsm_" + name + "_validate(struct Machine_" + name + " *);"
    }
}

/// Create the C code for an LLFSM.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the LLFSM.
///   - numberOfStates: The number of states the LLFSM contains.
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated C code.
public func cMachineCode(for llfsm: LLFSM, named name: String, isSupensible: Bool) -> Code {
    """
    //
    // Machine_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .block {
        "#include \"Machine_\(name).h\""
        ""
        "#ifndef NULL"
        "#define NULL ((void*)0)"
        "#endif"
        ""
        "/// Initialise an instance of `Machine_" + name + "."
        "///"
        "/// - Parameter machine: The machine to initialise."
        "void fsm_" + name + "_init(struct Machine_" + name + " *machine)"
        Code.bracedBlock {
            "machine->current_state = machine->states[0];"
            "machine->previous_state = NULL;"
            "machine->state_time = 0;"
            if isSupensible {
                "machine->suspend_state = " + ((llfsm.suspendState.flatMap {
                    llfsm.states.firstIndex(of: $0).map { "machine->states[\($0)];" }
                }) ?? "NULL;")
                "machine->resume_state = NULL;"
            }
        }
        ""
        "/// Validate an instance of `Machine_" + name + "."
        "///"
        "/// - Parameter machine: The machine to validate."
        "/// - Returns: `true` iff the machine appears valid."
        "bool fsm_" + name + "_validate(struct Machine_" + name + " *machine)"
        Code.bracedBlock {
            "return machine->current_state != NULL &&"
            "true // FIXME: check states"
        }
    }
}

/// Create the C include file for a State.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the State.
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated header for the state.
public func cStateInterface(for state: State, llfsm: LLFSM, named name: String, isSupensible: Bool) -> Code {
    let upperName = name.uppercased()
    return """
    //
    // State_\(state.name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    
    """ + .includeFile(named: "LLFSM_" + name + "_" + state.name + "_h") {
        "#include <stdbool.h>"
        ""
        "#define MACHINE_\(upperName)_NUMBER_OF_TRANSITIONS \(llfsm.states.count)"
        ""
        "struct FSM\(name)_State_\(state.name)"
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
        "/// Initialise the given state."
        "///"
        "/// - Parameter state: The state to initialise."
        "void fsm_" + name + "_" + state.name + "_init(struct LLFSMState *);"
        ""
        "/// Check the sequence of transitions for \(state.name)."
        "///"
        "/// - Returns: The state the machine transitions to (`NULL` if no transition fired)."
        "struct LLFSMState *fsm_" + name + "_" + state.name + "_check_transitions();"
        ""
        "/// The onEntry function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine that entered the state."
        "///   - state: The state that was entered."
        "void fsm_" + name + "_" + state.name + "_on_entry(struct LLFSMachine *machine, struct LLFSMState *state);"
        ""
        "/// The onExit function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being exited."
        "void fsm_" + name + "_" + state.name + "_on_exit(struct LLFSMachine *machine, struct LLFSMState *state);"
        ""
        "/// The internal action for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state whose internal action to execute."
        "void fsm_" + name + "_" + state.name + "_internal(struct LLFSMachine *machine, struct LLFSMState *state);"
        ""
        "/// The onSuspend function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine that entered the state."
        "///   - state: The state that was suspended."
        "void fsm_" + name + "_" + state.name + "_on_suspend(struct LLFSMachine *machine, struct LLFSMState *state);"
        ""
        "/// The onResume function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being resumed."
        "void fsm_" + name + "_" + state.name + "_on_resume(struct LLFSMachine *machine, struct LLFSMState *state);"
    }
}

/// Create the C code for a State.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - state: The name of the state to write the code for.
///   - isSupensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated code for the state.
public func cStateCode(for state: State, llfsm: LLFSM, named name: String, isSupensible: Bool) -> Code {
    .block {
        "//"
        "// State_\(state.name).c"
        "//"
        "// Automatically created using fsmconvert -- do not change manually!"
        "//"
        ""
        "#include \"State_\(state.name).h\""
        ""
        "/// Initialise the given \(state.name) state."
        "///"
        "/// - Parameter state: The state to initialise."
        "void fsm_" + name + "_" + state.name + "_init(struct FSM\(name)_State_\(state.name) *state)"
        Code.bracedBlock {
            "state->on_entry   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_entry;"
            "state->on_exit    = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_exit;"
            "state->internal   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_internal;"
            if isSupensible {
                "state->on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_suspend;"
                "state->on_resume  = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_resume;"
            }
        }
        ""
        "/// Check the validity of the given \(state.name) state."
        "///"
        "/// - Parameter state: The state to initialise."
        "bool fsm_" + name + "_" + state.name + "_validate(const struct FSM\(name)_State_\(state.name) *state)"
        Code.bracedBlock {
            "return state->on_entry   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_entry &&"
            Code.indentedBlock(with: "       ") {
                "state->on_exit    == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_exit &&"
                "state->internal   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_internal \(isSupensible ? "&&" : ";")"
                if isSupensible {
                    "state->on_suspend == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_suspend &&"
                    "state->on_resume  == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + name + "_" + state.name + "_on_resume;"
                }
            }
        }
        ""
        "/// Check the sequence of transitions for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being resumed."
        "/// - Returns: The state the machine transitions to (`NULL` if no transition fired)."
        "struct LLFSMState *fsm_" + name + "_" + state.name + "_check_transitions(const struct Machine_" + name + " *machine, const struct FSM\(name)_State_\(state.name) *state)"
        Code.bracedBlock {
            Code.enumerating(array: llfsm.transitionsFrom(state.id)) { i, transitionID in
                if let transition = llfsm.transitionMap[transitionID],
                   let targetState = llfsm.stateMap[transition.target] {
                    "if ("
                    "    #include \"State_\(state.name)_Transition_\(i).expr\""
                    ") return \(llfsm.states.firstIndex(of: targetState.id).map { "machine->states[\($0)];" } ?? "NULL; // Warning: cannot find \(targetState.name) in machine \(name)")"
                } else {
                    "// Warning: ignoring incomplete transition \(i) with ID \(transitionID)"
                }
            }
            "return NULL; // None of the transitions fired."
        }
    }
}
