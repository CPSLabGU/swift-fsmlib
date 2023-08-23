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
            "union"
            Code.bracedBlock {
                "struct LLFSMachine *machines[\(instances.count)];"
                "struct"
                Code.bracedBlock {
                    Code.forEach(instances) { instance in
                        "struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) *fsm_\(instance.name.lowercased());"
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
    #include \"Arrangement_\(name).h\"
    #include \"Machine_Common.h\"

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
            Code.forEach(instances) { instance in
                "fsm_" + name + "_init(arrangement->fsm_" + instance.name.lowercased() + ");"
            }
        }
        ""
        "/// Run a ringlet of a C-language LLFSM Arrangement."
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
        "#include <stdbool.h>"
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
            "/// Static instantiation of a \(instance.url.deletingPathExtension().lastPathComponent) LLFSM."
            "extern struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) static_fsm_\(instance.name.lowercased());"
        }
        "/// Static instantiation of the \(name) LLFSM Arrangement."
        "extern struct Arrangement_" + name + " static_arrangement_" + name.lowercased() + ");"
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
    let upperName = name.uppercased()
    return """
    //
    // Static_Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Static_Arrangement_\(name).h\"

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored \"-Wunused-macros\"

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        "#include <stdbool.h>"
        ""
        Code.forEach(instances) { instance in
            "/// Static instantiation of a \(instance.url.deletingPathExtension().lastPathComponent) LLFSM."
            "extern struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) static_fsm_\(instance.name.lowercased());"
        }
        "/// Static instantiation of the \(name) LLFSM Arrangement."
        "extern struct Arrangement_" + name + " static_arrangement_" + name.lowercased() + ");"
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
        "set(\(name)_ARRANGEMENT_MACHINES"
        "    Arrangement_\(name).c"
        "    Machine_Common.c"
        ")"
        ""
        "add_library(\(name)_arrangement STATIC ${\(name)_ARRANGEMENT_SOURCES})"
        ""
        Code.forEach(Array(Set(instances.map(\.url.lastPathComponent)))) { directory in
            "add_subdirectory(" + directory + ")"
        }
        ""
        "add_executable(run_\(name)_arrangement main.c)"
        "target_link_libraries(run_\(name)_arrangement"
        "    \(name)_arrangement"
        Code.enumerating(array: instances) { i, instance in
            "    \(instance.name)_fsm"
        }
        ")"
        ""
    }
}

