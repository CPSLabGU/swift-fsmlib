# FSMLib Examples

This directory contains example finite state machines (FSMs) and arrangements demonstrating various features of the swift-fsmlib library. These examples serve as both reference implementations and templates for building your own FSMs.

## Overview

The examples are organised into two categories:
- **Individual Machines** (`.machine` directories): Single FSM definitions
- **Arrangements** (`.arrangement` directories): Collections of multiple FSMs working together

All examples include both the FSM structure (states, transitions) and generated code for different language bindings (C and Objective-C++).

## Individual Machines

### Counter.machine
**Language**: Objective-C++ (default)
**Type**: Basic FSM

A simple counter state machine that demonstrates fundamental FSM concepts:
- **States**: Initial, CountUp, Print, SUSPENDED
- **Behaviour**: Increments a counter variable and prints the value
- **Key Features**:
  - Basic state transitions with time-based guards (`at(t)`)
  - OnEntry actions (incrementing counter, printing output)
  - OnExit actions (clearing output)
  - Machine-level variables (counter, machine name)

**What It Demonstrates**: Core FSM structure, state entry/exit actions, and basic variable management.

### CounterC.machine
**Language**: C
**Type**: Basic FSM

The same counter logic as `Counter.machine` but using C language bindings instead of Objective-C++.

**What It Demonstrates**: How to generate C code from FSM definitions, showing differences in syntax (e.g., `machine->counter++` vs `counter++`).

### CounterCPP.machine
**Language**: Objective-C++
**Type**: Basic FSM

Another variant of the counter FSM using C++ member access patterns.

**What It Demonstrates**: C++ code generation patterns for FSMs.

### SuspendCounter.machine
**Language**: Objective-C++
**Type**: Suspensible FSM

A control FSM that demonstrates suspending and resuming another FSM:
- **States**: Initial, Suspend_Counter, Resume_Counter
- **Behaviour**: Suspends and resumes a Counter FSM instance
- **Key Features**:
  - `SUSPEND()` and `RESUME()` macros
  - Inter-FSM communication
  - Timing-based state transitions

**What It Demonstrates**: Suspensible FSM protocol, coordinating multiple FSMs, and the arrangement pattern.

### SuspendCounterC.machine / SuspendCounterC2.machine
**Language**: C
**Type**: Suspensible FSM

C language versions of the suspend/resume controller FSM.

**What It Demonstrates**: Suspensible FSMs in C, showing the necessary includes and linkage for arrangement-based FSM control.

### SuspendCounterCPP.machine
**Language**: Objective-C++
**Type**: Suspensible FSM

C++ variant of the suspend/resume controller.

**What It Demonstrates**: C++ suspensible FSM patterns.

## Arrangements

Arrangements are collections of FSMs that work together. Each arrangement includes:
- Multiple `.machine` subdirectories
- A `Machines` file listing the FSM instances
- Generated boilerplate code for coordination
- Build configuration files (CMakeLists.txt, project.cmake)

### Counter.arrangement
**Language**: C
**Machines**: 1 instance (Counter)

A single-FSM arrangement demonstrating:
- Arrangement structure and build configuration
- Static FSM instantiation
- Generated common code for C-based FSMs

**Usage**:
```bash
# View arrangement contents
swift run fsmconvert examples/Counter.arrangement -v

# Generate fresh arrangement code
swift run fsmconvert examples/Counter.machine -a -o MyCounter.arrangement
```

### CounterC.arrangement
**Language**: C
**Machines**: 1 instance (CounterC)

Similar to Counter.arrangement but specifically for the C version.

**What It Demonstrates**: Single-FSM C arrangement with complete build scaffolding.

### Counter2.arrangement
**Language**: Objective-C++
**Machines**: 4 instances (Susp: SuspendCounter, Instance1-3: Counter)

A more complex arrangement showing:
- Multiple instances of the same FSM (Counter)
- One controller FSM (SuspendCounter)
- How arrangements handle multiple FSM instances

**What It Demonstrates**: Multi-instance FSM coordination, showing how one FSM can control multiple others.

### SuspendCounter.arrangement
**Language**: C
**Machines**: 2 instances (SuspendCounter, Counter)

The canonical suspend/resume example:
- **SuspendCounter**: Controller FSM that suspends/resumes the Counter
- **Counter**: Worker FSM being controlled

**Usage**:
```bash
# Build the arrangement with CMake
cd examples/SuspendCounter.arrangement
cmake -B build
cmake --build build

# Run the generated executable
./build/static_main
```

**What It Demonstrates**:
- Complete arrangement workflow
- Inter-FSM suspend/resume protocol
- Generated arrangement boilerplate (`Machine_Common.[ch]`, `Static_Arrangement_*.c`)
- CMake-based build system for FSM projects

### SuspendCounterCPP.arrangement
**Language**: Objective-C++
**Machines**: 2 instances (SuspendCounterCPP, CounterCPP)

C++ version of the suspend/resume arrangement.

**What It Demonstrates**: Objective-C++ arrangement patterns and build configuration.

### Machine123.arrangement
**Language**: Objective-C++
**Machines**: 3 instances (Machine1, Machine2, Machine3)

A simple three-FSM arrangement used for testing arrangement functionality.

**What It Demonstrates**: Multiple distinct FSMs in a single arrangement (not multiple instances of the same FSM).

## Working with Examples

### Viewing FSM Structure

Use `fsmconvert` to inspect any machine or arrangement:

```bash
# View a single machine
swift run fsmconvert examples/Counter.machine -v

# View an arrangement
swift run fsmconvert examples/SuspendCounter.arrangement -v
```

### Converting Between Formats

Convert a machine between language bindings:

```bash
# Convert from Objective-C++ to C
swift run fsmconvert examples/Counter.machine -o CounterInC.machine

# The tool will generate C bindings instead of C++
```

### Creating New Arrangements

Create an arrangement from multiple machines:

```bash
# Create an arrangement from two machines
swift run fsmconvert examples/Counter.machine examples/SuspendCounter.machine \
  -a -o MyArrangement.arrangement
```

### Building and Running

Arrangements include CMake build configurations:

```bash
cd examples/SuspendCounter.arrangement
cmake -B build
cmake --build build
./build/static_main
```

## File Structure

Each `.machine` directory contains:
- `States`: List of state names (one per line)
- `State_<name>_OnEntry.mm`: Code executed when entering a state
- `State_<name>_OnExit.mm`: Code executed when exiting a state
- `State_<name>_Internal.mm`: Code executed while in the state
- `State_<name>_Transition_N.expr`: Transition guard expressions
- `State_<name>_Variables.h`: State-specific variables
- `<Machine>_Variables.h`: Machine-level variables
- `<Machine>_Includes.h`: Machine-level includes
- `Layout.plist`: Graphical layout information
- Language-specific boilerplate files (`.h`, `.mm`, `.c`)

Each `.arrangement` directory contains:
- `.machine` subdirectories for each FSM instance
- `Machines`: List of FSM instance names and paths
- `Language`: Target language binding (c or objc++)
- `Arrangement_*.c/h`: Generated arrangement code
- `Static_Arrangement_*.c/h`: Static FSM instantiation code
- `Machine_Common.c/h`: Common FSM runtime code
- `CMakeLists.txt`: Build configuration
- `project.cmake`: Project-specific build settings
- `static_main.c`: Example main function

## Common Patterns

### Time-Based Transitions

Most examples use the `at(t)` macro for time-based guards:

```c
#define at(t) (time(&machine->now) > machine->start + (t))
```

In transition expressions:
```
at(2)  // Transition after 2 seconds
```

### State Actions

**OnEntry**: Executed once when entering the state
```c
machine->counter++;  // Increment counter on entry
```

**OnExit**: Executed once when leaving the state
```c
printf("\r");  // Clear line on exit
```

**Internal**: Executed repeatedly while in the state (less common in these examples)

### Suspend/Resume Pattern

Controller FSM:
```c
SUSPEND(&static_fsm_counter);  // Suspend another FSM
RESUME(&static_fsm_counter);   // Resume another FSM
```

The suspended FSM must include a `SUSPENDED` state and appropriate transitions.

## Learning Path

1. **Start with Counter.machine**: Understand basic FSM structure, states, and transitions
2. **Explore CounterC.machine**: See how language bindings affect code generation
3. **Study SuspendCounter.arrangement**: Learn how FSMs coordinate in arrangements
4. **Examine Counter2.arrangement**: Understand multiple FSM instances
5. **Build and run**: Use the CMake build system to compile and execute examples

## Further Reading

- See `/README.md` for general library information
- See the test suite in `/Tests/FSMTests/` for additional usage examples
