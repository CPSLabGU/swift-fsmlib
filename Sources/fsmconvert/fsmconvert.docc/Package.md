# fsmconvert

A command-line tool for converting finite-state machines between
different representations and creating arrangements from multiple machines.

@Metadata {
  @PageKind(article)
}

## Overview

The `fsmconvert` tool reads Logic-Labelled Finite-State Machines (LLFSMs)
from `.machine` directories and can write them in different language formats
or combine them into `.arrangement` directories. It supports C and
Objective-C++ output formats and generates the complete build system
files (CMake) needed to compile the resulting code.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Concepts>

### Command-Line Tool

The `fsmconvert` executable provides format conversion and arrangement
creation through command-line flags. Run `fsmconvert --help` for a
complete list of options.
