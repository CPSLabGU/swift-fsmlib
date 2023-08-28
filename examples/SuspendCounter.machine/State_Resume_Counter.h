//
// State_Resume_Counter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_SuspendCounter_State_Resume_Counter_h
#define clfsm_SuspendCounter_State_Resume_Counter_h

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
            class Resume_Counter: public CLState
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wzero-length-array"
                CLTransition *_transitions[0];

                public:
                    Resume_Counter(const char *name = "Resume_Counter");
                    virtual ~Resume_Counter();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 0; }

#                   include "State_Resume_Counter_Variables.h"
#                   include "State_Resume_Counter_Methods.h"
            };
        }
      }
    }
}

#endif
#pragma clang diagnostic pop
