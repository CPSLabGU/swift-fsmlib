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
