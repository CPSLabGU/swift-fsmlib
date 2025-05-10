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
                #include \"\(name)_Variables.h\"
                #include \"\(name)_Methods.h\"
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
    let transitionCount = llfsm.transitionsFrom(state.id).count
    let className = state.name
    var transitions = ""
    for i in 0..<transitionCount {
        transitions += "                    class Transition_\(i): public CLTransition\n                    {\n                    public:\n                        Transition_\(i)(int toState = 0): CLTransition(toState) {}\n\n                        virtual bool check(CLMachine *, CLState *) const;\n                    };\n"
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
                    CLTransition *_transitions[\(transitionCount)];

                    public:
                        \(className)(const char *name = "\(className)");
                        virtual ~\(className)();

                        virtual CLTransition * const *transitions() const { return _transitions; }
                        virtual int numberOfTransitions() const { return \(transitionCount); }

                        #include "State_\(className)_Variables.h"
                        #include "State_\(className)_Methods.h"
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
        transitionChecks += "bool \(className)::Transition_\(i)::check(CLMachine *_machine, CLState *_state) const\n{\n#\tinclude \"\(name)_VarRefs.mm\"\n#\tinclude \"State_\(className)_VarRefs.mm\"\n#\tinclude \"\(name)_FuncRefs.mm\"\n#\tinclude \"State_\(className)_FuncRefs.mm\"\n\n\treturn\n\t(\n#\t\tinclude \"State_\(className)_Transition_\(i).expr\"\n\t);\n}\n\n"
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
        "include(project.cmake)"
        ""
        "add_library(\(name)_fsm STATIC ${\(name)_FSM_SOURCES})"
        "target_include_directories(\(name)_fsm PRIVATE"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
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
    return .block {
        "# Sources for the \(name) Objective-C++ FSM arrangement."
        "set(\(name)_ARRANGEMENT_SOURCES"
        "    Arrangement_\(name).mm"
        Code.forEach(instances) { instance in
            "    \(instance.typeName).machine/\(instance.typeName).mm"
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
    .block {
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
        "include(project.cmake)"
        ""
        "add_executable(\(name)_arrangement ${\(name)_ARRANGEMENT_SOURCES})"
        "target_include_directories(\(name)_arrangement PRIVATE"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
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
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    var includes = ""
    for machine in machineTypes {
        includes += "#include \"\(machine).machine/\(machine).h\"\n"
    }
    var externs = ""
    for instance in instances {
        externs += "extern struct \(instance.typeName) static_fsm_\(instance.name.lowercased());\n"
    }
    return """
//
// Static_Arrangement_\(name).h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_static_arrangement_\(name)_h
#define clfsm_static_arrangement_\(name)_h

#include "Arrangement_\(name).h"
\(includes)
#define STATIC_ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)
#ifndef SUSPEND_ALL
#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct CLFSMArrangement *)&static_arrangement_\(name.lowercased()))
#endif // SUSPEND_ALL
#ifndef RESUME_ALL
#define RESUME_ALL() fsm_arrangement_resume_all((struct CLFSMArrangement *)&static_arrangement_\(name.lowercased()))
#endif // RESUME_ALL
#ifndef RESTART_ALL
#define RESTART_ALL() fsm_arrangement_restart_all((struct CLFSMArrangement *)&static_arrangement_\(name.lowercased()))
#endif // RESTART_ALL

struct CLMachine;
struct CLFSMArrangement;
\(externs)
extern struct Arrangement_\(name) static_arrangement_\(name.lowercased());

#endif
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
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    var includes = "#include <stdbool.h>\n#include \"Arrangement_\(name).h\"\n"
    for machine in machineTypes {
        includes += "#include \"\(machine).machine/\(machine).h\"\n"
    }
    var staticDecls = ""
    for instance in instances {
        staticDecls += "struct \(instance.typeName) static_fsm_\(instance.name.lowercased()) = {0};\n"
    }
    return """
//
// Static_Arrangement_\(name).c
//
// Automatically created through MiCASE -- do not change manually!
//
\(includes)
\(staticDecls)
struct Arrangement_\(name) static_arrangement_\(name.lowercased()) = {0};
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
    return """
//
// static_main.c
//
// Automatically created through MiCASE -- do not change manually!
//
#include <stdio.h>
#include "Static_Arrangement_\(name).h"

int main(void)
{
    arrangement_\(name.lowercased())_init(&static_arrangement_\(name.lowercased()));
    arrangement_\(name.lowercased())_validate(&static_arrangement_\(name.lowercased()));
    printf("Static arrangement \"%s\" initialised and validated.\n", "\(name)");
    return 0;
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
    return .block {
        "# Sources for the \(name) Objective-C++ static arrangement."
        "set(\(name)_STATIC_ARRANGEMENT_SOURCES"
        "    Static_Arrangement_\(name).c"
        "    static_main.c"
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
    .block {
        "cmake_minimum_required(VERSION 3.21)"
        ""
        "project(\(name)_static_arrangement C)"
        ""
        "set(CMAKE_C_STANDARD 17)"
        "set(CMAKE_C_STANDARD_REQUIRED ON)"
        "set(CMAKE_C_EXTENSIONS ON)"
        ""
        "# Set the default build type to Debug."
        "if(NOT CMAKE_BUILD_TYPE)"
        "   set(CMAKE_BUILD_TYPE Debug)"
        "endif()"
        ""
        "include(project.cmake)"
        ""
        "add_executable(\(name)_static_arrangement ${\(name)_STATIC_ARRANGEMENT_SOURCES})"
        "target_include_directories(\(name)_static_arrangement PRIVATE"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>"
        "  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>"
        ")"
        ""
    }
}
