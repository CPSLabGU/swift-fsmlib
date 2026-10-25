# swift-fsmlib

`swift-fsmlib` provides Logic-Labelled Finite-State Machine (LLFSM) types, file-format support, code generation, and metamodel-backed workflows for Swift packages and command-line tools.

The package is split into three main surfaces:

- `FSM` contains the native machine, arrangement, serialisation, and code-generation APIs.
- `FSMEcore` adds the structural, sectioned and kernel Ecore metamodels, kernel model validation, XMI round-tripping, and MTL model-to-text generation.
- `fsmconvert` wraps both modules in a command-line interface for native format conversion, arrangement assembly, XMI import and export, and template-driven generation.

## Background

The native Swift types remain the production reference implementation. They define the file formats that `swift-fsmlib` reads and writes today, and they act as the regression oracle for metamodel-backed workflows.

The metamodel layer adds a structural view of the same domain. The structural metamodel mirrors the current Swift runtime shape and is the fidelity model for `.machine`, `.arrangement`, `.scxml`, and structural XMI round-trips. Two further levels describe machines with typed, language-neutral expressions and statements: the `sectioned` level is the traditional view with entry, exit, internal, suspend and resume sections, and the `kernel` level is the sectionless core with one action per state, ordered Boolean labels and pass-through states, into which sectioned models are encoded.

## Overview

The library supports:

- Type-safe state and transition definitions with UUID-based identifiers.
- Logic-labelled LLFSM execution structure with suspend and resume support.
- Native `.machine`, `.arrangement`, and `.scxml` serialisation and parsing.
- C, Objective-C++, Swift, and SCXML-oriented generation paths.
- Structural metamodel workflows built on Ecore and MTL.
- Sectioned and kernel metamodels with validation of kernel models under strict and relaxed profiles.
- Layout and geometry support for editor-facing round-trips.

## Package Layout

```text
Sources/FSM/          Native LLFSM and arrangement APIs.
Sources/FSMEcore/     Structural, sectioned and kernel metamodel support.
Sources/fsmconvert/   Command-line interface and DocC for the tool.
Tests/                Unit and end-to-end regression coverage.
examples/             Sample machines, SCXML files, and arrangements.
```

## Building

Build the package with Swift Package Manager:

```bash
swift build
```

Run the test suite:

```bash
swift test
```

Some tests compile and run generated programs or check generated models, and run only when the tools they need are installed; `TESTING.md` lists them, together with the environment variables that control the tests.

### WebAssembly (WASI)

`FSM`, `FSMEcore` and `fsmconvert` also build for WebAssembly (`wasm32-unknown-wasip1`) with the Swift 6.4 toolchain and its WebAssembly Swift SDK. Install the SDK as described in the [Swift WebAssembly guide](https://www.swift.org/documentation/articles/wasm-getting-started.html), then build with the native build system:

```bash
swift build -c release --build-system native \
  --swift-sdk swift-6.4.0-RELEASE_wasm \
  -Xlinker -z -Xlinker stack-size=8388608
```

The bundled metamodels, templates and transformations of `FSMEcore` are not linked into the module: they sit in the `FSM_FSMEcore.resources` directory beside the built `.wasm` module, where `FSMEcore` looks for them at run time, and then in the current directory. Keep that directory next to the module when you copy it, and grant the WASI runtime access to it and to the files the module reads and writes. For example, from the package directory, with the `wasmkit` runtime that the Swift 6.4 toolchain includes:

```bash
wasmkit run --stack-size 67108864 --dir . --dir /tmp \
  .build/wasm32-unknown-wasip1/release/fsmconvert.wasm \
  examples/Counter.machine --format scxml -o /tmp/Counter.scxml
```

`wasmtime` passes only the file name of the module to it, so run it in the directory of the module and map that directory as the root directory of the guest, whose current directory then holds the resources:

```bash
cd .build/wasm32-unknown-wasip1/release
wasmtime run -W max-wasm-stack=67108864 --dir .::/ --dir /tmp \
  fsmconvert.wasm /tmp/Counter.machine --format scxml -o /tmp/Counter.scxml
```

`TESTING.md` describes how to run the tests under a WASI runtime.

## Platform Support

| platform | support |
|---|---|
| macOS | libraries, `fsmconvert` and all tests |
| Linux | libraries, `fsmconvert` and all tests |
| Windows | libraries and `fsmconvert` |
| WebAssembly (WASI) | libraries and `fsmconvert`; the Swift Testing tests that need no other processes |

On WASI, files are written directly instead of atomically, as the platform has no temporary files for an atomic replace, and property lists are written by the package itself in the same XML format that Foundation writes on the other platforms.

## Installation

Add `swift-fsmlib` as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CPSLabGU/swift-fsmlib.git", from: "1.0.0")
]
```

Then add the product you need to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FSM", package: "swift-fsmlib"),
        .product(name: "FSMEcore", package: "swift-fsmlib")
    ]
)
```

## Native Usage

Construct a machine directly in Swift:

```swift
import FSM

let idle = State(name: "Idle")
let running = State(name: "Running")
let start = Transition(label: "start", source: idle.id, target: running.id)
let stop = Transition(label: "stop", source: running.id, target: idle.id)

let llfsm = LLFSM(states: [idle, running], transitions: [start, stop], suspendState: nil)
var machine = Machine()
machine.llfsm = llfsm
```

Inspect the resulting machine:

```swift
print(machine.llfsm.stateNames)
print(machine.llfsm.initialState)
```

Write a machine bundle or SCXML file through the native storage layer:

```swift
import FSM
import Foundation

let outputURL = URL(fileURLWithPath: "Example.machine")
try machine.write(to: outputURL, isSuspensible: true)
```

## Metamodel Usage

Write a structural XMI document:

```swift
import FSM
import FSMEcore
import Foundation

let metamodel = try await LLFSMMetamodel()
let roundTrip = XMIRoundTrip(metamodel: metamodel)
try await roundTrip.write(machine: machine, name: "Example", to: URL(fileURLWithPath: "Example.xmi"))
```

Generate an SCXML file through the bundled MTL templates:

```swift
import FSM
import FSMEcore
import Foundation

let generator = StructuralTemplateGenerator()
try await generator.generateSCXML(
    for: machine,
    named: "Example",
    to: URL(fileURLWithPath: "Example.scxml")
)
```

### Kernel and Sectioned Metamodels

Load the sectioned and kernel metamodels, read a kernel model and validate it:

```swift
import ECore
import FSMEcore
import Foundation

let metamodels = try await LLFSMMetamodels()
let resourceSet = ResourceSet()
await metamodels.register(in: resourceSet)
let resource = try await XMIParser(resourceSet: resourceSet)
    .parse(URL(fileURLWithPath: "Example.xmi"))

let validator = KernelValidator(metamodel: metamodels.kernel, profile: .strict)
for diagnostic in await validator.validate(resource) {
    print(diagnostic)
}
```

Kernel documents use the namespace `http://cpslabgu.github.io/llfsm/kernel` and sectioned documents `http://cpslabgu.github.io/llfsm/sectioned`; a sectioned document contains kernel statements and expressions under the kernel namespace. The strict profile admits only typed kernel nodes; the relaxed profile also admits opaque host-language expressions, statements, types and host declarations. Each diagnostic names its rule (`STRUCT`, `W1` to `W9`, `W7?` or `STRICT`), its severity, the path of the offending object and a message. The `MetamodelLevels` and `SectionedSemantics` articles in the `FSMEcore` documentation describe the levels, the rules and the execution semantics.

### Kernel Targets

`KernelTemplateGenerator` generates programs, verification models and drawings from a kernel model with the bundled MTL template sets:

| target | output |
|---|---|
| `kernel-c`, `kernel-cpp`, `kernel-swift`, `kernel-java` | a C11, C++20, Swift 6 or Java 17 program that runs the arrangement and prints its canonical trace |
| `smv` | a nuXmv or NuSMV model with range invariants |
| `tla` | a TLA+ specification with a TLC configuration |
| `dot` | a Graphviz drawing of the instances, states and transitions |

```swift
let generator = KernelTemplateGenerator(metamodel: metamodels.kernel)
let files = try await generator.generate(.smv, resource: resource,
                                         parameters: ["maxRounds": "20"], to: outputDirectory)
```

The model is validated first: the verification targets require the strict profile, the other targets the relaxed one. A generated program takes the number of rounds and an optional inputs file whose lines `<round> name=value` set external variables, and prints `arrangement <name>`, one line per `Print`, `R<round> <instance> <state>` after every ringlet and `halt R<round>` when the arrangement halts. The verification targets take the parameters `maxRounds`, `entry=ringlet|fused`, `sanity=true` and `opaque=reject|havoc`. The `KernelTargets` article in the `FSMEcore` documentation describes the targets, their parameters, the treatment of opaque host-language text and how to check the generated models with nuXmv and TLC.

### Transformations

Transform a structural machine into the sectioned level, encode it into the kernel and rebuild the sectioned model from the encoding:

```swift
import ECore
import FSM
import FSMEcore

let structural = try await LLFSMMetamodel()
let source = Resource(uri: "memory:/structural.xmi")
_ = await MachineEcoreCodec(metamodel: structural).encode(machine, name: "Lights", into: source)

let transformations = try await LLFSMTransformations()
let sectioned = try await transformations.structuralToSectioned(source)
let options = try SectionedToKernelOptions(keyValues: ["selfLoop=reentry", "time=clock"])
let kernel = try await transformations.sectionedToKernel(sectioned.resource, options: options)
let rebuilt = try await transformations.kernelToSectioned(kernel.resource)
let back = try await transformations.sectionedToStructural(rebuilt.resource)
await transformations.restoreLayouts(into: back.resource, from: source)
for warning in sectioned.diagnostics.warnings + kernel.diagnostics.warnings + back.diagnostics.warnings {
    print(warning)
}
```

The structural transformation keeps every section and label as opaque host-language text in the language of the machine, including text that holds only white space, and the boilerplate of each machine and state, with its include path, as host declarations of that machine or state. A typing pass then declares the simple variables of each machine (`int`, `unsigned`, `bool` and arrays of these), recording the line, text and comment of each declaration, and replaces each label and section that lies completely in the typed subset by typed kernel expressions and statements, for example `after(60)` by a comparison of the time since the state was entered, or `printf("go\n");` by a print statement; everything else stays opaque with its exact text. The encoding into the kernel follows the traditional execution order by default; the options `selfLoop`, `elideEmptySections`, `suspension`, `resumeFallback`, `time` and `inState` select the alternatives described in the `SectionedSemantics` article, and every kernel state and transition it creates records its origin, so that the inverse transformation rebuilds the sectioned model exactly. A kernel model without origin records is mapped flatly, which the diagnostics report. `sectionedToStructural(_:uri:)` turns a sectioned model back into a structural machine or arrangement, and `kernelToStructural(_:uri:)` does the same for a kernel model: opaque text comes back byte for byte, recognised variable declarations come back as written at their original lines, and typed nodes are written in the host language of the machine in the form that the typing pass reads back, such as `after(60)` or `printf("go\n");`. A structural machine or arrangement taken to the sectioned level and back is therefore written as the same bundle, byte for byte, except for its layouts, which the sectioned level does not keep: `restoreLayouts(into:from:)` copies them from the original structural model into the rebuilt one, matching states by name and transitions by source, position and target. Information that a sectioned or kernel model does not carry, such as the include paths, layouts and declaration texts of a model made at those levels, is reported by the diagnostics. The `Transformations` article in the `FSMEcore` documentation describes the typed subset, the names the encoding adds and the diagnostics.

## Template Engine

`FSMEcore` bundles MTL templates for every output format that has a Swift language binding: C, Objective-C++ and SCXML. They read a machine or an arrangement in the structural metamodel and write every file of the bundle byte for byte as the Swift bindings do, from the generated code and CMake files to the layout files and the Objective-C++ infrastructure headers. `TemplateBinding` turns their output into an output language, so the templates can take the place of a Swift language binding:

```swift
import FSM
import FSMEcore
import Foundation

let binding = try await TemplateBinding.make(for: machine, named: "Example", format: .c, isSuspensible: true)
try machine.write(to: URL(fileURLWithPath: "Example.machine"), language: binding, isSuspensible: true)
```

`TemplateBinding.make(for:named:format:isSuspensible:)` also renders an arrangement together with the bundles of its machines, which an `ArrangementWrapper` using the binding as its language then writes. The files are rendered for the given name and format, so write the bundle with the same name; machines are rendered in both suspensibility variants, and each bundle receives the variant that the Swift binding would write.

Each template set has its own directory with a `templateset.json` manifest below `Sources/FSMEcore/Resources/Templates/structural`, alongside shared modules for the files every machine bundle holds; files emitted verbatim, such as the infrastructure headers, are kept as plain resource files. Where the Swift arrangement code lists machine types in an unspecified order, the templates use the order of the first instance of each type.

## Command-Line Usage

Convert a native machine to SCXML:

```bash
fsmconvert Example.machine --format scxml --output Example.scxml
```

Export a machine as structural XMI:

```bash
fsmconvert Example.machine --metamodel structural --format xmi --output Example.xmi
```

Generate SCXML through a bundled structural template:

```bash
fsmconvert Example.machine \
  --metamodel structural \
  --transform structural2scxml \
  --output Example.scxml
```

The `--transform` option accepts `structural2machine`, `structural2scxml`, `structural2cmake`, and `structural2layout`, and requires `--metamodel structural`.

Native formats are written by the bundled templates, byte for byte as the Swift language bindings write them; `--generator swift` writes them with the Swift language bindings instead.

### Levels and Kernel Targets

`fsmconvert` reads XMI and JSON models at the structural, sectioned and kernel levels, recognising the level by the namespace of the root element, and transforms a model along the shortest chain of levels to the one that `--format` needs. `--format` accepts the native formats, `xmi` and `json` (at the level that `--metamodel` names, or at the level of the input), `structural-xmi`, `sectioned-xmi` and `kernel-xmi`, and the kernel targets `kernel-c`, `kernel-cpp`, `kernel-swift`, `kernel-java`, `smv`, `tla` and `dot`, whose files are written into the `--output` directory. With `--metamodel kernel`, `c`, `cpp`, `swift` and `java` name the kernel targets of those languages. The value `--metamodel executable` is a deprecated name of `sectioned` and prints a deprecation warning.

Write a machine as a kernel model, with self transitions that re-enter their state:

```bash
fsmconvert Example.machine --format kernel-xmi --semantics selfLoop=reentry --output Example.xmi
```

Generate a nuXmv model with a bounded round counter, and a C program:

```bash
fsmconvert Example.xmi --format smv --max-rounds 20 --output Verification
fsmconvert ExampleC.machine --metamodel kernel --format c --output Program
```

Validate the kernel model of a machine; each diagnostic is printed on standard error and the exit status is 1 if any is an error:

```bash
fsmconvert Example.machine --validate --profile strict
```

`--semantics option=value` sets the options of the encoding into the kernel (`selfLoop`, `elideEmptySections`, `suspension`, `resumeFallback`, `time`, `inState`). The verification targets take `--max-rounds N`, `--entry ringlet|fused`, `--sanity` and `--opaque reject|havoc`; `--param name=value` and `--template-path` pass parameters and module directories to the templates, `--reference-style plain` writes XMI as the Eclipse Modeling Framework does, and `--unset-features undefined` reads unset features as undefined. Warnings are printed on standard error, and a progress bar is shown when standard error is a terminal; `--quiet` hides both. Native formats are not yet written from sectioned or kernel models. The `fsmconvert` documentation describes every option and target.

Create an arrangement from multiple machines:

```bash
fsmconvert Machine1.machine Machine2.machine --arrangement --output System.arrangement
```

Run with verbose output:

```bash
fsmconvert Example.machine --verbose --output output.machine
```

## Examples

The `examples/` directory contains sample machines, arrangements, and SCXML files that exercise the native and metamodel-backed workflows.

Representative examples include:

- `Counter.machine`, `CounterC.machine`, and `CounterCPP.machine` for basic machine formats.
- `SuspendCounter.machine` and `SuspendCounterC.machine` for suspend and resume behaviour.
- `Counter.arrangement` and `SuspendCounter.arrangement` for multi-machine composition.
- `Counter.scxml` and related SCXML samples for single-file interchange.

## Documentation

DocC catalogues are provided for:

- `FSM` at `Sources/FSM/FSM.docc`
- `FSMEcore` at `Sources/FSMEcore/FSMEcore.docc`
- `fsmconvert` at `Sources/fsmconvert/fsmconvert.docc`

Start with the package landing pages and tutorials there when you need the higher-level workflows or the expected conversion boundaries.

Generate DocC documentation locally:

```bash
swift package generate-documentation
```

Preview the documentation in a browser:

```bash
swift package --disable-sandbox preview-documentation --target FSM
```

## Licence

Copyright &copy; 2015, 2016, 2023, 2025, 2026 Rene Hexel. All rights reserved.
