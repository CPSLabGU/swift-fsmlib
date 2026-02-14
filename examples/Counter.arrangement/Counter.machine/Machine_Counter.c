//
// Machine_Counter.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_Counter.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise an instance of `Machine_Counter.
///
/// - Parameter machine: The machine to initialise.
void fsm_counter_init(struct Machine_Counter * const machine)
{
    machine->current_state = machine->states[0];
    machine->previous_state = NULL;
    machine->state_time = 0;
    machine->suspend_state = machine->states[4];
    machine->resume_state = NULL;
}

/// Validate an instance of `Machine_Counter.
///
/// - Parameter machine: The machine to validate.
/// - Returns: `true` iff the machine appears valid.
bool fsm_counter_validate(struct Machine_Counter * const machine)
{
    return machine->current_state != NULL &&
    true; // FIXME: check states
}
