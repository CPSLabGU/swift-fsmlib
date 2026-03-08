
(***************************************************************************)
(* TLA+ specification generated from LLFSM arrangement FischerConcurrencyAlgorithm *)
(***************************************************************************)
--------------------------- MODULE FischerConcurrencyAlgorithm ---------------------------
EXTENDS Integers


CONSTANTS NotAThread, GlobalWCET


VARIABLES

    StarterState,

    Thread1State,

    Thread2State


,

    SharedX


,

    Thread1NonCriticalSectionWCET,

    Thread1CriticalSectionWCET,

    Thread2NonCriticalSectionWCET,

    Thread2CriticalSectionWCET









,

    Thread1_IamThreadT1




,

    Thread2_IamThreadT2



,
    sequentialTurn

vars == <<StarterState, Thread1State, Thread2State, SharedX, Thread1NonCriticalSectionWCET, Thread1CriticalSectionWCET, Thread2NonCriticalSectionWCET, Thread2CriticalSectionWCET, Thread1_IamThreadT1, Thread2_IamThreadT2, sequentialTurn>>

(***************************************************************************)
(* Type invariants                                                         *)
(***************************************************************************)


TypesStarterOK == StarterState \in {"__Starter", "INITIAL"}



TypesThread1OK == Thread1State \in {"__Thread1", "T1NonCriticalSection", "T1WAIT", "T1ASSIGN", "T1CriticalSection", "T1LetGo"}



TypesThread2OK == Thread2State \in {"__Thread2", "T2NonCriticalSection", "T2WAIT", "T2ASSIGN", "T2CriticalSection", "T2LetGo"}





TypesSharedXOK == SharedX \in (0..2)


TypesSeqTurnOK == sequentialTurn \in (0..3)

(***************************************************************************)
(* Initial state predicate                                                 *)
(***************************************************************************)
FischerConcurrencyAlgorithmInit ==
    /\ sequentialTurn = 0

    /\ StarterState = "__Starter"

    /\ Thread1State = "__Thread1"

    /\ Thread2State = "__Thread2"




    /\ SharedX \in (0..2)




    /\ Thread1NonCriticalSectionWCET \in (0..3)

    /\ Thread1CriticalSectionWCET \in (0..4)

    /\ Thread2NonCriticalSectionWCET \in (0..2)

    /\ Thread2CriticalSectionWCET \in (0..1)







    /\ Thread1_IamThreadT1 \in (0..1)





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







    /\ SharedX' = NotAThread






    /\ UNCHANGED<<Thread1State, Thread2State>>



    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>











    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)





T0Default == /\ sequentialTurn = 0
    /\ ( ~StarterState = "__Starter"

        )
    /\ UNCHANGED<<StarterState>>

    /\ UNCHANGED<<Thread1State, Thread2State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>




    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






(***************************************************************************)
(* Transitions of machine Thread1                                       *)
(***************************************************************************)
T10 == /\ sequentialTurn = 1
    /\ Thread1State = "__Thread1"
    /\ Thread1State' = "T1NonCriticalSection"







    /\ Thread1_IamThreadT1' = 1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)





T11 == /\ sequentialTurn = 1
    /\ Thread1State = "T1NonCriticalSection"

    /\ Thread1State' = "T1WAIT"



























    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>















    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T12 == /\ sequentialTurn = 1
    /\ Thread1State = "T1WAIT"

    /\ (NotAThread = SharedX)

    /\ Thread1State' = "T1ASSIGN"






























    /\ SharedX' = Thread1_IamThreadT1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>











    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T13 == /\ sequentialTurn = 1
    /\ Thread1State = "T1ASSIGN"


    /\ ( ~(Thread1_IamThreadT1 = SharedX))


    /\ Thread1State' = "T1WAIT"



























    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>















    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T14 == /\ sequentialTurn = 1
    /\ Thread1State = "T1ASSIGN"




    /\ Thread1State' = "T1CriticalSection"














        /\ ~(( ~(Thread1_IamThreadT1 = SharedX)))
























    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>






    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T15 == /\ sequentialTurn = 1
    /\ Thread1State = "T1CriticalSection"

    /\ Thread1State' = "T1LetGo"






























    /\ SharedX' = NotAThread






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>











    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T16 == /\ sequentialTurn = 1
    /\ Thread1State = "T1LetGo"




    /\ Thread1State' = "T1NonCriticalSection"
































    /\ Thread1_IamThreadT1' = 1






    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>










    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T1Default == /\ sequentialTurn = 1
    /\ ( ~Thread1State = "__Thread1"

         /\ ~(Thread1State = "T1NonCriticalSection")

         /\ ~(Thread1State = "T1WAIT" /\ (NotAThread = SharedX))

         /\ ~(Thread1State = "T1ASSIGN" /\ ( ~(Thread1_IamThreadT1 = SharedX)))

         /\ ~(Thread1State = "T1ASSIGN" /\ TRUE)

         /\ ~(Thread1State = "T1CriticalSection")

         /\ ~(Thread1State = "T1LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<Thread1State>>

    /\ UNCHANGED<<StarterState, Thread2State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>




    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






(***************************************************************************)
(* Transitions of machine Thread2                                       *)
(***************************************************************************)
T20 == /\ sequentialTurn = 2
    /\ Thread2State = "__Thread2"
    /\ Thread2State' = "T2NonCriticalSection"







    /\ Thread2_IamThreadT2' = 2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)





T21 == /\ sequentialTurn = 2
    /\ Thread2State = "T2NonCriticalSection"

    /\ Thread2State' = "T2WAIT"



























    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>















    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T22 == /\ sequentialTurn = 2
    /\ Thread2State = "T2WAIT"

    /\ (NotAThread = SharedX)

    /\ Thread2State' = "T2ASSIGN"






























    /\ SharedX' = Thread2_IamThreadT2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>











    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T23 == /\ sequentialTurn = 2
    /\ Thread2State = "T2ASSIGN"


    /\ ( ~(Thread2_IamThreadT2 = SharedX))


    /\ Thread2State' = "T2WAIT"



























    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>















    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T24 == /\ sequentialTurn = 2
    /\ Thread2State = "T2ASSIGN"




    /\ Thread2State' = "T2CriticalSection"














        /\ ~(( ~(Thread2_IamThreadT2 = SharedX)))
























    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>






    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T25 == /\ sequentialTurn = 2
    /\ Thread2State = "T2CriticalSection"

    /\ Thread2State' = "T2LetGo"






























    /\ SharedX' = NotAThread






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>





    /\ UNCHANGED<<Thread2_IamThreadT2>>











    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T26 == /\ sequentialTurn = 2
    /\ Thread2State = "T2LetGo"




    /\ Thread2State' = "T2NonCriticalSection"
































    /\ Thread2_IamThreadT2' = 2






    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>










    /\ UNCHANGED<<SharedX>>






    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






T2Default == /\ sequentialTurn = 2
    /\ ( ~Thread2State = "__Thread2"

         /\ ~(Thread2State = "T2NonCriticalSection")

         /\ ~(Thread2State = "T2WAIT" /\ (NotAThread = SharedX))

         /\ ~(Thread2State = "T2ASSIGN" /\ ( ~(Thread2_IamThreadT2 = SharedX)))

         /\ ~(Thread2State = "T2ASSIGN" /\ TRUE)

         /\ ~(Thread2State = "T2CriticalSection")

         /\ ~(Thread2State = "T2LetGo" /\ TRUE)

        )
    /\ UNCHANGED<<Thread2State>>

    /\ UNCHANGED<<StarterState, Thread1State>>





    /\ UNCHANGED<<Thread1_IamThreadT1>>



    /\ UNCHANGED<<Thread2_IamThreadT2>>



    /\ UNCHANGED<<SharedX>>




    /\ Thread1NonCriticalSectionWCET' \in (0..3)

    /\ Thread1CriticalSectionWCET' \in (0..4)

    /\ Thread2NonCriticalSectionWCET' \in (0..2)

    /\ Thread2CriticalSectionWCET' \in (0..1)






(***************************************************************************)
(* Next-state relation                                                     *)
(***************************************************************************)
FischerConcurrencyAlgorithmNext ==
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


    \/ T2Default



(***************************************************************************)
(* Specification                                                           *)
(***************************************************************************)
SpecFischerConcurrencyAlgorithm == FischerConcurrencyAlgorithmInit /\ [][FischerConcurrencyAlgorithmNext]_vars /\ WF_vars(FischerConcurrencyAlgorithmNext)

=============================================================================
