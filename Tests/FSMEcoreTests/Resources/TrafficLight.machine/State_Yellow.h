//
// State_Yellow.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_TrafficLight_State_Yellow_h
#define clfsm_TrafficLight_State_Yellow_h

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMTrafficLight
      {
        namespace State
        {
            class Yellow: public CLState
            {
                class OnEntry: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class OnExit: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Internal: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Transition_0: public CLTransition
                {
                public:
                    Transition_0(int toState = 1): CLTransition(toState) {}

                    virtual bool check(CLMachine *, CLState *) const;
                };

                CLTransition *_transitions[1];

                public:
                    Yellow(const char *name = "Yellow");
                    virtual ~Yellow();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_Yellow_Variables.h"
#                   include "State_Yellow_Methods.h"
            };
        }
      }
    }
}

#endif
