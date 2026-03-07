//
// CounterCPP.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_CounterCPP_
#define clfsm_machine_CounterCPP_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class CounterCPP: public CLMachine
        {
            CLState *_states[5];
        public:
            CounterCPP(int mid = 0, const char *name = "CounterCPP");
            virtual ~CounterCPP();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 5; }
#           include "CounterCPP_Variables.h"
#           include "CounterCPP_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::CounterCPP *CLM_Create_CounterCPP(int mid, const char *name);
}

#endif // defined(clfsm_machine_CounterCPP_)