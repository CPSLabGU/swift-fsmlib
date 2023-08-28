//
// State_Suspend_Counter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_SuspendCounter_State_Suspend_Counter_h
#define clfsm_SuspendCounter_State_Suspend_Counter_h

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMSuspendCounter
      {
        namespace State
        {
            class Suspend_Counter: public CLState
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
                    Suspend_Counter(const char *name = "Suspend_Counter");
                    virtual ~Suspend_Counter();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_Suspend_Counter_Variables.h"
#                   include "State_Suspend_Counter_Methods.h"
            };
        }
      }
    }
}

#endif
