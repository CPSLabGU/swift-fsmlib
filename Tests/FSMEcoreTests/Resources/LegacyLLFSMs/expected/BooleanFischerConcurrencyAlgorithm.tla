
(***************************************************************************)
(* TLA+ specification generated from LLFSM arrangement BooleanFischerConcurrencyAlgorithm *)
(***************************************************************************)
--------------------------- MODULE BooleanFischerConcurrencyAlgorithm ---------------------------
EXTENDS Integers


CONSTANTS NotAThread, GlobalWCET


VARIABLES

    StarterState,

    Thread1State,

    Thread2State

,

    Thread1NonCriticalSectionDelay,

    Thread1CriticalSectionDelay,

    Thread2NonCriticalSectionDelay,

    Thread2CriticalSectionDelay


,

    sharedX










,

    Thread1_IamThreadT1




,

    Thread2_IamThreadT2



,
    sequentialTurn

vars == <<StarterState, Thread1State, Thread2State, Thread1NonCriticalSectionDelay, Thread1CriticalSectionDelay, Thread2NonCriticalSectionDelay, Thread2CriticalSectionDelay, sharedX, Thread1_IamThreadT1, Thread2_IamThreadT2, sequentialTurn>>

(***************************************************************************)
(* Type invariants                                                         *)
(***************************************************************************)


TypesStarterOK == StarterState \in {"__Starter", "INITIAL"}



TypesThread1OK == Thread1State \in {"__Thread1", "T1NonCriticalSection", "T1WAIT", "T1NonAtomicAtoB", "T1ASSIGN", "T1CriticalSection", "T1LetGo"}



TypesThread2OK == Thread2State \in {"__Thread2", "T2NonCriticalSection", "T2WAIT", "T2NonAtomicAtoB", "T2ASSIGN", "T2CriticalSection", "T2LetGo"}




TypesThread1NonCriticalSectionDelayOK == Thread1NonCriticalSectionDelay \in BOOLEAN

TypesThread1CriticalSectionDelayOK == Thread1CriticalSectionDelay \in BOOLEAN

TypesThread2NonCriticalSectionDelayOK == Thread2NonCriticalSectionDelay \in BOOLEAN

TypesThread2CriticalSectionDelayOK == Thread2CriticalSectionDelay \in BOOLEAN




TypessharedXOK == sharedX \in (0..2)


TypesSeqTurnOK == sequentialTurn \in (0..3)

(***************************************************************************)
(* Initial state predicate                                                 *)
(***************************************************************************)
BooleanFischerConcurrencyAlgorithmInit ==
    /\ sequentialTurn = 0

    /\ StarterState = "__Starter"

    /\ Thread1State = "__Thread1"

    /\ Thread2State = "__Thread2"



    /\ Thread1NonCriticalSectionDelay \in BOOLEAN

    /\ Thread1CriticalSectionDelay \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay \in BOOLEAN

    /\ Thread2CriticalSectionDelay \in BOOLEAN




    /\ sharedX \in (0..2)








    /\ Thread1_IamThreadT1 \in (0..2)





    /\ Thread2_IamThreadT2 \in (0..2)




(***************************************************************************)
(* Transitions                                                             *)
(***************************************************************************)


(***************************************************************************)
(* Transitions of machine Starter                                       *)
(***************************************************************************)
T00 == /\ sequentialTurn = 0
    /\ StarterState = "__Starter"
    /\ StarterState' = "INITIAL"







    /\ sharedX' = NotAThread






    /\ UNCHANGED<<Thread1State, Thread2State>>



    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN






T0Default == /\ sequentialTurn = 0
    /\ ( ~StarterState = "__Starter"

        )
    /\ UNCHANGED<<StarterState>>

    /\ UNCHANGED<<Thread1State, Thread2State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<sharedX>>



    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Transitions of machine Thread1                                       *)
(***************************************************************************)
T10 == /\ sequentialTurn = 1
    /\ Thread1State = "__Thread1"
    /\ Thread1State' = "T1NonCriticalSection"







    /\ Thread1_IamThreadT1' = 1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN






T11 == /\ sequentialTurn = 1
    /\ Thread1State = "T1NonCriticalSection"

    /\ Thread1NonCriticalSectionDelay

    /\ Thread1State' = "T1WAIT"































    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T12 == /\ sequentialTurn = 1
    /\ Thread1State = "T1WAIT"

    /\ (NotAThread = sharedX)

    /\ Thread1State' = "T1NonAtomicAtoB"































    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T13 == /\ sequentialTurn = 1
    /\ Thread1State = "T1NonAtomicAtoB"




    /\ Thread1State' = "T1ASSIGN"


































    /\ sharedX' = Thread1_IamThreadT1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T14 == /\ sequentialTurn = 1
    /\ Thread1State = "T1ASSIGN"


    /\ ( ~(Thread1_IamThreadT1 = sharedX))


    /\ Thread1State' = "T1WAIT"































    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T15 == /\ sequentialTurn = 1
    /\ Thread1State = "T1ASSIGN"




    /\ Thread1State' = "T1CriticalSection"


















        /\ ~(( ~(Thread1_IamThreadT1 = sharedX)))
























    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>






    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T16 == /\ sequentialTurn = 1
    /\ Thread1State = "T1CriticalSection"

    /\ Thread1CriticalSectionDelay

    /\ Thread1State' = "T1LetGo"


































    /\ sharedX' = NotAThread






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T17 == /\ sequentialTurn = 1
    /\ Thread1State = "T1LetGo"




    /\ Thread1State' = "T1NonCriticalSection"




































    /\ Thread1_IamThreadT1' = 1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T1Default == /\ sequentialTurn = 1
    /\ ( ~Thread1State = "__Thread1"

         /\ ~(Thread1State = "T1NonCriticalSection" /\ Thread1NonCriticalSectionDelay)

         /\ ~(Thread1State = "T1WAIT" /\ (NotAThread = sharedX))

         /\ ~(Thread1State = "T1NonAtomicAtoB" /\ TRUE)

         /\ ~(Thread1State = "T1ASSIGN" /\ ( ~(Thread1_IamThreadT1 = sharedX)))

         /\ ~(Thread1State = "T1ASSIGN" /\ TRUE)

         /\ ~(Thread1State = "T1CriticalSection" /\ Thread1CriticalSectionDelay)

         /\ ~(Thread1State = "T1LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<Thread1State>>

    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<sharedX>>



    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Transitions of machine Thread2                                       *)
(***************************************************************************)
T20 == /\ sequentialTurn = 2
    /\ Thread2State = "__Thread2"
    /\ Thread2State' = "T2NonCriticalSection"







    /\ Thread2_IamThreadT2' = 2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN






T21 == /\ sequentialTurn = 2
    /\ Thread2State = "T2NonCriticalSection"

    /\ Thread2NonCriticalSectionDelay

    /\ Thread2State' = "T2WAIT"































    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T22 == /\ sequentialTurn = 2
    /\ Thread2State = "T2WAIT"

    /\ (NotAThread = sharedX)

    /\ Thread2State' = "T2NonAtomicAtoB"































    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T23 == /\ sequentialTurn = 2
    /\ Thread2State = "T2NonAtomicAtoB"




    /\ Thread2State' = "T2ASSIGN"


































    /\ sharedX' = Thread2_IamThreadT2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T24 == /\ sequentialTurn = 2
    /\ Thread2State = "T2ASSIGN"


    /\ ( ~(Thread2_IamThreadT2 = sharedX))


    /\ Thread2State' = "T2WAIT"































    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>














    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T25 == /\ sequentialTurn = 2
    /\ Thread2State = "T2ASSIGN"




    /\ Thread2State' = "T2CriticalSection"


















        /\ ~(( ~(Thread2_IamThreadT2 = sharedX)))
























    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>






    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T26 == /\ sequentialTurn = 2
    /\ Thread2State = "T2CriticalSection"

    /\ Thread2CriticalSectionDelay

    /\ Thread2State' = "T2LetGo"


































    /\ sharedX' = NotAThread






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T27 == /\ sequentialTurn = 2
    /\ Thread2State = "T2LetGo"




    /\ Thread2State' = "T2NonCriticalSection"




































    /\ Thread2_IamThreadT2' = 2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ UNCHANGED<<sharedX>>





    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







T2Default == /\ sequentialTurn = 2
    /\ ( ~Thread2State = "__Thread2"

         /\ ~(Thread2State = "T2NonCriticalSection" /\ Thread2NonCriticalSectionDelay)

         /\ ~(Thread2State = "T2WAIT" /\ (NotAThread = sharedX))

         /\ ~(Thread2State = "T2NonAtomicAtoB" /\ TRUE)

         /\ ~(Thread2State = "T2ASSIGN" /\ ( ~(Thread2_IamThreadT2 = sharedX)))

         /\ ~(Thread2State = "T2ASSIGN" /\ TRUE)

         /\ ~(Thread2State = "T2CriticalSection" /\ Thread2CriticalSectionDelay)

         /\ ~(Thread2State = "T2LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<Thread2State>>

    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<sharedX>>



    /\ Thread1NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread1CriticalSectionDelay' \in BOOLEAN

    /\ Thread2NonCriticalSectionDelay' \in BOOLEAN

    /\ Thread2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Next-state relation                                                     *)
(***************************************************************************)
BooleanFischerConcurrencyAlgorithmNext ==
(*************************************************************************)
(* A deterministic scheduler advances turns in round robin fashion       *)
(*************************************************************************)
    sequentialTurn' = (sequentialTurn + 1) % 3 /\


(*************************************************************************)
(* The transitions of machine Starter                                 *)
(*************************************************************************)
    \/ T00

    \/ T0Default



(*************************************************************************)
(* The transitions of machine Thread1                                 *)
(*************************************************************************)
    \/ T10


    \/ T11



    \/ T12



    \/ T13



    \/ T14



    \/ T15



    \/ T16



    \/ T17


    \/ T1Default



(*************************************************************************)
(* The transitions of machine Thread2                                 *)
(*************************************************************************)
    \/ T20


    \/ T21



    \/ T22



    \/ T23



    \/ T24



    \/ T25



    \/ T26



    \/ T27


    \/ T2Default



(***************************************************************************)
(* Specification                                                           *)
(***************************************************************************)
SpecBooleanFischerConcurrencyAlgorithm == BooleanFischerConcurrencyAlgorithmInit /\ [][BooleanFischerConcurrencyAlgorithmNext]_vars /\ WF_vars(BooleanFischerConcurrencyAlgorithmNext)

=============================================================================
