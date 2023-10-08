//
// State_Initial.c
//
// Automatically created using fsmconvert -- do not change manually!
//
#include "Machine_CounterC.h"
#include "State_Initial.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-function-pointer-types"
#pragma clang diagnostic ignored "-Wcompare-distinct-pointer-types"
#pragma clang diagnostic ignored "-Wvisibility"

/// Initialise the given Initial state.
///
/// - Parameter state: The state to initialise.
void fsm_counterc_initial_init(struct FSMCounterC_State_Initial * const state)
{
    state->check_transitions = (struct LLFSMState *(*)(const struct LLFSMachine *, const struct LLFSMState *))fsm_counterc_initial_check_transitions;
    state->on_entry   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_entry;
    state->on_exit    = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_exit;
    state->internal   = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_internal;
    state->on_suspend = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_suspend;
    state->on_resume  = (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_resume;
}

/// Check the validity of the given Initial state.
///
/// - Parameter state: The state to validate.
bool fsm_counterc_initial_validate(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_Initial * const state)
{
    (void)machine;
    return state->check_transitions == (struct LLFSMState *(*)(const struct LLFSMachine * const machine, const struct LLFSMState * const state))fsm_counterc_initial_check_transitions &&
           state->on_entry   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_entry &&
           state->on_exit    == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_exit &&
           state->internal   == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_internal &&
           state->on_suspend == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_suspend &&
           state->on_resume  == (void (*)(struct LLFSMachine *, struct LLFSMState *))fsm_counterc_initial_on_resume;
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

/// The onEntry function for Initial.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was entered.
void fsm_counterc_initial_on_entry(struct Machine_CounterC * const machine, struct FSMCounterC_State_Initial * const state)
{
#   include "State_Initial_OnEntry.mm"
}

/// The onExit function for Initial.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being exited.
void fsm_counterc_initial_on_exit(struct Machine_CounterC * const machine, struct FSMCounterC_State_Initial * const state)
{
#   include "State_Initial_OnExit.mm"
}

/// The internal action for Initial.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state whose internal action to execute.
void fsm_counterc_initial_internal(struct Machine_CounterC * const machine, struct FSMCounterC_State_Initial * const state)
{
#   include "State_Initial_Internal.mm"
}

/// The onSuspend function for Initial.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was suspended.
void fsm_counterc_initial_on_suspend(struct Machine_CounterC * const machine, struct FSMCounterC_State_Initial * const state)
{
#   include "State_Initial_OnSuspend.mm"
}

/// The onResume function for Initial.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being resumed.
void fsm_counterc_initial_on_resume(struct Machine_CounterC * const machine, struct FSMCounterC_State_Initial * const state)
{
#   include "State_Initial_OnResume.mm"
}

/// Check the sequence of transitions for Initial.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being resumed.
/// - Returns: The state the machine transitions to (`NULL` if no transition fired).
struct LLFSMState *fsm_counterc_initial_check_transitions(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_Initial * const state)
{
    if (
        #include "State_Initial_Transition_0.expr"
    ) return machine->states[2];
    return NULL; // None of the transitions fired.
}
