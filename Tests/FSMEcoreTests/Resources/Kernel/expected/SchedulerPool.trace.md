<!--
Derivation of the canonical trace of SchedulerPool (closed, maxRounds 14).

Model: shared current : Slot (0..2, default 0) and done : Flags (three
Booleans, default false). Machine Scheduler: Dispatch (initial, no action,
done[current] -> Advance) and Advance (pass-through,
current := (current + 1) mod 3, true -> Dispatch). Machine Worker with
local id : Slot: Ready (initial, done[id] := false,
(gate in Dispatch) and current = id -> Working) and Working
(done[id] := true, print "work" id, current != id -> Ready). Instances in
order: gate, first (id 0), second (id 1), third (id 2).

Round 1. gate: Dispatch, no action; done[0] is false: R1 gate Dispatch.
first: Ready's action sets done[0] := false; gate is in Dispatch and
current = 0 = id: R1 first Working. second and third: their Ready actions
clear done[1] and done[2]; current differs from their ids: Ready.

Round 2. gate: done[0] still false: Dispatch. first: Working was entered,
so done[0] := true and "work 0" is printed before R2 first Working
(current != 0 fails). second, third: Ready.

Round 3. gate: done[0] holds, Advance runs in the same ringlet
(current := 1) and true returns to Dispatch: R3 gate Dispatch. first:
current = 1 != 0 moves it to Ready. second: gate in Dispatch and
current = 1: Working. third: Ready.

Round 4. gate: Dispatch re-entered (no action); done[1] is false:
Dispatch. first: Ready's action clears done[0]; current != 0: Ready.
second: prints "work 1" and sets done[1]: Working. third: Ready.

Round 5. gate: done[1] holds, current := 2: Dispatch. first: Ready.
second: current = 2 != 1: Ready. third: current = 2: Working.

Round 6. gate: done[2] false: Dispatch. first: Ready. second: clears
done[1]: Ready. third: prints "work 2", sets done[2]: Working.

Round 7. gate: done[2] holds, current := 0: Dispatch. first:
current = 0: Working. second: Ready. third: current != 2: Ready.

Round 8. gate: done[0] was cleared in round 4: Dispatch. first: prints
"work 0", sets done[0]: Working. second: Ready. third: clears done[2]:
Ready. The state after round 8 equals the state after round 2 (current 0,
done = [true, false, false], every instance not entered), so rounds 9 to
14 repeat rounds 3 to 8. No state is accepting, so the run stops at
maxRounds = 14 without a halt line.
-->
# SchedulerPool

Hand-derived canonical trace for 14 rounds; the bare trace is in
`SchedulerPool.trace`.
