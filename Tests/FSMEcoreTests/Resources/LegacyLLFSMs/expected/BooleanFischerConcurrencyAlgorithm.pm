
// PRISM model generated from LLFSM arrangement BooleanFischerConcurrencyAlgorithm
// Model type: mdp (Markov Decision Process)

mdp


// Global Constants

const int NotAThread = 0;

const int GlobalWCET = 0;



// Global Variables

// Boolean Sensor Variables

global Thread1NonCriticalSectionDelay : bool init false;

global Thread1CriticalSectionDelay : bool init false;

global Thread2NonCriticalSectionDelay : bool init false;

global Thread2CriticalSectionDelay : bool init false;




// Whiteboard Variables

global sharedX : [0..2] init 0;








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
// State Machine: Starter (ID: 0)
// ============================================================================

module Starter
    Starter_pc : [0..1] init 0;
    
    

    // Initial transition: pseudo-initial to initial state
    [] Starter_pc=0 & turn=0 & !scheduler_turn ->
        (Starter_pc'=1);


endmodule





// ============================================================================
// State Machine: Thread1 (ID: 1)
// ============================================================================

module Thread1
    Thread1_pc : [0..6] init 0;
    
    // Local variables
    
    Thread1_IamThreadT1 : [0..2] init 0;
    
    
    

    // Initial transition: pseudo-initial to initial state
    [] Thread1_pc=0 & turn=1 & !scheduler_turn ->
        (Thread1_pc'=1);


    // Transition: T1NonCriticalSection -> T1WAIT
    [] Thread1_pc=1 & turn=1 & !scheduler_turn & (Thread1NonCriticalSectionDelay) ->
        (Thread1_pc'=2);


    // Transition: T1WAIT -> T1NonAtomicAtoB
    [] Thread1_pc=2 & turn=1 & !scheduler_turn & ((NotAThread=sharedX)) ->
        (Thread1_pc'=3);


    // Transition: T1NonAtomicAtoB -> T1ASSIGN
    [] Thread1_pc=3 & turn=1 & !scheduler_turn & (true) ->
        (Thread1_pc'=4);


    // Transition: T1ASSIGN -> T1WAIT
    [] Thread1_pc=4 & turn=1 & !scheduler_turn & (!(IamThreadT1=sharedX)) ->
        (Thread1_pc'=2);


    // Transition: T1ASSIGN -> T1CriticalSection
    [] Thread1_pc=4 & turn=1 & !scheduler_turn & (true) ->
        (Thread1_pc'=5);


    // Transition: T1CriticalSection -> T1LetGo
    [] Thread1_pc=5 & turn=1 & !scheduler_turn & (Thread1CriticalSectionDelay) ->
        (Thread1_pc'=6);


    // Transition: T1LetGo -> T1NonCriticalSection
    [] Thread1_pc=6 & turn=1 & !scheduler_turn & (true) ->
        (Thread1_pc'=1);


endmodule





// ============================================================================
// State Machine: Thread2 (ID: 2)
// ============================================================================

module Thread2
    Thread2_pc : [0..6] init 0;
    
    // Local variables
    
    Thread2_IamThreadT2 : [0..2] init 0;
    
    
    

    // Initial transition: pseudo-initial to initial state
    [] Thread2_pc=0 & turn=2 & !scheduler_turn ->
        (Thread2_pc'=1);


    // Transition: T2NonCriticalSection -> T2WAIT
    [] Thread2_pc=1 & turn=2 & !scheduler_turn & (Thread2NonCriticalSectionDelay) ->
        (Thread2_pc'=2);


    // Transition: T2WAIT -> T2NonAtomicAtoB
    [] Thread2_pc=2 & turn=2 & !scheduler_turn & ((NotAThread=sharedX)) ->
        (Thread2_pc'=3);


    // Transition: T2NonAtomicAtoB -> T2ASSIGN
    [] Thread2_pc=3 & turn=2 & !scheduler_turn & (true) ->
        (Thread2_pc'=4);


    // Transition: T2ASSIGN -> T2WAIT
    [] Thread2_pc=4 & turn=2 & !scheduler_turn & (!(IamThreadT2=sharedX)) ->
        (Thread2_pc'=2);


    // Transition: T2ASSIGN -> T2CriticalSection
    [] Thread2_pc=4 & turn=2 & !scheduler_turn & (true) ->
        (Thread2_pc'=5);


    // Transition: T2CriticalSection -> T2LetGo
    [] Thread2_pc=5 & turn=2 & !scheduler_turn & (Thread2CriticalSectionDelay) ->
        (Thread2_pc'=6);


    // Transition: T2LetGo -> T2NonCriticalSection
    [] Thread2_pc=6 & turn=2 & !scheduler_turn & (true) ->
        (Thread2_pc'=1);


endmodule




// ============================================================================
// Labels for state properties
// ============================================================================

label "At_Starter_INITIAL" = Starter_pc=1;


label "At_Thread1_T1NonCriticalSection" = Thread1_pc=1;


label "At_Thread1_T1WAIT" = Thread1_pc=2;



label "At_Thread1_T1NonAtomicAtoB" = Thread1_pc=3;



label "At_Thread1_T1ASSIGN" = Thread1_pc=4;



label "At_Thread1_T1CriticalSection" = Thread1_pc=5;



label "At_Thread1_T1LetGo" = Thread1_pc=6;



label "At_Thread2_T2NonCriticalSection" = Thread2_pc=1;


label "At_Thread2_T2WAIT" = Thread2_pc=2;



label "At_Thread2_T2NonAtomicAtoB" = Thread2_pc=3;



label "At_Thread2_T2ASSIGN" = Thread2_pc=4;



label "At_Thread2_T2CriticalSection" = Thread2_pc=5;



label "At_Thread2_T2LetGo" = Thread2_pc=6;



