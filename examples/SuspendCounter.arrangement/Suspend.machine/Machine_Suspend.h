//
// Machine_Suspend.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_MACHINE_SUSPEND_H
#define LLFSM_MACHINE_SUSPEND_H

#include <inttypes.h>
#include <stdbool.h>
#include "Machine_Suspend_Includes.h"

#ifdef INCLUDE_MACHINE_CUSTOM
#include "Machine_Custom.h"
#endif

#ifdef INCLUDE_MACHINE_SUSPEND_CUSTOM
#include "Machine_Suspend_Custom.h"
#endif

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#define MACHINE_SUSPEND_NUMBER_OF_STATES 4

#define MACHINE_SUSPEND_IS_SUSPENSIBLE 1

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

/// A Suspend LLFSM.
struct Machine_Suspend
{
    struct LLFSMState *current_state;
    struct LLFSMState *previous_state;
    uintptr_t          state_time;
    struct LLFSMState *suspend_state;
    struct LLFSMState *resume_state;
    struct LLFSMState * const states[MACHINE_SUSPEND_NUMBER_OF_STATES];

#   include "Machine_Suspend_Variables.h"
};

/// Initialise a `Machine_Suspend` LLFSM.
///
/// - Parameter machine: The LLFSM to initialise.
void fsm_suspend_init(struct Machine_Suspend *);

/// Validate a `Machine_Suspend` LLFSM.
///
/// - Parameter machine: The LLFSM to initialise.
bool fsm_suspend_validate(struct Machine_Suspend *);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#endif /* LLFSM_MACHINE_SUSPEND_H */
