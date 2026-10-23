# Background

`FSMEcore` adds metamodel support to `swift-fsmlib` without replacing the native Swift implementation.

The native `FSM` types remain the reference model for current behaviour. They define how `.machine`, `.arrangement`, and `.scxml` files are read and written, and they provide the regression baseline that metamodel-backed paths must match.

The metamodel layer exists to make those same models available to model-driven tooling. The structural metamodel is used because it preserves fidelity to the current runtime shape.

## Native And Metamodel Boundaries

The package does not route ordinary file I/O through MTL by default. Native parsers and writers still sit at the boundary for production work because they are the most mature, directly tested implementation.

Metamodel workflows sit alongside that boundary. They can export and import structural XMI and generate artefacts through templates, but every user-facing path is intended to be checked against the native Swift behaviour.

## When To Use Each Layer

Use `FSM` when you need to parse, modify, or emit the supported file formats directly in Swift.

Use `FSMEcore` when you need one of the following:

- Structural XMI for lossless machine or arrangement round-trips.
- MTL generation driven from a model rather than the native file wrappers.

Use the sectioned and kernel metamodels when you need machines with typed, language-neutral expressions and statements, for example to validate a kernel model before it is handed to a verification or code target (see <doc:MetamodelLevels>).
