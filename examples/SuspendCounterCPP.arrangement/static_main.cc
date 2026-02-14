//
// static_main.cc
//
// Automatically created using fsmconvert -- do not change manually!
//
#include <cstdio>
#include <cstdlib>
#include "Static_Arrangement.h"
#include "StateMachineVector.h"

/// Main function to run the static SuspendCounterCPP arrangement.
///
/// - Parameter argc: The number of command line arguments.
/// - Parameter argv: The command line arguments. If argc > 1, argv[1] is the number of runs.
/// - Returns: EXIT_SUCCESS if the arrangement validates and runs successfully, EXIT_FAILURE otherwise.
int main(int argc, char *argv[])
{
    unsigned long num_runs = argc > 1 ? strtoull(argv[1], nullptr, 10) : ~0UL;

    struct Arrangement_SuspendCounterCPP *arrangement = static_arrangement_suspendcountercpp();
    if (!arrangement_suspendcountercpp_validate(arrangement)) {
        printf("Error: 'static_arrangement_suspendcountercpp' does not validate!\n");
        return EXIT_FAILURE;
    }

    FSM::StateMachineVector *vector = FSM::static_arrangement_suspendcountercpp_vector();

    while (num_runs--) {
        vector->executeOnce();
    }

    return EXIT_SUCCESS;
}