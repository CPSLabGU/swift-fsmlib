//
// Arrangement_Counter.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Arrangement_Counter.h"
#include "Counter.machine/Counter.h"
#include "SuspendCounter.machine/SuspendCounter.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise the Counter CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counter_init(struct Arrangement_Counter * const arrangement)
{
    arrangement->number_of_instances = ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES;
    fsm_suspendcounter_init(arrangement->fsm_suspendcounter);
    fsm_counter_init(arrangement->fsm_counter);
    fsm_counter_init(arrangement->fsm_counter_1);
    fsm_counter_init(arrangement->fsm_counter_2);
}

/// Validate the Counter CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to validate.
bool arrangement_counter_validate(struct Arrangement_Counter * const arrangement)
{
    return arrangement->number_of_instances == ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES &&
    fsm_suspendcounter_validate(arrangement->fsm_suspendcounter) &&
    fsm_counter_validate(arrangement->fsm_counter) &&
    fsm_counter_validate(arrangement->fsm_counter_1) &&
    fsm_counter_validate(arrangement->fsm_counter_2);
}