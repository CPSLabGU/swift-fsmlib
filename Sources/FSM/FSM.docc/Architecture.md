# Architecture

@Metadata {
  @PageKind(article)
}

An overview of the architectural patterns and component structure
of the ``FSM`` framework.

## Architectural Patterns

The library demonstrates several well-established software architecture
patterns, chosen for clarity, testability, and extensibility.

### Protocol-Oriented Design

Core concepts are defined as protocols that establish contracts for
implementations. ``FSM``, ``StateNode``, ``TransitionVertex``,
``LanguageBinding``, and ``OutputLanguage`` all define abstract
interfaces that concrete types conform to. This allows the framework
to be extended with new language bindings or state representations
without modifying existing code.

### Value Semantics

Most data structures are Swift value types (structs): ``State``,
``Transition``, ``Path``, ``Coordinate2D``, ``Rectangle``,
``StateLayout``, and ``TransitionLayout`` are all structs. This
ensures thread safety and predictable behaviour when copying or
passing FSM components around.

### Composition over Inheritance

Complex behaviours are built through composition of smaller
components rather than deep class hierarchies. A ``Machine``
*contains* an ``LLFSM``, a ``LanguageBinding``, layout data,
and boilerplate code, rather than inheriting from multiple
base classes.

### Builder Pattern

The ``CodeBuilder`` implements Swift's result builder pattern,
enabling declarative code generation. Language bindings use
`@CodeBuilder` closures to compose generated source code in a
readable, structured manner.

### Visitor Pattern

Language bindings act as visitors that traverse the abstract FSM
model and produce language-specific output. The ``CBinding`` and
``ObjCPPBinding`` each visit the same ``LLFSM`` structure but
generate different code.

## Component Structure

### FSM Core Model

The core model defines the abstract and concrete representations
of finite-state machines:

- ``FSM`` protocol and ``LLFSM`` struct define the state-machine logic.
- ``State`` and ``Transition`` represent the fundamental FSM components.
- ``SuspensibleFSM`` extends FSMs with suspend and resume capabilities.
- ``Machine`` wraps an ``LLFSM`` with metadata for serialisation.

### Layout System

Geometric primitives and visual layout types support graphical
FSM editors:

- ``Vector2D``, ``Coordinate2D``, and ``Rectangle`` provide
  2D geometry.
- ``StateLayout`` and ``TransitionLayout`` capture visual
  positioning.
- ``BezierPath`` and ``Path`` handle transition curve
  representations.

### Code Generation Engine

Language bindings drive code generation for target languages:

- ``LanguageBinding`` defines read operations (deserialisation).
- ``OutputLanguage`` extends with write operations (code generation).
- ``CBinding`` generates plain C machine and arrangement code.
- ``ObjCPPBinding`` generates Objective-C++ code with a C++ class
  hierarchy.
- ``CodeBuilder`` provides a declarative DSL for composing source code.

### Serialisation Layer

File-system wrappers handle persistence of machines and arrangements:

- ``DirectoryWrapper`` provides base directory operations.
- ``MachineWrapper`` reads and writes `.machine` directory bundles.
- ``ArrangementWrapper`` reads and writes `.arrangement` directory
  bundles.

### Arrangement System

The arrangement system composes multiple FSMs into coordinated
systems:

- ``Arrangement`` manages a collection of machine instances.
- ``Instance`` associates a machine with a name and type file.

## Data Flow

The typical data flow through the framework follows this path:

1. FSM models are defined with states and transitions.
2. Layout information is attached for visual representation.
3. A language binding is assigned for the target language.
4. Code generation produces language-specific source files.
5. File wrappers persist the FSM and generated code to disk.
6. Arrangements compose multiple FSMs for coordinated execution.

## Dependencies

The package has minimal external dependencies:

- **Foundation**: Basic data structures and file operations.
- **SystemPackage**: Cross-platform system-level operations.
- **ArgumentParser**: Command-line interface for `fsmconvert`.

## Platform Considerations

The library supports both macOS and Linux. Platform-specific
differences are handled through conditional compilation:

- `UUID_NULL` is defined for non-Darwin platforms.
- Dictionary mutation patterns differ between platforms.
- `#if canImport(Darwin)` guards platform-specific code paths.
