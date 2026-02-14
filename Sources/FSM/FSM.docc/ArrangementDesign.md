# Arrangement Design

@Metadata {
  @PageKind(article)
}

A detailed look at how arrangements compose multiple finite-state
machines into coordinated systems, with a focus on the generated
code architecture.

## Overview

An ``Arrangement`` groups multiple FSM instances together so they
can be compiled and executed as a single coordinated system. Each
machine within an arrangement retains its own state-machine logic
while sharing a common execution infrastructure.

## Machine Type vs Instance

A key distinction in the arrangement architecture is between
machine *types* and machine *instances*:

**Machine Type**: A class or struct defining a state machine's
structure and behaviour. Each machine type is compiled into its
own static library. The type contains state classes, transition
logic, and behaviour definitions but creates no runtime instances.

**Machine Instance**: A runtime instantiation of a machine type.
Instances are created by the arrangement code and have a unique
machine ID and name. Multiple instances of the same type can
coexist within a single arrangement.

## Dual C/C++ Interface

Arrangement structures provide both C and C++ interfaces using
conditional compilation (`#ifdef __cplusplus`). This ensures
compatibility with both C-based tools and C++ implementations:

- **C API**: Uses `snake_case` member names and `void *` pointers,
  compiles with a plain C compiler.
- **C++ API**: Uses `camelCase` member names and typed pointers,
  provides type safety.

Both interfaces use the same `snake_case` wrapper functions for
initialisation and validation, ensuring a single API surface.

## Generated File Structure

### Machine Directory (`.machine/`)

Each machine compiles into a static library containing only
type definitions:

```
MyMachine.machine/
    MyMachine.h              # Machine type declaration
    MyMachine.mm             # Machine type implementation
    State_*.h                # State type declarations
    State_*.mm               # State type implementations
    State_*_OnEntry.mm       # User action code
    State_*_OnExit.mm        # User action code
    State_*_Internal.mm      # User action code
    State_*_Transition_*.expr  # Transition expressions
    *_VarRefs.mm             # Variable reference helpers
    CMakeLists.txt           # Builds machine library
    project.cmake            # CMake fragment
```

### Arrangement Directory (`.arrangement/`)

Arrangements link against machine libraries and create instances:

```
MySystem.arrangement/
    infrastructure/
        CLMachine.h            # Generic base class
        CLState.h              # Generic state base
        CLAction.h             # Generic action base
        CLTransition.h         # Generic transition base
        CLMacros.h             # Runtime macros
        Machine_Common.h       # Common utilities
        StateMachineVector.h   # Execution vector
        StateMachineVector.cc  # Implementation
    Machine1.machine/          # Machine library
    Machine2.machine/          # Machine library
    Arrangement_MySystem.h     # Arrangement structure
    Arrangement_MySystem.mm    # Arrangement implementation
    Static_Arrangement.h       # Static instances
    Static_Arrangement_MySystem.mm
    static_main.cc             # Main entry point
    CMakeLists.txt             # Builds arrangement
    project.cmake              # CMake fragment
```

## Infrastructure Layer

The generic infrastructure classes form the base layer shared by
all arrangements. These classes reside in the `FSM` namespace and
include:

- **CLMachine**: Abstract base class for all machine types, providing
  state management, suspension, and execution control.
- **CLState**: Base class for states, with actions for entry, exit,
  internal, suspend, and resume.
- **CLAction**: Abstract base class for state actions.
- **CLTransition**: Abstract base class for transitions with a
  Boolean check method.
- **StateMachineVector**: Execution engine that cycles through all
  machines in an arrangement.

## Build System

The CMake build system follows a modular structure:

1. Each machine type compiles into a static library (e.g.,
   `libMyMachine_fsm.a`).
2. Machine libraries contain only type definitions, no instances.
3. The arrangement executable links against all machine libraries.
4. Instance creation happens in the arrangement's static
   initialisation code.

This separation allows machines to be built and tested in
isolation, reused across multiple arrangements, and compiled
only once regardless of how many instances exist.
