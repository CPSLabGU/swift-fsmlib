# swift-fsmlib

A cross-platform Swift library for Logic-Labelled Finite-State Machines
(LLFSMs) and FSM conversion tools.

## Overview

`swift-fsmlib` provides robust, type-safe tools for defining, analysing,
serialising, and converting finite-state machines. It supports both
macOS and Linux and is designed for research and production use.

- **FSM**: Core framework for state machines, including states,
  transitions, state activities, language bindings, and code generation.
- **fsmconvert**: Command-line tool for converting machines between
  language formats and creating arrangements from multiple FSMs.

## Features

- Type-safe state and transition definitions with UUID-based identifiers
- Logic-Labelled FSM model with Boolean transition expressions
- Suspend and resume support for interruptible state machines
- C and Objective-C++ language bindings with code generation
- Arrangements for composing multiple FSMs into coordinated systems
- CMake build system integration for generated code
- Layout and geometry types for graphical FSM editors
- Round-trip serialisation via `.machine` and `.arrangement` directory
  bundles

## Installation

Add `swift-fsmlib` as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CPSLabGU/swift-fsmlib.git", from: "1.0.0")
]
```

Then add `FSM` as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FSM", package: "swift-fsmlib")
    ]
)
```

## Quick Start

```swift
import FSM

// Define states
let red = State(name: "Red")
let green = State(name: "Green")

// Define transitions with Boolean expressions
let toGreen = Transition(label: "after_ms(5000)", source: red.id, target: green.id)
let toRed = Transition(label: "after_ms(5000)", source: green.id, target: red.id)

// Create a logic-labelled FSM
let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed])

print("States: \(fsm.stateNames)")
print("Initial state: \(fsm.initialState)")
```

## Using fsmconvert

Convert a machine to a different language format:

```bash
swift run fsmconvert MyMachine.machine -f c -o MyMachine_C.machine
```

Create an arrangement from multiple machines:

```bash
swift run fsmconvert Machine1.machine Machine2.machine -a -o System.arrangement
```

Run with verbose output:

```bash
swift run fsmconvert MyMachine.machine -v -o output.machine
```

## Examples

The `examples/` directory contains pre-built machines and arrangements:

- `Counter.machine` / `CounterC.machine` / `CounterCPP.machine`:
  Basic counter FSMs in different language formats.
- `SuspendCounter.machine` / `SuspendCounterC.machine`:
  Suspensible counter FSMs demonstrating suspend and resume.
- `SuspendCounter.arrangement` / `Counter.arrangement`:
  Multi-machine arrangements.

See `examples/README.md` for detailed descriptions.

## Documentation

Generate DocC documentation locally:

```bash
swift package generate-documentation
```

Preview the documentation in a browser:

```bash
swift package --disable-sandbox preview-documentation --target FSM
```

The documentation includes:
- API reference for all public types and functions
- Conceptual articles on architecture, language bindings, and
  arrangement design
- Hands-on tutorials for getting started, working with examples,
  and using fsmconvert

## Licence

Copyright &copy; 2015, 2016, 2023, 2025 Rene Hexel. All rights reserved.
