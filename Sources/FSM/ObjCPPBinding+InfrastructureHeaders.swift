//
//  ObjCPPBinding+InfrastructureHeaders.swift
//
//  Created by Rene Hexel on 14/10/2025.
//  Copyright © 2012, 2013, 2014, 2015, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Generate infrastructure header files for Objective-C++ FSM arrangements.
///
/// These functions generate the C++ infrastructure headers and implementation files
/// required for executing FSM arrangements, including the base machine, state, action,
/// and transition classes, as well as the StateMachineVector executor.

/// Standard copyright header for infrastructure files.
private let copyrightHeader: (String, String) -> String = { filename, project in
    """
    /*
     *  \(filename)
     *  \(project)
     *
     *  Created by Rene Hexel on 24/08/2014.
     *  Copyright (c) 2012, 2014, 2015, 2025 Rene Hexel. All rights reserved.
     *
     * Redistribution and use in source and binary forms, with or without
     * modification, are permitted provided that the following conditions
     * are met:
     *
     * 1. Redistributions of source code must retain the above copyright
     *    notice, this list of conditions and the following disclaimer.
     *
     * 2. Redistributions in binary form must reproduce the above
     *    copyright notice, this list of conditions and the following
     *    disclaimer in the documentation and/or other materials
     *    provided with the distribution.
     *
     * 3. All advertising materials mentioning features or use of this
     *    software must display the following acknowledgement:
     *
     *        This product includes software developed by Rene Hexel.
     *
     * 4. Neither the name of the author nor the names of contributors
     *    may be used to endorse or promote products derived from this
     *    software without specific prior written permission.
     *
     * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
     * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
     * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
     * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
     * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
     * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
     * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
     * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
     * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
     * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
     * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
     *
     * -----------------------------------------------------------------------
     * This program is free software; you can redistribute it and/or
     * modify it under the above terms or under the terms of the GNU
     * General Public License as published by the Free Software Foundation;
     * either version 2 of the License, or (at your option) any later version.
     *
     * This program is distributed in the hope that it will be useful,
     * but WITHOUT ANY WARRANTY; without even the implied warranty of
     * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     * GNU General Public License for more details.
     *
     * You should have received a copy of the GNU General Public License
     * along with this program; if not, see http://www.gnu.org/licenses/
     * or write to the Free Software Foundation, Inc., 51 Franklin Street,
     * Fifth Floor, Boston, MA  02110-1301, USA.
     *
     */
    """
}

/// Generate the CLAction.h infrastructure header.
///
/// - Returns: The CLAction.h header code.
public func objcppInfrastructureCLActionHeader() -> Code {
    """
    /*
     *  CLAction.h
     *  clfsm infrastructure
     *
     *  Created by Rene Hexel on 24/08/2014.
     *  Copyright (c) 2012, 2014, 2015, 2025 Rene Hexel. All rights reserved.
     *
     * Redistribution and use in source and binary forms, with or without
     * modification, are permitted provided that the following conditions
     * are met:
     *
     * 1. Redistributions of source code must retain the above copyright
     *    notice, this list of conditions and the following disclaimer.
     *
     * 2. Redistributions in binary form must reproduce the above
     *    copyright notice, this list of conditions and the following
     *    disclaimer in the documentation and/or other materials
     *    provided with the distribution.
     *
     * 3. All advertising materials mentioning features or use of this
     *    software must display the following acknowledgement:
     *
     *        This product includes software developed by Rene Hexel.
     *
     * 4. Neither the name of the author nor the names of contributors
     *    may be used to endorse or promote products derived from this
     *    software without specific prior written permission.
     *
     * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
     * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
     * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
     * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
     * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
     * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
     * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
     * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
     * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
     * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
     * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
     *
     * -----------------------------------------------------------------------
     * This program is free software; you can redistribute it and/or
     * modify it under the above terms or under the terms of the GNU
     * General Public License as published by the Free Software Foundation;
     * either version 2 of the License, or (at your option) any later version.
     *
     * This program is distributed in the hope that it will be useful,
     * but WITHOUT ANY WARRANTY; without even the implied warranty of
     * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     * GNU General Public License for more details.
     *
     * You should have received a copy of the GNU General Public License
     * along with this program; if not, see http://www.gnu.org/licenses/
     * or write to the Free Software Foundation, Inc., 51 Franklin Street,
     * Fifth Floor, Boston, MA  02110-1301, USA.
     *
     */
    #ifndef clfsm_infrastructure_CLAction_h
    #define clfsm_infrastructure_CLAction_h

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wweak-vtables"

    namespace FSM
    {
        class CLMachine;
        class CLState;

        class CLAction
        {
        public:
            virtual ~CLAction() {}
            virtual void perform(CLMachine *, CLState *) const {}
        };
    }

    #pragma clang diagnostic pop

    #endif
    """
}

/// Generate the CLTransition.h infrastructure header.
///
/// - Returns: The CLTransition.h header code.
public func objcppInfrastructureCLTransitionHeader() -> Code {
    """
    \(copyrightHeader("CLTransition.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_CLTransition_h
    #define clfsm_infrastructure_CLTransition_h

    #ifdef bool
    #undef bool
    #endif

    #ifdef true
    #undef true
    #undef false
    #endif

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wweak-vtables"
    #pragma clang diagnostic ignored "-Wpadded"

    namespace FSM
    {
        class CLMachine;
        class CLState;

        /** class representing a transition in a clang FSM */
        class CLTransition
        {
            int _destinationState;  /// destination state for this transition
        public:
            /** default constructor */
            CLTransition(int to = -1): _destinationState(to) {}

            /** default destructor */
            virtual ~CLTransition() {}

            /** destination state getter */
            int destinationState() const { return _destinationState; }

            /** destination state setter */
            void setDestinationState(int to) { _destinationState = to; }

            /** check if the transition should fire */
            virtual bool check(CLMachine *, CLState *) const { return true; }
        };
    }

    #pragma clang diagnostic pop

    #endif
    """
}

/// Generate the CLState.h infrastructure header.
///
/// - Returns: The CLState.h header code.
public func objcppInfrastructureCLStateHeader() -> Code {
    """
    \(copyrightHeader("CLState.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_CLState_h
    #define clfsm_infrastructure_CLState_h

    #include "CLAction.h"

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wweak-vtables"

    namespace FSM
    {
        class CLMachine;
        class CLTransition;

        class CLState
        {
            const char      *_name;                 /// name fo the state
            CLAction        &_onEntryAction;        /// onEntry
            CLAction        &_onExitAction;         /// onExit
            CLAction        &_internalAction;       /// internal
            CLAction        *_onSuspendAction;      /// onSuspend (optional)
            CLAction        *_onResumeAction;       /// onResume (optional)
        public:
            /** default constructor */
            CLState(const char *name, CLAction &onEntry, CLAction &onExit, CLAction &internal, void *context = NULLPTR, CLAction *onSuspend = NULLPTR, CLAction *onResume = NULLPTR): _name(name), _onEntryAction(onEntry), _onExitAction(onExit), _internalAction(internal), _onSuspendAction(onSuspend), _onResumeAction(onResume) {}

            /** destructor (subclass responsibility!) */
            virtual ~CLState() {}

            /** name getter */
            const char *name() const { return _name; }

            /** name setter */
            void setName(const char *name) { _name = name; }

            /** onEntry action getter */
            CLAction &onEntryAction() const { return _onEntryAction; }

            /** onExit action getter */
            CLAction &onExitAction()  const { return _onExitAction; }

            /** internal action getter */
            CLAction &internalAction()const { return _internalAction; }

            /** onSuspend action getter (NULLPTR if not set) */
            CLAction *onSuspendAction() const { return _onSuspendAction; }

            /** onResume action getter (NULLPTR if not set) */
            CLAction *onResumeAction() const { return _onResumeAction; }

            /** perform the onEntry action */
            void performOnEntry(CLMachine *m) { _onEntryAction.perform(m, this); }

            /** perform the onExit action */
            void performOnExit(CLMachine *m)  { _onExitAction.perform(m, this); }

            /** perform the internal action */
            void performInternal(CLMachine *m){ _internalAction.perform(m, this); }

            /** perform the onSuspend action */
            void performOnSuspend(CLMachine *m) { if (_onSuspendAction) _onSuspendAction->perform(m, this); }

            /** perform the onResume action */
            void performOnResume(CLMachine *m) { if (_onResumeAction) _onResumeAction->perform(m, this); }

            /** return the ith transition leading out of this state */
            CLTransition *transition(int i) const { return transitions()[i]; }

            /** return the array of transitions for this state */
            virtual CLTransition * const *transitions() const { return 0; }

            /** return the number of transitions leading out of this state */
            virtual int numberOfTransitions() const { return 0; }
        };
    }

    #pragma clang diagnostic pop

    #endif
    """
}

/// Generate the CLMachine.h infrastructure header.
///
/// - Parameters:
///   - isSuspensible: Whether to include suspend/resume support.
/// - Returns: The CLMachine.h header code.
public func objcppInfrastructureCLMachineHeader(isSuspensible: Bool) -> Code {
    """
    \(copyrightHeader("CLMachine.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_CLMachine_h
    #define clfsm_infrastructure_CLMachine_h

    #include "Machine_Common.h"

    #ifdef bool
    #undef bool
    #endif

    #ifdef true
    #undef true
    #undef false
    #endif

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpadded"
    #pragma clang diagnostic ignored "-Wweak-vtables"
    #pragma clang diagnostic ignored "-Wignored-qualifiers"

    namespace FSM
    {
        class StateMachineVector;
        class CLState;

        /**
         *  Simple uc FSM base class
         */
        class Machine
        {
            CLState                 *_currentState;         ///< current state
            CLState                 *_previousState;        ///< previous state
            unsigned long           _state_time;            ///< state start time
        public:
            /// Designated constructor
            Machine(CLState *initialState = NULLPTR): _currentState(initialState), _previousState(0), _state_time(0UL) {}

            /** Current state getter */
            CLState *currentState() { return _currentState; }

            /** Current state const getter */
            CLState * const currentState() const { return _currentState; }

            /** Current state setter */
            void setCurrentState(CLState *s) { _currentState = s; }

            /** Previous state getter */
            CLState *previousState() { return _previousState; }

            /** Current state const getter */
            CLState * const previousState() const { return _previousState; }

            /** Previous state setter */
            void setPreviousState(CLState *s) { _previousState = s; }

            /** Get the time stamp for when the machine executed onEntry */
            const unsigned long stateTime() const { return _state_time; }

            /** Set the onEntry time stamp of the machine for the current state */
            void setStateTime(const unsigned long t) { _state_time = t; }
        };

    \(isSuspensible ? """
    #ifdef FSM_SUPPORT_SUSPEND

        class SuspensibleMachine: public Machine
        {
            CLState *_suspendState;         ///< the suspend state
            CLState *_resumeState;          ///< state to resume to
            bool _deleteSuspendState;       ///< should delete in destructor?
        public:
            /** constructor */
            SuspensibleMachine(CLState *initialState = 0, CLState *s = 0, bool del = false): Machine(initialState), _suspendState(s), _resumeState(0), _deleteSuspendState(del) {}

            /** destructor */
            virtual ~SuspensibleMachine();

            /** suspend state getter method */
            CLState *suspendState() const { return _suspendState; }

            /** suspend state setter */
            void setSuspendState(CLState *s, bool del = false);

            /** tell whether this machine is suspended */
            bool isSuspended() const { return _suspendState && currentState() == _suspendState; }

            /** suspend this state machine */
            virtual void suspend();

            /** resume this state machine where it left off */
            virtual void resume();
        };

    #define CL_SUPER_MACHINE SuspensibleMachine
    #else
    #define CL_SUPER_MACHINE Machine
    #endif

    """ : """
    // FSM_SUPPORT_SUSPEND not defined
    #define CL_SUPER_MACHINE Machine

    """)
        /**
         *  This is the machine as seen from within an FSM
         */
        class CLMachine: public CL_SUPER_MACHINE
        {
            StateMachineVector      *_vectorContext;        ///< current vector
            CLState                 *_initialState;         ///< initial state
            CLState                 *_suspendState;         ///< suspend state
            const char              *_machineName;          ///< name of this machine
            int                      _machineID;            ///< number of this machine
        public:
            /** default constructor */
            CLMachine(int mid = 0, const char *name = ""): CL_SUPER_MACHINE(), _vectorContext(0), _initialState(0), _suspendState(0), _machineName(name), _machineID(mid) {}

            /** default destructor (subclass responsibility) */
            virtual ~CLMachine() {}

            /** access method for the current state the machine is in */
            CLState *initialState() const { return _initialState; }

            /** access method for the suspend state of the machine */
            CLState *suspendState() const { return _suspendState; }

            /** access method for the FSM context of this machine */
            Machine *machineContext() const { return const_cast<Machine *>(static_cast<const Machine *>(this)); }

            /** access method for the FSM vector of this machine */
            StateMachineVector *vectorContext() const { return _vectorContext; }

            /** return the name of this machine */
            const char *machineName() const { return _machineName; }

            /** return the ID number of this machine */
            int machineID() const { return _machineID; }

            /** set the current state of this machine */
            void setInitialState(CLState *state) { _initialState = state; }

            /** set the suspend state of this machine */
            void setSuspendState(CLState *state) { _suspendState = state; }

            /** set the name of this machine (name needs to be retained externally!) */
            void setMachineName(const char *name) { _machineName = name; }

            /** set the ID number of this machine */
            void setMachineID(int mid) { _machineID = mid; }

            /** return the ith state of this machine */
            CLState *state(int i) const { return states()[i]; }

            /** return the array of states this machine contains */
            virtual CLState * const *states() const = 0;

            /** return the number of states this machine has */
            virtual int numberOfStates() const = 0;

    \(isSuspensible ? """
    #ifdef FSM_SUPPORT_SUSPEND
            /** resume */
            virtual void resume() { SuspensibleMachine::resume(); if (!currentState()) setCurrentState(states()[0]); }
    #endif

    """ : "")
        };
    }

    #pragma clang diagnostic pop

    #endif
    """
}

/// Generate the CLMacros.h infrastructure header.
///
/// - Returns: The CLMacros.h header code.
public func objcppInfrastructureCLMacrosHeader() -> Code {
    """
    \(copyrightHeader("CLMacros.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_CLMacros_h
    #define clfsm_infrastructure_CLMacros_h

    #ifdef bool
    #undef bool
    #endif

    #ifdef true
    #undef true
    #undef false
    #endif

    #pragma GCC diagnostic ignored "-Wunused"
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc++98-compat-pedantic"

    namespace FSM
    {
        class Machine;
        class CLMachine;
        class CLState;

        enum CLControlStatus
        {
            CLError = -1,   ///< error indicator
            CLStatus,       ///< check status only
            CLSuspend,      ///< suspend the corresponding state machines
            CLResume,       ///< resume the corresponding state machines
            CLRestart       ///< restart the corresponding state machine
        };

        CLMachine *machine_at_index(unsigned index);
        CLState *current_state_of_machine(CLMachine *);
        long long start_time_for_current_state(const class Machine *machine);
        long long current_time_in_microseconds(void);
        int number_of_machines(void);
        const char *name_of_machine_at_index(int index = 0);
        int index_of_machine_named(const char *machine_name);
        enum CLControlStatus control_machine_at_index(int index, enum CLControlStatus command);

        /*
         * Macros for making state machines more readable
         */
    #ifndef NO_CL_READABILITY_MACROS

    #define timeout(t)      (current_time_in_microseconds() > start_time_for_current_state((_m)->machineContext()) + (t))
    #define after(t)        (timeout((t) * 1000000.0))
    #define after_ms(t)     (timeout((t) * 1000.0))

    #define machine_id()    ((_m)->machineID())
    #define machine_name()  ((_m)->machineName())
    #define state_name()    ((_s)->name())
    #define machine_index() index_of_machine_named(machine_name())
    #define cs_machine_named(m,c)      control_machine_at_index(index_of_machine_named(m), (c))

    static inline enum CLControlStatus suspend(const char *m) { return cs_machine_named(m, CLSuspend); }
    static inline enum CLControlStatus resume(const char *m)  { return cs_machine_named(m, CLResume); }
    static inline enum CLControlStatus restart(const char *m) { return cs_machine_named(m, CLRestart); }
    static inline enum CLControlStatus status(const char *m)  { return cs_machine_named(m, CLStatus); }

    #define suspend_all()   \\
        do { \\
            int _n = number_of_machines(); \\
            for (int _i = 0; _i < _n; _i++) { \\
                const CLMachine * const _m_ = machine_at_index(unsigned(_i)); \\
                if (_m != _m_) control_machine_at_index(_i, CLSuspend); \\
            } \\
        } while(0)

    #define suspend_self()  control_machine_at_index(machine_index(), CLSuspend)
    #define suspend_at(i)   control_machine_at_index((i), CLSuspend)
    #define resume_at(i)    control_machine_at_index((i), CLResume)
    #define restart_at(i)   control_machine_at_index((i), CLRestart)
    #define status_at(i)    control_machine_at_index((i), CLStatus)
    #define is_suspended_at(i)  (status_at(i) == CLSuspend)
    #define is_running_at(i)    (status_at(i) != CLSuspend)

    #define is_suspended(m) (status(m) == CLSuspend)
    #define is_running(m)   (status(m) != CLSuspend)

    #define state_of(m)     (machine_at_index(unsigned(index_of_machine_named(m)))->machineContext()->currentState())
    #define state_name_of(m)        (state_of(m)->name())

    #endif // NO_CL_READABILITY_MACROS
    }

    #pragma clang diagnostic pop

    #ifndef NO_CL_UNHYGIENIC_HEADERS
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wheader-hygiene"
    #endif

    #endif
    """
}

/// Generate the StateMachineVector.h infrastructure header.
///
/// - Returns: The StateMachineVector.h header code.
public func objcppInfrastructureStateMachineVectorHeader() -> Code {
    """
    \(copyrightHeader("StateMachineVector.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_StateMachineVector_h
    #define clfsm_infrastructure_StateMachineVector_h

    namespace FSM
    {
        class CLMachine;

        typedef bool (*visitor_f)(void *context, CLMachine *machine, int machine_number);

        /// Set the global machine vector for helper functions
        void set_global_machine_vector(class StateMachineVector *vector);

        class StateMachineVector
        {
            FSM::CLMachine **_machines; ///< vector of machines to execute
            bool _accepting;            ///< accepting state for all machines?
            unsigned char _n;           ///< number of machines in the vector

        public:
            /** Designated constructor for an FSM Vector */
            StateMachineVector(FSM::CLMachine **machines, unsigned char n);

            /** FSM Vector destructor */
            virtual ~StateMachineVector() {}

            /** Machine vector getter */
            FSM::CLMachine **machines() { return _machines; }

            /** Machine vector const getter */
            FSM::CLMachine * const * machines() const { return _machines; }

            /** Getter for the number of machines */
            unsigned char numberOfMachines() const { return _n; }

            /** Accepting state getter */
            bool accepting() const { return _accepting; }

            /** Execute one iteration of the current machine vector */
            virtual bool executeOnce(FSM::visitor_f visitor = 0, void *context = 0);

            /** Execute the given machine once */
            virtual bool executeMachineOnce(FSM::CLMachine *machine, bool *transitionFired);
        };
    }
    #endif
    """
}

/// Generate the StateMachineVector.cc infrastructure implementation.
///
/// - Returns: The StateMachineVector.cc implementation code.
public func objcppInfrastructureStateMachineVectorImplementation() -> Code {
    """
    \(copyrightHeader("StateMachineVector.cc", "clfsm infrastructure"))
    #include "StateMachineVector.h"
    #include "CLMachine.h"
    #include "CLState.h"
    #include "CLTransition.h"
    #include "CLMacros.h"
    #include "Machine_Common.h"
    #include <cstring>

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wweak-vtables"

    namespace FSM
    {

    StateMachineVector::StateMachineVector(CLMachine **ms, unsigned char n): _machines(ms), _accepting(false), _n(n)
    {
        CLMachine **mv = machines();
        if (mv) for (unsigned i = 0; i < numberOfMachines(); i++)
        {
            CLMachine *m = *mv++;
            if (!m) continue;                               // no machine? -> next

            m->setCurrentState(m->initialState());          // set initial state
        }
    }


    bool StateMachineVector::executeOnce(visitor_f visitor, void *context)
    {
        bool fired = false;

        CLMachine **mv = machines();
        if (mv) for (unsigned char i = 0; i < numberOfMachines(); i++)
        {
            CLMachine *m = *mv++;
            if (!m || (visitor && !visitor(context, m, i))) // should m execute?
                continue;                                   // no -> next

            bool mfire = false;
            bool accept = executeMachineOnce(m, &mfire);    // run machine action
            _accepting = _accepting && accept;              // accepting state?

            if (mfire) fired = true;                        // transition fired
        }

        return fired;
    }


    bool StateMachineVector::executeMachineOnce(CLMachine *m, bool *fired)
    {
        CLState * const previousState = m->previousState();
        CLState * const currentState = m->currentState();

        /*
         * perform onEntry if new state
         */
        if (currentState != previousState)
        {
            m->setStateTime(micros());
            currentState->performOnEntry(m);
        }

        /*
         * check all transitions
         */
        CLTransition * const * transitions = currentState->transitions();
        CLTransition *firingTransition = 0;
        const unsigned char n = static_cast<const unsigned char>(currentState->numberOfTransitions());
        if (transitions) for (unsigned char i = 0; i < n; i++)
        {
            CLTransition *t = *transitions++;
            if (t->check(m, currentState))      // evaluate transition
            {
                firingTransition = t;           // t fired
                break;                          // done checking transitions
            }
        }
        m->setPreviousState(currentState);      // onEntry has executed

        /*
         * Switch state and perform onExit if a transition fired
         */
        if (firingTransition)
        {
            if (fired) *fired = true;
            currentState->performOnExit(m);
            const unsigned char target = static_cast<const unsigned char>(firingTransition->destinationState());
            CLState * const targetState = m->state(target);
            m->setCurrentState(targetState);
            return true;
        }
        else if (fired) *fired = false;

        /*
         * No transition fired, perform internal action
         */
        currentState->performInternal(m);

        /*
         * If there were no transitions, this is an accepting state
         */
        return !n;
    }

    // Global machine vector for helper functions
    static StateMachineVector *g_machine_vector = NULLPTR;

    // Set the global machine vector (called from arrangement initialization)
    void set_global_machine_vector(StateMachineVector *vector) {
        g_machine_vector = vector;
    }

    // Helper functions for CLMacros.h
    CLMachine *machine_at_index(unsigned index) {
        if (!g_machine_vector || index >= g_machine_vector->numberOfMachines())
            return NULLPTR;
        return g_machine_vector->machines()[index];
    }

    CLState *current_state_of_machine(CLMachine *machine) {
        return machine ? machine->currentState() : NULLPTR;
    }

    long long start_time_for_current_state(const Machine *machine) {
        return machine ? static_cast<long long>(machine->stateTime()) : 0LL;
    }

    long long current_time_in_microseconds(void) {
        return static_cast<long long>(micros());
    }

    int number_of_machines(void) {
        return g_machine_vector ? g_machine_vector->numberOfMachines() : 0;
    }

    const char *name_of_machine_at_index(int index) {
        CLMachine *m = machine_at_index(static_cast<unsigned>(index));
        return m ? m->machineName() : "";
    }

    int index_of_machine_named(const char *machine_name) {
        if (!g_machine_vector || !machine_name) return -1;
        const int n = number_of_machines();
        for (int i = 0; i < n; i++) {
            CLMachine *m = machine_at_index(static_cast<unsigned>(i));
            if (m && strcmp(m->machineName(), machine_name) == 0)
                return i;
        }
        return -1;
    }

    enum CLControlStatus control_machine_at_index(int index, enum CLControlStatus command) {
        if (index < 0 || index >= number_of_machines())
            return CLError;

        CLMachine *m = machine_at_index(static_cast<unsigned>(index));
        if (!m) return CLError;

    #ifdef FSM_SUPPORT_SUSPEND
        switch (command) {
            case CLSuspend:
                if (!m->isSuspended()) m->suspend();
                return CLSuspend;
            case CLResume:
                if (m->isSuspended()) m->resume();
                return CLResume;
            case CLRestart:
                m->setCurrentState(m->initialState());
                return CLStatus;
            case CLStatus:
                return m->isSuspended() ? CLSuspend : CLStatus;
            default:
                return CLError;
        }
    #else
        switch (command) {
            case CLRestart:
                m->setCurrentState(m->initialState());
                return CLStatus;
            case CLStatus:
                return CLStatus;
            default:
                return CLError;
        }
    #endif
    }

    } // namespace FSM

    #pragma clang diagnostic pop
    """
}

/// Generate the Machine_Common.h infrastructure header with common definitions.
///
/// - Returns: The Machine_Common.h header code.
public func objcppInfrastructureMachineCommonHeader() -> Code {
    """
    \(copyrightHeader("Machine_Common.h", "clfsm infrastructure"))
    #ifndef clfsm_infrastructure_Machine_Common_h
    #define clfsm_infrastructure_Machine_Common_h

    #ifdef __cplusplus
    // Include C++ headers first
    #include <ctime>
    #include <sys/time.h>

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc++98-compat"

    // Common type definitions
    #ifndef NULL
    #define NULL nullptr
    #endif

    #ifndef NULLPTR
    #define NULLPTR nullptr
    #endif

    // Provide time-related functions
    extern "C" {
        inline unsigned long micros() {
            struct timespec ts;
            clock_gettime(CLOCK_MONOTONIC, &ts);
            return static_cast<unsigned long>(ts.tv_sec) * 1000000UL +
                   static_cast<unsigned long>(ts.tv_nsec) / 1000UL;
        }
    }

    #pragma clang diagnostic pop
    #else
    // For C, include the C headers
    #include <time.h>
    #include <sys/time.h>
    #endif

    #endif
    """
}

/// Generate the SuspensibleMachine.cc infrastructure implementation.
///
/// - Returns: The SuspensibleMachine.cc implementation code.
public func objcppInfrastructureSuspensibleMachineImplementation() -> Code {
    """
    \(copyrightHeader("SuspensibleMachine.cc", "clfsm infrastructure"))
    #include "CLMachine.h"
    #include "CLState.h"
    #include <cstdlib>

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wglobal-constructors"
    #pragma clang diagnostic ignored "-Wexit-time-destructors"

    #ifdef FSM_SUPPORT_SUSPEND

    void operator delete(void * ptr, unsigned int) {
      free(ptr);
    }

    void operator delete[](void * ptr, unsigned int) {
      free(ptr);
    }

    #endif

    namespace FSM
    {

    #ifdef FSM_SUPPORT_SUSPEND

    static CLAction noAction;

    SuspensibleMachine::~SuspensibleMachine()
    {
        if (_deleteSuspendState && _suspendState)
            delete _suspendState;
    }


    void SuspensibleMachine::setSuspendState(CLState *s, bool del)
    {
        if (_deleteSuspendState && _suspendState)
            delete _suspendState;

        _suspendState = s;
        _deleteSuspendState = del;
    }


    void SuspensibleMachine::suspend()
    {
        if (!_suspendState)
        {
            _suspendState = new CLState("Suspended", noAction, noAction, noAction);
            _deleteSuspendState = true;
        }

        if (currentState() != _suspendState)
        {
            _resumeState = currentState();
            setPreviousState(_resumeState);
        }

        setCurrentState(_suspendState);
    }


    void SuspensibleMachine::resume()
    {
        CLState *curr = currentState();

        /*
         * only do anything if suspended
         */
        if (curr != _suspendState)
            return;

        CLState *prev = _resumeState;

        setPreviousState(curr);
        setCurrentState(prev);
    }

    #endif // FSM_SUPPORT_SUSPEND

    } // namespace FSM

    #pragma clang diagnostic pop
    """
}
