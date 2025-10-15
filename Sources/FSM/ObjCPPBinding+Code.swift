//
//  ObjCPPBinding+Code.swift
//
//  Created by Rene Hexel on 10/05/2025.
//  Copyright © 2012-2019, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Create the Objective-C++ header for a machine.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the machine.
/// - Returns: The generated Objective-C++ header code.
public func objcppMachineHeader(for llfsm: LLFSM, named name: String) -> Code {
    let stateCount = llfsm.states.count
    return """
    //
    // \(name).h
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #ifndef clfsm_machine_\(name)_
    #define clfsm_machine_\(name)_

    #include \"CLMachine.h\"

    namespace FSM
    {
        class CLState;

        namespace CLM
        {
            class \(name): public CLMachine
            {
                CLState *_states[\(stateCount)];
            public:
                \(name)(int mid = 0, const char *name = \"\(name)\");
                virtual ~\(name)();
                virtual CLState * const * states() const { return _states; }
                virtual int numberOfStates() const { return \(stateCount); }
    #           include \"\(name)_Variables.h\"
    #           include \"\(name)_Methods.h\"
            };
        }
    }

    extern \"C\"
    {
        FSM::CLM::\(name) *CLM_Create_\(name)(int mid, const char *name);
    }

    #endif // defined(clfsm_machine_\(name)_)
    """
}

/// Create the Objective-C++ implementation for a machine.
///
/// - Parameters:
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the machine.
/// - Returns: The generated Objective-C++ implementation code.
public func objcppMachineImplementation(for llfsm: LLFSM, named name: String) -> Code {
    let stateNames = llfsm.states.compactMap { llfsm.stateMap[$0]?.name }
    let suspendStateIndex = llfsm.suspendState.flatMap { llfsm.states.firstIndex(of: $0) }
    var includes = ""
    for stateName in stateNames {
        includes += "#include \"State_\(stateName).h\"\n"
    }
    var stateInits = ""
    for (i, stateName) in stateNames.enumerated() {
        stateInits += "\t_states[\(i)] = new FSM\(name)::State::\(stateName);\n"
    }
    var stateDeletes = ""
    for i in 0..<stateNames.count {
        stateDeletes += "\tdelete _states[\(i)];\n"
    }
    // swiftlint:disable:next force_unwrapping
    let suspendLine = suspendStateIndex != nil ? "\n\tsetSuspendState(_states[\(suspendStateIndex!)]);            // set suspend state" : ""
    return """
    //
    // \(name).mm
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #include \"\(name)_Includes.h\"
    #include \"\(name).h\"
    \(includes)
    using namespace FSM;
    using namespace CLM;

    extern \"C\"
    {
    \t\(name) *CLM_Create_\(name)(int mid, const char *name)
    \t{
    \t\treturn new \(name)(mid, name);
    \t}
    }

    \(name)::\(name)(int mid, const char *name): CLMachine(mid, name)
    {
    \(stateInits)\(suspendLine)
    \tsetInitialState(_states[0]);            // set initial state
    }

    \(name)::~\(name)()
    {
    \(stateDeletes)}
    """
}

/// Create the Objective-C++ header for a state.
///
/// - Parameters:
///   - state: The state to create code for.
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the machine.
/// - Returns: The generated Objective-C++ state header code.
public func objcppStateHeader(for state: State, llfsm: LLFSM, named name: String) -> Code {
    let stateTransitionIDs = llfsm.transitionsFrom(state.id)
    let transitionCount = stateTransitionIDs.count
    let className = state.name
    var transitions = ""
    for (i, transitionID) in stateTransitionIDs.enumerated() {
        // Get the target state ID and find the index in the states array
        if let targetStateID = llfsm.targetState(for: transitionID),
           let targetStateIndex = llfsm.states.firstIndex(of: targetStateID) {
            transitions +=
                "                class Transition_\(i): public CLTransition\n" +
                "                {\n" +
                "                public:\n" +
                "                    Transition_\(i)(int toState = \(targetStateIndex)): CLTransition(toState) {}\n" +
                "\n" +
                "                    virtual bool check(CLMachine *, CLState *) const;\n" +
                "                };\n" +
                "\n"
        } else {
            // Fallback to 0 if we can't find the target state
            transitions +=
                "                class Transition_\(i): public CLTransition\n" +
                "                {\n" +
                "                public:\n" +
                "                    Transition_\(i)(int toState = 0): CLTransition(toState) {}\n" +
                "\n" +
                "                    virtual bool check(CLMachine *, CLState *) const;\n" +
                "                };\n" +
                "\n"
        }
    }
    return """
    //
    // State_\(className).h
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #ifndef clfsm_\(name)_State_\(className)_h
    #define clfsm_\(name)_State_\(className)_h

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc++98-compat"

    #include \"CLState.h\"
    #include \"CLAction.h\"
    #include \"CLTransition.h\"

    namespace FSM
    {
        namespace CLM
        {
          namespace FSM\(name)
          {
            namespace State
            {
                class \(className): public CLState
                {
                    class OnEntry: public CLAction
                    {
                        virtual void perform(CLMachine *, CLState *) const;
                    };

                    class OnExit: public CLAction
                    {
                        virtual void perform(CLMachine *, CLState *) const;
                    };

                    class Internal: public CLAction
                    {
                        virtual void perform(CLMachine *, CLState *) const;
                    };

                    class OnSuspend: public CLAction
                    {
                        virtual void perform(CLMachine *, CLState *) const;
                    };

                    class OnResume: public CLAction
                    {
                        virtual void perform(CLMachine *, CLState *) const;
                    };

    \(transitions)
                    CLTransition *_transitions[\(transitionCount)];

                    public:
                        \(className)(const char *name = "\(className)");
                        virtual ~\(className)();

                        virtual CLTransition * const *transitions() const { return _transitions; }
                        virtual int numberOfTransitions() const { return \(transitionCount); }

    #                   include "State_\(className)_Variables.h"
    #                   include "State_\(className)_Methods.h"
                };
            }
          }
        }
    }

    #endif
    """
}

/// Create the Objective-C++ implementation for a state.
///
/// - Parameters:
///   - state: The state to create code for.
///   - llfsm: The finite-state machine to create code for.
///   - name: The name of the machine.
/// - Returns: The generated Objective-C++ state implementation code.
public func objcppStateImplementation(for state: State, llfsm: LLFSM, named name: String) -> Code {
    let className = state.name
    let transitionCount = llfsm.transitionsFrom(state.id).count
    let transitionTargets = llfsm.transitionsFrom(state.id).compactMap { llfsm.transitionMap[$0]?.target }.compactMap { llfsm.states.firstIndex(of: $0) }
    func transitionTargetIndex(_ i: Int) -> Int { transitionTargets.indices.contains(i) ? transitionTargets[i] : 0 }
    var transitionInits = ""
    for i in 0..<transitionCount {
        transitionInits += "\t_transitions[\(i)] = new Transition_\(i)(\(transitionTargetIndex(i)));"
    }
    var transitionDeletes = ""
    for i in 0..<transitionCount {
        transitionDeletes += "\tdelete _transitions[\(i)];\n"
    }
    var actionSections = ""
    for section in ["OnEntry", "OnExit", "Internal", "OnSuspend", "OnResume"] {
        actionSections += "void \(className)::\(section)::perform(CLMachine *_machine, CLState *_state) const\n{\n#\tinclude \"\(name)_VarRefs.mm\"\n#\tinclude \"State_\(className)_VarRefs.mm\"\n#\tinclude \"\(name)_FuncRefs.mm\"\n#\tinclude \"State_\(className)_FuncRefs.mm\"\n#\tinclude \"State_\(className)_\(section).mm\"\n}\n\n"
    }
    var transitionChecks = ""
    for i in 0..<transitionCount {
        transitionChecks +=
            "bool \(className)::Transition_\(i)::check(CLMachine *_machine, CLState *_state) const\n" +
            "{\n#\tinclude \"\(name)_VarRefs.mm\"\n" +
            "#\tinclude \"State_\(className)_VarRefs.mm\"\n" +
            "#\tinclude \"\(name)_FuncRefs.mm\"\n" +
            "#\tinclude \"State_\(className)_FuncRefs.mm\"\n\n" +
            "\treturn\n\t(\n#\t\tinclude \"State_\(className)_Transition_\(i).expr\"\n\t);\n}\n\n"
    }
    return """
    //
    // State_\(className).mm
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #include \"\(name)_Includes.h\"
    #include \"\(name).h\"
    #include \"State_\(className).h\"

    #include \"State_\(className)_Includes.h\"

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc++98-compat"

    using namespace FSM;
    using namespace CLM;
    using namespace FSM\(name);
    using namespace State;

    \(className)::\(className)(const char *name): CLState(name, *new \(className)::OnEntry, *new \(className)::OnExit, *new \(className)::Internal, NULLPTR, new \(className)::OnSuspend, new \(className)::OnResume)
    {
    \(transitionInits)    }

    \(className)::~\(className)()
    {
    \tdelete &onEntryAction();
    \tdelete &onExitAction();
    \tdelete &internalAction();
    \tdelete onSuspendAction();
    \tdelete onResumeAction();

    \(transitionDeletes)    }

    \(actionSections)\(transitionChecks)
    """
}

/// Create CMakeList fragment for an Objective-C++ FSM.
///
/// - Parameters:
///   - fsm: The FSM to create the cmake fragment for.
///   - name: The name of the Machine
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code fragment.
public func objcppCMakeFragment(for fsm: LLFSM, named name: String, isSuspensible: Bool) -> Code {
    return .block {
        "# Sources for the \(name) Objective-C++ FSM."
        "set(\(name)_FSM_SOURCES"
        "    \(name).mm"
        Code.enumerating(array: fsm.states) { i, stateID in
            if let state = fsm.stateMap[stateID] {
                "    State_\(state.name).mm"
            } else {
                "// Warning: ignoring orphaned state \(i) (\(stateID))"
            }
        }
        ")"
        ""
    }
}

/// Create CMakeLists for an Objective-C++ FSM.
///
/// - Parameters:
///   - fsm: The FSM to create the CMakeLists.txt for.
///   - name: The name of the Machine
///   - boilerplate: The boilerplate containing the include paths.
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func objcppCMakeLists(for fsm: LLFSM, named name: String, boilerplate: any Boilerplate, isSuspensible: Bool) -> Code {
    .block {
        let includePaths = boilerplate.getSection(named: CBoilerplate.SectionName.includePath.rawValue).split(separator: "\n")
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name) CXX)"
        ""
        "# Require the C++ standard to be C++17,"
        "# but allow extensions."
        "set(CMAKE_CXX_STANDARD 17)"
        "set(CMAKE_CXX_STANDARD_REQUIRED ON)"
        "set(CMAKE_CXX_EXTENSIONS ON)"
        ""
        "# Set the default build type to Debug."
        "if(NOT CMAKE_BUILD_TYPE)"
        "   set(CMAKE_BUILD_TYPE Debug)"
        "endif()"
        ""
        if isSuspensible {
            "# Define FSM_SUPPORT_SUSPEND for suspensible machines"
            "add_definitions(-DFSM_SUPPORT_SUSPEND)"
            ""
        }
        "include(project.cmake)"
        ""
        "add_library(\(name)_fsm STATIC ${\(name)_FSM_SOURCES})"
        "target_include_directories(\(name)_fsm PRIVATE"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/infrastructure>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
        "  $<INSTALL_INTERFACE:include/fsms/\(name).machine>"
        "  $<INSTALL_INTERFACE:fsms/\(name).machine>"
        Code.forEach(includePaths) { path in
            "  \(path)"
        }
        ")"
        ""
    }
}

/// Create CMakeList fragment for an Objective-C++ FSM arrangement.
///
/// - Parameters:
///   - instances: The FSM instances.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code fragment.
public func objcppArrangementCMakeFragment(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machines = Array(Set(instances.map(\.typeName)))
    return .block {
        "# Sources for the \(name) Objective-C++ FSM arrangement."
        "set(\(name)_ARRANGEMENT_SOURCES"
        "    Arrangement_\(name).mm"
        "    Static_Arrangement_\(name).mm"
        ")"
        ""
        "# Infrastructure sources for the FSM C++ runtime."
        "set(INFRASTRUCTURE_SOURCES"
        "    infrastructure/StateMachineVector.cc"
        if isSuspensible {
            "    infrastructure/SuspensibleMachine.cc"
        }
        ")"
        ""
        "# Include directories for building \(name)."
        "set(\(name)_ARRANGEMENT_INCDIRS"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/infrastructure>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
        Code.forEach(machines) { machine in
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/\(machine).machine/include>"
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/\(machine).machine>"
        }
        ")"
        ""
    }
}

/// Create CMakeLists for an Objective-C++ FSM arrangement.
///
/// - Parameters:
///   - instances: The FSM instances.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func objcppArrangementCMakeLists(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machines = Array(Set(instances.map(\.typeName)))
    return .block {
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name)_arrangement CXX)"
        ""
        "set(CMAKE_CXX_STANDARD 17)"
        "set(CMAKE_CXX_STANDARD_REQUIRED ON)"
        "set(CMAKE_CXX_EXTENSIONS ON)"
        ""
        "# Set the default build type to Debug."
        "if(NOT CMAKE_BUILD_TYPE)"
        "   set(CMAKE_BUILD_TYPE Debug)"
        "endif()"
        ""
        if isSuspensible {
            "# Define FSM_SUPPORT_SUSPEND for suspensible machines"
            "add_definitions(-DFSM_SUPPORT_SUSPEND)"
            ""
        }
        "include(project.cmake)"
        ""
        Code.forEach(machines) { machine in
            "add_subdirectory(\(machine).machine)"
        }
        "add_executable(run_\(name)_arrangement static_main.cc ${\(name)_ARRANGEMENT_SOURCES} ${INFRASTRUCTURE_SOURCES})"
        "target_include_directories(run_\(name)_arrangement PRIVATE"
        "  ${\(name)_ARRANGEMENT_INCDIRS}"
        ")"
        "target_link_libraries(run_\(name)_arrangement"
        Code.forEach(machines) { machine in
            "    \(machine)_fsm"
        }
        ")"
        ""
    }
}

/// Create the Objective-C++ static arrangement interface.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The static arrangement interface code.
public func objcppStaticArrangementInterface(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    let machineIncludes = machineTypes.map { machine in
        "#include \"\(machine).machine/\(machine).h\""
    }.joined(separator: "\n")
    return """
    //
    // Static_Arrangement.h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #ifndef clfsm_static_arrangement_\(lowerName)_h
    #define clfsm_static_arrangement_\(lowerName)_h

    \(isSuspensible ? "#ifndef FSM_SUPPORT_SUSPEND\n#define FSM_SUPPORT_SUSPEND\n#endif\n" : "")
    #include "Arrangement_\(name).h"
    \(machineIncludes)


    #define STATIC_ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)

    #ifdef __cplusplus
    extern "C" {
    #endif

    /// Get a pointer to the static \(name) arrangement.
    struct Arrangement_\(name) *static_arrangement_\(lowerName)(void);

    #ifdef __cplusplus
    }

    namespace FSM {
        /// Get the StateMachineVector for the static \(name) arrangement.
        StateMachineVector *static_arrangement_\(lowerName)_vector(void);
    }
    #endif

    #endif // clfsm_static_arrangement_\(lowerName)_h
    """
}

/// Create the Objective-C++ static arrangement code.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The static arrangement code.
public func objcppStaticArrangementCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let lowerName = name.lowercased()
    let upperName = name.uppercased()
    let machines = Dictionary(instances.map { ($0.typeName, $0) }, uniquingKeysWith: { a,_ in a })

    return """
    //
    // Static_Arrangement_\(name).mm
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include <cstddef>
    #include "Static_Arrangement.h"
    #include "StateMachineVector.h"
    """ + "\n" + machines.keys.sorted().map { machine in
        "#include \"\(machine).machine/\(machine).h\""
    }.joined(separator: "\n") + """



    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-macros"

    #ifndef NULL
    #define NULL nullptr
    #endif

    using namespace FSM::CLM;

    """ + Code.enumerating(array: instances) { i, instance in
        let machineName = instance.typeName
        let varName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()

        "/// Static instantiation of a \(machineName) CLFSM."
        "static \(machineName) \(varName)(\(i), \"\(instance.name)\");"
    } + """

    /// Static instantiation of the \(name) CLFSM Arrangement.
    static Arrangement_\(name) static_arrangement = {
        .number_of_instances = STATIC_ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES,
        {
    """ + Code.enumerating(array: instances) { i, instance in
        let varName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        "        .\(varName) = &\(varName)\(i < instances.count - 1 ? "," : "")"
    } + """
        }
    };

    /// Static machine vector for the arrangement.
    static FSM::CLMachine *machine_vector[\(instances.count)] = {
    """ + Code.enumerating(array: instances) { i, instance in
        let varName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        "    &\(varName)\(i < instances.count - 1 ? "," : "")"
    } + """
    };

    /// Static StateMachineVector for the arrangement.
    static FSM::StateMachineVector static_vector(machine_vector, \(instances.count));

    extern "C" {
        /// Get a pointer to the static \(name) arrangement.
        struct Arrangement_\(name) *static_arrangement_\(lowerName)(void)
        {
            return &static_arrangement;
        }
    }

    namespace FSM {
        /// Get the StateMachineVector for the static \(name) arrangement.
        StateMachineVector *static_arrangement_\(lowerName)_vector(void)
        {
            set_global_machine_vector(&static_vector);
            return &static_vector;
        }
    }

    #pragma clang diagnostic pop
    """
}

/// Create the Objective-C++ static arrangement main code.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The static arrangement main code.
public func objcppStaticArrangementMainCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let lowerName = name.lowercased()
    return """
//
// static_main.cc
//
// Automatically created using fsmconvert -- do not change manually!
//
#include <cstdio>
#include <cstdlib>
#include "Static_Arrangement.h"
#include "StateMachineVector.h"

/// Main function to run the static \(name) arrangement.
///
/// - Parameter argc: The number of command line arguments.
/// - Parameter argv: The command line arguments. If argc > 1, argv[1] is the number of runs.
/// - Returns: EXIT_SUCCESS if the arrangement validates and runs successfully, EXIT_FAILURE otherwise.
int main(int argc, char *argv[])
{
    unsigned long num_runs = argc > 1 ? strtoull(argv[1], nullptr, 10) : ~0UL;

    struct Arrangement_\(name) *arrangement = static_arrangement_\(lowerName)();
    if (!arrangement_\(lowerName)_validate(arrangement)) {
        printf("Error: 'static_arrangement_\(lowerName)' does not validate!\\n");
        return EXIT_FAILURE;
    }

    FSM::StateMachineVector *vector = FSM::static_arrangement_\(lowerName)_vector();

    while (num_runs--) {
        vector->executeOnce();
    }

    return EXIT_SUCCESS;
}
"""
}

/// Create CMakeList fragment for an Objective-C++ static arrangement.
///
/// - Parameters:
///   - instances: The FSM instances.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code fragment.
public func objcppStaticArrangementCMakeFragment(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    return .block {
        "# Sources for the \(name) Objective-C++ static arrangement."
        "set(\(name)_STATIC_ARRANGEMENT_SOURCES"
        "    Static_Arrangement_\(name).mm"
        "    static_main.cc"
        ")"
        ""
        "# Infrastructure sources for the FSM C++ runtime."
        "set(INFRASTRUCTURE_SOURCES"
        "    infrastructure/StateMachineVector.cc"
        if isSuspensible {
            "    infrastructure/SuspensibleMachine.cc"
        }
        ")"
        ""
        "# Include directories for building \(name)."
        "set(\(name)_STATIC_ARRANGEMENT_INCDIRS"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/infrastructure>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
        Code.forEach(machineTypes) { machine in
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/\(machine).machine/include>"
            "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/\(machine).machine>"
        }
        ")"
        ""
    }
}

/// Create CMakeLists for an Objective-C++ static arrangement.
///
/// - Parameters:
///   - instances: The FSM instances.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The CMakeLists.txt code.
public func objcppStaticArrangementCMakeLists(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    return .block {
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name)_static_arrangement CXX)"
        ""
        "# Require the C++ standard to be C++17,"
        "# but allow extensions."
        "set(CMAKE_CXX_STANDARD 17)"
        "set(CMAKE_CXX_STANDARD_REQUIRED ON)"
        "set(CMAKE_CXX_EXTENSIONS ON)"
        ""
        "# Set the default build type to Debug."
        "if(NOT CMAKE_BUILD_TYPE)"
        "   set(CMAKE_BUILD_TYPE Debug)"
        "endif()"
        ""
        if isSuspensible {
            "# Define FSM_SUPPORT_SUSPEND for suspensible machines"
            "add_definitions(-DFSM_SUPPORT_SUSPEND)"
            ""
        }
        "include(project.cmake)"
        ""
        "# Build machine type libraries"
        Code.forEach(machineTypes) { machine in
            "add_subdirectory(\(machine).machine)"
        }
        ""
        "# Build static arrangement executable"
        "add_executable(run_\(name)_arrangement ${\(name)_STATIC_ARRANGEMENT_SOURCES} ${INFRASTRUCTURE_SOURCES})"
        "target_include_directories(run_\(name)_arrangement PRIVATE"
        "  ${\(name)_STATIC_ARRANGEMENT_INCDIRS}"
        ")"
        "target_link_libraries(run_\(name)_arrangement"
        Code.forEach(machineTypes) { machine in
            "    \(machine)_fsm"
        }
        ")"
        ""
    }
}
