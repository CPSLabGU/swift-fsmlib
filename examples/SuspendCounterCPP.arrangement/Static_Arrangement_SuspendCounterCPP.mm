//
// Static_Arrangement_SuspendCounterCPP.mm
//
// Automatically created using fsmconvert -- do not change manually!
//
#include <cstddef>
#include "Static_Arrangement.h"
#include "StateMachineVector.h"
#include "CounterCPP.machine/CounterCPP.h"
#include "SuspendCounterCPP.machine/SuspendCounterCPP.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL nullptr
#endif

using namespace FSM::CLM;
/// Static instantiation of a SuspendCounterCPP CLFSM.
static SuspendCounterCPP fsmSuspendCounterCPP(0, "SuspendCounterCPP");
/// Static instantiation of a CounterCPP CLFSM.
static CounterCPP fsmCounterCPP(1, "CounterCPP");
/// Static instantiation of the SuspendCounterCPP CLFSM Arrangement.
static Arrangement_SuspendCounterCPP static_arrangement = {
    .number_of_instances = STATIC_ARRANGEMENT_SUSPENDCOUNTERCPP_NUMBER_OF_INSTANCES,
    {        .fsmSuspendCounterCPP = &fsmSuspendCounterCPP,
        .fsmCounterCPP = &fsmCounterCPP    }
};

/// Static machine vector for the arrangement.
static FSM::CLMachine *machine_vector[2] = {    &fsmSuspendCounterCPP,
    &fsmCounterCPP};

/// Static StateMachineVector for the arrangement.
static FSM::StateMachineVector static_vector(machine_vector, 2);

extern "C" {
    /// Get a pointer to the static SuspendCounterCPP arrangement.
    struct Arrangement_SuspendCounterCPP *static_arrangement_suspendcountercpp(void)
    {
        return &static_arrangement;
    }
}

namespace FSM {
    /// Get the StateMachineVector for the static SuspendCounterCPP arrangement.
    StateMachineVector *static_arrangement_suspendcountercpp_vector(void)
    {
        set_global_machine_vector(&static_vector);
        return &static_vector;
    }
}

#pragma clang diagnostic pop