//
// Static_Arrangement_Counter.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_static_arrangement_Counter_h
#define clfsm_static_arrangement_Counter_h

#include "Arrangement_Counter.h"
#include "Counter.machine/Counter.h"
#include "SuspendCounter.machine/SuspendCounter.h"

#define STATIC_ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES 4
#ifndef SUSPEND_ALL
#define SUSPEND_ALL() fsm_arrangement_suspend_all((struct CLFSMArrangement *)&static_arrangement_counter)
#endif // SUSPEND_ALL
#ifndef RESUME_ALL
#define RESUME_ALL() fsm_arrangement_resume_all((struct CLFSMArrangement *)&static_arrangement_counter)
#endif // RESUME_ALL
#ifndef RESTART_ALL
#define RESTART_ALL() fsm_arrangement_restart_all((struct CLFSMArrangement *)&static_arrangement_counter)
#endif // RESTART_ALL

struct CLMachine;
struct CLFSMArrangement;
extern struct SuspendCounter static_fsm_suspendcounter;
extern struct Counter static_fsm_counter;
extern struct Counter static_fsm_counter_1;
extern struct Counter static_fsm_counter_2;

extern struct Arrangement_Counter static_arrangement_counter;

#endif