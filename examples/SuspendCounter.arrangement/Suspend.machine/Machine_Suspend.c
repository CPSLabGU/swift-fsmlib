//
// Machine_Suspend.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_Suspend.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise an instance of `Machine_Suspend.
///
/// - Parameter machine: The machine to initialise.
void fsm_suspend_init(struct Machine_Suspend * const machine)
{
    machine->current_state = machine->states[0];
    machine->previous_state = NULL;
    machine->state_time = 0;
    machine->suspend_state = NULL;
    machine->resume_state = NULL;
}

/// Validate an instance of `Machine_Suspend.
///
/// - Parameter machine: The machine to validate.
/// - Returns: `true` iff the machine appears valid.
bool fsm_suspend_validate(struct Machine_Suspend * const machine)
{
    return machine->current_state != NULL &&
    true; // FIXME: check states
}
