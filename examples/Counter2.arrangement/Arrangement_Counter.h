//
// Arrangement_Counter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_arrangement_Counter_h
#define clfsm_arrangement_Counter_h

#include <inttypes.h>
#include <stdbool.h>

#define ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES 4

struct CLMachine;
struct CLFSMArrangement;

/// A Counter CLFSM Arrangement.
struct Arrangement_Counter
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
    union {
        /// The machines in this arrangement.
        struct CLMachine *machines[4];
        struct {                /// An instance of the SuspendCounter CLFSM.
                struct SuspendCounter *fsm_suspendcounter;
                /// An instance of the Counter CLFSM.
                struct Counter *fsm_counter;
                /// An instance of the Counter CLFSM.
                struct Counter *fsm_counter_1;
                /// An instance of the Counter CLFSM.
                struct Counter *fsm_counter_2;        };
    };
};

/// Initialise the Counter CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_counter_init(struct Arrangement_Counter * const arrangement);

/// Validate the Counter CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to validate.
bool arrangement_counter_validate(struct Arrangement_Counter * const arrangement);

#endif // clfsm_arrangement_Counter_h