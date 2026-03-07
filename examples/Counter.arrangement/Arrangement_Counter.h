//
// Arrangement_Counter.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_ARRANGEMENT_COUNTER_H
#define LLFSM_ARRANGEMENT_COUNTER_H

#include <inttypes.h>
#include <stdbool.h>

#define ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES 1

struct LLFSMachine;
struct LLFSMArrangement;

/// A Counter LLFSM Arrangement.
struct Arrangement_Counter
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
    union
    {
        /// The machines in this arrangement.
        struct LLFSMachine *machines[1];
        struct
        {
            /// An instance of the Counter LLFSM.
            struct Machine_Counter *fsm_counter;
        };
    };
};

/// Initialise the Counter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counter_init(struct Arrangement_Counter * const arrangement);

/// Validate the Counter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_counter_validate(struct Arrangement_Counter * const arrangement);


#endif /* LLFSM_ARRANGEMENT_COUNTER_H */
