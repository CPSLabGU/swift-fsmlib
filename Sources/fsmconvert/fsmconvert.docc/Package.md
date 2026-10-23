# fsmconvert

A command-line tool for converting finite-state machines between
different representations and creating arrangements from multiple machines.

@Metadata {
  @PageKind(article)
}

## Overview

The `fsmconvert` tool reads Logic-Labelled Finite-State Machines (LLFSMs)
from `.machine` and `.arrangement` bundles, SCXML documents, and XMI or JSON
models, and can write them in different language formats or combine them
into `.arrangement` directories. It supports C and Objective-C++ output
formats and generates the complete build system files (CMake) needed to
compile the resulting code. Native formats are written by the bundled
templates, byte for byte as the Swift language bindings write them.

`fsmconvert` also works at the structural, sectioned and kernel levels of
LLFSMs. It recognises the level of an XMI or JSON input by its namespace,
transforms models between the levels, validates kernel models, and generates
C, C++, Swift and Java programs, nuXmv and TLA+ models for model checking,
and Graphviz drawings from them (see <doc:Levels>).

With `--metamodel structural`, it can also import and export structural XMI
(`--format xmi` or an `.xmi` output extension) and run the bundled
template sets through the `structural2machine`, `structural2scxml`,
`structural2cmake`, and `structural2layout` values of `--transform`.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Concepts>
- <doc:Levels>

### Command-Line Tool

The `fsmconvert` executable provides format conversion, arrangement
creation, transformations between levels, validation and kernel target
generation through command-line options. Run `fsmconvert --help` for a
complete list of options.

- <doc:OptionReference>
