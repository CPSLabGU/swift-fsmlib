# Getting Started with fsmconvert

Learn how to install and use `fsmconvert` to convert machines
and create arrangements from the command line.

## Installation

Build `fsmconvert` from the `swift-fsmlib` repository:

```bash
swift build -c release
```

The built binary is located in `.build/release/fsmconvert`.

## Basic Usage

### Reading and Writing a Machine

Convert a machine to a different output format:

```bash
fsmconvert MyMachine.machine -f c -o MyMachine_C.machine
```

This reads `MyMachine.machine`, converts it to plain C format,
and writes the result to `MyMachine_C.machine`.

### Verbose Output

Use the `-v` flag to see detailed information about the machine
being processed:

```bash
fsmconvert MyMachine.machine -v
```

### Creating an Arrangement

Combine multiple machines into an arrangement:

```bash
fsmconvert Machine1.machine Machine2.machine -a -o MySystem.arrangement
```

This creates `MySystem.arrangement` containing instances of both machines.

## Command-Line Flags

| Flag | Description |
|------|-------------|
| `-f`, `--format` | Output machine format (e.g. `c`, `c++`, `objcpp`) |
| `-a`, `--arrangement` | Create an arrangement from the input machines |
| `-n`, `--non-suspensible` | Generate non-suspensible machine code |
| `-i`, `--introspectable` | Make generated code introspectable |
| `-v`, `--verbose` | Enable verbose output |
| `-o`, `--output` | Output file path (default: `fsm.out`) |

## Next Steps

- Read <doc:Concepts> for details on supported formats and conversion.
- Explore the `examples/` directory in the repository for sample machines.
