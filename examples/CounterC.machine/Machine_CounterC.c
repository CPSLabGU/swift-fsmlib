//
// Machine_CounterC.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_CounterC.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise an instance of `Machine_CounterC.
///
/// - Parameter machine: The machine to initialise.
void fsm_counterc_init(struct Machine_CounterC * const machine)
{
    machine->current_state = machine->states[0];
    machine->previous_state = NULL;
    machine->state_time = 0;
    machine->suspend_state = machine->states[4];
    machine->resume_state = NULL;
}

/// Validate an instance of `Machine_CounterC.
///
/// - Parameter machine: The machine to validate.
/// - Returns: `true` iff the machine appears valid.
bool fsm_counterc_validate(struct Machine_CounterC * const machine)
{
    return machine->current_state != NULL &&
    true; // FIXME: check states
}
