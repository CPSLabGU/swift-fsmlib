//
// Arrangement_CounterC.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef LLFSM_ARRANGEMENT_COUNTERC_H
#define LLFSM_ARRANGEMENT_COUNTERC_H

#include <inttypes.h>
#include <stdbool.h>

#define ARRANGEMENT_COUNTERC_NUMBER_OF_INSTANCES 1

struct LLFSMachine;
struct LLFSMArrangement;

/// A CounterC LLFSM Arrangement.
struct Arrangement_CounterC
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
    union
    {
        /// The machines in this arrangement.
        struct LLFSMachine *machines[1];
        struct
        {
            /// An instance of the CounterC LLFSM.
            struct Machine_CounterC *fsm_counterc;
        };
    };
};

/// Initialise the CounterC LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counterc_init(struct Arrangement_CounterC * const arrangement);

/// Validate the CounterC LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_counterc_validate(struct Arrangement_CounterC * const arrangement);


#endif /* LLFSM_ARRANGEMENT_COUNTERC_H */
