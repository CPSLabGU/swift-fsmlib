# Structural And Executable Models

`FSMEcore` exposes two metamodel levels because the package has two distinct goals: fidelity to the native runtime shape and compatibility with the legacy executable generators.

## Structural Models

The structural metamodel mirrors the `swift-fsmlib` in-memory model closely. Machines, arrangements, state activities, boilerplate, and layout data are all represented directly so the current native formats can round-trip through XMI with minimal reshaping.

Use the structural layer when you want to preserve the same information that the native Swift serialisers already understand:

```swift
let metamodel = try await LLFSMMetamodel()
let roundTrip = XMIRoundTrip(metamodel: metamodel)
try await roundTrip.write(machine: machine, name: "Example", to: url)
```

## Executable Models

The executable metamodel restores the typed hierarchy used by the legacy LLFSM model-to-text templates. It adds statement and expression nodes, typed variable containers, and fidelity-oriented escape hatches such as opaque statements and expressions.

Use the executable layer when you need to drive the existing template set or move through ATL transforms that expect the legacy typed shape:

```swift
let metamodel = try await ExecutableLLFSMMetamodel()
let generator = ExecutableTemplateGenerator(metamodel: metamodel)
let templateURL = try generator.bundledTemplateURL(named: "llfsm2dot")
try await generator.generate(
    templateURL: templateURL,
    machine: machine,
    name: "Example",
    outputDirectory: outputDirectory
)
```

## Transforming Between Them

`LLFSMATLTransformer` runs the bundled ATL modules that move between the structural and executable views. The transformer still canonicalises the known target shapes through the native codecs so the resulting model matches the package’s expected semantics.

That arrangement keeps ATL focused on model reshaping while the Swift codecs continue to own the details that are already proven by the native regression suite.
