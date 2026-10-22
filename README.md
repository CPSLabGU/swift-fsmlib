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

Generate an SCXML file through a bundled MTL template (the bundled templates are `structural2machine`, `structural2scxml`, `structural2cmake`, and `structural2layout`):

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

The `--transform` option accepts `structural2machine`, `structural2scxml`, `structural2cmake`, and `structural2layout`, and requires `--metamodel structural`. The value `--metamodel executable` is deprecated: it maps to the planned `sectioned` level, prints a deprecation warning, and exits with an error because that level is not yet available.

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
