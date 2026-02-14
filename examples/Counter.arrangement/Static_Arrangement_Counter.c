//
// Static_Arrangement_Counter.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include <stdbool.h>
#include "Machine_Common.h"
#include "Arrangement_Counter.h"
#include "Static_Arrangement_Counter.h"
#include "Counter.machine/Machine_Counter.h"
#include "Counter.machine/State_InitialPseudoState.h"
#include "Counter.machine/State_Initial.h"
#include "Counter.machine/State_CountUp.h"
#include "Counter.machine/State_Print.h"
#include "Counter.machine/State_SUSPENDED.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef NULL
#define NULL ((void*)0)
#endif
#include <stdbool.h>

/// Static instantiation of a Counter LLFSM.
struct Machine_Counter static_fsm_counter = 
{
    .current_state = (struct LLFSMState *) &static_counter_state_InitialPseudoState,
    .suspend_state = (struct LLFSMState *) &static_counter_state_SUSPENDED,
    .states =
    {
        (struct LLFSMState *) &static_counter_state_InitialPseudoState,
        (struct LLFSMState *) &static_counter_state_Initial,
        (struct LLFSMState *) &static_counter_state_CountUp,
        (struct LLFSMState *) &static_counter_state_Print,
        (struct LLFSMState *) &static_counter_state_SUSPENDED
    }
};

/// Static instantiation of the Counter LLFSM state InitialPseudoState.
struct FSMCounter_State_InitialPseudoState static_counter_state_InitialPseudoState = 
{
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counter_initialpseudostate_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initialpseudostate_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initialpseudostate_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initialpseudostate_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initialpseudostate_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initialpseudostate_on_resume
};
/// Static instantiation of the Counter LLFSM state Initial.
struct FSMCounter_State_Initial static_counter_state_Initial = 
{
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counter_initial_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initial_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initial_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initial_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initial_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_initial_on_resume
};
/// Static instantiation of the Counter LLFSM state CountUp.
struct FSMCounter_State_CountUp static_counter_state_CountUp = 
{
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counter_countup_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_countup_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_countup_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_countup_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_countup_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_countup_on_resume
};
/// Static instantiation of the Counter LLFSM state Print.
struct FSMCounter_State_Print static_counter_state_Print = 
{
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counter_print_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_print_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_print_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_print_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_print_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_print_on_resume
};
/// Static instantiation of the Counter LLFSM state SUSPENDED.
struct FSMCounter_State_SUSPENDED static_counter_state_SUSPENDED = 
{
    .check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *)) fsm_counter_suspended_check_transitions,
    .on_entry = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_suspended_on_entry,
    .on_exit = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_suspended_on_exit,
    .internal = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_suspended_internal,
    .on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_suspended_on_suspend,
    .on_resume = (void (*)(struct LLFSMachine *, struct LLFSMState *)) fsm_counter_suspended_on_resume
};
/// Static instantiation of the Counter LLFSM Arrangement.
struct Arrangement_Counter static_arrangement_counter =
{
    .number_of_instances = STATIC_ARRANGEMENT_COUNTER_NUMBER_OF_INSTANCES,
    {
        .fsm_counter = &static_fsm_counter
    },
};
