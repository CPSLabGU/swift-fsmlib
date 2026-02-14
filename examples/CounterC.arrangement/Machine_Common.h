//
// Machine_Common.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef LLFSM_ARRANGEMENT_COMMON_H
#define LLFSM_ARRANGEMENT_COMMON_H

#include <inttypes.h>
#include <stdbool.h>

#ifdef INCLUDE_MACHINE_CUSTOM
#include "Machine_Custom.h"
#endif

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunknown-pragmas"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"

#ifndef IS_SUSPENSIBLE
#define IS_SUSPENSIBLE(m) (!!(m)->suspend_state)
#endif
#ifndef IS_SUSPENDED
#define IS_SUSPENDED(m) ((m)->suspend_state == (m)->current_state)
#endif
#ifndef SUSPEND
#define SUSPEND(m) ((m)->suspend_state && ((m)->resume_state = (m)->current_state == (m)->suspend_state ? (m)->resume_state : (m)->current_state) && ((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->suspend_state))
#endif
#ifndef RESUME
#define RESUME(m)  ((m)->suspend_state && (m)->current_state == (m)->suspend_state && ((m)->current_state = (m)->resume_state ? (m)->resume_state : ((m)->previous_state && (m)->previous_state != (m)->suspend_state ? (m)->previous_state : (m)->states[0])) && ((m)->previous_state = (m)->suspend_state))
#endif
#ifndef RESTART
#define RESTART(m) (((m)->previous_state = (m)->current_state) && ((m)->current_state = (m)->states[0]))
#endif
#ifndef GET_TIME
#define GET_TIME() (machine->state_time + 1)
#endif
#ifndef TAKE_SNAPSHOT
#define TAKE_SNAPSHOT()
#endif

struct LLFSMState;
struct LLFSMachine;

/// A generic LLFSM Arrangement.
struct LLFSMArrangement
{
    /// The number of instances in this arrangement.
    uintptr_t number_of_instances;
    struct LLFSMachine *machines[1];
};

#ifndef STRUCT_LLFSMACHINE_
#define STRUCT_LLFSMACHINE_
/// A generic LLFSM.
struct LLFSMachine
{
    struct LLFSMState *current_state;
    struct LLFSMState *previous_state;
    uintptr_t          state_time;
    struct LLFSMState *suspend_state;
    struct LLFSMState *resume_state;
    struct LLFSMState * const states[1];
};
#endif // STRUCT_LLFSMACHINE_

#ifndef STRUCT_LLFSMSTATE_
#define STRUCT_LLFSMSTATE_
struct LLFSMState
{
    struct LLFSMState *(*check_transitions)(const struct LLFSMachine * const, const struct LLFSMState * const);
    void (*on_entry)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_exit) (struct LLFSMachine *, struct LLFSMState *);
    void (*internal)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_suspend)(struct LLFSMachine *, struct LLFSMState *);
    void (*on_resume) (struct LLFSMachine *, struct LLFSMState *);
};
#endif // STRUCT_LLFSMSTATE_
/// Run a ringlet of a C-language LLFSM Arrangement.
///
/// This runs one ringlet of the machines of the given LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to run a ringlet over.
void fsm_arrangement_execute_once(struct LLFSMArrangement * const arrangement);

/// Suspend all machines except for the first one.
///
/// This suspends all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to suspend.
void fsm_arrangement_suspend_all(struct LLFSMArrangement * const arrangement);

/// Suspend all machines except for the given machine.
///
/// This suspends all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to suspend.
///   - machine: The machine to be excepted from suspension.
void fsm_arrangement_suspend_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);

/// Resume all machines except for the first one.
///
/// This resumes all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to resume.
void fsm_arrangement_resume_all(struct LLFSMArrangement * const arrangement);

/// Resume all machines except for the given machine.
///
/// This resumes all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to resume.
///   - machine: The machine to be excepted from resumption.
void fsm_arrangement_resume_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);

/// Restart all machines except for the first one.
///
/// This restarts all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to restart.
void fsm_arrangement_restart_all(struct LLFSMArrangement * const arrangement);

/// Restart all machines except for the given machine.
///
/// This restarts all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to restart.
///   - machine: The machine to be excepted from restarting.
void fsm_arrangement_restart_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine);

/// Run a ringlet of a C-language LLFSM.
///
/// - Parameter machine: The machine arrangement to initialise.
void llfsm_execute_once(struct LLFSMachine * const machine);

#pragma clang diagnostic pop
#pragma GCC diagnostic pop


#endif /* LLFSM_ARRANGEMENT_COMMON_H */
