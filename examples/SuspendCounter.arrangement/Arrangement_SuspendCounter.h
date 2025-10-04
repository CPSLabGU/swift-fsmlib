//
// Arrangement_SuspendCounter.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_ARRANGEMENT_SUSPENDCOUNTER_H
#define LLFSM_ARRANGEMENT_SUSPENDCOUNTER_H

#include <inttypes.h>
#include <stdbool.h>

#define ARRANGEMENT_SUSPENDCOUNTER_NUMBER_OF_INSTANCES 2

struct LLFSMachine;
struct LLFSMArrangement;

/// A SuspendCounter LLFSM Arrangement.
struct Arrangement_SuspendCounter
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
    union
    {
        /// The machines in this arrangement.
        struct LLFSMachine *machines[2];
        struct
        {
            /// An instance of the Suspend LLFSM.
            struct Machine_Suspend *fsm_suspend;
            /// An instance of the Counter LLFSM.
            struct Machine_Counter *fsm_counter;
        };
    };
};

/// Initialise the SuspendCounter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_suspendcounter_init(struct Arrangement_SuspendCounter * const arrangement);

/// Validate the SuspendCounter LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
bool arrangement_suspendcounter_validate(struct Arrangement_SuspendCounter * const arrangement);


#endif /* LLFSM_ARRANGEMENT_SUSPENDCOUNTER_H */
