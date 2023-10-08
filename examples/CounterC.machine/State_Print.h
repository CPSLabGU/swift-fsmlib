//
// State_Print.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_COUNTERC_PRINT_H
#define LLFSM_COUNTERC_PRINT_H

#include <stdbool.h>
#include "Machine_CounterC_Includes.h"
#include "State_Print_Includes.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

#define MACHINE_COUNTERC_NUMBER_OF_TRANSITIONS 5

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvisibility"

struct FSMCounterC_State_Print
{
    struct LLFSMState *(*check_transitions)(const struct LLFSMachine *, const struct LLFSMState *);
    void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);
    void (*internal)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);

#   include "State_Print_Variables.h"
};

/// Initialise the given state.
///
/// - Parameter state: The state to initialise.
void fsm_counterc_print_init(struct FSMCounterC_State_Print * const state);

/// Validate the given state.
///
/// - Parameter state: The state to initialise.
bool fsm_counterc_print_validate(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_Print * const state);

/// Check the sequence of transitions for Print.
///
/// - Returns: The state the machine transitions to (`NULL` if no transition fired).
struct LLFSMState *fsm_counterc_print_check_transitions(const struct Machine_CounterC * const machine, const struct FSMCounterC_State_Print * const state);

/// The onEntry function for Print.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was entered.
void fsm_counterc_print_on_entry(struct Machine_CounterC * const machine, struct FSMCounterC_State_Print * const state);

/// The onExit function for Print.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being exited.
void fsm_counterc_print_on_exit(struct Machine_CounterC * const machine, struct FSMCounterC_State_Print * const state);

/// The internal action for Print.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state whose internal action to execute.
void fsm_counterc_print_internal(struct Machine_CounterC * const machine, struct FSMCounterC_State_Print * const state);

/// The onSuspend function for Print.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was suspended.
void fsm_counterc_print_on_suspend(struct Machine_CounterC * const machine, struct FSMCounterC_State_Print * const state);

/// The onResume function for Print.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being resumed.
void fsm_counterc_print_on_resume(struct Machine_CounterC * const machine, struct FSMCounterC_State_Print * const state);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#endif /* LLFSM_COUNTERC_PRINT_H */
