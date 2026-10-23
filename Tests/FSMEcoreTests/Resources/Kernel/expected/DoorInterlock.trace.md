<!--
Derivation of the canonical trace of DoorInterlock (open, maxRounds 10,
inputs ../inputs/DoorInterlock.inputs, host functions from
../host/<language>/DoorInterlockHost.*).

Model: external doorClosed : Bool and shared motorOn : Bool = false; the
pure function isSafe(closed) and the function logEvent(event). The host
implementations used by the tests return closed from isSafe and print
"log <event>" from logEvent. Machine Interlock: Idle (initial, no action,
isSafe(doorClosed) -> Running), Running (motorOn := true, logEvent(1),
not doorClosed -> Halting) and Halting (pass-through, motorOn := false,
logEvent(2), true -> Idle). Machine Monitor: Quiet (initial, no action,
(lock in Running) and not doorClosed -> Alarm) and Alarm (print "alarm"
motorOn, lock in Idle -> Quiet). Instances in order: lock, watch. The
inputs set doorClosed to false in round 1, true in round 2, false in
round 5 and true in round 8.

Round 1 (doorClosed false): lock: isSafe(false) is false: Idle. watch:
lock is not in Running: Quiet.
Round 2 (true): lock: isSafe(true) moves to Running: R2 lock Running.
watch: lock is in Running but doorClosed holds: Quiet.
Round 3 (true): lock: Running was entered: motorOn := true, logEvent(1)
prints "log 1"; not doorClosed fails: Running. watch: Quiet.
Round 4 (true): nothing changes.
Round 5 (false): lock: not doorClosed moves to the pass-through Halting,
whose action runs in the same ringlet (motorOn := false, "log 2"); true
moves to Idle: R5 lock Idle. watch: lock is no longer in Running: Quiet.
Rounds 6 and 7 (false): lock: Idle (re-entered, no action), isSafe(false)
fails. watch: Quiet.
Round 8 (true): lock moves to Running. watch: Quiet.
Round 9 (true): lock: "log 1", Running. watch: Quiet.
Round 10 (true): nothing changes.
Within a round both instances see the same value of doorClosed, and lock
leaves Running in the ringlet in which it sees the door open, so watch
never observes lock in Running with the door open and Alarm is not
reached. No state is accepting, so no halt line.
-->
# DoorInterlock

Hand-derived canonical trace for 10 rounds with the inputs in
`../inputs/DoorInterlock.inputs`; the bare trace is in
`DoorInterlock.trace`.
