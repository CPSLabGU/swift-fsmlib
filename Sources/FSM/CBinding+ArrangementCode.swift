//
//  CBinding+ArrangementCode.swift
//
//  Created by Rene Hexel on 19/8/2023.
//  Copyright © 2012-2019, 2023, 2025 Rene Hexel. All rights reserved.
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
    let lowerName = name.lowercased()
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
                        let machineName = instance.typeName
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
        "void arrangement_" + lowerName + "_init(struct Arrangement_" + name + " * const arrangement);"
        ""
        "/// Validate the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "bool arrangement_" + lowerName + "_validate(struct Arrangement_" + name + " * const arrangement);"
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
public func cArrangementCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()
    let machineTypes = Array(Set(instances.map(\.typeName)))
    return """
    //
    // Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Machine_Common.h\"
    #include \"Arrangement_\(name).h\"

    """ + Code.forEach(machineTypes) { machine in
        "#include \"" + machine + ".machine/Machine_" + machine + ".h\""
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
        "void arrangement_" + lowerName + "_init(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            "arrangement->number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;"
            Code.forEach(instances) { instance in
                let lowerInstance = instance.name.lowercased()
                let lowerType = instance.typeName.lowercased()
                "fsm_" + lowerType + "_init(arrangement->fsm_" + lowerInstance + ");"
            }
        }
        ""
        "/// Validate the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "bool arrangement_" + lowerName + "_validate(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            "return arrangement->number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&"
            Code.enumerating(array: instances) { (i, instance) in
                let lowerInstance = instance.name.lowercased()
                let lowerType = instance.typeName.lowercased()
                "    fsm_" + lowerType + "_validate(arrangement->fsm_" + lowerInstance + (i < instances.count - 1 ? ") &&" : ");")
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
    let lowerName = name.lowercased()
    let machineTypes = Array(Set(instances.map(\.typeName)))
    return """
    //
    // Static_Arrangement_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_STATIC_ARRANGEMENT_" + upperName + "_H") {
        "#include \"Arrangement_" + name + ".h\""
        Code.forEach(machineTypes) { machine in
            "#include \"" + machine + ".machine/Machine_" + machine + ".h\""
        }
        ""
        "#define STATIC_ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)"
        "#ifndef SUSPEND_ALL"
        "#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct LLFSMArrangement *)&static_arrangement_" + lowerName + ")"
        "#endif // SUSPEND_ALL"
        "#ifndef RESUME_ALL"
        "#define RESUME_ALL() fsm_arrangement_resume_all((struct LLFSMArrangement *)&static_arrangement_" + lowerName + ")"
        "#endif // RESUME_ALL"
        "#ifndef RESTART_ALL"
        "#define RESTART_ALL() fsm_arrangement_restart_all((struct LLFSMArrangement *)&static_arrangement_" + lowerName + ")"
        "#endif // RESTART_ALL"
        ""
        "struct LLFSMachine;"
        "struct LLFSMArrangement;"
        ""
        Code.forEach(instances) { instance in
            let machineName = instance.typeName
            let lowerInstance = instance.name.lowercased()
            let fsm = instance.machine.llfsm
            "/// Static instantiation of a \(machineName) LLFSM."
            "extern struct Machine_" + machineName + " static_fsm_" + lowerInstance + ";"
            Code.forEach(fsm.states.compactMap {
                fsm.stateMap[$0]
            }) { state in
                "/// Static instantiation of the \(machineName) LLFSM state \(state.name)."
                "extern struct FSM\(machineName)_State_\(state.name) static_\(lowerInstance)_state_\(state.name);"
            }
        }
        "/// Static instantiation of the \(name) LLFSM Arrangement."
        "extern struct Arrangement_" + name + " static_arrangement_" + lowerName + ";"
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
    let machines = Dictionary(instances.map { ($0.typeName, $0) }, uniquingKeysWith: { a,_ in a })
    return """
    //
    // Static_Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include <stdbool.h>
    #include \"Machine_Common.h\"
    #include \"Arrangement_\(name).h\"
    #include \"Static_Arrangement_\(name).h\"

    """ + Code.forEach(machines) { (machine, instance) in
        let fsm = instance.machine.llfsm
        "#include \"" + machine + ".machine/Machine_" + machine + ".h\""
        Code.forEach(fsm.states.compactMap {
            fsm.stateMap[$0]
        }) { state in
            "#include \"" + machine + ".machine/State_" + state.name + ".h\""
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
            let machineName = instance.typeName
            let lowerMachine = machineName.lowercased()
            let lowerInstance = instance.name.lowercased()
            let fsm = instance.machine.llfsm
            "/// Static instantiation of a \(machineName) LLFSM."
            "struct Machine_" + machineName + " static_fsm_" + lowerInstance + " = "
            Code.bracedBlock {
                if let initialState = fsm.stateMap[fsm.initialState] {
                    ".current_state = (struct LLFSMState *) &static_" + lowerInstance + "_state_" + initialState.name + ","
                }
                if isSuspensible,
                   let suspendStateID = fsm.suspendState,
                   let suspendState = fsm.stateMap[suspendStateID] {
                    ".suspend_state = (struct LLFSMState *) &static_" + lowerInstance + "_state_" + suspendState.name + ","
                }
                ".states ="
                Code.bracedBlock {
                    Code.enumerating(array: fsm.states.compactMap {
                        fsm.stateMap[$0]
                    }) { (i, state) in
                        "(struct LLFSMState *) &static_" + lowerInstance + "_state_" + state.name +
                        (i == fsm.states.count - 1 ? "" : ",")
                    }
                }
            } + ";"
            ""
            Code.forEach(fsm.states.compactMap {
                fsm.stateMap[$0]
            }) { state in
                let lowerState = state.name.lowercased()
                "/// Static instantiation of the \(machineName) LLFSM state \(state.name)."
                "struct FSM" + machineName + "_State_" + state.name + " static_" + lowerInstance + "_state_\(state.name) = "
                Code.bracedBlock {
                    ".check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_check_transitions,"
                    ".on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_on_entry,"
                    ".on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_on_exit,"
                    ".internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_internal" + (isSuspensible ? "," : "")
                    if isSuspensible {
                        ".on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_on_suspend,"
                        ".on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_" + lowerMachine + "_" + lowerState + "_on_resume"
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
        "#ifdef INCLUDE_MACHINE_CUSTOM"
        "#include \"Machine_Custom.h\""
        "#endif"
        ""
        "#pragma GCC diagnostic push"
        "#pragma GCC diagnostic ignored \"-Wunknown-pragmas\""
        ""
        "#pragma clang diagnostic push"
        "#pragma clang diagnostic ignored \"-Wunused-macros\""
        ""
        if isSuspensible {
            "#ifndef IS_SUSPENSIBLE"
            "#define IS_SUSPENSIBLE(m) (!!(m)->suspend_state)"
            "#endif"
            "#ifndef IS_SUSPENDED"
            "#define IS_SUSPENDED(m) ((m)->suspend_state == (m)->current_state)"
            "#endif"
            "#ifndef SUSPEND"
            "#define SUSPEND(m) ((m)->suspend_state && ((m)->resume_state = (m)->current_state == (m)->suspend_state ? (m)->resume_state : (m)->current_state) && ((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->suspend_state))"
            "#endif"
            "#ifndef RESUME"
            "#define RESUME(m)  ((m)->suspend_state && (m)->current_state == (m)->suspend_state && ((m)->current_state = (m)->resume_state ? (m)->resume_state : ((m)->previous_state && (m)->previous_state != (m)->suspend_state ? (m)->previous_state : (m)->states[0])) && ((m)->previous_state = (m)->suspend_state))"
            "#endif"
        } else {
            "#define IS_SUSPENSIBLE(m) false"
            "#define IS_SUSPENDED(m)   false"
        }
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
        "struct LLFSMState;"
        "struct LLFSMachine;"
        ""
        "/// A generic LLFSM Arrangement."
        "struct LLFSMArrangement"
        Code.bracedBlock {
            "/// The number of instances in this arrangement."
            "uintptr_t number_of_instances;"
            "struct LLFSMachine *machines[\(instances.count)];"
        } + ";"
        ""
        "#ifndef STRUCT_LLFSMACHINE_"
        "#define STRUCT_LLFSMACHINE_"
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
        "#endif // STRUCT_LLFSMACHINE_"
        ""
        "#ifndef STRUCT_LLFSMSTATE_"
        "#define STRUCT_LLFSMSTATE_"
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
        "#endif // STRUCT_LLFSMSTATE_"
        //        "/// Validate an LLFSM arrangement."
        //        "///"
        //        "/// - Parameter arrangement: The machine arrangement to validate."
        //        "bool fsm_arrangement_validate(struct LLFSMArrangement * const arrangement);"
        //        ""
        "/// Run a ringlet of a C-language LLFSM Arrangement."
        "///"
        "/// This runs one ringlet of the machines of the given LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to run a ringlet over."
        "void fsm_arrangement_execute_once(struct LLFSMArrangement * const arrangement);"
        ""
        if isSuspensible {
            "/// Suspend all machines except for the first one."
            "///"
            "/// This suspends all LLFSMs in the given arrangement,"
            "/// with the exception of the first machine."
            "///"
            "/// - Parameter arrangement: The machine arrangement to suspend."
            "void fsm_arrangement_suspend_all(struct LLFSMArrangement * const arrangement);"
            ""
            "/// Suspend all machines except for the given machine."
            "///"
            "/// This suspends all LLFSMs in the given arrangement,"
            "/// with the exception of machine specified."
            "///"
            "/// - Parameters:"
            "///   - arrangement: The machine arrangement to suspend."
            "///   - machine: The machine to be excepted from suspension."
            "void fsm_arrangement_suspend_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);"
            ""
            "/// Resume all machines except for the first one."
            "///"
            "/// This resumes all LLFSMs in the given arrangement,"
            "/// with the exception of the first machine."
            "///"
            "/// - Parameter arrangement: The machine arrangement to resume."
            "void fsm_arrangement_resume_all(struct LLFSMArrangement * const arrangement);"
            ""
            "/// Resume all machines except for the given machine."
            "///"
            "/// This resumes all LLFSMs in the '" + name + "' arrangement,"
            "/// with the exception of machine specified."
            "///"
            "/// - Parameters:"
            "///   - arrangement: The machine arrangement to resume."
            "///   - machine: The machine to be excepted from resumption."
            "void fsm_arrangement_resume_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);"
            ""
        }
        "/// Restart all machines except for the first one."
        "///"
        "/// This restarts all LLFSMs in the given arrangement,"
        "/// with the exception of the first machine."
        "///"
        "/// - Parameter arrangement: The machine arrangement to restart."
        "void fsm_arrangement_restart_all(struct LLFSMArrangement * const arrangement);"
        ""
        "/// Restart all machines except for the given machine."
        "///"
        "/// This restarts all LLFSMs in the given arrangement,"
        "/// with the exception of machine specified."
        "///"
        "/// - Parameters:"
        "///   - arrangement: The machine arrangement to restart."
        "///   - machine: The machine to be excepted from restarting."
        "void fsm_arrangement_restart_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);"
        ""
        "/// Run a ringlet of a C-language LLFSM."
        "///"
        "/// - Parameter machine: The machine arrangement to initialise."
        "void llfsm_execute_once(struct LLFSMachine * const machine);"
        ""
        "#pragma clang diagnostic pop"
        "#pragma GCC diagnostic pop"
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

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        //        "/// Validate an LLFSM arrangement."
        //        "///"
        //        "/// - Parameter arrangement: The machine arrangement to validate."
        //        "bool fsm_arrangement_validate(struct LLFSMArrangement * const arrangement)"
        //        Code.bracedBlock {
        //            "const uintptr_t n = arrangement->number_of_instances;"
        //            "unsigned i;"
        //            "for (i = 0; i < n; i++)"
        //            Code.bracedBlock {
        //                "struct LLFSMachine * const machine = arrangement->machines[i];"
        //                "llfsm_validate(machine);"
        //            }
        //        }
        //        ""
        "/// Run a ringlet of a C-language LLFSM Arrangement."
        "///"
        "/// This runs one ringlet of the machines of the given LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to run a ringlet over."
        "void fsm_arrangement_execute_once(struct LLFSMArrangement * const arrangement)"
        Code.bracedBlock {
            "const uintptr_t n = arrangement->number_of_instances;"
            "unsigned i;"
            "for (i = 0; i < n; i++)"
            Code.bracedBlock {
                "struct LLFSMachine * const machine = arrangement->machines[i];"
                "llfsm_execute_once(machine);"
            }
        }
        ""
        if isSuspensible {
            "/// Suspend all machines except for the first one."
            "///"
            "/// This suspends all LLFSMs in the given arrangement,"
            "/// with the exception of the first machine."
            "///"
            "/// - Parameter arrangement: The machine arrangement to suspend."
            "void fsm_arrangement_suspend_all(struct LLFSMArrangement * const arrangement)"
            Code.bracedBlock {
                "const uintptr_t n = arrangement->number_of_instances;"
                "unsigned i;"
                "for (i = 1; i < n; i++)"
                Code.bracedBlock {
                    "struct LLFSMachine * const machine = arrangement->machines[i];"
                    "SUSPEND(machine);"
                }
            }
            ""
            "/// Suspend all machines except for the given machine."
            "///"
            "/// This suspends all LLFSMs in the given arrangement,"
            "/// with the exception of machine specified."
            "///"
            "/// - Parameters:"
            "///   - arrangement: The machine arrangement to suspend."
            "///   - machine: The machine to be excepted from suspension."
            "void fsm_arrangement_suspend_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)"
            Code.bracedBlock {
                "const uintptr_t n = arrangement->number_of_instances;"
                "unsigned i;"
                "for (i = 1; i < n; i++)"
                Code.bracedBlock {
                    "struct LLFSMachine * const m = arrangement->machines[i];"
                    "if (m != machine) SUSPEND(machine);"
                }
            }
            ""
            "/// Resume all machines except for the first one."
            "///"
            "/// This resumes all LLFSMs in the given arrangement,"
            "/// with the exception of the first machine."
            "///"
            "/// - Parameter arrangement: The machine arrangement to resume."
            "void fsm_arrangement_resume_all(struct LLFSMArrangement * const arrangement)"
            Code.bracedBlock {
                "const uintptr_t n = arrangement->number_of_instances;"
                "unsigned i;"
                "for (i = 1; i < n; i++)"
                Code.bracedBlock {
                    "struct LLFSMachine * const machine = arrangement->machines[i];"
                    "RESUME(machine);"
                }
            }
            ""
            "/// Resume all machines except for the given machine."
            "///"
            "/// This resumes all LLFSMs in the '" + name + "' arrangement,"
            "/// with the exception of machine specified."
            "///"
            "/// - Parameters:"
            "///   - arrangement: The machine arrangement to resume."
            "///   - machine: The machine to be excepted from resumption."
            "void fsm_arrangement_resume_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)"
            Code.bracedBlock {
                "const uintptr_t n = arrangement->number_of_instances;"
                "unsigned i;"
                "for (i = 1; i < n; i++)"
                Code.bracedBlock {
                    "struct LLFSMachine * const m = arrangement->machines[i];"
                    "if (m != machine) RESUME(machine);"
                }
            }
            ""
        }
        "/// Restart all machines except for the first one."
        "///"
        "/// This restarts all LLFSMs in the given arrangement,"
        "/// with the exception of the first machine."
        "///"
        "/// - Parameter arrangement: The machine arrangement to restart."
        "void fsm_arrangement_restart_all(struct LLFSMArrangement * const arrangement)"
        Code.bracedBlock {
            "const uintptr_t n = arrangement->number_of_instances;"
            "unsigned i;"
            "for (i = 1; i < n; i++)"
            Code.bracedBlock {
                "struct LLFSMachine * const machine = arrangement->machines[i];"
                "RESTART(machine);"
            }
        }
        ""
        "/// Restart all machines except for the given machine."
        "///"
        "/// This restarts all LLFSMs in the given arrangement,"
        "/// with the exception of machine specified."
        "///"
        "/// - Parameters:"
        "///   - arrangement: The machine arrangement to restart."
        "///   - machine: The machine to be excepted from restarting."
        "void fsm_arrangement_restart_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)"
        Code.bracedBlock {
            "const uintptr_t n = arrangement->number_of_instances;"
            "unsigned i;"
            "for (i = 1; i < n; i++)"
            Code.bracedBlock {
                "struct LLFSMachine * const m = arrangement->machines[i];"
                "if (m != machine) RESTART(machine);"
            }
        }
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
                "machine->state_time = GET_TIME();"
                if isSuspensible {
                    "if (current_state == machine->suspend_state)"
                    Code.bracedBlock {
                        "if (machine->previous_state && machine->previous_state->on_suspend) machine->previous_state->on_suspend(machine, machine->previous_state);"
                        "if (current_state->on_suspend) current_state->on_suspend(machine, current_state);"
                    }
                    "else if (machine->previous_state == machine->suspend_state)"
                    Code.bracedBlock {
                        "if (machine->previous_state && machine->previous_state->on_resume) machine->previous_state->on_resume(machine, machine->previous_state);"
                        "if (current_state->on_resume) current_state->on_resume(machine, current_state);"
                    }
                }
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
        let lowerName = name.lowercased()
        "uintptr_t num_runs = (uintptr_t)(argc > 1 ? strtoull(argv[1], NULL, 10) : ~0ULL);"
        ""
        "if (!arrangement_" + lowerName + "_validate(&static_arrangement_" + lowerName + "))"
        Code.bracedBlock {
            "printf(\"'static_arrangement_" + lowerName + "' does not validate!\\n\");"
            "return EXIT_FAILURE;"
        }
        ""
        "while (num_runs--)"
        Code.bracedBlock {
            "fsm_arrangement_execute_once((struct LLFSMArrangement *)&static_arrangement_" + lowerName + ");"
        }
        ""
        "return EXIT_SUCCESS;"
    } + "\n"
}

/// Create a CMake fragment for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func cArrangementCMakeFragment(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machines = Array(Set(instances.map(\.typeName)))
    return .block {
        "# Sources for the \(name) LLFSM arrangement."
        "set(\(name)_ARRANGEMENT_SOURCES"
        "    Arrangement_\(name).c"
        "    Machine_Common.c"
        ")"
        ""
        "# Static arrangement of machines for \(name)."
        "set(\(name)_STATIC_ARRANGEMENT_SOURCES"
        "    Static_Arrangement_\(name).c"
        ")"
        ""
        "# Include directories for building \(name)."
        "set(\(name)_ARRANGEMENT_INCDIRS"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
        Code.forEach(machines) { machine in
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/" + machine + ".machine/include>"
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/" + machine + ".machine>"
        }
        ")"
        ""
        "# Subdirectories for building \(name)."
        "set(\(name)_ARRANGEMENT_SUBDIRS"
        Code.forEach(machines) { machine in
            "    \"" + machine + ".machine\""
        }
        ")"
        ""
        "# Build directories for \(name)."
        "set(\(name)_ARRANGEMENT_BUILD_DIRS"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        Code.forEach(machines) { machine in
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/" + machine + ".machine>"
        }
        ")"
        ""
        "# Installed include directories for \(name)."
        "set(\(name)_ARRANGEMENT_INSTALL_INCDIRS"
        "  $<INSTALL_INTERFACE:include/fsms/\(name).arrangement> "
        "  $<INSTALL_INTERFACE:fsms/\(name).arrangement> "
        Code.forEach(machines) { machine in
            "  $<INSTALL_INTERFACE:include/fsms/\(name).arrangement/" + machine + ".machine>"
            "  $<INSTALL_INTERFACE:fsms/\(name).arrangement/" + machine + ".machine>"
        }
        ")"
        ""
        Code.forEach(machines) { machine in
            let directory = machine + MachineWrapper.dottedSuffix
            "include(${CMAKE_CURRENT_LIST_DIR}/" + directory + "/project.cmake)"
            "foreach(src ${\(machine)_FSM_SOURCES})"
            "  list(APPEND \(name)_ARRANGEMENT_FSMS \"\(machine)\")"
            "  list(APPEND \(name)_ARRANGEMENT_FSM_\(machine)_SOURCES \(directory)/${src})"
            "  list(APPEND \(name)_ARRANGEMENT_SOURCES \(directory)/${src})"
            "endforeach()"
        }
    }
}


/// Create CMakeLists for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func cArrangementCMakeLists(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machines = Array(Set(instances.map(\.typeName)))
    return .block {
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name) C)"
        ""
        "include(project.cmake)"
        ""
        "add_library(\(name)_arrangement STATIC ${\(name)_ARRANGEMENT_SOURCES})"
        "add_library(\(name)_static_arrangement STATIC ${\(name)_STATIC_ARRANGEMENT_SOURCES})"
        ""
        "target_include_directories(\(name)_arrangement PRIVATE "
        "  ${\(name)_ARRANGEMENT_INCDIRS}"
        "  ${\(name)_ARRANGEMENT_INSTALL_INCDIRS}"
        ")"
        "target_include_directories(\(name)_static_arrangement PRIVATE"
        "  ${\(name)_ARRANGEMENT_INCDIRS}"
        "  ${\(name)_ARRANGEMENT_INSTALL_INCDIRS}"
        ")"
        ""
        "add_executable(run_\(name)_arrangement static_main.c)"
        ""
        "target_include_directories(run_\(name)_arrangement PRIVATE"
        "  ${\(name)_ARRANGEMENT_INCDIRS}"
        "  ${\(name)_ARRANGEMENT_INSTALL_INCDIRS}"
        ")"
        Code.forEach(Array(Set(instances.map(\.typeName)))) { machine in
            "add_subdirectory(" + machine + ".machine)"
        }
        "target_link_libraries(run_\(name)_arrangement"
        "    \(name)_static_arrangement"
        "    \(name)_arrangement"
        Code.enumerating(array: machines) { i, machine in
            "    \(machine)_fsm"
        }
        ")"
        ""
    }
}
