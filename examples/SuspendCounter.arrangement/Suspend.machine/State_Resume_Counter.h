//
// State_Resume_Counter.h
//
// Automatically created using fsmconvert -- do not change manually!
//
#ifndef LLFSM_SUSPEND_RESUME_COUNTER_H
#define LLFSM_SUSPEND_RESUME_COUNTER_H

#include <stdbool.h>
#include "Machine_Suspend_Includes.h"
#include "State_Resume_Counter_Includes.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

#define MACHINE_SUSPEND_NUMBER_OF_TRANSITIONS 4

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvisibility"

struct FSMSuspend_State_Resume_Counter
{
    struct LLFSMState *(*check_transitions)(const struct LLFSMachine *, const struct LLFSMState *);
    void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);
    void (*internal)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);

#   include "State_Resume_Counter_Variables.h"
};

/// Initialise the given state.
///
/// - Parameter state: The state to initialise.
void fsm_suspend_resume_counter_init(struct FSMSuspend_State_Resume_Counter * const state);

/// Validate the given state.
///
/// - Parameter state: The state to initialise.
bool fsm_suspend_resume_counter_validate(const struct Machine_Suspend * const machine, const struct FSMSuspend_State_Resume_Counter * const state);

/// Check the sequence of transitions for Resume_Counter.
///
/// - Returns: The state the machine transitions to (`NULL` if no transition fired).
struct LLFSMState *fsm_suspend_resume_counter_check_transitions(const struct Machine_Suspend * const machine, const struct FSMSuspend_State_Resume_Counter * const state);

/// The onEntry function for Resume_Counter.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was entered.
void fsm_suspend_resume_counter_on_entry(struct Machine_Suspend * const machine, struct FSMSuspend_State_Resume_Counter * const state);

/// The onExit function for Resume_Counter.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being exited.
void fsm_suspend_resume_counter_on_exit(struct Machine_Suspend * const machine, struct FSMSuspend_State_Resume_Counter * const state);

/// The internal action for Resume_Counter.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state whose internal action to execute.
void fsm_suspend_resume_counter_internal(struct Machine_Suspend * const machine, struct FSMSuspend_State_Resume_Counter * const state);

/// The onSuspend function for Resume_Counter.
///
/// - Parameters:
///   - machine: The machine that entered the state.
///   - state: The state that was suspended.
void fsm_suspend_resume_counter_on_suspend(struct Machine_Suspend * const machine, struct FSMSuspend_State_Resume_Counter * const state);

/// The onResume function for Resume_Counter.
///
/// - Parameters:
///   - machine: The machine this function belongs to.
///   - state: The state being resumed.
void fsm_suspend_resume_counter_on_resume(struct Machine_Suspend * const machine, struct FSMSuspend_State_Resume_Counter * const state);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#endif /* LLFSM_SUSPEND_RESUME_COUNTER_H */
