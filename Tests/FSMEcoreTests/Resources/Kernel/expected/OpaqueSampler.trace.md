<!--
Derivation of the canonical trace of OpaqueSampler (closed, relaxed,
C only, maxRounds 9).

Model: shared latest : Reading (opaque struct reading); host declarations
define struct reading { int value; }, a poll counter sensor_polls
starting at 0, sensor_ready() (increments the counter and holds when it
is even), read_sensor(out) (sets out->value to 10 times the counter) and
print_Reading(value) (prints the value). Machine Sampler: Wait (initial,
no action, opaque label sensor_ready() -> Sample) and Sample (opaque
statement read_sensor(&latest); print "sample" latest, true -> Wait). One
instance probe.

Round 1: Wait was entered (no action); sensor_ready() raises the counter
to 1 and fails: R1 probe Wait.
Round 2: the counter becomes 2 and the label holds: R2 probe Sample.
Round 3: Sample was entered: read_sensor stores 20, "sample 20" is
printed; true moves to Wait (the label of Wait is not evaluated in this
ringlet): R3 probe Wait.
Rounds 4 to 6 repeat rounds 1 to 3 with the counter at 3 and 4, printing
"sample 40"; rounds 7 to 9 repeat them with the counter at 5 and 6,
printing "sample 60". No state is accepting, so no halt line.
-->
# OpaqueSampler

Hand-derived canonical trace for 9 rounds of the C target; the bare trace
is in `OpaqueSampler.trace`.
