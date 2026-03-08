
// PRISM model generated from LLFSM arrangement FischerDelaysByBooleanSensors
// Model type: mdp (Markov Decision Process)

mdp


// Global Constants

const int NotAThread = 0;



// Global Variables

// Boolean Sensor Variables

global T1NonCriticalSectionDelay : bool init false;

global T1CriticalSectionDelay : bool init false;

global T2NonCriticalSectionDelay : bool init false;

global T2CriticalSectionDelay : bool init false;




// Whiteboard Variables

global SharedX : [..2] init ;








// Scheduler Variables
global turn : [0..2] init 0;

// ============================================================================
// Scheduler Module
// ============================================================================

module SCHEDULER
    scheduler_turn : bool init true;

    [] scheduler_turn ->
        (turn' = (turn + 1) % 3) &
        (scheduler_turn' = false);

    [] !scheduler_turn ->
        (scheduler_turn' = true);
endmodule




// ============================================================================
// State Machine: STARTER (ID: 0)
// ============================================================================

module STARTER
    STARTER_pc : [0..1] init 0;
    
    

    // Initial transition: pseudo-initial to initial state
    [] STARTER_pc=0 & turn=0 & !scheduler_turn ->
        (STARTER_pc'=1);


endmodule





// ============================================================================
// State Machine: THREAD_1 (ID: 1)
// ============================================================================

module THREAD_1
    THREAD_1_pc : [0..5] init 0;
    
    // Local variables
    
    THREAD_1_IamThreadT1 : [..2] init ;
    
    
    

    // Initial transition: pseudo-initial to initial state
    [] THREAD_1_pc=0 & turn=1 & !scheduler_turn ->
        (THREAD_1_pc'=1);


    // Transition: T1NonCriticalSection -> T1Wait
    [] THREAD_1_pc=1 & turn=1 & !scheduler_turn & (T1NonCriticalSectionDelay) ->
        (THREAD_1_pc'=2);


    // Transition: T1Wait -> T1Assign
    [] THREAD_1_pc=2 & turn=1 & !scheduler_turn & ((NotAThread=SharedX)) ->
        (THREAD_1_pc'=3);


    // Transition: T1Assign -> T1Wait
    [] THREAD_1_pc=3 & turn=1 & !scheduler_turn & (!(IamThreadT1=SharedX)) ->
        (THREAD_1_pc'=2);


    // Transition: T1Assign -> T1CriticalSection
    [] THREAD_1_pc=3 & turn=1 & !scheduler_turn & (true) ->
        (THREAD_1_pc'=4);


    // Transition: T1CriticalSection -> T1LetGo
    [] THREAD_1_pc=4 & turn=1 & !scheduler_turn & (T1CriticalSectionDelay) ->
        (THREAD_1_pc'=5);


    // Transition: T1LetGo -> T1NonCriticalSection
    [] THREAD_1_pc=5 & turn=1 & !scheduler_turn & (true) ->
        (THREAD_1_pc'=1);


endmodule





// ============================================================================
// State Machine: THREAD_2 (ID: 2)
// ============================================================================

module THREAD_2
    THREAD_2_pc : [0..5] init 0;
    
    // Local variables
    
    THREAD_2_IamThreadT2 : [..2] init ;
    
    
    

    // Initial transition: pseudo-initial to initial state
    [] THREAD_2_pc=0 & turn=2 & !scheduler_turn ->
        (THREAD_2_pc'=1);


    // Transition: T2NonCriticalSection -> T2Wait
    [] THREAD_2_pc=1 & turn=2 & !scheduler_turn & (T2NonCriticalSectionDelay) ->
        (THREAD_2_pc'=2);


    // Transition: T2Wait -> T2Assign
    [] THREAD_2_pc=2 & turn=2 & !scheduler_turn & ((NotAThread=SharedX)) ->
        (THREAD_2_pc'=3);


    // Transition: T2Assign -> T2Wait
    [] THREAD_2_pc=3 & turn=2 & !scheduler_turn & (!(IamThreadT2=SharedX)) ->
        (THREAD_2_pc'=2);


    // Transition: T2Assign -> T2CriticalSection
    [] THREAD_2_pc=3 & turn=2 & !scheduler_turn & (true) ->
        (THREAD_2_pc'=4);


    // Transition: T2CriticalSection -> T2LetGo
    [] THREAD_2_pc=4 & turn=2 & !scheduler_turn & (T2CriticalSectionDelay) ->
        (THREAD_2_pc'=5);


    // Transition: T2LetGo -> T2NonCriticalSection
    [] THREAD_2_pc=5 & turn=2 & !scheduler_turn & (true) ->
        (THREAD_2_pc'=1);


endmodule




// ============================================================================
// Labels for state properties
// ============================================================================

label "At_STARTER_START" = STARTER_pc=1;


label "At_THREAD_1_T1NonCriticalSection" = THREAD_1_pc=1;


label "At_THREAD_1_T1Wait" = THREAD_1_pc=2;



label "At_THREAD_1_T1Assign" = THREAD_1_pc=3;



label "At_THREAD_1_T1CriticalSection" = THREAD_1_pc=4;



label "At_THREAD_1_T1LetGo" = THREAD_1_pc=5;



label "At_THREAD_2_T2NonCriticalSection" = THREAD_2_pc=1;


label "At_THREAD_2_T2Wait" = THREAD_2_pc=2;



label "At_THREAD_2_T2Assign" = THREAD_2_pc=3;



label "At_THREAD_2_T2CriticalSection" = THREAD_2_pc=4;



label "At_THREAD_2_T2LetGo" = THREAD_2_pc=5;



