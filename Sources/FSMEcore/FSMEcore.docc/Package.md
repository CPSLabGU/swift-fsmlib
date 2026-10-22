# ``FSMEcore``

`FSMEcore` bridges the native `FSM` model to the structural Ecore metamodel, XMI serialisation, and MTL generation.

@Metadata {
  @PageKind(article)
}

## Overview

The module keeps the native Swift readers and writers as the production boundary while exposing metamodel-backed workflows for testing, analysis, and transformation. Structural models mirror the in-memory `swift-fsmlib` types so current file formats can round-trip without semantic drift.

Bundled MTL templates generate machine, SCXML, CMake, and layout artefacts from structural models, and the results match those produced by the native Swift code.

## Topics

### Essentials

- <doc:Background>
- <doc:StructuralModels>

### Structural Models

- ``LLFSMMetamodel``
- ``MachineEcoreCodec``
- ``ArrangementEcoreCodec``
- ``XMIRoundTrip``
- ``StructuralTemplateGenerator``

### Errors

- ``LLFSMMetamodelError``
- ``StructuralTemplateGeneratorError``

### Tutorials

- <doc:Table-of-Contents>
