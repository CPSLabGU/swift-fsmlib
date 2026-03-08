
/*
 * C simulation generated from LLFSM arrangement: FischerDelaysByBooleanSensors
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

/* ======================================================================== */
/* Constants                                                                */
/* ======================================================================== */


#define NotAThread 0


#define MAX_STEPS 20

/* ======================================================================== */
/* State encoding                                                           */
/* ======================================================================== */

/* States for STARTER */
#define STARTER_DINIT 0
#define STARTER_START 1


/* States for THREAD_1 */
#define THREAD_1_DINIT 0
#define THREAD_1_T1NonCriticalSection 1

#define THREAD_1_T1Wait 2

#define THREAD_1_T1Assign 3

#define THREAD_1_T1CriticalSection 4

#define THREAD_1_T1LetGo 5


/* States for THREAD_2 */
#define THREAD_2_DINIT 0
#define THREAD_2_T2NonCriticalSection 1

#define THREAD_2_T2Wait 2

#define THREAD_2_T2Assign 3

#define THREAD_2_T2CriticalSection 4

#define THREAD_2_T2LetGo 5



/* State name lookup */

static const char *STARTER_state_names[] = {
    "dInitSTARTER",
    "START"
};

static const char *THREAD_1_state_names[] = {
    "dInitTHREAD_1",
    "T1NonCriticalSection",
    "T1Wait",
    "T1Assign",
    "T1CriticalSection",
    "T1LetGo"
};

static const char *THREAD_2_state_names[] = {
    "dInitTHREAD_2",
    "T2NonCriticalSection",
    "T2Wait",
    "T2Assign",
    "T2CriticalSection",
    "T2LetGo"
};


/* ======================================================================== */
/* Variables                                                                */
/* ======================================================================== */

/* Whiteboard variables */

static int SharedX = 0;



/* Boolean sensor variables */

static bool T1NonCriticalSectionDelay = false;

static bool T1CriticalSectionDelay = false;

static bool T2NonCriticalSectionDelay = false;

static bool T2CriticalSectionDelay = false;




/* Program counter for STARTER */
static int pc_STARTER = 0;



/* Program counter for THREAD_1 */
static int pc_THREAD_1 = 0;

/* Local variables for THREAD_1 */

static int IamThreadT1 = 0;




/* Program counter for THREAD_2 */
static int pc_THREAD_2 = 0;

/* Local variables for THREAD_2 */

static int IamThreadT2 = 0;





/* ======================================================================== */
/* OnEntry actions                                                          */
/* ======================================================================== */

static void onEntry_STARTER_START(void) {



    printf("%s\n", "Initialise shared variable");




    SharedX = NotAThread;




}


static void onEntry_THREAD_1_T1NonCriticalSection(void) {



    printf("%s\n", "T1 in non-critical section");




    IamThreadT1 = 1;




}

static void onEntry_THREAD_1_T1Wait(void) {

}

static void onEntry_THREAD_1_T1Assign(void) {




    SharedX = IamThreadT1;




}

static void onEntry_THREAD_1_T1CriticalSection(void) {

}

static void onEntry_THREAD_1_T1LetGo(void) {




    SharedX = NotAThread;




}


static void onEntry_THREAD_2_T2NonCriticalSection(void) {



    printf("%s\n", "T2 in non-critical section");




    IamThreadT2 = 2;




}

static void onEntry_THREAD_2_T2Wait(void) {

}

static void onEntry_THREAD_2_T2Assign(void) {




    SharedX = IamThreadT2;




}

static void onEntry_THREAD_2_T2CriticalSection(void) {

}

static void onEntry_THREAD_2_T2LetGo(void) {




    SharedX = NotAThread;




}



/* ======================================================================== */
/* Step functions                                                           */
/* ======================================================================== */

static void step_STARTER(void) {
    int old_pc = pc_STARTER;
    /* Pseudo-initial transition */
    if (pc_STARTER == STARTER_DINIT) {
        pc_STARTER = STARTER_START;
        onEntry_STARTER_START();
        printf("  [STARTER] dInitSTARTER -> %s\n", STARTER_state_names[pc_STARTER]);
        return;
    }
    /* Transitions with priority ordering */

    /* Default: no transition taken */
}

static void step_THREAD_1(void) {
    int old_pc = pc_THREAD_1;
    /* Pseudo-initial transition */
    if (pc_THREAD_1 == THREAD_1_DINIT) {
        pc_THREAD_1 = THREAD_1_T1NonCriticalSection;
        onEntry_THREAD_1_T1NonCriticalSection();
        printf("  [THREAD_1] dInitTHREAD_1 -> %s\n", THREAD_1_state_names[pc_THREAD_1]);
        return;
    }
    /* Transitions with priority ordering */


    /* Transition 0: T1NonCriticalSection -> T1Wait */
    if (pc_THREAD_1 == THREAD_1_T1NonCriticalSection && (T1NonCriticalSectionDelay)) {
        pc_THREAD_1 = THREAD_1_T1Wait;
        onEntry_THREAD_1_T1Wait();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }



    /* Transition 1: T1Wait -> T1Assign */
    if (pc_THREAD_1 == THREAD_1_T1Wait && ((NotAThread == SharedX))) {
        pc_THREAD_1 = THREAD_1_T1Assign;
        onEntry_THREAD_1_T1Assign();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }



    /* Transition 2: T1Assign -> T1Wait */
    if (pc_THREAD_1 == THREAD_1_T1Assign && (!(IamThreadT1 == SharedX))) {
        pc_THREAD_1 = THREAD_1_T1Wait;
        onEntry_THREAD_1_T1Wait();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }



    /* Transition 3: T1Assign -> T1CriticalSection */
    if (pc_THREAD_1 == THREAD_1_T1Assign && (1)) {
        pc_THREAD_1 = THREAD_1_T1CriticalSection;
        onEntry_THREAD_1_T1CriticalSection();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }



    /* Transition 4: T1CriticalSection -> T1LetGo */
    if (pc_THREAD_1 == THREAD_1_T1CriticalSection && (T1CriticalSectionDelay)) {
        pc_THREAD_1 = THREAD_1_T1LetGo;
        onEntry_THREAD_1_T1LetGo();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }



    /* Transition 5: T1LetGo -> T1NonCriticalSection */
    if (pc_THREAD_1 == THREAD_1_T1LetGo && (1)) {
        pc_THREAD_1 = THREAD_1_T1NonCriticalSection;
        onEntry_THREAD_1_T1NonCriticalSection();
        printf("  [THREAD_1] %s -> %s\n", THREAD_1_state_names[old_pc], THREAD_1_state_names[pc_THREAD_1]);
        return;
    }


    /* Default: no transition taken */
}

static void step_THREAD_2(void) {
    int old_pc = pc_THREAD_2;
    /* Pseudo-initial transition */
    if (pc_THREAD_2 == THREAD_2_DINIT) {
        pc_THREAD_2 = THREAD_2_T2NonCriticalSection;
        onEntry_THREAD_2_T2NonCriticalSection();
        printf("  [THREAD_2] dInitTHREAD_2 -> %s\n", THREAD_2_state_names[pc_THREAD_2]);
        return;
    }
    /* Transitions with priority ordering */


    /* Transition 0: T2NonCriticalSection -> T2Wait */
    if (pc_THREAD_2 == THREAD_2_T2NonCriticalSection && (T2NonCriticalSectionDelay)) {
        pc_THREAD_2 = THREAD_2_T2Wait;
        onEntry_THREAD_2_T2Wait();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }



    /* Transition 1: T2Wait -> T2Assign */
    if (pc_THREAD_2 == THREAD_2_T2Wait && ((NotAThread == SharedX))) {
        pc_THREAD_2 = THREAD_2_T2Assign;
        onEntry_THREAD_2_T2Assign();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }



    /* Transition 2: T2Assign -> T2Wait */
    if (pc_THREAD_2 == THREAD_2_T2Assign && (!(IamThreadT2 == SharedX))) {
        pc_THREAD_2 = THREAD_2_T2Wait;
        onEntry_THREAD_2_T2Wait();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }



    /* Transition 3: T2Assign -> T2CriticalSection */
    if (pc_THREAD_2 == THREAD_2_T2Assign && (1)) {
        pc_THREAD_2 = THREAD_2_T2CriticalSection;
        onEntry_THREAD_2_T2CriticalSection();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }



    /* Transition 4: T2CriticalSection -> T2LetGo */
    if (pc_THREAD_2 == THREAD_2_T2CriticalSection && (T2CriticalSectionDelay)) {
        pc_THREAD_2 = THREAD_2_T2LetGo;
        onEntry_THREAD_2_T2LetGo();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }



    /* Transition 5: T2LetGo -> T2NonCriticalSection */
    if (pc_THREAD_2 == THREAD_2_T2LetGo && (1)) {
        pc_THREAD_2 = THREAD_2_T2NonCriticalSection;
        onEntry_THREAD_2_T2NonCriticalSection();
        printf("  [THREAD_2] %s -> %s\n", THREAD_2_state_names[old_pc], THREAD_2_state_names[pc_THREAD_2]);
        return;
    }


    /* Default: no transition taken */
}


/* ======================================================================== */
/* Main: round-robin scheduler                                              */
/* ======================================================================== */
int main(int argc, char **argv) {
    int turn = 0;
    int num_machines = 3;
    int steps = MAX_STEPS;

    printf("LLFSM Arrangement: FischerDelaysByBooleanSensors\n");
    printf("Running %d scheduler steps\n\n", steps);

    for (int i = 0; i < steps; i++) {
        printf("Step %d (turn=%d):\n", i, turn);
        switch (turn) {


        case 0:
            step_STARTER();
            break;



        case 1:
            step_THREAD_1();
            break;



        case 2:
            step_THREAD_2();
            break;


        }
        turn = (turn + 1) % num_machines;
    }

    printf("\nSimulation complete.\n");
    return 0;
}
