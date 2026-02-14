# Conversion Concepts

@Metadata {
  @PageKind(article)
}

An overview of the principles behind FSM conversion in `fsmconvert`.

## Supported Formats

The tool converts between the following language formats, identified
by the ``Format`` enumeration in the FSM library:

| Format Flag | Language | Binding |
|-------------|----------|---------|
| `c` | Plain C | ``CBinding`` |
| `c++`, `cpp`, `cxx` | C++ | ``ObjCPPBinding`` |
| `objc` | Objective-C | ``ObjCPPBinding`` |
| `objc++`, `objcpp` | Objective-C++ | ``ObjCPPBinding`` |

## Machines vs Arrangements

A **machine** (`.machine` directory) contains a single FSM with its
states, transitions, layout, and language-specific code. An
**arrangement** (`.arrangement` directory) groups multiple machine
instances together, enabling them to be compiled and executed as a
coordinated system.

When the `-a` flag is passed, `fsmconvert` creates an arrangement
from the input machines rather than converting a single machine.

## Conversion Process

1. Each input `.machine` directory is read using a ``MachineWrapper``.
2. The language binding is detected from the machine's file structure.
3. If a different output format is specified with `-f`, the machine is
   converted by applying the new ``LanguageBinding`` and regenerating
   the code.
4. The result is written to the output path using the appropriate wrapper.

## CMake Integration

Both machine and arrangement outputs include generated `CMakeLists.txt`
and CMake fragment files. These allow the generated C or Objective-C++
code to be compiled directly using CMake, making integration with
existing build systems straightforward.
