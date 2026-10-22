# Structural Models

`FSMEcore` exposes a structural metamodel that mirrors the native runtime shape of `swift-fsmlib`, so machines and arrangements can be exchanged with model-driven tooling without semantic drift.

## Structural Models

The structural metamodel mirrors the `swift-fsmlib` in-memory model closely. Machines, arrangements, state activities, boilerplate, and layout data are all represented directly so the current native formats can round-trip through XMI with minimal reshaping.

Use the structural layer when you want to preserve the same information that the native Swift serialisers already understand:

```swift
let metamodel = try await LLFSMMetamodel()
let roundTrip = XMIRoundTrip(metamodel: metamodel)
try await roundTrip.write(machine: machine, name: "Example", to: url)
```

Written documents declare the namespace of the `LLFSMStructural` package, and documents are read against the structural metamodel. Reading or writing through ``XMIRoundTrip`` can also collect conversion diagnostics, for example elements whose classes the structural metamodel does not define:

```swift
var diagnostics = ConversionDiagnostics()
let decoded = try await roundTrip.readMachine(from: url, diagnostics: &diagnostics)
for warning in diagnostics.warnings {
    print(warning)
}
```

Use ``XMIRoundTrip/loadResource(from:diagnostics:)`` when you need the parsed object graph itself.

## Generating Artefacts

``StructuralTemplateGenerator`` runs the bundled model-to-text templates (`structural2machine`, `structural2scxml`, `structural2cmake`, and `structural2layout`) to generate machine bundles, SCXML, CMake files, and layout files.

```swift
let generator = StructuralTemplateGenerator()
try await generator.generateSCXML(
    for: machine,
    named: "Example",
    to: outputURL
)
```

## Further Levels

The `sectioned` and `kernel` metamodels describe machines with typed, language-neutral expressions and statements. See <doc:MetamodelLevels> for how the three levels relate.
