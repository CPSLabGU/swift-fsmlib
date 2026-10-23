# ``FSMEcore``

`FSMEcore` bridges the native `FSM` model to the structural Ecore metamodel, XMI serialisation, and MTL generation.

@Metadata {
  @PageKind(article)
}

## Overview

The module keeps the native Swift readers and writers as the production boundary while exposing metamodel-backed workflows for testing, analysis, and transformation. Structural models mirror the in-memory `swift-fsmlib` types so current file formats can round-trip without semantic drift.

Bundled MTL templates write C, Objective-C++ and SCXML machine and arrangement bundles from structural models, byte for byte as the native Swift language bindings write them, so that ``TemplateBinding`` can take the place of a Swift language binding.

## Topics

### Essentials

- <doc:Background>
- <doc:StructuralModels>
- <doc:TemplateGeneration>

### Structural Models

- ``LLFSMMetamodel``
- ``MachineEcoreCodec``
- ``ArrangementEcoreCodec``
- ``XMIRoundTrip``

### Template Generation

- ``TemplateBinding``
- ``TemplateFileStorage``
- ``StructuralTemplateGenerator``
- ``StructuralTemplateSet``
- ``StructuralTemplateServices``
- ``StructuralTemplateServiceName``

### Errors

- ``LLFSMMetamodelError``
- ``StructuralTemplateGeneratorError``
- ``TemplateBindingError``
- ``StructuralTemplateServicesError``

### Tutorials

- <doc:Table-of-Contents>
