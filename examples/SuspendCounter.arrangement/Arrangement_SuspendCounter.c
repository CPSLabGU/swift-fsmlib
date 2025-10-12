//
// Arrangement_SuspendCounter.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_Common.h"
#include "Arrangement_SuspendCounter.h"
#include "Counter.machine/Machine_Counter.h"
#include "SuspendCounter.machine/Machine_SuspendCounter.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise the SuspendCounter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_suspendcounter_init(struct Arrangement_SuspendCounter * const arrangement)
{
    arrangement->number_of_instances = ARRANGEMENT_SUSPENDCOUNTER_NUMBER_OF_INSTANCES;
    fsm_suspendcounter_init(arrangement->fsm_suspendcounter);
    fsm_counter_init(arrangement->fsm_counter);
}

/// Validate the SuspendCounter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_suspendcounter_validate(struct Arrangement_SuspendCounter * const arrangement)
{
    return arrangement->number_of_instances == ARRANGEMENT_SUSPENDCOUNTER_NUMBER_OF_INSTANCES &&
        fsm_suspendcounter_validate(arrangement->fsm_suspendcounter) &&
        fsm_counter_validate(arrangement->fsm_counter);
}
