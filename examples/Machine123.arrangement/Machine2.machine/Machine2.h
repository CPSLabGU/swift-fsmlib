//
// Machine2.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_Machine2_
#define clfsm_machine_Machine2_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class Machine2: public CLMachine
        {
            CLState *_states[3];
        public:
            Machine2(int mid  = 0, const char *name = "Machine2");
            virtual ~Machine2();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 3; }
#           include "Machine2_Variables.h"
#           include "Machine2_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::Machine2 *CLM_Create_Machine2(int mid, const char *name);
}

#endif // defined(clfsm_machine_Machine2_)
