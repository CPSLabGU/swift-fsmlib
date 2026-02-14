//
// Machine3.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_Machine3_
#define clfsm_machine_Machine3_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class Machine3: public CLMachine
        {
            CLState *_states[2];
        public:
            Machine3(int mid  = 0, const char *name = "Machine3");
            virtual ~Machine3();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 2; }
#           include "Machine3_Variables.h"
#           include "Machine3_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::Machine3 *CLM_Create_Machine3(int mid, const char *name);
}

#endif // defined(clfsm_machine_Machine3_)
