//
// TrafficLight.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_machine_TrafficLight_
#define clfsm_machine_TrafficLight_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class TrafficLight: public CLMachine
        {
            CLState *_states[5];
        public:
            TrafficLight(int mid  = 0, const char *name = "TrafficLight");
            virtual ~TrafficLight();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 5; }
#           include "TrafficLight_Variables.h"
#           include "TrafficLight_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::TrafficLight *CLM_Create_TrafficLight(int mid, const char *name);
}

#endif // defined(clfsm_machine_TrafficLight_)
