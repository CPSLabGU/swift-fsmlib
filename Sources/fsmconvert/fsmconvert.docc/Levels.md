# Levels and Targets

Convert machines between the structural, sectioned and kernel levels, and
generate programs, verification models and drawings from them.

@Metadata {
  @PageKind(article)
}

## Overview

`fsmconvert` describes a logic-labelled finite-state machine at one of three
levels:

| level | what it holds | read from |
|---|---|---|
| `structural` | the native machines and arrangements with their host-language code sections and layout | `.machine` and `.arrangement` bundles, SCXML documents, structural XMI or JSON |
| `sectioned` | the traditional view with entry, exit, internal, suspend and resume sections, written with typed expressions and statements where the code allows | sectioned XMI or JSON |
| `kernel` | the sectionless core with one action per state, from which the kernel targets are generated | kernel XMI or JSON |

The level of an XMI or JSON input is recognised by the namespace of its root
element, so no option is needed to read it. `fsmconvert` then transforms the
model along the shortest chain of levels to the one that the output target
needs: a native machine becomes a sectioned model and then a kernel model
before a kernel target is generated from it, while a kernel model is
generated from directly.

## Output Targets

`--format` names what is written:

| targets | level | output |
|---|---|---|
| `c`, `c++`, `cpp`, `cxx`, `objc`, `objc++`, `objcpp`, `scxml`, `swift`, `verilog`, `vhdl` | structural | a machine or arrangement bundle, or an SCXML document |
| `xmi`, `json` | the level of `--metamodel`, or the level of the input | a model document |
| `structural-xmi`, `sectioned-xmi`, `kernel-xmi` | the named level | an XMI document |
| `kernel-c`, `kernel-cpp`, `kernel-swift`, `kernel-java` | kernel | a C11, C++20, Swift 6 or Java 17 program that runs the arrangement and prints its canonical trace |
| `smv` | kernel | a nuXmv or NuSMV model |
| `tla` | kernel | a TLA+ specification and its TLC configuration |
| `dot` | kernel | a Graphviz drawing |

Without `--format`, a native machine keeps the format that the output name
implies, and an output ending in `.xmi` or `.json` names a model document.
The files of a kernel target are written into the directory that `--output`
names.

With `--metamodel kernel`, the language names `c`, `cpp`, `swift` and `java`
stand for the kernel targets of those languages, and `xmi` and `json` write
kernel models. Without `--metamodel`, every native format keeps the meaning
it has always had, and `xmi` keeps it for native inputs; use
`structural-xmi`, `sectioned-xmi` or `kernel-xmi` to choose the level of an
XMI document instead.

## Native Formats

Native formats are written by the bundled MTL templates, byte for byte as the
Swift language bindings write them. `--generator swift` writes them with the
Swift language bindings instead. Formats that no template set writes, such as
`swift`, are always written by the Swift language bindings.

Native formats are written from the structural level. Sectioned and kernel
models cannot be written in native formats in this release: `fsmconvert`
reports that the transformation to the structural level is not available.

## Encoding into the Kernel

`--semantics option=value` chooses how a sectioned model is encoded into the
kernel. The option can be given several times:

| option | values (default first) |
|---|---|
| `selfLoop` | `traditional`, `reentry` |
| `elideEmptySections` | `true`, `false` |
| `suspension` | `encode`, `omit` |
| `resumeFallback` | `initial`, `previous` |
| `time` | `external`, `clock` |
| `inState` | `expand`, `exact` |

What a transformation cannot keep, such as host-language text that has no
place at the target level, is reported as a `warning:` line on standard
error.

## Validation

`--validate` transforms the input to the kernel, validates it and prints one
line per diagnostic on standard error, such as
`error: STRICT /Sampler/types[Reading]: The strict profile admits no OpaqueType`.
Nothing is written. The exit status is 1 if a diagnostic is an error and 0
otherwise.

`--profile strict`, the default of `--validate`, admits only typed kernel
nodes; `--profile relaxed` also admits opaque host-language expressions,
statements, types and host declarations. When a kernel target is generated,
the model must satisfy the profile that the target requires, the strict
profile for `smv` and `tla` and the relaxed profile otherwise, and also the
profile given with `--profile`.

## Verification Targets

The `smv` and `tla` targets take these options:

| option | effect |
|---|---|
| `--max-rounds N` | bounds the round counter (default 0: no counter) |
| `--entry ringlet` or `--entry fused` | runs the action of a state in a micro-step of its own at the start of the next ringlet (the default), or in the micro-step of the transition that enters it |
| `--sanity` | adds sanity properties |
| `--opaque reject` or `--opaque havoc` | rejects opaque nodes (the default), or leaves opaque values unconstrained and opaque statements without effect, which also lets the relaxed profile apply |

## Templates

`--param name=value` passes a parameter to the templates of native formats
and kernel targets; the verification options above take precedence over
parameters of the same names. `--template-path` names a directory that is
searched for imported modules before the bundled ones.
`--unset-features undefined` makes transformations and templates read every
unset feature as undefined, and `--reference-style plain` writes XMI with
references as the Eclipse Modeling Framework writes them.

## Examples

Generate a nuXmv model from a kernel model:

```bash
fsmconvert DoorInterlock.xmi --format smv --max-rounds 20 --output Verification
```

Generate a C program from a native C machine through the kernel:

```bash
fsmconvert CounterC.machine --metamodel kernel --format c --output Program
```

The opaque host-language text of a machine can only be generated for its own
language, so an Objective-C++ machine cannot be generated as `kernel-c`.

Write a native machine as a kernel model with re-entering self transitions:

```bash
fsmconvert Counter.machine --format kernel-xmi --semantics selfLoop=reentry --output Counter.xmi
```

Check whether a model can be model checked; each diagnostic names an element
that stands in the way:

```bash
fsmconvert CounterC.machine --validate --profile strict
```

Generate a TLA+ specification from a machine whose code is not in the typed
subset:

```bash
fsmconvert TrafficLight.machine --format tla --opaque havoc --output Verification
```

Draw a sectioned model:

```bash
fsmconvert Crossing.xmi --format dot --output Drawing
```
