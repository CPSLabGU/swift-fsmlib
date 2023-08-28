//
// SuspendCounter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_SuspendCounter_
#define clfsm_machine_SuspendCounter_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class SuspendCounter: public CLMachine
        {
            CLState *_states[4];
        public:
            SuspendCounter(int mid  = 0, const char *name = "SuspendCounter");
            virtual ~SuspendCounter();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 4; }
#           include "SuspendCounter_Variables.h"
#           include "SuspendCounter_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::SuspendCounter *CLM_Create_SuspendCounter(int mid, const char *name);
}

#endif // defined(clfsm_machine_SuspendCounter_)
