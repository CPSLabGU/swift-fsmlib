
(***************************************************************************)
(* TLA+ specification generated from LLFSM arrangement PingPongTikiTakaForC *)
(***************************************************************************)
--------------------------- MODULE PingPongTikiTakaForC ---------------------------
EXTENDS Integers


VARIABLES

    PingPongState










,
    sequentialTurn

vars == <<PingPongState, sequentialTurn>>

(***************************************************************************)
(* Type invariants                                                         *)
(***************************************************************************)


TypesPingPongOK == PingPongState \in {"__PingPong", "START_PING_PONG", "PING", "PONG"}




TypesSeqTurnOK == sequentialTurn \in (0..1)

(***************************************************************************)
(* Initial state predicate                                                 *)
(***************************************************************************)
PingPongTikiTakaForCInit ==
    /\ sequentialTurn = 0

    /\ PingPongState = "__PingPong"








(***************************************************************************)
(* Transitions                                                             *)
(***************************************************************************)


(***************************************************************************)
(* Transitions of machine PingPong                                       *)
(***************************************************************************)
T00 == /\ sequentialTurn = 0
    /\ PingPongState = "__PingPong"
    /\ PingPongState' = "START_PING_PONG"














T01 == /\ sequentialTurn = 0
    /\ PingPongState = "START_PING_PONG"




    /\ PingPongState' = "PING"




























T02 == /\ sequentialTurn = 0
    /\ PingPongState = "PING"




    /\ PingPongState' = "PONG"




























T03 == /\ sequentialTurn = 0
    /\ PingPongState = "PONG"




    /\ PingPongState' = "PING"




























T0Default == /\ sequentialTurn = 0
    /\ ( ~PingPongState = "__PingPong"

         /\ ~(PingPongState = "START_PING_PONG" /\ TRUE)

         /\ ~(PingPongState = "PING" /\ TRUE)

         /\ ~(PingPongState = "PONG" /\ TRUE)

        )
    /\ UNCHANGED<<PingPongState>>











(***************************************************************************)
(* Next-state relation                                                     *)
(***************************************************************************)
PingPongTikiTakaForCNext ==
(*************************************************************************)
(* A deterministic scheduler advances turns in round robin fashion       *)
(*************************************************************************)
    sequentialTurn' = (sequentialTurn + 1) % 1 /\


(*************************************************************************)
(* The transitions of machine PingPong                                 *)
(*************************************************************************)
    \/ T00


    \/ T01



    \/ T02



    \/ T03


    \/ T0Default



(***************************************************************************)
(* Specification                                                           *)
(***************************************************************************)
SpecPingPongTikiTakaForC == PingPongTikiTakaForCInit /\ [][PingPongTikiTakaForCNext]_vars /\ WF_vars(PingPongTikiTakaForCNext)

=============================================================================
