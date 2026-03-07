//
// State_InitialPseudoState.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_TrafficLight_State_InitialPseudoState_h
#define clfsm_TrafficLight_State_InitialPseudoState_h

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
            class InitialPseudoState: public CLState
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
                    InitialPseudoState(const char *name = "InitialPseudoState");
                    virtual ~InitialPseudoState();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_InitialPseudoState_Variables.h"
#                   include "State_InitialPseudoState_Methods.h"
            };
        }
      }
    }
}

#endif
