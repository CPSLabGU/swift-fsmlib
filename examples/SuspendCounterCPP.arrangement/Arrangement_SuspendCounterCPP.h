//
// Arrangement_SuspendCounterCPP.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_arrangement_SuspendCounterCPP_h
#define clfsm_arrangement_SuspendCounterCPP_h

#include <inttypes.h>
#include <stdbool.h>

#define ARRANGEMENT_SUSPENDCOUNTERCPP_NUMBER_OF_INSTANCES 2

#ifdef __cplusplus
namespace FSM {
    class CLMachine;
    class StateMachineVector;
    namespace CLM {            class CounterCPP;
            class SuspendCounterCPP;    }
}
#endif

/// A SuspendCounterCPP CLFSM Arrangement.
struct Arrangement_SuspendCounterCPP
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
#ifdef __cplusplus
    union {
        /// The machines in this arrangement.
        FSM::CLMachine *machines[2];
        struct {                /// An instance of the SuspendCounterCPP CLFSM.
                FSM::CLM::SuspendCounterCPP *fsmSuspendCounterCPP;
                /// An instance of the CounterCPP CLFSM.
                FSM::CLM::CounterCPP *fsmCounterCPP;        };
    };
#else
    void *machines[2];
#endif
};

#ifdef __cplusplus
extern "C" {
#endif

/// Initialise the SuspendCounterCPP CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to initialise.
void arrangement_suspendcountercpp_init(struct Arrangement_SuspendCounterCPP * const arrangement);

/// Validate the SuspendCounterCPP CLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to validate.
bool arrangement_suspendcountercpp_validate(struct Arrangement_SuspendCounterCPP * const arrangement);

#ifdef __cplusplus
}
#endif

#endif // clfsm_arrangement_SuspendCounterCPP_h