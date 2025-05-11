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

enum TrafficLightState: String, State {
    case red, yellow, green
}

enum TrafficLightEvent: String, Event {
    case timer, emergency
}

let fsm = FSM<TrafficLightState, TrafficLightEvent>(initialState: .red) {
    $0.addTransition(from: .red, event: .timer, to: .green)
    $0.addTransition(from: .green, event: .timer, to: .yellow)
    $0.addTransition(from: .yellow, event: .timer, to: .red)
}
```

## Next Steps

- Explore the API documentation for advanced usage.
- See the [Concepts](Concepts.md) guide for a deeper dive into FSM theory.
