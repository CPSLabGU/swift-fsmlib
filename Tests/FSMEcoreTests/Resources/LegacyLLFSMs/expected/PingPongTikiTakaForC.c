
/*
 * C simulation generated from LLFSM arrangement: PingPongTikiTakaForC
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

/* ======================================================================== */
/* Constants                                                                */
/* ======================================================================== */

#define MAX_STEPS 20

/* ======================================================================== */
/* State encoding                                                           */
/* ======================================================================== */

/* States for PingPong */
#define PingPong_DINIT 0
#define PingPong_START_PING_PONG 1

#define PingPong_PING 2

#define PingPong_PONG 3



/* State name lookup */

static const char *PingPong_state_names[] = {
    "dInitPingPong",
    "START_PING_PONG",
    "PING",
    "PONG"
};


/* ======================================================================== */
/* Variables                                                                */
/* ======================================================================== */




/* Program counter for PingPong */
static int pc_PingPong = 0;




/* ======================================================================== */
/* OnEntry actions                                                          */
/* ======================================================================== */

static void onEntry_PingPong_START_PING_PONG(void) {



    printf("%s\n", "Start Ping Pong");



}

static void onEntry_PingPong_PING(void) {



    printf("%s\n", "ping");



}

static void onEntry_PingPong_PONG(void) {



    printf("%s\n", "pong");



}



/* ======================================================================== */
/* Step functions                                                           */
/* ======================================================================== */

static void step_PingPong(void) {
    int old_pc = pc_PingPong;
    /* Pseudo-initial transition */
    if (pc_PingPong == PingPong_DINIT) {
        pc_PingPong = PingPong_START_PING_PONG;
        onEntry_PingPong_START_PING_PONG();
        printf("  [PingPong] dInitPingPong -> %s\n", PingPong_state_names[pc_PingPong]);
        return;
    }
    /* Transitions with priority ordering */


    /* Transition 0: START_PING_PONG -> PING */
    if (pc_PingPong == PingPong_START_PING_PONG && (1)) {
        pc_PingPong = PingPong_PING;
        onEntry_PingPong_PING();
        printf("  [PingPong] %s -> %s\n", PingPong_state_names[old_pc], PingPong_state_names[pc_PingPong]);
        return;
    }



    /* Transition 1: PING -> PONG */
    if (pc_PingPong == PingPong_PING && (1)) {
        pc_PingPong = PingPong_PONG;
        onEntry_PingPong_PONG();
        printf("  [PingPong] %s -> %s\n", PingPong_state_names[old_pc], PingPong_state_names[pc_PingPong]);
        return;
    }



    /* Transition 2: PONG -> PING */
    if (pc_PingPong == PingPong_PONG && (1)) {
        pc_PingPong = PingPong_PING;
        onEntry_PingPong_PING();
        printf("  [PingPong] %s -> %s\n", PingPong_state_names[old_pc], PingPong_state_names[pc_PingPong]);
        return;
    }


    /* Default: no transition taken */
}


/* ======================================================================== */
/* Main: round-robin scheduler                                              */
/* ======================================================================== */
int main(int argc, char **argv) {
    int turn = 0;
    int num_machines = 1;
    int steps = MAX_STEPS;

    printf("LLFSM Arrangement: PingPongTikiTakaForC\n");
    printf("Running %d scheduler steps\n\n", steps);

    for (int i = 0; i < steps; i++) {
        printf("Step %d (turn=%d):\n", i, turn);
        switch (turn) {


        case 0:
            step_PingPong();
            break;


        }
        turn = (turn + 1) % num_machines;
    }

    printf("\nSimulation complete.\n");
    return 0;
}
