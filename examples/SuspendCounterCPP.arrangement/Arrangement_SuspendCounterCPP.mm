//
// Arrangement_SuspendCounterCPP.mm
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Arrangement_SuspendCounterCPP.h"
#include "SuspendCounterCPP.machine/SuspendCounterCPP.h"
#include "CounterCPP.machine/CounterCPP.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL nullptr
#endif

extern "C" {
    /// Initialise the SuspendCounterCPP CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to initialise.
    /// - Note: For C++, machine instances are initialized elsewhere.
    void arrangement_suspendcountercpp_init(struct Arrangement_SuspendCounterCPP * const arrangement)
    {
        arrangement->number_of_instances = ARRANGEMENT_SUSPENDCOUNTERCPP_NUMBER_OF_INSTANCES;
    }

    /// Validate the SuspendCounterCPP CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to validate.
    bool arrangement_suspendcountercpp_validate(struct Arrangement_SuspendCounterCPP * const arrangement)
    {
        return arrangement->number_of_instances == ARRANGEMENT_SUSPENDCOUNTERCPP_NUMBER_OF_INSTANCES &&
        arrangement->machines[0] != nullptr;
    }
}

#pragma clang diagnostic pop