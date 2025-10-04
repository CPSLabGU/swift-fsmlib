//
// Static_Arrangement_SuspendCounter.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_STATIC_ARRANGEMENT_SUSPENDCOUNTER_H
#define LLFSM_STATIC_ARRANGEMENT_SUSPENDCOUNTER_H

#include "Arrangement_SuspendCounter.h"
#include "Suspend.machine/Machine_Suspend.h"
#include "Counter.machine/Machine_Counter.h"

#define STATIC_ARRANGEMENT_SUSPENDCOUNTER_NUMBER_OF_INSTANCES 2
#ifndef SUSPEND_ALL
#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct LLFSMArrangement *)&static_arrangement_suspendcounter)
#endif // SUSPEND_ALL
#ifndef RESUME_ALL
#define RESUME_ALL() fsm_arrangement_resume_all((struct LLFSMArrangement *)&static_arrangement_suspendcounter)
#endif // RESUME_ALL
#ifndef RESTART_ALL
#define RESTART_ALL() fsm_arrangement_restart_all((struct LLFSMArrangement *)&static_arrangement_suspendcounter)
#endif // RESTART_ALL

struct LLFSMachine;
struct LLFSMArrangement;

/// Static instantiation of a Suspend LLFSM.
extern struct Machine_Suspend static_fsm_suspend;
/// Static instantiation of the Suspend LLFSM state InitialPseudoState.
extern struct FSMSuspend_State_InitialPseudoState static_suspend_state_InitialPseudoState;
/// Static instantiation of the Suspend LLFSM state Initial.
extern struct FSMSuspend_State_Initial static_suspend_state_Initial;
/// Static instantiation of the Suspend LLFSM state Suspend_Counter.
extern struct FSMSuspend_State_Suspend_Counter static_suspend_state_Suspend_Counter;
/// Static instantiation of the Suspend LLFSM state Resume_Counter.
extern struct FSMSuspend_State_Resume_Counter static_suspend_state_Resume_Counter;
/// Static instantiation of a Counter LLFSM.
extern struct Machine_Counter static_fsm_counter;
/// Static instantiation of the Counter LLFSM state InitialPseudoState.
extern struct FSMCounter_State_InitialPseudoState static_counter_state_InitialPseudoState;
/// Static instantiation of the Counter LLFSM state Initial.
extern struct FSMCounter_State_Initial static_counter_state_Initial;
/// Static instantiation of the Counter LLFSM state CountUp.
extern struct FSMCounter_State_CountUp static_counter_state_CountUp;
/// Static instantiation of the Counter LLFSM state Print.
extern struct FSMCounter_State_Print static_counter_state_Print;
/// Static instantiation of the Counter LLFSM state SUSPENDED.
extern struct FSMCounter_State_SUSPENDED static_counter_state_SUSPENDED;
/// Static instantiation of the SuspendCounter LLFSM Arrangement.
extern struct Arrangement_SuspendCounter static_arrangement_suspendcounter;

#endif /* LLFSM_STATIC_ARRANGEMENT_SUSPENDCOUNTER_H */
