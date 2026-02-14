# Concepts

@Metadata {
  @PageKind(article)
}

An overview of the key concepts underpinning the ``FSM`` framework.

## Machines

A ``Machine`` represents the complete structure and behavioural specification
of a finite-state machine, including its transitions, graphical layout,
language binding, boilerplate code, and state activities. Internally, it
wraps an ``LLFSM`` instance that holds the core state-machine logic.

### Logic-Labelled Finite-State Machines

The library is built around the concept of Logic-Labelled Finite-State
Machines (LLFSMs). Unlike event-driven FSMs, LLFSMs evaluate all
transition labels (Boolean expressions) on every execution cycle.
If a transition's expression evaluates to `true`, the machine fires
that transition and moves to the target state. This model is
deterministic and well-suited to real-time and embedded systems.

### States

The behavioural steps of the system are represented by states.
A state is represented by the ``StateNode`` protocol
and implemented by the ``State`` struct. Each state has a unique
``StateID`` (a UUID) and a human-readable name.

The actual behaviour of a state is expressed in a programming language
through a ``LanguageBinding`` implementation. The behaviour is divided
into sections that form ``StateActivities``:

- **OnEntry**: Executed once when the state is first entered.
- **OnExit**: Executed once when leaving the state.
- **Internal**: Executed repeatedly whilst the state is active.
- **OnSuspend**: Executed when the machine is suspended in this state.
- **OnResume**: Executed when the machine resumes in this state.

These activities are indexed by ``StateActionIndex`` and named by
``StateActivityName``.

### Transitions

A ``Transition`` defines how an FSM moves from one state to another.
Each transition has a label expression, a source state, and a target state.
In an LLFSM, the label is a Boolean expression that determines whether a
transition should fire (if the expression evaluates to `true`) or not.

Transitions are modelled through a hierarchy of protocols:
``TransitionLabel``, ``TransitionSource``, ``TransitionTarget``,
``TransitionPath``, ``TargetTransition``, and ``TransitionVertex``.

## Language Bindings

The behaviour of a state machine is expressed in a programming language
through a concrete type that conforms to the ``LanguageBinding`` protocol.
A language binding that can be serialised (written to storage) must also
conform to the ``OutputLanguage`` protocol. The ``Format`` enumeration
maps format identifiers to their corresponding binding implementations.

Currently supported bindings:

| Binding | Formats | Description |
|---------|---------|-------------|
| ``CBinding`` | `.c` | Plain C machines |
| ``ObjCPPBinding`` | `.cx`, `.cpp`, `.cxx`, `.objC`, `.objCX`, `.objCPP` | Objective-C++ machines |

## Boilerplate

Language bindings use ``Boilerplate`` to manage the various code sections
associated with a machine and its states. For C-based languages, the
``CBoilerplate`` struct provides named sections such as includes,
variables, and function declarations that surround the state-activity code.

## Arrangements

A collection of finite-state machines can be composed into
complex system behaviour through an ``Arrangement``.
In an arrangement, machines can interact and control
each other, implementing structural concepts such as
the subsumption architecture.

Each machine within an arrangement is wrapped in an ``Instance``
that associates it with a name and type file, allowing multiple
instances of the same machine type.

## Serialisation

FSMs are serialised to and from `.machine` directory bundles, and
arrangements to `.arrangement` directory bundles. The serialisation
layer uses Foundation's `FileWrapper` class, extended through:

- ``DirectoryWrapper``: Base class for directory-based file wrappers.
- ``MachineWrapper``: Reads and writes `.machine` directories.
- ``ArrangementWrapper``: Reads and writes `.arrangement` directories.

A `.machine` directory typically contains:
- A `States` file listing state names
- Transition expression files (`State_<name>_Transition_<n>.expr`)
- A `Layout.plist` with graphical positioning data
- Language-specific boilerplate and code files

## Layout

The framework includes a geometry and layout system for graphical
FSM editors. ``StateLayout`` and ``TransitionLayout`` capture the
positions and dimensions of states and transitions, using types
such as ``Coordinate2D``, ``Rectangle``, and ``Path`` for
Bezier curve representations.

Layout data is stored in property lists and converted between
name-based (``StateNameLayouts``) and ID-based (``StateLayouts``)
representations during serialisation.
