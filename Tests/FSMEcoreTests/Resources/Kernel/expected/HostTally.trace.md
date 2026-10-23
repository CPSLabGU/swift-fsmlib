<!--
Derivation of the canonical trace of HostTally (closed, relaxed, one
model per code target under ../models/<language>/HostTally.xmi, all with
the same trace).

Model: shared tally : Tally (an opaque host type with an internal sum
starting at 0, a method bump(by) that adds to the sum and a pure method
sum()), local n : Count (0..9, default 0), the pure function isEven(n)
and the function note(n), which prints "note <n>". Machine Counter:
Start (initial, opaque statement printing "start", true -> Work), Work
(tally.bump(n); note(n); n := n + 1; print "sum" tally.sum(); opaque label
tally.sum() >= 6 -> Done, isEven(n) -> Pause, true -> Work), Pause
(pass-through, print "pause" n, true -> Work) and Done (opaque statement
printing "done", no transitions, so accepting). One instance counter.

Round 1: Start prints "start"; true moves to Work: R1 counter Work.
Round 2: Work was entered: bump(0) leaves the sum at 0, "note 0", n := 1,
"sum 0"; 0 >= 6 fails, isEven(1) fails, true re-enters Work:
R2 counter Work.
Round 3: bump(1) makes the sum 1, "note 1", n := 2, "sum 1"; 1 >= 6
fails, isEven(2) holds and moves to the pass-through Pause, which prints
"pause 2" in the same ringlet and re-enters Work: R3 counter Work.
Round 4: bump(2) makes the sum 3, "note 2", n := 3, "sum 3"; 3 >= 6 and
isEven(3) fail, true re-enters Work: R4 counter Work.
Round 5: bump(3) makes the sum 6, "note 3", n := 4, "sum 6"; 6 >= 6 moves
to Done: R5 counter Done.
Round 6: Done was entered and prints "done"; it has no transitions:
R6 counter Done. Every instance is accepting and has run its action, so
the arrangement halts: halt R6.
-->
# HostTally

Hand-derived canonical trace shared by the C, C++, Swift and Java
HostTally models; the bare trace is in `HostTally.trace`.
