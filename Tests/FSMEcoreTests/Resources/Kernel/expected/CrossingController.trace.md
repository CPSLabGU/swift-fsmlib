<!--
Derivation of the canonical trace of CrossingController (open,
maxRounds 16, inputs ../inputs/CrossingController.inputs).

Model: external now : Time (0..10000) and request : Bool; machine Crossing
with local enteredAt : Time; states Go (initial, enteredAt := now,
print "go", request -> Go_x0), Go_x0 (pass-through, print "clearing",
true -> Amber), Amber (enteredAt := now, print "amber",
now - enteredAt >= 3 -> Stop) and Stop (enteredAt := now, print "stop",
now - enteredAt >= 5 -> Go). One instance main. The inputs set now to
round - 1 in every round and request to true in rounds 3 and 14 only (an
absent value keeps its previous value). Each ringlet reads one snapshot.

Round 1 (now 0, request false): Go was entered: enteredAt := 0, "go"; no
label holds: R1 main Go.
Round 2 (now 1): nothing holds: R2 main Go.
Round 3 (now 2, request true): request moves to the pass-through Go_x0,
whose action prints "clearing" in the same ringlet; true moves to Amber:
R3 main Amber.
Round 4 (now 3, request false): Amber was entered: enteredAt := 3,
"amber"; 3 - 3 >= 3 fails: R4 main Amber.
Rounds 5 and 6 (now 4, 5): differences 1 and 2: Amber.
Round 7 (now 6): 6 - 3 >= 3 moves to Stop: R7 main Stop.
Round 8 (now 7): Stop was entered: enteredAt := 7, "stop"; 0 >= 5 fails.
Rounds 9 to 12 (now 8 to 11): differences 1 to 4: Stop.
Round 13 (now 12): 12 - 7 >= 5 moves to Go: R13 main Go.
Round 14 (now 13, request true): Go was entered: enteredAt := 13, "go";
request holds, Go_x0 prints "clearing", rests in Amber: R14 main Amber.
Round 15 (now 14, request false): Amber was entered: enteredAt := 14,
"amber"; 0 >= 3 fails: Amber.
Round 16 (now 15): 1 >= 3 fails: R16 main Amber.
No state is accepting, so no halt line.
-->
# CrossingController

Hand-derived canonical trace for 16 rounds with the inputs in
`../inputs/CrossingController.inputs`; the bare trace is in
`CrossingController.trace`.
