# Transformations

Transform LLFSMs between the structural, sectioned and kernel levels, and
type host-language labels and sections.

## Overview

``LLFSMTransformations`` runs the bundled model transformations between the
three levels described in <doc:MetamodelLevels>:

| transformation | from | to | what is kept |
|---|---|---|---|
| ``LLFSMTransformations/structuralToSectioned(_:arrangementName:uri:)`` | structural machine or arrangement | sectioned arrangement | states, sections, labels, suspend state, boilerplate, instances; typed where the text lies in the typed subset |
| ``LLFSMTransformations/sectionedToKernel(_:options:uri:)`` | sectioned arrangement | kernel arrangement | the execution semantics of <doc:SectionedSemantics>, with origin records |
| ``LLFSMTransformations/kernelToSectioned(_:uri:)`` | kernel arrangement | sectioned arrangement | the encoded sectioned model exactly, or a flat mapping |

Each transformation reads the model held by a resource and returns a
``TransformationResult``: a new resource with the transformed model and
``TransformationDiagnostics`` that list what the target level could not keep.

```swift
import ECore
import FSMEcore

let transformations = try await LLFSMTransformations()
let sectioned = try await transformations.structuralToSectioned(structuralResource, arrangementName: "Lights")
let options = try SectionedToKernelOptions(keyValues: ["selfLoop=reentry"])
let kernel = try await transformations.sectionedToKernel(sectioned.resource, options: options)
for warning in sectioned.diagnostics.warnings + kernel.diagnostics.warnings {
    print(warning)
}
```

The produced resources belong to resource sets in which the kernel,
sectioned and structural metamodels are registered, so they can be
serialised with `XMISerializer` directly.

## Structural to Sectioned

Every non-empty section of a state becomes an `OpaqueStatement` and every
transition label an `OpaqueExpression`, each holding the exact host-language
text and the language of its machine. The first state of a machine is its
initial state, and its suspend state is kept. The machine boilerplate becomes
`HostDeclarations` of the sectioned machine: the includes and variables of
the machine first, then its functions, then the includes, variables and
functions of each state. Include paths have no place at the sectioned level
and are reported.

A structural arrangement holds a copy of a machine for every instance. The
sectioned arrangement holds one machine per machine name, which all
instances of that name share. A single structural machine becomes an
arrangement of the same name with one instance of that name; a structural
arrangement, which has no name of its own, is named by the
`arrangementName` argument.

A typing pass then makes the model as typed as the text allows:

1. ``VariableDeclarationScanner`` recognises simple declarations in the
   variables of each machine, such as `int counter;`, `bool flag;`,
   `unsigned ticks;` and `int samples[4];`, each optionally followed by a
   `///<` comment. Each becomes a kernel `Variable` of the machine with a
   conservative type: `int` and `signed` the 32-bit integer range,
   `unsigned` its non-negative part, `bool` the Boolean type, and arrays of
   these named after their element type and size, such as `intArray4`. The
   recognised lines are removed from the host declarations; every other line
   is kept verbatim.
2. ``ExpressionTyper`` types every opaque label and section against the
   variables and functions of the machine and the arrangement. A label or
   section that types completely is replaced by typed kernel nodes; anything
   else stays opaque with its exact text.

## The Typed Subset

The typer never guesses. Text types only if all of it lies in the subset,
every name it uses is declared, and it is well typed under the kernel
typing rule; a label must also be Boolean and call only pure functions. A
section types only as a whole. Text that is outside the subset, parses only
in part or names an undeclared variable becomes a single opaque node with
the exact original text.

| construct | C family | Swift | Java |
|---|---|---|---|
| literals | `true`, `false`, decimal integers | same | same |
| names | declared variables, `a[i]` for arrays | same | same |
| operators | `!`, unary `-`, `* / %`, `+ -`, `< <= > >=`, `== !=`, `&&`, `\|\|` with C precedence | the same operators; comparisons do not chain | as the C family |
| conditional | `c ? a : b` | same | same |
| time | `timeout(e)`, `after(e)`, `after_ms(e)` | | |
| calls | `f(args)` and `recv.f(args)` of declared functions | same | same |
| statements | `x = e;`, `x[i] = e;`, `f(args);`, `recv.f(args);` | the same, ended by `;` or a line break | as the C family |
| output | `printf("text\n");`, `puts("text");` | `print("text")` | `System.out.println("text");` |

The C family comprises the languages `c`, `c++`, `cpp`, `cxx`, `objc`,
`objc++` and `objcpp`. The time helpers hold once the time since the current
state was entered exceeds their argument, in microseconds, seconds and
milliseconds respectively, and become a `StateTimeExpression` compared with
the argument. A print statement types only for plain literal text: no
escapes other than the final `\n` that `printf` requires, and no `%`
conversions in a `printf` format. Integer literals must be plain decimal
numbers within the 32-bit range. Comments, preprocessor directives, control
flow, increments, member access and pointer dereferences are outside the
subset.

``ExpressionTyper`` can also be used on its own:

```swift
let scope = await ExpressionTyper.Scope(machine: machineID, in: resource, metamodel: metamodels.kernel)
let typer = ExpressionTyper(language: "c", scope: scope)
let label = await typer.condition(from: "counter < 10", in: resource, metamodel: metamodels.sectioned)
```

## Sectioned to Kernel

The encoding follows <doc:SectionedSemantics> under the options of
``SectionedToKernelOptions``, which defines the option names and values:

| option | values (default first) |
|---|---|
| `selfLoop` | `traditional`, `reentry` |
| `elideEmptySections` | `true`, `false` |
| `suspension` | `encode`, `omit` |
| `resumeFallback` | `initial`, `previous` |
| `time` | `external`, `clock` |
| `inState` | `expand`, `exact` |

``SectionedToKernelOptions/init(keyValues:)`` reads options from `key=value`
pairs, rejecting unknown names, repeated names and values an option does not
accept. Options are `Codable`; options missing from the coded data keep
their defaults.

The kernel states that encode a sectioned state `S` are named `S` (entry),
`S_i` (internal), `S_w` (resting), `S_x0`, `S_x1` and so on (exit, per
transition), `S_s` (suspend) and `S_r` (resume); the state that dispatches a
resumption from a suspend state `Z` is named `Z_d`. The encoding adds, as
needed, the shared variable `now` and the local variable `enteredAt` of the
integer type `Time`, the shared Boolean `suspend<Machine>` and the local
variable `resumeTo` of the enumeration `<Machine>States`, a Boolean type
`Bool` when the model declares none, and, with `time=clock`, the machine
`Clock` with the state `Tick` and the instance `clock`. Every kernel state
and transition that the encoding creates records its origin (see
``OriginAnnotations``). These names are reserved: a sectioned model should
not use them for its own elements. Validate an encoding with
``KernelValidator`` under the strict profile when the sectioned model holds
no opaque nodes and no host declarations, and under the relaxed profile
otherwise.

## Kernel to Sectioned

A kernel machine whose states record their origins is rebuilt as the
sectioned machine it encodes: entry states become sectioned states, the
actions of the states that encode the same sectioned state become its exit,
internal, suspend and resume sections, time and in-state expressions are
folded back, and assignments of a suspension request become machine control
statements. The variables, types, machine and instance added by the encoding
are dropped. Encoding a sectioned model that does not use the reserved
names and rebuilding it therefore gives the original model, except for what
the encoding reports as dropped.

A kernel machine without origin records is mapped flatly: every state
becomes an ordinary sectioned state whose action is its entry section,
pass-through states included, and the labels are copied. The execution
semantics of the result differ from those of the kernel machine, which the
diagnostics report.

## Diagnostics

``TransformationWarning/Kind`` lists what a transformation can lose:

- ``TransformationWarning/Kind/droppedText(section:owner:)``: host-language
  text without a place at the target level, such as an include path;
- ``TransformationWarning/Kind/suspensionOmitted(machine:)``: suspension was
  not encoded under `suspension=omit`;
- ``TransformationWarning/Kind/sharedSuspension(machine:instances:)``:
  several instances of a suspensible machine share one suspension request;
- ``TransformationWarning/Kind/controlDropped(operation:instance:)``: a
  restart, or a suspend or resume request whose suspension is not encoded,
  was dropped;
- ``TransformationWarning/Kind/flatMapping(machine:)``: a kernel machine
  without origin records was mapped flatly.

## Topics

### Running Transformations

- ``LLFSMTransformations``
- ``TransformationResult``
- ``SectionedToKernelOptions``

### Typing Host-Language Text

- ``ExpressionTyper``
- ``VariableDeclarationScanner``
- ``ScannedType``

### Diagnostics and Errors

- ``TransformationDiagnostics``
- ``TransformationWarning``
- ``LLFSMTransformationError``
- ``SectionedToKernelOptionsError``
