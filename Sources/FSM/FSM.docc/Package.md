# ``FSM``

The ``FSM`` module provides a high-performance, type-safe framework
for defining and manipulating finite-state machines in Swift.
It is designed for both academic and production use, supporting extensibility
and cross-platform compatibility (macOS and Linux).

## Overview

Finite-state machines (FSMs) are mathematical models of computation widely used
in software engineering, linguistics, and hardware design. This library focuses
on Logic-Labelled Finite-State Machines (LLFSMs), where transitions are guarded
by Boolean expressions evaluated each execution cycle.

The library provides:
- Type-safe state and transition definitions
- Support for C, C++, Objective-C, and Objective-C++ language bindings
- Serialisation and deserialisation via file-system wrappers
- Arrangements for composing multiple FSMs into complex systems
- Layout and geometry types for graphical FSM editors
- Code generation for machine and arrangement implementations

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Concepts>
- <doc:Architecture>
- <doc:LanguageBindings>
- <doc:ArrangementDesign>

### Machines

- ``Machine``
- ``LLFSM``
- ``FSM``
- ``Suspensible``
- ``SuspensibleFSM``

### States

- ``State``
- ``StateNode``
- ``StateID``
- ``StateName``
- ``StateNames``
- ``StateArray``
- ``StateDictionary``

### Transitions

- ``Transition``
- ``TransitionID``
- ``Expression``
- ``TransitionLabel``
- ``TransitionSource``
- ``TransitionTarget``
- ``TransitionPath``
- ``TargetTransition``
- ``TransitionVertex``
- ``TransitionArray``
- ``TransitionDictionary``

### State Activities

- ``StateActivities``
- ``StateActivitiesSourceCode``
- ``StateActivityName``
- ``StateActionIndex``

### Arrangements

- ``Arrangement``
- ``Instance``

### Serialisation

- ``MachineDirectoryWrapper``
- ``ArrangementWrapper``
- ``DirectoryWrapper``
- ``PropertyList``

### Language Bindings

- ``LanguageBinding``
- ``OutputLanguage``
- ``Format``
- ``CBinding``
- ``ObjCPPBinding``

### Boilerplate

- ``Boilerplate``
- ``CBoilerplate``

### Layout

- ``StateLayout``
- ``StateNodeLayout``
- ``TransitionLayout``
- ``TransitionVertexLayout``
- ``StateLayouts``
- ``TransitionLayouts``
- ``StateNameLayouts``

### Geometry

- ``Vector2D``
- ``Coordinate2D``
- ``Point2D``
- ``Dimensions2D``
- ``Rectangle2D``
- ``Rectangle``
- ``Ellipse``
- ``BezierPath``
- ``Path``

### Code Generation

- ``Code``
- ``MachineName``
- ``Filename``

### Errors

- ``FSMError``

### Tutorials

- <doc:Table-of-Contents>
