# SCXML Support

@Metadata {
  @PageKind(article)
}

An overview of SCXML (State Chart XML) support in the ``FSM`` framework,
including round-trip conversion between directory-based `.machine` bundles
and single-file `.scxml` documents.

## Overview

The ``FSM`` framework supports SCXML as both an input and output format,
enabling:

- **Single-file storage**: SCXML machines are stored as single XML files
  rather than directory bundles.
- **Round-trip conversion**: Convert between `.machine` and `.scxml`
  without data loss.
- **Multi-namespace support**: Compatible with ScxmlEditor, Qt Creator,
  and other SCXML-aware tools.
- **Boilerplate preservation**: C/C++ code sections are embedded in SCXML
  using custom `fsm:` namespace extensions.

## Storage Formats

The framework supports two storage strategies, unified under the
``MachineStorage`` protocol:

**Directory-based** (`.machine`)
- Handled by ``MachineDirectoryWrapper``
- Separate files for states, transitions, and boilerplate
- Traditional format for C/C++/Objective-C++ code generation

**Single-file** (`.scxml`)
- Handled by ``MachineFileWrapper``
- Entire machine encoded as a single XML document
- Compatible with external SCXML editors and standard tooling

## Quick Start

### Converting to SCXML

Convert any `.machine` directory bundle to a single `.scxml` file using
`fsmconvert`:

```bash
swift run fsmconvert MyMachine.machine -o MyMachine.scxml
```

### Converting from SCXML

Convert an `.scxml` file back to a `.machine` directory bundle:

```bash
swift run fsmconvert MyMachine.scxml -o MyMachine.machine
```

### Round-Trip Verification

```bash
# Convert to SCXML
swift run fsmconvert examples/CounterC.machine -o /tmp/CounterC.scxml

# Convert back
swift run fsmconvert /tmp/CounterC.scxml -o /tmp/CounterC.machine

# Build with CMake
cd /tmp && rm -rf build && mkdir build && cd build
cmake -G Ninja ../CounterC.machine
ninja
```

## API Usage

### Reading Machines

Use ``MachineStorageFactory`` to auto-detect the storage format from the
URL extension:

```swift
// Auto-detect format from file extension
let storage = try MachineStorageFactory.read(from: url)
let machine = storage.machine
```

To read a specific format directly:

```swift
// Directory bundle
let dirStorage = try MachineDirectoryWrapper(url: machineURL)

// Single-file SCXML
let fileStorage = try MachineFileWrapper(url: scxmlURL)
```

### Writing Machines

```swift
// Auto-detect output format from URL extension
let storage = MachineStorageFactory.create(for: machine, format: nil, at: url)
try storage.write(to: url)

// Force SCXML output regardless of URL extension
let scxmlStorage = MachineStorageFactory.create(for: machine, format: .scxml, at: url)
try scxmlStorage.write(to: url)
```

## Known Limitations

### CBoilerplate Coupling

``SCXMLBinding`` currently uses ``CBoilerplate`` internally to store state
activities (``StateActivities/onEntry``, ``StateActivities/onExit``,
``StateActivities/internal``, ``StateActivities/onSuspend``,
``StateActivities/onResume``). This works for all existing language bindings
(C, C++, Objective-C++) because they all share the same activity structure.

However, this couples SCXML serialisation to C-style boilerplate and will
not generalise directly to language bindings with fundamentally different
activity models.

### Future Direction

To make SCXML a truly universal interchange format, the following
improvements are planned:

1. **Generic Activity Storage**: Replace the hardcoded ``CBoilerplate``
   sections with a language-agnostic representation.
2. **Language Binding Metadata**: Preserve the source language binding
   identifier in the SCXML file for faithful reconstruction.
3. **Extensible `fsm:` Namespace**: Support arbitrary language-specific
   sections beyond the current fixed set.
4. **Boilerplate Abstraction**: Delegate boilerplate conversion entirely
   to the language binding implementation.

## References

- [W3C SCXML Specification](https://www.w3.org/TR/scxml/)
- [ScxmlEditor](http://scxmleditor.sf.net/)
- [Qt SCXML](https://doc.qt.io/qt-6/qtscxml-index.html)
