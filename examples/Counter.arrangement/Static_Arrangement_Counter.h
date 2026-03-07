//
// Static_Arrangement_Counter.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_STATIC_ARRANGEMENT_COUNTER_H
#define LLFSM_STATIC_ARRANGEMENT_COUNTER_H

#include "Arrangement_Counter.h"
#include "Counter.machine/Machine_Counter.h"

#define STATIC_ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES 1
#ifndef SUSPEND_ALL
#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct LLFSMArrangement *)&static_arrangement_counter)
#endif // SUSPEND_ALL
#ifndef RESUME_ALL
#define RESUME_ALL() fsm_arrangement_resume_all((struct LLFSMArrangement *)&static_arrangement_counter)
#endif // RESUME_ALL
#ifndef RESTART_ALL
#define RESTART_ALL() fsm_arrangement_restart_all((struct LLFSMArrangement *)&static_arrangement_counter)
#endif // RESTART_ALL

struct LLFSMachine;
struct LLFSMArrangement;

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
/// Static instantiation of the Counter LLFSM Arrangement.
extern struct Arrangement_Counter static_arrangement_counter;

#endif /* LLFSM_STATIC_ARRANGEMENT_COUNTER_H */
