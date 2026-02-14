//
// Arrangement_CounterC.c
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine_Common.h"
#include "Arrangement_CounterC.h"
#include "CounterC.machine/Machine_CounterC.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif

/// Initialise the CounterC LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counterc_init(struct Arrangement_CounterC * const arrangement)
{
    arrangement->number_of_instances = ARRANGEMENT_COUNTERC_NUMBER_OF_INSTANCES;
    fsm_counterc_init(arrangement->fsm_counterc);
}

/// Validate the CounterC LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_counterc_validate(struct Arrangement_CounterC * const arrangement)
{
    return arrangement->number_of_instances == ARRANGEMENT_COUNTERC_NUMBER_OF_INSTANCES &&
        fsm_counterc_validate(arrangement->fsm_counterc);
}
