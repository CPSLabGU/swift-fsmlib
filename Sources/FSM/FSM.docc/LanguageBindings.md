# Language Bindings

@Metadata {
  @PageKind(article)
}

An overview of how language bindings enable the FSM framework to
read, write, and generate code for different programming languages.

## Overview

Language bindings bridge the abstract FSM model and concrete
programming language representations. They handle both reading
existing FSM files (deserialisation) and writing FSM code in a
target language (serialisation and code generation).

## Protocols

### LanguageBinding

The ``LanguageBinding`` protocol defines the operations needed to
read an FSM from a language-specific file format. A conforming type
provides closures or methods for:

- Extracting transition expressions from state files.
- Determining transition targets.
- Reading the suspend state for suspensible machines.
- Loading boilerplate code for machines and individual states.

Language bindings are associated with machines through the
``Format`` enumeration, which maps format identifiers (such as
`c`, `c++`, or `objcpp`) to their corresponding binding instances.

### OutputLanguage

The ``OutputLanguage`` protocol extends ``LanguageBinding`` with
the ability to write FSMs back to disk. Conforming types generate
all necessary source files, headers, build system files (CMake),
and boilerplate for the target language.

An output language can generate code for:
- Individual machines (state and transition implementations).
- Arrangements (infrastructure, instance management, and execution).
- Build system integration (CMakeLists.txt and CMake fragments).

## Concrete Bindings

### CBinding

``CBinding`` generates plain C code for machines and arrangements.
The generated code uses `snake_case` naming conventions throughout
and compiles with any standard C compiler.

Key characteristics:
- State actions are plain C functions.
- Transition expressions are C Boolean expressions.
- Machine and state variables are accessed through a machine pointer.
- Arrangements use C structs with `void *` machine pointers.

### ObjCPPBinding

``ObjCPPBinding`` generates Objective-C++ code using a C++ class
hierarchy within the `FSM` namespace. This binding produces more
structured code with proper encapsulation and type safety.

Key characteristics:
- Machine types are C++ classes inheriting from `CLMachine`.
- State types are C++ classes inheriting from `CLState`.
- Actions are implemented as nested classes inheriting from `CLAction`.
- Variable references use C++ references for type-safe access.
- A dual C/C++ interface ensures compatibility with C-based tools.

Despite its name, `ObjCPPBinding` handles all C++-family formats:
`c++`, `cpp`, `cxx`, `objc`, `objc++`, and `objcpp`.

### SCXMLBinding

``SCXMLBinding`` reads and writes State Chart XML (`.scxml`) files.
Unlike ``CBinding`` and ``ObjCPPBinding``, it does not generate
compilable target-language code; instead it serialises the complete
machine — states, transitions, layout, and boilerplate — into a single
well-formed XML document.

Key characteristics:
- Produces a single `.scxml` file (single-file storage via ``MachineFileWrapper``).
- Embeds C/C++ boilerplate in custom `fsm:` namespace extensions for
  round-trip fidelity.
- Compatible with ScxmlEditor, Qt Creator, and W3C-conformant SCXML tooling.
- Uses ``CBoilerplate`` internally, which suits all existing C-family
  language bindings (C, C++, Objective-C++).

## Format Mapping

The ``Format`` enumeration maps string identifiers to bindings:

| Format | Raw Value | Binding |
|--------|-----------|---------|
| `.c` | `"c"` | ``CBinding`` |
| `.cx` | `"c++"` | ``ObjCPPBinding`` |
| `.cpp` | `"cpp"` | ``ObjCPPBinding`` |
| `.cxx` | `"cxx"` | ``ObjCPPBinding`` |
| `.objC` | `"objc"` | ``ObjCPPBinding`` |
| `.objCX` | `"objc++"` | ``ObjCPPBinding`` |
| `.objCPP` | `"objcpp"` | ``ObjCPPBinding`` |
| `.scxml` | `"scxml"` | ``SCXMLBinding`` |

Use the ``outputLanguage(for:default:)`` function to resolve a
``Format`` value to its corresponding ``OutputLanguage`` binding.

## Boilerplate

Language bindings use the ``Boilerplate`` protocol to manage
supplementary code sections. For C-family languages, the
``CBoilerplate`` struct provides named sections including:

- **includePath**: Search paths for header files.
- **includes**: Preprocessor include directives.
- **variables**: Machine or state variable declarations.
- **functions**: Helper function declarations.
- **onEntry**, **onExit**, **internal**, **onSuspend**, **onResume**:
  User-provided action code for each state activity.

Each machine and each state within a machine has its own boilerplate
instance, allowing per-state customisation of includes, variables,
and helper functions.

## Detecting Bindings

When reading a `.machine` directory, the framework detects the
appropriate language binding by examining the file structure:

- The presence of C-specific files indicates a ``CBinding``.
- The presence of Objective-C++ header files indicates an
  ``ObjCPPBinding``.

For single-file formats, the URL file extension determines the binding:

- A `.scxml` extension selects ``SCXMLBinding`` automatically.

``MachineStorageFactory`` combines format detection with the correct
storage wrapper so that calling code does not need to distinguish
between directory-based and single-file formats.

The `languageBinding(for:)` family of functions automates binding
detection for both URLs and file wrappers.
