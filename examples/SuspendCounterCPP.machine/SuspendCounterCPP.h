//
// SuspendCounterCPP.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_SuspendCounterCPP_
#define clfsm_machine_SuspendCounterCPP_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class SuspendCounterCPP: public CLMachine
        {
            CLState *_states[4];
        public:
            SuspendCounterCPP(int mid  = 0, const char *name = "SuspendCounterCPP");
            virtual ~SuspendCounterCPP();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 4; }
#           include "SuspendCounterCPP_Variables.h"
#           include "SuspendCounterCPP_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::SuspendCounterCPP *CLM_Create_SuspendCounterCPP(int mid, const char *name);
}

#endif // defined(clfsm_machine_SuspendCounterCPP_)
