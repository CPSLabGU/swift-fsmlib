//
// main.c for running the static LLFSM arrangement named CounterC.
//
// Automatically created through MiCASE -- do not change manually!
//
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "Machine_Common.h"
#include "Arrangement_CounterC.h"
#include "Static_Arrangement_CounterC.h"

int main(int argc, char *argv[])
{
    uintptr_t num_runs = (uintptr_t)(argc > 1 ? strtoull(argv[1], NULL, 10) : ~0ULL);

    if (!arrangement_counterc_validate(&static_arrangement_counterc))
    {
        printf("'static_arrangement_counterc' does not validate!\n");
        return EXIT_FAILURE;
    }

    while (num_runs--)
    {
        fsm_arrangement_execute_once((struct LLFSMArrangement *)&static_arrangement_counterc);
    }

    return EXIT_SUCCESS;
}
