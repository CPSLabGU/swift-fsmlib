/*
 *  StateMachineVector.cc
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