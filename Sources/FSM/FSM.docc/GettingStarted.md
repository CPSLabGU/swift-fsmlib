# Getting Started with ``FSM``

This guide will help you quickly set up and use the FSM framework in your Swift project.

## Installation

Add `swift-fsmlib` as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/CPSLabGU/swift-fsmlib.git", from: "1.0.0")
```

## Defining a Simple FSM

```swift
import FSM

// Define two states using the real State struct
let red = State(name: "Red")
let green = State(name: "Green")

// Define transitions using the Transition struct
let toGreen = Transition(label: "timer", source: red.id, target: green.id)
let toRed = Transition(label: "timer", source: green.id, target: red.id)

// Create a minimal LLFSM using the tested API
let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed], suspendState: nil)

// Access states and transitions (for demonstration)
print("Initial state: \(fsm.initialState)")
print("States: \(fsm.states)")
print("Transitions: \(fsm.transitions)")
```

This example is tested and cross-platform. For more advanced usage, see the API documentation and tests.


## Next Steps

- Explore the API documentation for advanced usage.
- See the [Concepts](Concepts.md) guide for a deeper dive into FSM theory.
