# Sectioned Semantics and Kernel Encoding

How the sectioned view of a logic-labelled finite-state machine is executed,
and how it is encoded into the sectionless kernel.

## Overview

The sectioned metamodel is the traditional view of an LLFSM: every state has
entry, exit, internal, suspend and resume sections, a machine may name a
suspend state, and a transition label may read the time since the current
state was entered. The kernel has none of these: a state has one action and
an ordered list of labels, and a pass-through state continues the ringlet
instead of ending it.

The encoding from the sectioned view into the kernel is a model
transformation with semantic options. The default options reproduce the
traditional execution order of the reference engines. Each option is a
parameter of ``LLFSMTransformations/sectionedToKernel(_:options:uri:)``,
given by ``SectionedToKernelOptions``; this article specifies the semantics
that the transformation implements, and <doc:Transformations> describes how
to run it.

## Traditional execution order (the default)

A round runs one ringlet of every instance in arrangement order. A ringlet of
an instance in state `S`:

1. takes the snapshot of all external variables, including the clock, before
   any section runs;
2. if `S` was entered since the previous ringlet, resets the state clock and
   runs the entry section of `S`;
3. evaluates the transition labels of `S` in order against the snapshot; the
   first label that holds selects its transition;
4. if a transition fired, runs the exit section of `S`, moves to the target
   and ends the ringlet; the entry section of the target runs at the start of
   the target's first ringlet;
5. otherwise runs the internal section of `S` and ends the ringlet.

A state without transitions is accepting: its entry section runs once and its
internal section runs on every later ringlet. A self transition fires like
any other transition: the exit section runs, the state is not re-entered, the
entry section does not run again and the state clock is not reset.

Suspension and resumption are requested by other instances and take effect at
the start of the suspended instance's next ringlet:

- suspend from state `W`: the suspend section of `W` runs, then the entry
  section of the suspend state runs; the exit section of `W` does not run;
- resume to `W`: the resume section of the suspend state runs, then the
  resume section of `W`, then the entry section of `W` (the state is
  re-entered and its clock reset); the exit section of the suspend state does
  not run;
- restart: the machine re-enters its initial state; no exit section runs.

While suspended, the suspend state behaves like any other state: its own
labels are evaluated and its internal section runs.

Writes to shared variables are visible immediately to the instances that run
later in the same round. An `InState` observation of another instance reads
that instance's current state at the moment of evaluation.

## Encoding into the kernel

### Sections (E1)

A sectioned state `S` with entry `E`, exit `X`, internal `I` and ordered
labels `g_1 … g_n` with targets `T_1 … T_n` becomes:

| kernel state | pass-through | action | labels, in order |
|---|---|---|---|
| `S` | no | `E` | `g_1 → S_x1`, …, `g_n → S_xn`, `true → S_i` |
| `S_i` | yes | `I` | `true → S_w` |
| `S_w` | no | none | `g_1 → S_x1`, …, `g_n → S_xn`, `true → S_i` |
| `S_xk` | yes | `X` | `true → T_k` |

The first ringlet after entering `S` runs `E`, evaluates the labels, and
either runs `X` in `S_xk` and rests in `T_k`, or runs `I` in `S_i` and rests
in `S_w`. Later ringlets start in `S_w`, evaluate the labels, and rest in
`T_k` or `S_w` again. The action and label sequence and the yield points are
those of the traditional order, so the interleaving with other instances and
the observable trace are identical.

When `elideEmptySections` is on (the default), an empty `I` removes `S_i` and
`S_w` (the labels of `S` then include no `true` fallback, so a state with no
labels stays accepting), and an empty `X` makes the labels of `S` and `S_w`
target `T_k` directly. A sectioned machine with only entry sections therefore
encodes to a kernel machine with the same number of states.

A self transition `g_k → S` is encoded as `g_k → S_xk` with `S_xk → S_w`
(`selfLoop=traditional`), so the state is not re-entered, or with
`S_xk → S` (`selfLoop=reentry`), so `E` runs again and the clock resets.

### In-state observations

An `InState(J, S)` observation at the sectioned level holds in every kernel
state that encodes `S`: `S`, `S_i`, `S_w` and the `S_xk`. With
`inState=expand` (the default) it becomes the disjunction of the kernel
observations; with `inState=exact` it observes only the kernel state `S`.

### Suspension (E2)

For a machine with suspend state `Z` the encoding adds a shared Boolean
`suspend<Machine>` (set and cleared by the encoded
`MachineControlStatement`s of other instances, or external when the
controller is outside the arrangement) and a local variable `resumeTo` of
the enumeration `<Machine>States` over the working states. The request
belongs to the machine, so all instances of a suspensible machine are
suspended and resumed together; the encoding reports a machine with more
than one instance. Every working state `W` gains, as its first label,
`suspend<M> → W_s`, where `W_s` is pass-through, runs the suspend section of
`W` and records `resumeTo := W`. All `W_s` lead to the kernel encoding of `Z`
(whose entry section runs as its action). `Z` gains the label
`¬suspend<M> → Z_d`, where `Z_d` is pass-through, runs the resume section of
`Z` and dispatches on `resumeTo` to one pass-through state `W_r` per `W` that
runs the resume section of `W` and enters `W`. The labels of `Z` itself follow, so
the suspend state keeps its own behaviour while suspended.

With `suspension=omit` the suspend state designation, the control
statements and the suspend and resume sections are dropped with a
diagnostic; the former suspend state remains an ordinary state. With
`resumeFallback=initial` (the default) an instance resumed before it was
ever suspended enters its initial state; with `resumeFallback=previous` the
entry of every working state records that state, so the instance enters the
working state it entered most recently. Restart requests are not encoded:
they are dropped with a diagnostic, as are suspend and resume requests for
an instance whose suspension is not encoded.

### Time

`StateTimeExpression` becomes `now − enteredAt`, where `now` is an external
integer variable read from the snapshot and `enteredAt` is a local variable
assigned `now` in the action of every kernel state that encodes a sectioned
state entry (`S`, and the resume target of a resume dispatch). With
`time=external` (the default) `now` is supplied by the environment; with
`time=clock` a `Clock` machine instance placed first in the arrangement
advances `now` by one unit per round so that verification models stay
closed. The clock unit is the microsecond, and units are converted at the
encoding: a state-time expression in milliseconds or seconds becomes the
elapsed time divided by 1000 or 1000000, and one in ticks, which counts
clock units, the elapsed time divided by one.

### Origin annotations

Every kernel state and transition created by the encoding records its
origin in an `Origin` object held by its `origin` containment. The
attributes of the origin correspond to the detail keys of the annotation
source `http://cpslabgu.github.io/llfsm/origin`: the sectioned state
(`state`), the role of the kernel element (`entry`, `wait`, `internal`,
`exit`, `suspend`, `resume`, `dispatch` or `clock`) and, for exit states and
their transitions, the zero-based index of the sectioned transition
(`transition`). ``OriginAnnotations`` reads and writes these records and
converts them to and from annotation details. The inverse transformation
uses the origins to rebuild the sectioned machine exactly; a kernel model
without them is mapped flatly (actions become entry sections, pass-through
states become ordinary states) with a diagnostic that the execution
semantics differ.

## Options

| option | values (default first) | effect |
|---|---|---|
| `selfLoop` | `traditional`, `reentry` | whether a self transition re-enters the state |
| `elideEmptySections` | `true`, `false` | collapse states whose internal and exit sections are empty |
| `suspension` | `encode`, `omit` | encode or drop suspension |
| `resumeFallback` | `initial`, `previous` | where an instance resumes when nothing was recorded |
| `time` | `external`, `clock` | source of the clock for state-time expressions |
| `inState` | `expand`, `exact` | how in-state observations map onto the kernel states |

Verification targets add `entry=ringlet|fused` (whether the entry action is
a separate micro-step or fused with the transition), `maxRounds`, `sanity`
and `opaque=reject|havoc` (how opaque host-language nodes are treated).
