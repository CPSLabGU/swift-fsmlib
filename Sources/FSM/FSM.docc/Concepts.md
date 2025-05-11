# FSM Concepts

This page covers key concepts underpinning the ``FSM`` framework.

## Machines

A ``Machine`` represents the structure and behavioural setting
of a finite state machine, including its transitions, layouts,
and associated boilerpate for the language it is expressed in.

### States

The behavioural steps of the system is represented by States.
A state is represented by the ``StateNode`` concept (protocol)
and implemented by the ``State`` struct.

The actual behaviour of a state is expressed in a language
through a ``LanguageBinding`` implementation in different
sections of the state.  Sections represent the semantics
of state behaviour that form ``StateActivities``.
For example, a state in a logic-labelled finite state machine
may have an `onEntry` section that defines what happens
if the state has just been transitioned into.

### Transitions

A ``Transition`` defines how an FSM moves from one state to another.
Each transition has a label, a source state, and a target state.
In a logic-labelled finite state machine, the label is a Boolean
expression that determines whether a transition should fire
(if the expression evaluates to `true`) or not.

## Languages

The behaviour of a state machine is expressed in a programming
language through a concrete type that conforms to the
``LanguageBinding`` protocol.  A language binding that can
be serialised (written to storage) needs to conform to the
``OutputLanguage`` protocol.

## Arrangements

A collection of finite state machines can be composed into
complex system behaviour through an ``Arrangement``.
In an arrangement, machines can interact and control
each other, implementing structural concepts such as
the subsumption architecture.

## Serialisation

FSMs can be serialised to and from various formats
for persistence and interoperability.
The serialised representation of a machine is captured by
a ``MachineWrapper``, and the serialised representation
of an arrangement is captured by an ``ArrangementWrapper``.
