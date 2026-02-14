//
// Arrangement_Counter.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_Common.h"
#include "Arrangement_Counter.h"
#include "Counter.machine/Machine_Counter.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise the Counter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counter_init(struct Arrangement_Counter * const arrangement)
{
    arrangement->number_of_instances = ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES;
    fsm_counter_init(arrangement->fsm_counter);
}

/// Validate the Counter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_counter_validate(struct Arrangement_Counter * const arrangement)
{
    return arrangement->number_of_instances == ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES &&
        fsm_counter_validate(arrangement->fsm_counter);
}
