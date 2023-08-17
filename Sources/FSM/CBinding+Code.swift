//
//  CBinding+Code.swift
//
//  Created by Rene Hexel on 17/08/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

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
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wpadded\""
        ""
        "struct LLFSMachine;"
        "struct LLFSMState;"
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
            "struct LLFSMState * const states[MACHINE_\(upperName)_NUMBER_OF_STATES];"
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
        ""
        "#pragma clang diagnostic pop"
        "#pragma GCC diagnostic pop"
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
        "#include \"Machine_\(name)_Includes.h\""
        ""
        "#ifndef NULL"
        "#define NULL ((void*)0)"
        "#endif"
        ""
        "/// Initialise an instance of `Machine_" + name + "."
        "///"
        "/// - Parameter machine: The machine to initialise."
        "void fsm_" + name + "_init(struct Machine_" + name + " * const machine)"
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
        "bool fsm_" + name + "_validate(struct Machine_" + name + " * const machine)"
        Code.bracedBlock {
            "return machine->current_state != NULL &&"
            "true; // FIXME: check states"
        }
    } + "\n"
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
        "#ifndef NULL"
        "#define NULL ((void*)0)"
        "#endif"
        ""
        "#define MACHINE_\(upperName)_NUMBER_OF_TRANSITIONS \(llfsm.states.count)"
        ""
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wvisibility\""
        ""
        "struct FSM\(name)_State_\(state.name)"
        Code.bracketedBlock(openingBracket: "{\n", closingBracket: "") {
            "void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);"
            "void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);"
            "void (*internal)(struct LLFSMachine *, struct LLFSMState *);"
            if isSupensible {
                "void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);"
                "void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);"
            }
        }
        "#   include \"State_\(state.name)_Variables.h\""
        "};"
        ""
        "/// Initialise the given state."
        "///"
        "/// - Parameter state: The state to initialise."
        "void fsm_" + name + "_" + state.name + "_init(struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// Validate the given state."
        "///"
        "/// - Parameter state: The state to initialise."
        "bool fsm_" + name + "_" + state.name + "_validate(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// Check the sequence of transitions for \(state.name)."
        "///"
        "/// - Returns: The state the machine transitions to (`NULL` if no transition fired)."
        "struct LLFSMState *fsm_" + name + "_" + state.name + "_check_transitions(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The onEntry function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine that entered the state."
        "///   - state: The state that was entered."
        "void fsm_" + name + "_" + state.name + "_on_entry(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The onExit function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being exited."
        "void fsm_" + name + "_" + state.name + "_on_exit(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The internal action for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state whose internal action to execute."
        "void fsm_" + name + "_" + state.name + "_internal(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        if isSupensible {
            "/// The onSuspend function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine that entered the state."
            "///   - state: The state that was suspended."
            "void fsm_" + name + "_" + state.name + "_on_suspend(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
            ""
            "/// The onResume function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine this function belongs to."
            "///   - state: The state being resumed."
            "void fsm_" + name + "_" + state.name + "_on_resume(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        }
        ""
        "#pragma clang diagnostic pop"
        "#pragma GCC diagnostic pop"
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
        "#include \"Machine_\(name).h\""
        "#include \"State_\(state.name).h\""
        "#include \"Machine_\(name)_Includes.h\""
        "#include \"State_\(state.name)_Includes.h\""
        ""
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        "#pragma GCC diagnostic ignored \"-Wincompatible-pointer-types\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wincompatible-function-pointer-types\""
        "#pragma clang diagnostic ignored \"-Wcompare-distinct-pointer-types\""
        "#pragma clang diagnostic ignored \"-Wvisibility\""
        ""
        "/// Initialise the given \(state.name) state."
        "///"
        "/// - Parameter state: The state to initialise."
        "void fsm_" + name + "_" + state.name + "_init(struct FSM\(name)_State_\(state.name) * const state)"
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
        "bool fsm_" + name + "_" + state.name + "_validate(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state)"
        Code.bracedBlock {
            "(void)machine;"
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
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wunused-parameter\""
        ""
        "/// The onEntry function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine that entered the state."
        "///   - state: The state that was entered."
        "void fsm_" + name + "_" + state.name + "_on_entry(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_OnEntry.mm\""
        "}"
        ""
        "/// The onExit function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being exited."
        "void fsm_" + name + "_" + state.name + "_on_exit(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_OnExit.mm\""
        "}"
        ""
        "/// The internal action for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state whose internal action to execute."
        "void fsm_" + name + "_" + state.name + "_internal(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_Internal.mm\""
        "}"
        ""
        if isSupensible {
            "/// The onSuspend function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine that entered the state."
            "///   - state: The state that was suspended."
            "void fsm_" + name + "_" + state.name + "_on_suspend(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
            "{"
            "#   include \"State_\(state.name)_OnSuspend.mm\""
            "}"
            ""
            "/// The onResume function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine this function belongs to."
            "///   - state: The state being resumed."
            "void fsm_" + name + "_" + state.name + "_on_resume(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
            "{"
            "#   include \"State_\(state.name)_OnResume.mm\""
            "}"
        }
        ""
        "/// Check the sequence of transitions for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being resumed."
        "/// - Returns: The state the machine transitions to (`NULL` if no transition fired)."
        "struct LLFSMState *fsm_" + name + "_" + state.name + "_check_transitions(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state)"
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
    } + "\n"
}

public func cMakeLists(for fsm: LLFSM, at url: URL, isSuspensible: Bool) -> Code {
    let name = url.deletingPathExtension().lastPathComponent
    return .block {
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name) C)"
        ""
        "# Require the C standard to be C17,"
        "# but allow extensions."
        "set(CMAKE_C_STANDARD 17)"
        "set(CMAKE_C_STANDARD_REQUIRED ON)"
        "set(CMAKE_C_EXTENSIONS ON)"
        ""
        "# Set the default build type to Debug."
        "if(NOT CMAKE_BUILD_TYPE)"
        "   set(CMAKE_BUILD_TYPE Debug)"
        "endif()"
        ""
        "# Sources for the \(name) LLFSM."
        "set(\(name)_SOURCES"
        "    Machine_\(name).c"
        Code.enumerating(array: fsm.states) { i, stateID in
            if let state = fsm.stateMap[stateID] {
                "    State_\(state.name).c"
            } else {
                "// Warning: ignoring orphaned state \(i) (\(stateID))"
            }
        }
        ")"
        ""
        "add_library(\(name) STATIC ${\(name)_SOURCES})"
        ""
    }
}

