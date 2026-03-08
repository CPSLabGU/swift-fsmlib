
(***************************************************************************)
(* TLA+ specification generated from LLFSM arrangement FischerDelaysByBooleanSensors *)
(***************************************************************************)
--------------------------- MODULE FischerDelaysByBooleanSensors ---------------------------
EXTENDS Integers


CONSTANTS NotAThread


VARIABLES

    STARTERState,

    THREAD_1State,

    THREAD_2State

,

    T1NonCriticalSectionDelay,

    T1CriticalSectionDelay,

    T2NonCriticalSectionDelay,

    T2CriticalSectionDelay


,

    SharedX










,

    THREAD_1_IamThreadT1




,

    THREAD_2_IamThreadT2



,
    sequentialTurn

vars == <<STARTERState, THREAD_1State, THREAD_2State, T1NonCriticalSectionDelay, T1CriticalSectionDelay, T2NonCriticalSectionDelay, T2CriticalSectionDelay, SharedX, THREAD_1_IamThreadT1, THREAD_2_IamThreadT2, sequentialTurn>>

(***************************************************************************)
(* Type invariants                                                         *)
(***************************************************************************)


TypesSTARTEROK == STARTERState \in {"__STARTER", "START"}



TypesTHREAD_1OK == THREAD_1State \in {"__THREAD_1", "T1NonCriticalSection", "T1Wait", "T1Assign", "T1CriticalSection", "T1LetGo"}



TypesTHREAD_2OK == THREAD_2State \in {"__THREAD_2", "T2NonCriticalSection", "T2Wait", "T2Assign", "T2CriticalSection", "T2LetGo"}




TypesT1NonCriticalSectionDelayOK == T1NonCriticalSectionDelay \in BOOLEAN

TypesT1CriticalSectionDelayOK == T1CriticalSectionDelay \in BOOLEAN

TypesT2NonCriticalSectionDelayOK == T2NonCriticalSectionDelay \in BOOLEAN

TypesT2CriticalSectionDelayOK == T2CriticalSectionDelay \in BOOLEAN




TypesSharedXOK == SharedX \in (0..2)


TypesSeqTurnOK == sequentialTurn \in (0..3)

(***************************************************************************)
(* Initial state predicate                                                 *)
(***************************************************************************)
FischerDelaysByBooleanSensorsInit ==
    /\ sequentialTurn = 0

    /\ STARTERState = "__STARTER"

    /\ THREAD_1State = "__THREAD_1"

    /\ THREAD_2State = "__THREAD_2"



    /\ T1NonCriticalSectionDelay \in BOOLEAN

    /\ T1CriticalSectionDelay \in BOOLEAN

    /\ T2NonCriticalSectionDelay \in BOOLEAN

    /\ T2CriticalSectionDelay \in BOOLEAN




    /\ SharedX \in (0..2)








    /\ THREAD_1_IamThreadT1 \in (0..2)





    /\ THREAD_2_IamThreadT2 \in (0..2)




(***************************************************************************)
(* Transitions                                                             *)
(***************************************************************************)


(***************************************************************************)
(* Transitions of machine STARTER                                       *)
(***************************************************************************)
T00 == /\ sequentialTurn = 0
    /\ STARTERState = "__STARTER"
    /\ STARTERState' = "START"







    /\ SharedX' = NotAThread






    /\ UNCHANGED<<THREAD_1State, THREAD_2State>>



    /\ UNCHANGED<<THREAD_1_IamThreadT1>>



    /\ UNCHANGED<<THREAD_2_IamThreadT2>>










    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN






T0Default == /\ sequentialTurn = 0
    /\ ( ~STARTERState = "__STARTER"

        )
    /\ UNCHANGED<<STARTERState>>

    /\ UNCHANGED<<THREAD_1State, THREAD_2State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>



    /\ UNCHANGED<<THREAD_2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>



    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Transitions of machine THREAD_1                                       *)
(***************************************************************************)
T10 == /\ sequentialTurn = 1
    /\ THREAD_1State = "__THREAD_1"
    /\ THREAD_1State' = "T1NonCriticalSection"







    /\ THREAD_1_IamThreadT1' = 1






    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>










    /\ UNCHANGED<<SharedX>>





    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN






T11 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1NonCriticalSection"

    /\ T1NonCriticalSectionDelay

    /\ THREAD_1State' = "T1Wait"



























    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T12 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1Wait"

    /\ (NotAThread = SharedX)

    /\ THREAD_1State' = "T1Assign"






























    /\ SharedX' = THREAD_1_IamThreadT1






    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>










    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T13 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1Assign"


    /\ ( ~(THREAD_1_IamThreadT1 = SharedX))


    /\ THREAD_1State' = "T1Wait"



























    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T14 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1Assign"




    /\ THREAD_1State' = "T1CriticalSection"














        /\ ~(( ~(THREAD_1_IamThreadT1 = SharedX)))




















    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T15 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1CriticalSection"

    /\ T1CriticalSectionDelay

    /\ THREAD_1State' = "T1LetGo"






























    /\ SharedX' = NotAThread






    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>










    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T16 == /\ sequentialTurn = 1
    /\ THREAD_1State = "T1LetGo"




    /\ THREAD_1State' = "T1NonCriticalSection"
































    /\ THREAD_1_IamThreadT1' = 1






    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>










    /\ UNCHANGED<<SharedX>>





    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T1Default == /\ sequentialTurn = 1
    /\ ( ~THREAD_1State = "__THREAD_1"

         /\ ~(THREAD_1State = "T1NonCriticalSection" /\ T1NonCriticalSectionDelay)

         /\ ~(THREAD_1State = "T1Wait" /\ (NotAThread = SharedX))

         /\ ~(THREAD_1State = "T1Assign" /\ ( ~(THREAD_1_IamThreadT1 = SharedX)))

         /\ ~(THREAD_1State = "T1Assign" /\ TRUE)

         /\ ~(THREAD_1State = "T1CriticalSection" /\ T1CriticalSectionDelay)

         /\ ~(THREAD_1State = "T1LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<THREAD_1State>>

    /\ UNCHANGED<<STARTERState, THREAD_2State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>



    /\ UNCHANGED<<THREAD_2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>



    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Transitions of machine THREAD_2                                       *)
(***************************************************************************)
T20 == /\ sequentialTurn = 2
    /\ THREAD_2State = "__THREAD_2"
    /\ THREAD_2State' = "T2NonCriticalSection"







    /\ THREAD_2_IamThreadT2' = 2






    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>










    /\ UNCHANGED<<SharedX>>





    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN






T21 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2NonCriticalSection"

    /\ T2NonCriticalSectionDelay

    /\ THREAD_2State' = "T2Wait"



























    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T22 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2Wait"

    /\ (NotAThread = SharedX)

    /\ THREAD_2State' = "T2Assign"






























    /\ SharedX' = THREAD_2_IamThreadT2






    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>










    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T23 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2Assign"


    /\ ( ~(THREAD_2_IamThreadT2 = SharedX))


    /\ THREAD_2State' = "T2Wait"



























    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T24 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2Assign"




    /\ THREAD_2State' = "T2CriticalSection"














        /\ ~(( ~(THREAD_2_IamThreadT2 = SharedX)))




















    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>














    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T25 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2CriticalSection"

    /\ T2CriticalSectionDelay

    /\ THREAD_2State' = "T2LetGo"






























    /\ SharedX' = NotAThread






    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>





    /\ UNCHANGED<<THREAD_2_IamThreadT2>>










    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T26 == /\ sequentialTurn = 2
    /\ THREAD_2State = "T2LetGo"




    /\ THREAD_2State' = "T2NonCriticalSection"
































    /\ THREAD_2_IamThreadT2' = 2






    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>










    /\ UNCHANGED<<SharedX>>





    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







T2Default == /\ sequentialTurn = 2
    /\ ( ~THREAD_2State = "__THREAD_2"

         /\ ~(THREAD_2State = "T2NonCriticalSection" /\ T2NonCriticalSectionDelay)

         /\ ~(THREAD_2State = "T2Wait" /\ (NotAThread = SharedX))

         /\ ~(THREAD_2State = "T2Assign" /\ ( ~(THREAD_2_IamThreadT2 = SharedX)))

         /\ ~(THREAD_2State = "T2Assign" /\ TRUE)

         /\ ~(THREAD_2State = "T2CriticalSection" /\ T2CriticalSectionDelay)

         /\ ~(THREAD_2State = "T2LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<THREAD_2State>>

    /\ UNCHANGED<<STARTERState, THREAD_1State>>





    /\ UNCHANGED<<THREAD_1_IamThreadT1>>



    /\ UNCHANGED<<THREAD_2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>



    /\ T1NonCriticalSectionDelay' \in BOOLEAN

    /\ T1CriticalSectionDelay' \in BOOLEAN

    /\ T2NonCriticalSectionDelay' \in BOOLEAN

    /\ T2CriticalSectionDelay' \in BOOLEAN







(***************************************************************************)
(* Next-state relation                                                     *)
(***************************************************************************)
FischerDelaysByBooleanSensorsNext ==
(*************************************************************************)
(* A deterministic scheduler advances turns in round robin fashion       *)
(*************************************************************************)
    sequentialTurn' = (sequentialTurn + 1) % 3 /\


(*************************************************************************)
(* The transitions of machine STARTER                                 *)
(*************************************************************************)
    \/ T00

    \/ T0Default



(*************************************************************************)
(* The transitions of machine THREAD_1                                 *)
(*************************************************************************)
    \/ T10


    \/ T11



    \/ T12



    \/ T13



    \/ T14



    \/ T15



    \/ T16


    \/ T1Default



(*************************************************************************)
(* The transitions of machine THREAD_2                                 *)
(*************************************************************************)
    \/ T20


    \/ T21



    \/ T22



    \/ T23



    \/ T24



    \/ T25



    \/ T26


    \/ T2Default



(***************************************************************************)
(* Specification                                                           *)
(***************************************************************************)
SpecFischerDelaysByBooleanSensors == FischerDelaysByBooleanSensorsInit /\ [][FischerDelaysByBooleanSensorsNext]_vars /\ WF_vars(FischerDelaysByBooleanSensorsNext)

=============================================================================
