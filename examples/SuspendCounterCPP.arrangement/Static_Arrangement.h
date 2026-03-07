//
// Static_Arrangement.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef clfsm_static_arrangement_suspendcountercpp_h
#define clfsm_static_arrangement_suspendcountercpp_h

#ifndef FSM_SUPPORT_SUSPEND
#define FSM_SUPPORT_SUSPEND
#endif

#include "Arrangement_SuspendCounterCPP.h"
#include "SuspendCounterCPP.machine/SuspendCounterCPP.h"
#include "CounterCPP.machine/CounterCPP.h"


#define STATIC_ARRANGEMENT_SUSPENDCOUNTERCPP_NUMBER_OF_INSTANCES 2

#ifdef __cplusplus
extern "C" {
#endif

/// Get a pointer to the static SuspendCounterCPP arrangement.
struct Arrangement_SuspendCounterCPP *static_arrangement_suspendcountercpp(void);

#ifdef __cplusplus
}

namespace FSM {
    /// Get the StateMachineVector for the static SuspendCounterCPP arrangement.
    StateMachineVector *static_arrangement_suspendcountercpp_vector(void);
}
#endif

#endif // clfsm_static_arrangement_suspendcountercpp_h