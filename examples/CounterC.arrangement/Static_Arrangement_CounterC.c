//
// Static_Arrangement_CounterC.c
//
// Automatically created through MiCASE -- do not change manually!
//
#include <stdbool.h>
#include "Machine_Common.h"
#include "Arrangement_CounterC.h"
#include "Static_Arrangement_CounterC.h"

#include "CounterC.machine/Machine_CounterC.h"
#include "CounterC.machine/State_InitialPseudoState.h"
#include "CounterC.machine/State_Initial.h"
#include "CounterC.machine/State_CountUp.h"
#include "CounterC.machine/State_Print.h"
#include "CounterC.machine/State_SUSPENDED.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif

#include <stdbool.h>

/// Static instantiation of a CounterC LLFSM.
struct Machine_CounterC static_fsm_counterc = {
    .current_state = (struct LLFSMState *) &static_counterc_state_InitialPseudoState,
    .suspend_state = (struct LLFSMState *) &static_counterc_state_SUSPENDED,
    .states = {
        (struct LLFSMState *) &static_counterc_state_InitialPseudoState,
        (struct LLFSMState *) &static_counterc_state_Initial,
        (struct LLFSMState *) &static_counterc_state_CountUp,
        (struct LLFSMState *) &static_counterc_state_Print,
        (struct LLFSMState *) &static_counterc_state_SUSPENDED
    }
};

/// Static instantiation of the CounterC LLFSM state InitialPseudoState.
struct FSMCounterC_State_InitialPseudoState static_counterc_state_InitialPseudoState = {
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counterc_initialpseudostate_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initialpseudostate_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initialpseudostate_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initialpseudostate_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initialpseudostate_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initialpseudostate_on_resume
};
/// Static instantiation of the CounterC LLFSM state Initial.
struct FSMCounterC_State_Initial static_counterc_state_Initial = {
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counterc_initial_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initial_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initial_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initial_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initial_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_initial_on_resume
};
/// Static instantiation of the CounterC LLFSM state CountUp.
struct FSMCounterC_State_CountUp static_counterc_state_CountUp = {
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counterc_countup_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_countup_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_countup_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_countup_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_countup_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_countup_on_resume
};
/// Static instantiation of the CounterC LLFSM state Print.
struct FSMCounterC_State_Print static_counterc_state_Print = {
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counterc_print_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_print_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_print_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_print_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_print_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_print_on_resume
};
/// Static instantiation of the CounterC LLFSM state SUSPENDED.
struct FSMCounterC_State_SUSPENDED static_counterc_state_SUSPENDED = {
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counterc_suspended_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_suspended_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_suspended_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_suspended_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_suspended_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counterc_suspended_on_resume
};

/// Static instantiation of the CounterC LLFSM Arrangement.
struct Arrangement_CounterC static_arrangement_counterc = {
    .number_of_instances = STATIC_ARRANGEMENT_COUNTERC_NUMBER_OF_INSTANCES,
    {
        .fsm_counterc = &static_fsm_counterc
    },
};
