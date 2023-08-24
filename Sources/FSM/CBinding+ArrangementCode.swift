//
//  CBinding+ArrangementCode.swift
//
//  Created by Rene Hexel on 19/8/2023.
//
/// Return the interface for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement interface code.
public func cArrangementInterface(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    return """
    //
    // Arrangement_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_ARRANGEMENT_" + upperName + "_H") {
        "#include <inttypes.h>"
        "#include <stdbool.h>"
        ""
        "#define ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)"
        ""
        "struct LLFSMachine;"
        "struct LLFSMArrangement;"
        ""
        "/// A \(name) LLFSM Arrangement."
        "struct Arrangement_" + name
        Code.bracedBlock {
            "/// The number of instances in this arrangement."
            "uintptr_t number_of_instances;"
            "union"
            Code.bracedBlock {
                "/// The machines in this arrangement."
                "struct LLFSMachine *machines[\(instances.count)];"
                "struct"
                Code.bracedBlock {
                    Code.forEach(instances) { instance in
                        let machineName = instance.url.deletingPathExtension().lastPathComponent
                        "/// An instance of the \(machineName) LLFSM."
                        "struct Machine_\(machineName) *fsm_\(instance.name.lowercased());"
                    }
                } + ";"
            } + ";"
        } + ";"
        ""
        "/// Initialise the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "void arrangement_" + name + "_init(struct Arrangement_" + name + " * const arrangement);"
        ""
        "/// Validate the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "bool arrangement_" + name + "_validate(struct Arrangement_" + name + " * const arrangement);"
        ""
        "/// Run a ringlet of a C-language LLFSM Arrangement."
        "///"
        "/// This runs one ringlet of the machines of Arrangement " + name + "."
        "///"
        "/// - Parameter arrangement: The machine arrangement to run a ringlet over."
        "void arrangement_" + name + "_execute_once(struct Arrangement_" + name + " * const arrangement);"
    }
}

/// Return the implementation for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement implementation code.
public func cArrangementCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    return """
    //
    // Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Machine_Common.h\"
    #include \"Arrangement_\(name).h\"

    """ + Code.forEach(instances) { instance in
        "#include \"" + instance.name + ".machine/Machine_" + instance.name + ".h\""
    } + """

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored \"-Wunused-macros\"

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        ""
        "/// Initialise the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "void arrangement_" + name + "_init(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            "arrangement->number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;"
            Code.forEach(instances) { instance in
                "fsm_" + name + "_init(arrangement->fsm_" + instance.name.lowercased() + ");"
            }
        }
        ""
        "/// Validate the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "bool arrangement_" + name + "_validate(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            "return arrangement->number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&"
            Code.enumerating(array: instances) { (i, instance) in
                "    fsm_" + name + "_validate(arrangement->fsm_" + instance.name.lowercased() + (i < instances.count - 1 ? ") &&" : ");")
            }
        }
        ""
        "/// Run a ringlet of the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to run a ringlet over."
        "void arrangement_" + name + "_execute_once(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            "unsigned i;"
            "for (i = 0; i < ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES; i++)"
            Code.bracedBlock {
                "struct LLFSMachine * const machine = arrangement->machines[i];"
                "llfsm_execute_once(machine);"
            }
        }
        ""
    }
}

/// Return the interface for a static C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement interface code.
public func cStaticArrangementInterface(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    return """
    //
    // Static_Arrangement_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_STATIC_ARRANGEMENT_" + upperName + "_H") {
        Code.forEach(instances) { instance in
            "#include \"" + instance.name + ".machine/Machine_" + instance.name + ".h\""
        }
        ""
        "#define STATIC_ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)"
        ""
        "struct LLFSMachine;"
        "struct LLFSMArrangement;"
        ""
        Code.forEach(instances) { instance in
            let machineName = instance.url.deletingPathExtension().lastPathComponent
            "/// Static instantiation of a \(machineName) LLFSM."
            "extern struct Machine_\(machineName) static_fsm_\(instance.name.lowercased());"
            Code.forEach(instance.fsm.states.compactMap {
                instance.fsm.stateMap[$0]
            }) { state in
                "/// Static instantiation of the \(machineName) LLFSM state \(state.name)."
                "extern struct FSM\(machineName)_State_\(state.name) static_\(instance.name.lowercased())_state_\(state.name);"
            }
        }
        "/// Static instantiation of the \(name) LLFSM Arrangement."
        "extern struct Arrangement_" + name + " static_arrangement_" + name.lowercased() + ";"
    }
}

/// Return the code for a static C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement interface code.
public func cStaticArrangementCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    """
    //
    // Static_Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include <stdbool.h>
    #include \"Machine_Common.h\"
    #include \"Arrangement_\(name).h\"
    #include \"Static_Arrangement_\(name).h\"

    """ + Code.forEach(instances) { instance in
        "#include \"" + instance.name + ".machine/Machine_" + instance.name + ".h\""
        Code.forEach(instance.fsm.states.compactMap {
            instance.fsm.stateMap[$0]
        }) { state in
            "#include \"" + instance.name + ".machine/State_" + state.name + ".h\""
        }
    } + "\n\n" + """
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored \"-Wunused-macros\"

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        "#include <stdbool.h>"
        ""
        Code.forEach(instances) { instance in
            let machineName = instance.url.deletingPathExtension().lastPathComponent
            "/// Static instantiation of a \(machineName) LLFSM."
            "struct Machine_\(machineName) static_fsm_\(instance.name.lowercased()) = "
            Code.bracedBlock {
                if let initialState = instance.fsm.stateMap[instance.fsm.initialState] {
                    ".current_state = (struct LLFSMState *) &static_\(instance.name.lowercased())_state_\(initialState.name),"
                }
                if isSuspensible,
                   let suspendStateID = instance.fsm.suspendState,
                   let suspendState = instance.fsm.stateMap[suspendStateID] {
                    ".suspend_state = &static_\(instance.name.lowercased())_state_\(suspendState.name),"
                }
                ".states ="
                Code.bracedBlock {
                    Code.enumerating(array: instance.fsm.states.compactMap {
                        instance.fsm.stateMap[$0]
                    }) { (i, state) in
                        "(struct LLFSMState *) &static_\(instance.name.lowercased())_state_\(state.name)" +
                            (i == instance.fsm.states.count - 1 ? "" : ",")
                    }
                }
            } + ";"
            ""
            Code.forEach(instance.fsm.states.compactMap {
                instance.fsm.stateMap[$0]
            }) { state in
                "/// Static instantiation of the \(machineName) LLFSM state \(state.name)."
                "struct FSM\(machineName)_State_\(state.name) static_\(instance.name.lowercased())_state_\(state.name) = "
                Code.bracedBlock {
                    ".check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_" + name + "_" + state.name + "_check_transitions,"
                    ".on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + name + "_" + state.name + "_on_entry,"
                    ".on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + name + "_" + state.name + "_on_exit,"
                    ".internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + name + "_" + state.name + "_internal" + (isSuspensible ? "," : "")
                    if isSuspensible {
                        ".on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + name + "_" + state.name + "_on_suspend,"
                        ".on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + name + "_" + state.name + "_on_resume"
                    }
                } + ";"
            }
        }
        "/// Static instantiation of the \(name) LLFSM Arrangement."
        "struct Arrangement_" + name + " static_arrangement_" + name.lowercased() + " ="
        Code.bracedBlock {
            ".number_of_instances = STATIC_ARRANGEMENT_" + name.uppercased() + "_NUMBER_OF_INSTANCES,"
            Code.bracedBlock {
                Code.enumerating(array: instances) { (i, instance) in
                    let lowerInstance = instance.name.lowercased()
                    ".fsm_\(lowerInstance) = &static_fsm_\(lowerInstance)" +
                        (i < instances.count - 1 ? "," : "")
                }
            } + ","
        } + ";"
        ""
    }
}


/// Return the interface for a C-language LLFSM.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement interface code.
public func cArrangementMachineInterface(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    """
    //
    // Machine_Common.h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_ARRANGEMENT_COMMON_H") {
        "#include <inttypes.h>"
        "#include <stdbool.h>"
        ""
        "struct LLFSMState;"
        ""
        "/// A generic LLFSM."
        "struct LLFSMachine"
        Code.bracedBlock {
            "struct LLFSMState *current_state;"
            "struct LLFSMState *previous_state;"
            "uintptr_t          state_time;"
            if isSuspensible {
                "struct LLFSMState *suspend_state;"
                "struct LLFSMState *resume_state;"
            }
            "struct LLFSMState * const states[1];"
        } + ";"
        ""
        "struct LLFSMState"
        Code.bracedBlock {
            "struct LLFSMState *(*check_transitions)(const struct LLFSMachine * const, const struct LLFSMState * const);"
            "void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);"
            "void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);"
            "void (*internal)(struct LLFSMachine *, struct LLFSMState *);"
            if isSuspensible {
                "void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);"
                "void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);"
            }
        } + ";"
        ""
        "/// Run a ringlet of a C-language LLFSM."
        "///"
        "/// - Parameter machine: The machine arrangement to initialise."
        "void llfsm_execute_once(struct LLFSMachine * const machine);"
        ""
    }
}

/// Return the implementation for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement implementation code.
public func cArrangementMachineCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    """
    //
    // Machine_Common.c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Machine_Common.h\"

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored \"-Wunused-macros\"
    #pragma clang diagnostic ignored \"-Wdeclaration-after-statement\"

    #ifdef INCLUDE_MACHINE_CUSTOM
    #include \"Machine_Custom.h\"
    #endif
    #ifndef GET_TIME
    #define GET_TIME() (machine->state_time + 1)
    #endif
    #ifndef TAKE_SNAPSHOT
    #define TAKE_SNAPSHOT()
    #endif

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        ""
        "/// Run a ringlet of a C-language LLFSM."
        "///"
        "/// - Parameter machine: The machine arrangement to initialise."
        "void llfsm_execute_once(struct LLFSMachine * const machine)"
        Code.bracedBlock {
            "struct LLFSMState * const current_state = machine->current_state;"
            ""
            "if (current_state != machine->previous_state)"
            Code.bracedBlock {
                "current_state->on_entry(machine, current_state);"
            }
            "TAKE_SNAPSHOT();"
            "struct LLFSMState * const target_state = current_state->check_transitions(machine, current_state);"
            "machine->previous_state = current_state;"
            "if (target_state)"
            Code.bracedBlock {
                "current_state->on_exit(machine, current_state);"
                "machine->current_state = target_state;"
            }
            "else"
            Code.bracedBlock {
                "current_state->internal(machine, current_state);"
            }
        }
        ""
    }
}


/// Return the main for running a static C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement implementation code.
public func cStaticArrangementMainCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    """
    //
    // main.c for running the static LLFSM arrangement named \(name).
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdbool.h>

    #include \"Machine_Common.h\"
    #include \"Arrangement_\(name).h\"
    #include \"Static_Arrangement_\(name).h\"

    int main(int argc, char *argv[])
    """ + Code.bracedBlock {
        "uintptr_t num_runs = (uintptr_t)(argc > 1 ? strtoull(argv[1], NULL, 10) : ~0ULL);"
        ""
        "if (!arrangement_" + name + "_validate(&static_arrangement_" + name.lowercased() + "))"
        Code.bracedBlock {
            "printf(\"'static_arrangement_" + name.lowercased() + "' does not validate!\\n\");"
            "return EXIT_FAILURE;"
        }
        ""
        "while (num_runs--)"
        Code.bracedBlock {
            "arrangement_" + name + "_execute_once(&static_arrangement_" + name.lowercased() + ");"
        }
        ""
        "return EXIT_SUCCESS;"
    } + "\n"
}

/// Create CMakeLists for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func cArrangementMakeLists(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
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
        "# Sources for the \(name) LLFSM arrangement."
        "set(\(name)_ARRANGEMENT_SOURCES"
        "    Arrangement_\(name).c"
        "    Machine_Common.c"
        ")"
        ""
        "# Machines for the \(name) LLFSM arrangement."
        "set(\(name)_STATIC_ARRANGEMENT_SOURCES"
        "    Static_Arrangement_\(name).c"
        ")"
        ""
        "add_library(\(name)_arrangement STATIC ${\(name)_ARRANGEMENT_SOURCES})"
        "add_library(\(name)_static_arrangement STATIC ${\(name)_STATIC_ARRANGEMENT_SOURCES})"
        ""
        Code.forEach(Array(Set(instances.map(\.url.lastPathComponent)))) { directory in
            "add_subdirectory(" + directory + ")"
        }
        ""
        "add_executable(run_\(name)_arrangement static_main.c)"
        "target_link_libraries(run_\(name)_arrangement"
        "    \(name)_static_arrangement"
        "    \(name)_arrangement"
        Code.enumerating(array: instances) { i, instance in
            "    \(instance.name)_fsm"
        }
        ")"
        ""
    }
}

