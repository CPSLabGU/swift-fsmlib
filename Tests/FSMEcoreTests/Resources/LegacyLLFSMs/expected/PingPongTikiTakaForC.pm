
// PRISM model generated from LLFSM arrangement PingPongTikiTakaForC
// Model type: mdp (Markov Decision Process)

mdp


// Global Variables







// Scheduler Variables
global turn : [0..0] init 0;

// ============================================================================
// Scheduler Module
// ============================================================================

module SCHEDULER
    scheduler_turn : bool init true;

    [] scheduler_turn ->
        (turn' = (turn + 1) % 1) &
        (scheduler_turn' = false);

    [] !scheduler_turn ->
        (scheduler_turn' = true);
endmodule




// ============================================================================
// State Machine: PingPong (ID: 0)
// ============================================================================

module PingPong
    PingPong_pc : [0..3] init 0;
    
    

    // Initial transition: pseudo-initial to initial state
    [] PingPong_pc=0 & turn=0 & !scheduler_turn ->
        (PingPong_pc'=1);


    // Transition: START_PING_PONG -> PING
    [] PingPong_pc=1 & turn=0 & !scheduler_turn & (true) ->
        (PingPong_pc'=2);


    // Transition: PING -> PONG
    [] PingPong_pc=2 & turn=0 & !scheduler_turn & (true) ->
        (PingPong_pc'=3);


    // Transition: PONG -> PING
    [] PingPong_pc=3 & turn=0 & !scheduler_turn & (true) ->
        (PingPong_pc'=2);


endmodule




// ============================================================================
// Labels for state properties
// ============================================================================

label "At_PingPong_START_PING_PONG" = PingPong_pc=1;


label "At_PingPong_PING" = PingPong_pc=2;



label "At_PingPong_PONG" = PingPong_pc=3;



