//
// Suspend.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_Suspend_
#define clfsm_machine_Suspend_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class Suspend: public CLMachine
        {
            CLState *_states[4];
        public:
            Suspend(int mid  = 0, const char *name = "Suspend");
            virtual ~Suspend();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 4; }
#           include "Suspend_Variables.h"
#           include "Suspend_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::Suspend *CLM_Create_Suspend(int mid, const char *name);
}

#endif // defined(clfsm_machine_Suspend_)
