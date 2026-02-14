//
// Machine1.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_Machine1_
#define clfsm_machine_Machine1_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class Machine1: public CLMachine
        {
            CLState *_states[3];
        public:
            Machine1(int mid  = 0, const char *name = "Machine1");
            virtual ~Machine1();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 3; }
#           include "Machine1_Variables.h"
#           include "Machine1_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::Machine1 *CLM_Create_Machine1(int mid, const char *name);
}

#endif // defined(clfsm_machine_Machine1_)
