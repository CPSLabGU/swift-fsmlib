# Kernel Targets

Generate programs, verification models and drawings from kernel models.

## Overview

``KernelTemplateGenerator`` runs the bundled MTL template sets on a kernel
arrangement. Each ``KernelTarget`` has its own template set:

| target | files | purpose |
|---|---|---|
| `kernel-c` | `<Arrangement>.c` | C11 program that runs the arrangement |
| `kernel-cpp` | `<Arrangement>.cpp` | C++20 program that runs the arrangement |
| `kernel-swift` | `<Arrangement>.swift` | Swift 6 program that runs the arrangement |
| `kernel-java` | `<Arrangement>.java` | Java 17 program that runs the arrangement |
| `smv` | `<Arrangement>.smv` | nuXmv or NuSMV model |
| `tla` | `<Arrangement>.tla`, `<Arrangement>.cfg` | TLA+ specification and TLC configuration |
| `dot` | `<Arrangement>.dot` | Graphviz drawing |

The programs print the canonical trace of the arrangement, so the four
execution targets can be compared with each other and with a trace derived
by hand from the kernel semantics. The verification targets encode the
same semantics for model checking.

## Generating

```swift
let metamodels = try await LLFSMMetamodels()
let generator = KernelTemplateGenerator(metamodel: metamodels.kernel)
for target in KernelTemplateGenerator.availableTargets() {
    let files = try await generator.render(target, resource: resource)
    for file in files {
        print(target.rawValue, file.path)
    }
}
let written = try await generator.generate(.tla, resource: resource,
                                           parameters: [KernelTemplateParameter.maxRounds: "20"],
                                           to: outputDirectory)
```

``KernelTemplateGenerator/render(_:resource:parameters:)`` returns the
generated files ordered by path, and
``KernelTemplateGenerator/generate(_:resource:parameters:to:)`` writes them
to a directory and returns their locations.

The model is validated before generation under the profile that
``KernelTarget/validationProfile(parameters:)`` names: the verification
targets require ``ValidationProfile/strict`` unless opaque nodes are
havocked, and the other targets accept ``ValidationProfile/relaxed``. A
diagnostic with severity ``KernelDiagnostic/Severity/error`` stops the run
with ``KernelTemplateGeneratorError/invalidModel(_:_:)``. Problems that only
the templates can detect, such as opaque text written for another language
or an unknown parameter value, stop it with
``KernelTemplateGeneratorError/templateErrors(_:_:)``; each message starts
with the path of the offending element, written as in validation
diagnostics, or with the name of the parameter.

Each template set lives in `Templates/kernel/<target>/` of the `FSMEcore`
resources and is described by its `templateset.json`
(``KernelTemplateSet``): the main module and template, and the directories
of the shared modules in `Templates/expressions/`, which render expressions
and statements once per language.

## Canonical Trace

A generated program writes to standard output, in this order:

```
arrangement <name>
<Print text>[ <value>]*
R<round> <instance> <state>
halt R<round>
```

The first line names the arrangement. Each executed `Print` statement
writes one line as it happens: its text, then each value after a space.
After every ringlet, the program writes the state in which the instance
rests. When, after a complete round, every instance is in a state without
transitions and has run that state's action, the program writes the halt
line and stops. Integers are written in decimal, Booleans as `true` and
`false`, and enumeration values by their literal.

A program takes two optional arguments: the number of rounds to run
(default 20) and an inputs file. It stops after that many rounds unless the
arrangement halts earlier. When a value leaves the range of its integer
variable, or an index leaves its array, the program writes
`range violation <variable>` to standard error and exits with status 2.

## Inputs Files

An inputs file sets external variables at the start of a round. Each line
holds a round number and assignments, separated by spaces:

```
1 now=0 request=false
3 now=2 request=true
4 doorClosed=true sensors[1]=3
```

`name=value` sets an external variable and `name[index]=value` one element
of an external array. Values are written as in the trace. An external
variable that a line does not set keeps its previous value, which starts as
its initial value or the default of its type. Every ringlet reads one
snapshot of the external variables, taken when it starts. An assignment
that names no external variable or a value outside its type stops the
program with `invalid input <assignment>` and status 1.

## Execution Targets

The programs compile under strict settings, for example:

```bash
cc -std=c11 -Wall -Wextra -Werror Model.c -o Model
c++ -std=c++20 -Wall -Wextra -Werror -pedantic Model.cpp -o Model
swiftc -swift-version 6 -parse-as-library -warnings-as-errors Model.swift -o Model
javac --release 17 -Xlint:all -Werror Model.java && java Model 20 Model.inputs
```

Variables keep their model names in the generated code, so that opaque
text can refer to them: in the action and the labels of a machine, its
local variables, the shared variables and the snapshot of the external
variables are all visible under their own names. Declared types keep their
names too (Java maps the typed kernel types to `boolean`, `int`, nested
enumerations and arrays). A local variable must not have the name of a
shared variable. Names that start with `llfsm` or `LLFSM` are reserved for
the generated code.

Host declarations apply to the target whose language they name: `c`,
`cpp`, `swift` or `java`. A host declaration, or an opaque node, without a
language of its own takes the language of its machine, else that of the
arrangement. Opaque text for another language than the target's is a
generation error. The `includes` of the host declarations follow the
standard imports of the generated file; the `declarations` follow the
typed kernel types, so they can use them, and come before the variables.
An opaque type is an alias of its text (in Java, its text is used where the
type appears).

Calls of declared functions:

- A call without a receiver is `f(arguments)`. The C and C++ targets
  declare a prototype for every such function, so its implementation can
  come from the host declarations or from another source file. Swift
  passes the arguments without labels, so the implementation declares its
  parameters with `_`. Java has no free functions: a call of `f` is
  `<Arrangement>Host.f(arguments)`, a static method of a class that the
  host declarations or another source file provide.
- A call with a receiver is `receiver.f(arguments)`; in C the receiver is a
  structure whose member `f` points to the function.
- A call statement discards any result.

An opaque expression is generated as its text in parentheses and an opaque
statement as its text, followed by `;` where the language needs one and the
text has none. A variable of an opaque type without an initial value starts
with the default of the host language: zero in C, value initialisation in
C++, `T()` in Swift and the field default in Java.

`Print` chooses how to write a value by the value's type: the declared type
of an opaque expression, or the result type of a called function. Printing
a value whose type is unknown, or an array, is a generation error. A value
of an opaque type is written by the host: in C by `print_<Type>(value)`,
which the host declarations provide, in C++ with `operator<<`, in Swift
with its description and in Java with `toString()`.

## Verification Targets

The verification targets model one micro-step of the instance whose turn
it is per step: the action of a state that was entered, or the evaluation
of the labels of a state that was not. An action of a state without
transitions also ends the ringlet. External variables keep their values
within a ringlet and take any value when the turn advances, which realises
one snapshot per ringlet.

`Print` statements, call statements and host declarations do not change
the model. A pure function whose parameter and result types are typed
kernel types is uninterpreted: the model chooses one table of results for
every path, so the function returns the same value for the same arguments
but may be any function of those types. A call of a function that is not
pure can only be a statement.

| parameter | values (default first) | effect |
|---|---|---|
| `maxRounds` | `0`, or a bound | `smv`: a saturating round counter up to the bound, none for 0; `tla`: the value of the constant `MaxRounds` |
| `entry` | `ringlet`, `fused` | whether an action runs in its own micro-step at the start of the next ringlet, or in the micro-step of the transition that enters the state |
| `sanity` | `false`, `true` | adds properties that check that every state is reachable and every transition fires |
| `opaque` | `reject`, `havoc` | how opaque nodes are treated |

With `opaque=reject` every opaque node, and every call that the model
cannot represent (a function that is not pure, or one whose types are not
typed kernel types, outside a call statement), is a generation error. With
`opaque=havoc` the model is generated under the relaxed profile: the value
of an opaque expression, or of such a call, is unconstrained wherever it
is evaluated, opaque statements do nothing, variables of opaque types are
left out, and the generated file says so in its first lines. A model that
relies on the host for a property may then violate it.

### nuXmv and NuSMV

The `smv` model consists of the modules `RoundRobin` (the turn and the
round counter), `Environment` (the external variables), `Shared` (the
shared variables), `Functions` (the tables of the pure functions), one
module per machine, and `main`, which comes last so that further
properties can be appended to the file. Every integer variable has its
range as its type, and every shared or local one an `INVARSPEC` range
invariant. An assignment outside
the range leaves a state without successors, which `check_fsm` reports.
Check a model with a command file such as:

```
read_model -i Model.smv
flatten_hierarchy
encode_variables
build_model
check_invar
check_ctlspec
check_fsm
quit
```

```bash
nuXmv -source commands.txt
```

With `sanity=true` the model carries, for every instance, a `CTLSPEC` that
each state is reachable, one that each state with transitions can be left,
and one that each transition fires.

### TLA+ and TLC

The `tla` specification has one action per micro-step kind and state:
`Run` and `Finish` (the action of a state with and without transitions),
`Fire` and `Chain` (a transition into a state that ends or continues the
ringlet) and `Yield` (no label holds), and `Halt`, which repeats the state
once the arrangement has halted. `<Arrangement>.cfg` checks `TypeOK` and
one `Range_<variable>` invariant per integer variable:

```bash
java -cp tla2tools.jar tlc2.TLC -config Model.cfg Model.tla
```

With `sanity=true` the specification defines the invariants
`Sanity_Reach_<instance>_<state>` and `Sanity_<action>`, each with its own
configuration `<Arrangement>.<invariant>.cfg`. Each of them must be
violated: TLC's counterexample shows how the state is reached or the
transition fires.

## Diagram Target

The `dot` drawing has one cluster per instance. A state shows its name, the
sectioned element that it encodes when it records an origin, and the
statements of its action; an accepting state has a double outline and a
pass-through state a dashed one. Each transition is labelled with its
position among the transitions of its state and its label:

```bash
dot -Tsvg Model.dot -o Model.svg
```
