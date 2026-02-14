//
// Machine_SuspendCounterC.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_MACHINE_SUSPENDCOUNTERC_H
#define LLFSM_MACHINE_SUSPENDCOUNTERC_H

#include <inttypes.h>
#include <stdbool.h>
#include "Machine_SuspendCounterC_Includes.h"

#ifdef INCLUDE_MACHINE_CUSTOM
#include "Machine_Custom.h"
#endif

#ifdef INCLUDE_MACHINE_SUSPENDCOUNTERC_CUSTOM
#include "Machine_SuspendCounterC_Custom.h"
#endif

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#define MACHINE_SUSPENDCOUNTERC_NUMBER_OF_STATES 4
#define MACHINE_SUSPENDCOUNTERC_NUMBER_OF_TRANSITIONS 3

#define MACHINE_SUSPENDCOUNTERC_IS_SUSPENSIBLE 1

#ifndef RESTART
#define RESTART(m) (((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->states[0]))
#endif
#ifndef GET_TIME
#define GET_TIME() (machine->state_time + 1)
#endif
#ifndef TAKE_SNAPSHOT
#define TAKE_SNAPSHOT()
#endif


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"

struct LLFSMArrangement;
struct LLFSMState;
struct LLFSMachine;

/// A SuspendCounterC LLFSM.
struct Machine_SuspendCounterC
{
    struct LLFSMState *current_state;
    struct LLFSMState *previous_state;
    uintptr_t          state_time;
    struct LLFSMState *suspend_state;
    struct LLFSMState *resume_state;
    struct LLFSMState * const states[MACHINE_SUSPENDCOUNTERC_NUMBER_OF_STATES];

#   include "Machine_SuspendCounterC_Variables.h"
};

/// Initialise a `Machine_SuspendCounterC` LLFSM.
///
/// - Parameter machine: The LLFSM to initialise.
void fsm_suspendcounterc_init(struct Machine_SuspendCounterC *);

/// Validate a `Machine_SuspendCounterC` LLFSM.
///
/// - Parameter machine: The LLFSM to initialise.
bool fsm_suspendcounterc_validate(struct Machine_SuspendCounterC *);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#endif /* LLFSM_MACHINE_SUSPENDCOUNTERC_H */
