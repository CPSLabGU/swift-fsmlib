//
// main.c for running the static LLFSM arrangement named SuspendCounter.
//
// Automatically created using fsmconvert -- do not change manually!
//
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "Machine_Common.h"
#include "Arrangement_SuspendCounter.h"
#include "Static_Arrangement.h"

int main(int argc, char *argv[]){
    uintptr_t num_runs = (uintptr_t)(argc > 1 ? strtoull(argv[1], NULL, 10) : ~0ULL);
    
    if (!arrangement_suspendcounter_validate(&static_arrangement_suspendcounter))
    {
        printf("'static_arrangement_suspendcounter' does not validate!\n");
        return EXIT_FAILURE;
    }
    
    while (num_runs--)
    {
        fsm_arrangement_execute_once((struct LLFSMArrangement *)&static_arrangement_suspendcounter);
    }
    
    return EXIT_SUCCESS;
}
