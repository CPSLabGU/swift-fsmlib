# ``FSMEcore``

`FSMEcore` bridges the native `FSM` model to structural and executable Ecore metamodels, XMI serialisation, ATL transforms, and MTL generation.

@Metadata {
  @PageKind(article)
}

## Overview

The module keeps the native Swift readers and writers as the production boundary while exposing metamodel-backed workflows for testing, analysis, and transformation. Structural models mirror the in-memory `swift-fsmlib` types so current file formats can round-trip without semantic drift.

Executable models restore the legacy typed LLFSM hierarchy used by the existing text generators. That lets the package run ATL and MTL workflows against models that still decode back to the same machines and arrangements produced by the native Swift code.

## Topics

### Essentials

- <doc:Background>
- <doc:StructuralAndExecutableModels>

### Structural Models

- ``LLFSMMetamodel``
- ``MachineEcoreCodec``
- ``ArrangementEcoreCodec``
- ``XMIRoundTrip``
- ``StructuralTemplateGenerator``

### Executable Models

- ``ExecutableLLFSMMetamodel``
- ``ExecutableMachineCodec``
- ``ExecutableArrangementCodec``
- ``ExecutableXMIRoundTrip``
- ``ExecutableTemplateGenerator``

### Transformations

- ``LLFSMATLTransformer``
- ``FormalLLFSMMetamodel``

### Errors

- ``LLFSMMetamodelError``
- ``ExecutableLLFSMMetamodelError``
- ``StructuralTemplateGeneratorError``
- ``ExecutableGenerationError``

### Tutorials

- <doc:Table-of-Contents>
