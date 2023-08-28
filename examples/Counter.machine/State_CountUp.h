//
// State_CountUp.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_Counter_State_CountUp_h
#define clfsm_Counter_State_CountUp_h

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMCounter
      {
        namespace State
        {
            class CountUp: public CLState
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

                class OnSuspend: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class OnResume: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Transition_0: public CLTransition
                {
                public:
                    Transition_0(int toState = 3): CLTransition(toState) {}

                    virtual bool check(CLMachine *, CLState *) const;
                };

                CLTransition *_transitions[1];

                public:
                    CountUp(const char *name = "CountUp");
                    virtual ~CountUp();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_CountUp_Variables.h"
#                   include "State_CountUp_Methods.h"
            };
        }
      }
    }
}

#endif
