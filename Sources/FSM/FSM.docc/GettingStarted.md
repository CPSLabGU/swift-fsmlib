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

// Define two states
let red = State(name: "Red")
let green = State(name: "Green")

// Define transitions
let toGreen = Transition(label: "after_ms(5000)", source: red.id, target: green.id)
let toRed = Transition(label: "after_ms(5000)", source: green.id, target: red.id)

// Create a minimal LLFSM
let fsm = LLFSM(states: [red, green], transitions: [toGreen, toRed])

// Access states and transitions
print("States: \(fsm.states)")
print("Transitions: \(fsm.transitions)")
print("State Names: \(fsm.stateNames)")
```

For more advanced usage, see the API documentation and tests.

## Next Steps

- Explore the API documentation for advanced usage.
- See the [Concepts](Concepts.md) guide for a deeper dive into the types used.
