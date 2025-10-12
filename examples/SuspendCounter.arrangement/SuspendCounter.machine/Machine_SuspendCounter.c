//
// Machine_SuspendCounter.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_SuspendCounter.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise an instance of `Machine_SuspendCounter.
///
/// - Parameter machine: The machine to initialise.
void fsm_suspendcounter_init(struct Machine_SuspendCounter * const machine)
{
    machine->current_state = machine->states[0];
    machine->previous_state = NULL;
    machine->state_time = 0;
    machine->suspend_state = NULL;
    machine->resume_state = NULL;
}

/// Validate an instance of `Machine_SuspendCounter.
///
/// - Parameter machine: The machine to validate.
/// - Returns: `true` iff the machine appears valid.
bool fsm_suspendcounter_validate(struct Machine_SuspendCounter * const machine)
{
    return machine->current_state != NULL &&
    true; // FIXME: check states
}
