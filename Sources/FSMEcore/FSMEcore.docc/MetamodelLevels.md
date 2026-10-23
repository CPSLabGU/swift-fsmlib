# Metamodel Levels

The structural, sectioned and kernel metamodels, the validation profiles of
the kernel and its well-formedness rules.

## Overview

`FSMEcore` describes logic-labelled finite-state machines at three levels.

| level | metamodel | purpose |
|---|---|---|
| structural | `LLFSMStructural.ecore` (``LLFSMMetamodel``) | mirrors the native `swift-fsmlib` types, including host-language code sections and layout, for lossless round-trips of `.machine`, `.arrangement` and `.scxml` files |
| sectioned | `sectioned` subpackage of `LLFSM.ecore` (``SectionedMetamodel``) | the traditional view of an LLFSM with entry, exit, internal, suspend and resume sections, a suspend state and state-time expressions, written with the kernel's typed expressions and statements |
| kernel | `kernel` subpackage of `LLFSM.ecore` (``KernelMetamodel``) | the sectionless core: one action per state, ordered Boolean labels, pass-through states, finite types and calls to declared functions |

The sectioned and kernel levels share the root package `llfsm`, whose
namespace URI is ``LLFSMMetamodels/rootNamespaceURI``. Documents qualify
kernel elements with ``LLFSMMetamodels/kernelNamespaceURI`` (prefix
`kernel`) and sectioned elements with
``LLFSMMetamodels/sectionedNamespaceURI`` (prefix `sectioned`), so a
sectioned document contains kernel statements and expressions under their
own namespace. <doc:SectionedSemantics> specifies how a sectioned model
executes and how it is encoded into the kernel, and <doc:Transformations>
describes the transformations between the levels.

## Loading and Registering

``LLFSMMetamodels`` loads both levels from the bundled document. The
document is loaded once per program, so every caller shares the same
classes:

```swift
let metamodels = try await LLFSMMetamodels()
let resourceSet = ResourceSet()
await metamodels.register(in: resourceSet)
let parser = XMIParser(resourceSet: resourceSet)
let resource = try await parser.parse(url)
```

Registration makes the root package and both subpackages known under
their namespace URIs, so a parsed document is typed by the classes of the
kernel and sectioned packages, and a serialised document declares one
namespace per package it uses.

## Host Text and Declarations

Host declarations and variables carry what a faithful round trip of a
structural model needs, as optional attributes that typed models can leave
unset:

| element | attribute | holds |
|---|---|---|
| kernel `HostDeclarations` | `includePaths` | the directories that a build searches for included files, one per line, as written; kernel code templates do not use them |
| kernel `HostDeclarations` | `includes` | include or import directives |
| kernel `HostDeclarations` | `declarations` | declarations such as variables, prototypes and type definitions |
| kernel `HostDeclarations` | `functions` | functions such as helper functions, written by code targets after the declarations |
| kernel `Variable` | `documentation` | the text of the documentation comment of a declaration recognised in host text, such as `Bean counter` for `///< Bean counter` |
| kernel `Variable` | `declarationText` | the line that declared the variable, as written and without its line break |
| kernel `Variable` | `declarationLine` | the zero-based index of that line among the lines of the host declarations that held it |
| sectioned `State` | `hostDeclarations` | host declarations of the state itself, such as state-local variables and functions; the encoding into the kernel adds them to those of the machine |

Sections, labels and host texts that hold only white space are kept as
written, as opaque nodes or host text.

## Validation Profiles

``KernelValidator`` checks a kernel model under a ``ValidationProfile``:

- ``ValidationProfile/strict`` applies every rule and rejects opaque
  host-language nodes (`OpaqueExpression`, `OpaqueStatement`, `OpaqueType`)
  and host declarations. Every target, including verification targets, can
  process a model that is valid under this profile.
- ``ValidationProfile/relaxed`` admits opaque nodes and host declarations
  for code targets. The structural rules and rules W1 to W4, W8 and W9
  always apply; rules W5 to W7 apply only where the types involved are typed
  kernel types, so an opaque operand suspends them for its subtree.

```swift
let validator = KernelValidator(metamodel: metamodels.kernel, profile: .strict)
for diagnostic in await validator.validate(resource) {
    print(diagnostic)
}
```

Each ``KernelDiagnostic`` names its ``KernelRule``, its severity, the path
of the offending object from the root of the model and a message.

## Well-Formedness Rules

| code | rule |
|---|---|
| `STRUCT` | Mandatory features are present, references resolve to objects of the declared class, transitions target states of their own machine, and a binding names a local variable of the instance's machine. |
| `W1` | Names are unique within each containment feature and match `[A-Za-z_][A-Za-z0-9_]*`; the literals of an enumeration are unique. |
| `W2` | The initial state of a machine is one of its states and is not pass-through. |
| `W3` | The transitions into pass-through states form no cycle, so every ringlet ends. |
| `W4` | External variables are declared only as shared variables of the arrangement and are never assigned. |
| `W5` | Expressions are well typed: labels are Boolean; equality compares operands of the same type; arithmetic and ordering apply to integers; conjunction, disjunction and negation apply to Booleans; the branches of a conditional have the same type; an in-state observation names a state of the observed instance's machine; array indices are integers; an enumeration literal belongs to its enumeration; calls pass arguments that match the declared parameters in number and type; and a call with a receiver names a method of the receiver's type. |
| `W6` | Within one action a variable, or an array variable as a whole, is assigned at most once and is not read after it has been assigned. |
| `W7` | Integer literals that are assigned or bound to a variable lie within its range. |
| `W7?` | The right operand of a division or remainder that is neither a non-negative literal nor a variable with a non-negative range is reported as a warning. |
| `W8` | Binding values are literals. |
| `W9` | Labels, binding values and initial values call only pure functions; a call statement may call any function. |
| `STRICT` | Under the strict profile the model contains no opaque nodes and no host declarations. |

## Origins

Kernel states and transitions that encode a sectioned element record it in
an optional `Origin` object. ``OriginAnnotations`` reads and writes these
records and converts them to and from the details of annotations with the
source ``OriginAnnotations/source``.
