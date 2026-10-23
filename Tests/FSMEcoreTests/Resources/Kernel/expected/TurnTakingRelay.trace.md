<!--
Derivation of the canonical trace of TurnTakingRelay (closed, maxRounds 32).

Model: shared turn : Side = left; machine Relay with locals me : Side and
passes : Count (0..9, default 0); states Waiting (initial, no action,
turn = me -> Holding), Holding (print "holding" me passes,
passes < 9 -> Passing) and Passing (pass-through, turn := right if
me = left else left, passes := passes + 1, true -> Waiting). Instances in
order: leftHand (me = left), rightHand (me = right). Every instance starts
in Waiting with entered = true.

Round 1. leftHand: Waiting has no action; turn = left = me, so it moves to
Holding and yields (Holding is not pass-through): R1 leftHand Holding.
rightHand: no action; turn = left differs from right, no label holds:
R1 rightHand Waiting.

Round 2. leftHand: Holding was entered, so its action prints
"holding left 0"; passes = 0 < 9 moves to the pass-through state Passing,
whose action runs in the same ringlet (turn := right, passes := 1); true
moves to Waiting, which ends the ringlet: R2 leftHand Waiting. rightHand:
turn = right = me moves to Holding: R2 rightHand Holding.

Round 3. leftHand: Waiting was entered (no action); turn = right, no label
holds: R3 leftHand Waiting. rightHand: prints "holding right 0", passes
becomes 1, turn := left, rests in Waiting: R3 rightHand Waiting.

Rounds 4 to 6 repeat rounds 1 to 3 with passes one higher in each
instance, and so on: for k = 0..8, round 3k+1 moves leftHand to Holding,
round 3k+2 prints "holding left k" and moves rightHand to Holding, and
round 3k+3 prints "holding right k". After round 27 both passes are 9 and
turn = left.

Round 28. leftHand: turn = left moves it to Holding: R28 leftHand Holding;
rightHand stays in Waiting.

Round 29. leftHand prints "holding left 9"; passes < 9 fails, so no label
holds and it rests in Holding: R29 leftHand Holding. rightHand: turn is
still left: R29 rightHand Waiting.

Rounds 30 to 32 change nothing. Holding has a transition, so no instance
is accepting and the arrangement never halts; the run stops at
maxRounds = 32 without a halt line. passes never leaves 0..9.
-->
# TurnTakingRelay

Hand-derived canonical trace for 32 rounds; the bare trace is in
`TurnTakingRelay.trace`.
