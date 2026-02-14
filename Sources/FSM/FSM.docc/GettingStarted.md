# Getting Started with ``FSM``

Learn how to set up and use the FSM framework in your Swift project.

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

## Defining a Simple FSM

Import the module and create states and transitions:

```swift
import FSM

// Define two states
let red = State(name: "Red")
let green = State(name: "Green")

// Define transitions between the states
let toGreen = Transition(label: "after_ms(5000)", source: red.id, target: green.id)
let toRed = Transition(label: "after_ms(5000)", source: green.id, target: red.id)

// Create a logic-labelled FSM
let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed])

// Access states and transitions
print("States: \(fsm.states)")
print("Transitions: \(fsm.transitions)")
print("Initial state: \(fsm.initialState)")
print("State Names: \(fsm.stateNames)")
```

## Creating a Machine with a Language Binding

To serialise an FSM, wrap it in a ``Machine`` with a language binding:

```swift
let machine = Machine()
machine.llfsm = fsm
machine.language = CBinding()
```

The ``Machine`` class holds additional metadata such as layout information,
boilerplate code, and state activities that are needed for code generation
and serialisation.

## Serialising to Disk

Use ``MachineWrapper`` to write a machine to a `.machine` directory:

```swift
let machineName = "TrafficLight"
let fileName = machineName + MachineWrapper.dottedSuffix
let wrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: fileName)
let url = URL(fileURLWithPath: "/tmp/\(fileName)")
try wrapper.write(to: url)
```

## Next Steps

- Read <doc:Concepts> for a deeper understanding of the framework's architecture.
- Follow the <doc:GettingStarted> tutorial for a hands-on walkthrough.
- Explore <doc:Arrangements> to learn about composing multiple FSMs.
