//
// Machine_Common.c
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine_Common.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-macros"
#pragma clang diagnostic ignored "-Wdeclaration-after-statement"

#ifndef NULL
#define NULL ((void*)0)
#endif
/// Run a ringlet of a C-language LLFSM Arrangement.
///
/// This runs one ringlet of the machines of the given LLFSM arrangement.
///
/// - Parameter arrangement: The machine arrangement to run a ringlet over.
void fsm_arrangement_execute_once(struct LLFSMArrangement * const arrangement)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 0; i < n; i++)
    {
        struct LLFSMachine * const machine = arrangement->machines[i];
        llfsm_execute_once(machine);
    }
}

/// Suspend all machines except for the first one.
///
/// This suspends all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to suspend.
void fsm_arrangement_suspend_all(struct LLFSMArrangement * const arrangement)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const machine = arrangement->machines[i];
        SUSPEND(machine);
    }
}

/// Suspend all machines except for the given machine.
///
/// This suspends all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to suspend.
///   - machine: The machine to be excepted from suspension.
void fsm_arrangement_suspend_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const m = arrangement->machines[i];
        if (m != machine) SUSPEND(machine);
    }
}

/// Resume all machines except for the first one.
///
/// This resumes all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to resume.
void fsm_arrangement_resume_all(struct LLFSMArrangement * const arrangement)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const machine = arrangement->machines[i];
        RESUME(machine);
    }
}

/// Resume all machines except for the given machine.
///
/// This resumes all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to resume.
///   - machine: The machine to be excepted from resumption.
void fsm_arrangement_resume_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const m = arrangement->machines[i];
        if (m != machine) RESUME(machine);
    }
}

/// Restart all machines except for the first one.
///
/// This restarts all LLFSMs in the given arrangement,
/// with the exception of the first machine.
///
/// - Parameter arrangement: The machine arrangement to restart.
void fsm_arrangement_restart_all(struct LLFSMArrangement * const arrangement)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const machine = arrangement->machines[i];
        RESTART(machine);
    }
}

/// Restart all machines except for the given machine.
///
/// This restarts all LLFSMs in the given arrangement,
/// with the exception of machine specified.
///
/// - Parameters:
///   - arrangement: The machine arrangement to restart.
///   - machine: The machine to be excepted from restarting.
void fsm_arrangement_restart_all_except(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)
{
    const uintptr_t n = arrangement->number_of_instances;
    unsigned i;
    for (i = 1; i < n; i++)
    {
        struct LLFSMachine * const m = arrangement->machines[i];
        if (m != machine) RESTART(machine);
    }
}

/// Run a ringlet of a C-language LLFSM.
///
/// - Parameter machine: The machine arrangement to initialise.
void llfsm_execute_once(struct LLFSMachine * const machine)
{
    struct LLFSMState * const current_state = machine->current_state;
    
    if (current_state != machine->previous_state)
    {
        machine->state_time = GET_TIME();
        if (current_state == machine->suspend_state)
        {
            if (machine->previous_state && machine->previous_state->on_suspend) machine->previous_state->on_suspend(machine, machine->previous_state);
            if (current_state->on_suspend) current_state->on_suspend(machine, current_state);
        }
        else if (machine->previous_state == machine->suspend_state)
        {
            if (machine->previous_state && machine->previous_state->on_resume) machine->previous_state->on_resume(machine, machine->previous_state);
            if (current_state->on_resume) current_state->on_resume(machine, current_state);
        }
        current_state->on_entry(machine, current_state);
    }
    TAKE_SNAPSHOT();
    struct LLFSMState * const target_state = current_state->check_transitions(machine, current_state);
    machine->previous_state = current_state;
    if (target_state)
    {
        current_state->on_exit(machine, current_state);
        machine->current_state = target_state;
    }
    else
    {
        current_state->internal(machine, current_state);
    }
}
