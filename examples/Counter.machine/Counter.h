//
// Counter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_Counter_
#define clfsm_machine_Counter_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class Counter: public CLMachine
        {
            CLState *_states[5];
        public:
            Counter(int mid  = 0, const char *name = "Counter");
            virtual ~Counter();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 5; }
#           include "Counter_Variables.h"
#           include "Counter_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::Counter *CLM_Create_Counter(int mid, const char *name);
}

#endif // defined(clfsm_machine_Counter_)
