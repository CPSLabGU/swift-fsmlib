
/*
 * C simulation generated from LLFSM arrangement: FischerConcurrencyAlgorithm
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

/* ======================================================================== */
/* Constants                                                                */
/* ======================================================================== */


#define NotAThread 0

#define GlobalWCET 0


#define MAX_STEPS 20

/* ======================================================================== */
/* State encoding                                                           */
/* ======================================================================== */

/* States for Starter */
#define Starter_DINIT 0
#define Starter_INITIAL 1


/* States for Thread1 */
#define Thread1_DINIT 0
#define Thread1_T1NonCriticalSection 1

#define Thread1_T1WAIT 2

#define Thread1_T1ASSIGN 3

#define Thread1_T1CriticalSection 4

#define Thread1_T1LetGo 5


/* States for Thread2 */
#define Thread2_DINIT 0
#define Thread2_T2NonCriticalSection 1

#define Thread2_T2WAIT 2

#define Thread2_T2ASSIGN 3

#define Thread2_T2CriticalSection 4

#define Thread2_T2LetGo 5



/* State name lookup */

static const char *Starter_state_names[] = {
    "dInitStarter",
    "INITIAL"
};

static const char *Thread1_state_names[] = {
    "dInitThread1",
    "T1NonCriticalSection",
    "T1WAIT",
    "T1ASSIGN",
    "T1CriticalSection",
    "T1LetGo"
};

static const char *Thread2_state_names[] = {
    "dInitThread2",
    "T2NonCriticalSection",
    "T2WAIT",
    "T2ASSIGN",
    "T2CriticalSection",
    "T2LetGo"
};


/* ======================================================================== */
/* Variables                                                                */
/* ======================================================================== */

/* Whiteboard variables */

static int SharedX = 0;





/* Program counter for Starter */
static int pc_Starter = 0;



/* Program counter for Thread1 */
static int pc_Thread1 = 0;

/* Local variables for Thread1 */

static int IamThreadT1 = 0;




/* Program counter for Thread2 */
static int pc_Thread2 = 0;

/* Local variables for Thread2 */

static int IamThreadT2 = 0;





/* ======================================================================== */
/* OnEntry actions                                                          */
/* ======================================================================== */

static void onEntry_Starter_INITIAL(void) {



    printf("%s\n", "Initialise shared varianle");




    SharedX = NotAThread;




}


static void onEntry_Thread1_T1NonCriticalSection(void) {



    printf("%s\n", "In T1 non critical section");




    IamThreadT1 = 1;




}

static void onEntry_Thread1_T1WAIT(void) {

}

static void onEntry_Thread1_T1ASSIGN(void) {




    SharedX = IamThreadT1;




}

static void onEntry_Thread1_T1CriticalSection(void) {



    printf("%s\n", "In T1 critical section");



}

static void onEntry_Thread1_T1LetGo(void) {




    SharedX = NotAThread;




}


static void onEntry_Thread2_T2NonCriticalSection(void) {



    printf("%s\n", "In T2 non critical section");




    IamThreadT2 = 2;




}

static void onEntry_Thread2_T2WAIT(void) {

}

static void onEntry_Thread2_T2ASSIGN(void) {




    SharedX = IamThreadT2;




}

static void onEntry_Thread2_T2CriticalSection(void) {



    printf("%s\n", "In T2 critical section");



}

static void onEntry_Thread2_T2LetGo(void) {




    SharedX = NotAThread;




}



/* ======================================================================== */
/* Step functions                                                           */
/* ======================================================================== */

static void step_Starter(void) {
    int old_pc = pc_Starter;
    /* Pseudo-initial transition */
    if (pc_Starter == Starter_DINIT) {
        pc_Starter = Starter_INITIAL;
        onEntry_Starter_INITIAL();
        printf("  [Starter] dInitStarter -> %s\n", Starter_state_names[pc_Starter]);
        return;
    }
    /* Transitions with priority ordering */

    /* Default: no transition taken */
}

static void step_Thread1(void) {
    int old_pc = pc_Thread1;
    /* Pseudo-initial transition */
    if (pc_Thread1 == Thread1_DINIT) {
        pc_Thread1 = Thread1_T1NonCriticalSection;
        onEntry_Thread1_T1NonCriticalSection();
        printf("  [Thread1] dInitThread1 -> %s\n", Thread1_state_names[pc_Thread1]);
        return;
    }
    /* Transitions with priority ordering */


    /* Transition 0: T1NonCriticalSection -> T1WAIT */
    if (pc_Thread1 == Thread1_T1NonCriticalSection && (1)) {
        pc_Thread1 = Thread1_T1WAIT;
        onEntry_Thread1_T1WAIT();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }



    /* Transition 1: T1WAIT -> T1ASSIGN */
    if (pc_Thread1 == Thread1_T1WAIT && ((NotAThread == SharedX))) {
        pc_Thread1 = Thread1_T1ASSIGN;
        onEntry_Thread1_T1ASSIGN();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }



    /* Transition 2: T1ASSIGN -> T1WAIT */
    if (pc_Thread1 == Thread1_T1ASSIGN && (!(IamThreadT1 == SharedX))) {
        pc_Thread1 = Thread1_T1WAIT;
        onEntry_Thread1_T1WAIT();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }



    /* Transition 3: T1ASSIGN -> T1CriticalSection */
    if (pc_Thread1 == Thread1_T1ASSIGN && (1)) {
        pc_Thread1 = Thread1_T1CriticalSection;
        onEntry_Thread1_T1CriticalSection();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }



    /* Transition 4: T1CriticalSection -> T1LetGo */
    if (pc_Thread1 == Thread1_T1CriticalSection && (1)) {
        pc_Thread1 = Thread1_T1LetGo;
        onEntry_Thread1_T1LetGo();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }



    /* Transition 5: T1LetGo -> T1NonCriticalSection */
    if (pc_Thread1 == Thread1_T1LetGo && (1)) {
        pc_Thread1 = Thread1_T1NonCriticalSection;
        onEntry_Thread1_T1NonCriticalSection();
        printf("  [Thread1] %s -> %s\n", Thread1_state_names[old_pc], Thread1_state_names[pc_Thread1]);
        return;
    }


    /* Default: no transition taken */
}

static void step_Thread2(void) {
    int old_pc = pc_Thread2;
    /* Pseudo-initial transition */
    if (pc_Thread2 == Thread2_DINIT) {
        pc_Thread2 = Thread2_T2NonCriticalSection;
        onEntry_Thread2_T2NonCriticalSection();
        printf("  [Thread2] dInitThread2 -> %s\n", Thread2_state_names[pc_Thread2]);
        return;
    }
    /* Transitions with priority ordering */


    /* Transition 0: T2NonCriticalSection -> T2WAIT */
    if (pc_Thread2 == Thread2_T2NonCriticalSection && (1)) {
        pc_Thread2 = Thread2_T2WAIT;
        onEntry_Thread2_T2WAIT();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
        return;
    }



    /* Transition 1: T2WAIT -> T2ASSIGN */
    if (pc_Thread2 == Thread2_T2WAIT && ((NotAThread == SharedX))) {
        pc_Thread2 = Thread2_T2ASSIGN;
        onEntry_Thread2_T2ASSIGN();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
        return;
    }



    /* Transition 2: T2ASSIGN -> T2WAIT */
    if (pc_Thread2 == Thread2_T2ASSIGN && (!(IamThreadT2 == SharedX))) {
        pc_Thread2 = Thread2_T2WAIT;
        onEntry_Thread2_T2WAIT();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
        return;
    }



    /* Transition 3: T2ASSIGN -> T2CriticalSection */
    if (pc_Thread2 == Thread2_T2ASSIGN && (1)) {
        pc_Thread2 = Thread2_T2CriticalSection;
        onEntry_Thread2_T2CriticalSection();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
        return;
    }



    /* Transition 4: T2CriticalSection -> T2LetGo */
    if (pc_Thread2 == Thread2_T2CriticalSection && (1)) {
        pc_Thread2 = Thread2_T2LetGo;
        onEntry_Thread2_T2LetGo();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
        return;
    }



    /* Transition 5: T2LetGo -> T2NonCriticalSection */
    if (pc_Thread2 == Thread2_T2LetGo && (1)) {
        pc_Thread2 = Thread2_T2NonCriticalSection;
        onEntry_Thread2_T2NonCriticalSection();
        printf("  [Thread2] %s -> %s\n", Thread2_state_names[old_pc], Thread2_state_names[pc_Thread2]);
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

    printf("LLFSM Arrangement: FischerConcurrencyAlgorithm\n");
    printf("Running %d scheduler steps\n\n", steps);

    for (int i = 0; i < steps; i++) {
        printf("Step %d (turn=%d):\n", i, turn);
        switch (turn) {


        case 0:
            step_Starter();
            break;



        case 1:
            step_Thread1();
            break;



        case 2:
            step_Thread2();
            break;


        }
        turn = (turn + 1) % num_machines;
    }

    printf("\nSimulation complete.\n");
    return 0;
}
