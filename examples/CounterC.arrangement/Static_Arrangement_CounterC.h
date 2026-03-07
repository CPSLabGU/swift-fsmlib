//
// Static_Arrangement_CounterC.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef LLFSM_STATIC_ARRANGEMENT_COUNTERC_H
#define LLFSM_STATIC_ARRANGEMENT_COUNTERC_H

#include "Arrangement_CounterC.h"
#include "CounterC.machine/Machine_CounterC.h"

#define STATIC_ARRANGEMENT_COUNTERC_NUMBER_OF_INSTANCES 1
#ifndef SUSPEND_ALL
#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct LLFSMArrangement *)&static_arrangement_counterc)
#endif // SUSPEND_ALL
#ifndef RESUME_ALL
#define RESUME_ALL() fsm_arrangement_resume_all((struct LLFSMArrangement *)&static_arrangement_counterc)
#endif // RESUME_ALL
#ifndef RESTART_ALL
#define RESTART_ALL() fsm_arrangement_restart_all((struct LLFSMArrangement *)&static_arrangement_counterc)
#endif // RESTART_ALL

struct LLFSMachine;
struct LLFSMArrangement;

/// Static instantiation of a CounterC LLFSM.
extern struct Machine_CounterC static_fsm_counterc;
/// Static instantiation of the CounterC LLFSM state InitialPseudoState.
extern struct FSMCounterC_State_InitialPseudoState static_counterc_state_InitialPseudoState;
/// Static instantiation of the CounterC LLFSM state Initial.
extern struct FSMCounterC_State_Initial static_counterc_state_Initial;
/// Static instantiation of the CounterC LLFSM state CountUp.
extern struct FSMCounterC_State_CountUp static_counterc_state_CountUp;
/// Static instantiation of the CounterC LLFSM state Print.
extern struct FSMCounterC_State_Print static_counterc_state_Print;
/// Static instantiation of the CounterC LLFSM state SUSPENDED.
extern struct FSMCounterC_State_SUSPENDED static_counterc_state_SUSPENDED;
/// Static instantiation of the CounterC LLFSM Arrangement.
extern struct Arrangement_CounterC static_arrangement_counterc;

#endif /* LLFSM_STATIC_ARRANGEMENT_COUNTERC_H */
