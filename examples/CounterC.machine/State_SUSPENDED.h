//
// State_SUSPENDED.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_COUNTERC_SUSPENDED_H
#define LLFSM_COUNTERC_SUSPENDED_H

#include <stdbool.h>
#include "Machine_CounterC_Includes.h"
#include "State_SUSPENDED_Includes.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

#define MACHINE_COUNTERC_NUMBER_OF_TRANSITIONS 5

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvisibility"

struct FSMCounterC_State_SUSPENDED
{
    struct LLFSMState *(*check_transitions)(const struct LLFSMachine *, const struct LLFSMState *);
    void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);
    void (*internal)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);

#   include "State_SUSPENDED_Variables.h"
};

/// Initialise the given state.
///
/// - Parameter state: The state to initialise.
void fsm_counterc_suspended_init(struct FSMCounterC_State_SUSPENDED * const state);

/// Validate the given state.
///
/// - Parameter state: The state to initialise.
bool fsm_counterc_suspended_validate(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_SUSPENDED * const state);

/// Check the sequence of transitions for SUSPENDED.
///
/// - Returns: The state the machine transitions to (`NULL` if no transition fired).
struct LLFSMState *fsm_counterc_suspended_check_transitions(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_SUSPENDED * const state);

/// The onEntry function for SUSPENDED.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was entered.
void fsm_counterc_suspended_on_entry(struct Machine_CounterC * const machine, struct FSMCounterC_State_SUSPENDED * const state);

/// The onExit function for SUSPENDED.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being exited.
void fsm_counterc_suspended_on_exit(struct Machine_CounterC * const machine, struct FSMCounterC_State_SUSPENDED * const state);

/// The internal action for SUSPENDED.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state whose internal action to execute.
void fsm_counterc_suspended_internal(struct Machine_CounterC * const machine, struct FSMCounterC_State_SUSPENDED * const state);

/// The onSuspend function for SUSPENDED.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was suspended.
void fsm_counterc_suspended_on_suspend(struct Machine_CounterC * const machine, struct FSMCounterC_State_SUSPENDED * const state);

/// The onResume function for SUSPENDED.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being resumed.
void fsm_counterc_suspended_on_resume(struct Machine_CounterC * const machine, struct FSMCounterC_State_SUSPENDED * const state);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#endif /* LLFSM_COUNTERC_SUSPENDED_H */
