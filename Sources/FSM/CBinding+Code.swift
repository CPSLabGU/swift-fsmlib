//
//  CBinding+Code.swift
//
//  Created by Rene Hexel on 17/08/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
/// Create the C include file for an LLFSM.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the LLFSM.
///   - isSuspensible: Set to `true` to create an interface that supports suspension.
/// - Returns:
public func cMachineInterface(for llfsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()
    return """
    //
    // Machine_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_MACHINE_" + upperName + "_H") {
        "#include <inttypes.h>"
        "#include <stdbool.h>"
        "#include \"Machine_" + name + "_Includes.h\""
        ""
        "#ifdef INCLUDE_MACHINE_CUSTOM"
        "#include \"Machine_Custom.h\""
        "#endif"
        ""
        "#ifdef INCLUDE_MACHINE_" + upperName + "_CUSTOM"
        "#include \"Machine_" + name + "_Custom.h\""
        "#endif"
        ""
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wunused-macros\""
        ""
        "#define MACHINE_" + upperName + "_NUMBER_OF_STATES \(llfsm.states.count)"
        ""
        "#undef IS_SUSPENDED"
        "#undef IS_SUSPENSIBLE"
        if isSuspensible {
            "#define IS_SUSPENSIBLE(m) (!!(m)->suspend_state)"
            "#define IS_SUSPENDED(m) ((m)->suspend_state == (m)->current_state)"
            "#define MACHINE_" + upperName + "_IS_SUSPENSIBLE true"
            ""
            "#ifndef SUSPEND"
            "#define SUSPEND(m) ((m)->suspend_state && ((m)->resume_state = (m)->current_state == (m)->suspend_state ? (m)->resume_state : (m)->current_state) && ((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->suspend_state))"
            "#endif"
            "#ifndef RESUME"
            "#define RESUME(m)  ((m)->suspend_state && (m)->current_state == (m)->suspend_state && ((m)->current_state = (m)->resume_state ? (m)->resume_state : ((m)->previous_state && (m)->previous_state != (m)->suspend_state ? (m)->previous_state : (m)->states[0])) && ((m)->previous_state = (m)->suspend_state))"
            "#endif"
        } else {
            "#define IS_SUSPENSIBLE(m) false"
            "#define IS_SUSPENDED(m)   false"
            "#define MACHINE_" + upperName + "_IS_SUSPENSIBLE false"
        }
        ""
        "#ifndef RESTART"
        "#define RESTART(m) (((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->states[0]))"
        "#endif"
        "#ifndef GET_TIME"
        "#define GET_TIME() (machine->state_time + 1)"
        "#endif"
        "#ifndef TAKE_SNAPSHOT"
        "#define TAKE_SNAPSHOT()"
        "#endif"
        ""
        ""
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wpadded\""
        ""
        "struct LLFSMArrangement;"
        "struct LLFSMState;"
        "struct LLFSMachine;"
        ""
        "/// A \(name) LLFSM."
        "struct Machine_" + name
        Code.bracketedBlock(openingBracket: "{\n", closingBracket: "") {
            "struct LLFSMState *current_state;"
            "struct LLFSMState *previous_state;"
            "uintptr_t          state_time;"
            if isSuspensible {
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
        "void fsm_" + lowerName + "_init(struct Machine_" + name + " *);"
        ""
        "/// Validate a `Machine_" + name + "` LLFSM."
        "///"
        "/// - Parameter machine: The LLFSM to initialise."
        "bool fsm_" + lowerName + "_validate(struct Machine_" + name + " *);"
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
///   - isSuspensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated C code.
public func cMachineCode(for llfsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
    """
    //
    // Machine_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .block {
        let lowerName = name.lowercased()
        "#include \"Machine_\(name).h\""
        ""
        "#ifndef NULL"
        "#define NULL ((void*)0)"
        "#endif"
        ""
        "/// Initialise an instance of `Machine_" + name + "."
        "///"
        "/// - Parameter machine: The machine to initialise."
        "void fsm_" + lowerName + "_init(struct Machine_" + name + " * const machine)"
        Code.bracedBlock {
            "machine->current_state = machine->states[0];"
            "machine->previous_state = NULL;"
            "machine->state_time = 0;"
            if isSuspensible {
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
        "bool fsm_" + lowerName + "_validate(struct Machine_" + name + " * const machine)"
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
///   - isSuspensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated header for the state.
public func cStateInterface(for state: State, llfsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()
    let lowerState = state.name.lowercased()
    return """
    //
    // State_\(state.name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_" + name + "_" + state.name + "_h") {
        "#include <stdbool.h>"
        "#include \"Machine_\(name)_Includes.h\""
        "#include \"State_\(state.name)_Includes.h\""
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
            "struct LLFSMState *(*check_transitions)(const struct LLFSMachine *, const struct LLFSMState *);"
            "void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);"
            "void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);"
            "void (*internal)(struct LLFSMachine *, struct LLFSMState *);"
            if isSuspensible {
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
        "void fsm_" + lowerName + "_" + lowerState + "_init(struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// Validate the given state."
        "///"
        "/// - Parameter state: The state to initialise."
        "bool fsm_" + lowerName + "_" + lowerState + "_validate(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// Check the sequence of transitions for \(state.name)."
        "///"
        "/// - Returns: The state the machine transitions to (`NULL` if no transition fired)."
        "struct LLFSMState *fsm_" + lowerName + "_" + lowerState + "_check_transitions(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The onEntry function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine that entered the state."
        "///   - state: The state that was entered."
        "void fsm_" + lowerName + "_" + lowerState + "_on_entry(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The onExit function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being exited."
        "void fsm_" + lowerName + "_" + lowerState + "_on_exit(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        "/// The internal action for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state whose internal action to execute."
        "void fsm_" + lowerName + "_" + lowerState + "_internal(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
        ""
        if isSuspensible {
            "/// The onSuspend function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine that entered the state."
            "///   - state: The state that was suspended."
            "void fsm_" + lowerName + "_" + lowerState + "_on_suspend(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
            ""
            "/// The onResume function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine this function belongs to."
            "///   - state: The state being resumed."
            "void fsm_" + lowerName + "_" + lowerState + "_on_resume(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state);"
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
///   - isSuspensible: Set to `true` to create an interface that supports suspension.
/// - Returns: The generated code for the state.
public func cStateCode(for state: State, llfsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
    .block {
        let lowerName = name.lowercased()
        let lowerState = state.name.lowercased()
        "//"
        "// State_\(state.name).c"
        "//"
        "// Automatically created using fsmconvert -- do not change manually!"
        "//"
        "#include \"Machine_\(name).h\""
        "#include \"State_\(state.name).h\""
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
        "void fsm_" + lowerName + "_" + lowerState + "_init(struct FSM\(name)_State_\(state.name) * const state)"
        Code.bracedBlock {
            "state->check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_check_transitions;"
            "state->on_entry   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_entry;"
            "state->on_exit    = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_exit;"
            "state->internal   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_internal;"
            if isSuspensible {
                "state->on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_suspend;"
                "state->on_resume  = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_resume;"
            }
        }
        ""
        "/// Check the validity of the given \(state.name) state."
        "///"
        "/// - Parameter state: The state to validate."
        "bool fsm_" + lowerName + "_" + lowerState + "_validate(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state)"
        Code.bracedBlock {
            "(void)machine;"
            "return state->check_transitions == (struct LLFSMState *(*)(const struct LLFSMachine * const machine, const struct LLFSMState * const state))fsm_" + lowerName + "_" + lowerState + "_check_transitions &&"
            Code.indentedBlock(with: "       ") {
                "state->on_entry   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_entry &&"
                "state->on_exit    == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_exit &&"
                "state->internal   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_internal \(isSuspensible ? "&&" : ";")"
                if isSuspensible {
                    "state->on_suspend == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_suspend &&"
                    "state->on_resume  == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_" + lowerName + "_" + lowerState + "_on_resume;"
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
        "void fsm_" + lowerName + "_" + lowerState + "_on_entry(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_OnEntry.mm\""
        "}"
        ""
        "/// The onExit function for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state being exited."
        "void fsm_" + lowerName + "_" + lowerState + "_on_exit(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_OnExit.mm\""
        "}"
        ""
        "/// The internal action for \(state.name)."
        "///"
        "/// - Parameters:"
        "///   - machine: The machine this function belongs to."
        "///   - state: The state whose internal action to execute."
        "void fsm_" + lowerName + "_" + lowerState + "_internal(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
        "{"
        "#   include \"State_\(state.name)_Internal.mm\""
        "}"
        ""
        if isSuspensible {
            "/// The onSuspend function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine that entered the state."
            "///   - state: The state that was suspended."
            "void fsm_" + lowerName + "_" + lowerState + "_on_suspend(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
            "{"
            "#   include \"State_\(state.name)_OnSuspend.mm\""
            "}"
            ""
            "/// The onResume function for \(state.name)."
            "///"
            "/// - Parameters:"
            "///   - machine: The machine this function belongs to."
            "///   - state: The state being resumed."
            "void fsm_" + lowerName + "_" + lowerState + "_on_resume(struct Machine_" + name + " * const machine, struct FSM\(name)_State_\(state.name) * const state)"
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
        "struct LLFSMState *fsm_" + lowerName + "_" + lowerState + "_check_transitions(const struct Machine_" + name + " * const machine, const struct FSM\(name)_State_\(state.name) * const state)"
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

/// Create CMakeLists for an FSM.
///
/// - Parameters:
///   - fsm: The FSM to create the CMakeLists.txt for.
///   - name: The name of the Machine
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func cMakeLists(for fsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
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
        "set(\(name)_FSM_SOURCES"
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
        "add_library(\(name)_fsm STATIC ${\(name)_FSM_SOURCES})"
        ""
    }
}

