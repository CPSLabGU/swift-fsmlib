# ``FSMEcore``

`FSMEcore` bridges the native `FSM` model to the structural Ecore metamodel, XMI serialisation, and MTL generation, and provides the sectioned and kernel LLFSM metamodels with validation of kernel models.

@Metadata {
  @PageKind(article)
}

## Overview

The module keeps the native Swift readers and writers as the production boundary while exposing metamodel-backed workflows for testing, analysis, and transformation. Structural models mirror the in-memory `swift-fsmlib` types so current file formats can round-trip without semantic drift.

Bundled MTL templates write C, Objective-C++ and SCXML machine and arrangement bundles from structural models, byte for byte as the native Swift language bindings write them, so that ``TemplateBinding`` can take the place of a Swift language binding.

The sectioned and kernel metamodels describe LLFSMs with typed, language-neutral expressions and statements. The sectioned level is the traditional view with code sections; the kernel level is the sectionless core into which sectioned models are encoded, and ``KernelValidator`` checks kernel models against its well-formedness rules.

## Topics

### Essentials

- <doc:Background>
- <doc:StructuralModels>
- <doc:TemplateGeneration>
- <doc:MetamodelLevels>
- <doc:SectionedSemantics>

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

### Kernel and Sectioned Metamodels

- ``LLFSMMetamodels``
- ``KernelMetamodel``
- ``SectionedMetamodel``
- ``KernelUnaryOperation``
- ``KernelBinaryOperation``
- ``SectionedTimeUnit``
- ``SectionedControlOperation``

### Kernel Validation

- ``KernelValidator``
- ``ValidationProfile``
- ``KernelRule``
- ``KernelDiagnostic``

### Origins

- ``OriginAnnotations``
- ``OriginRecord``
- ``OriginRole``

### Errors

- ``LLFSMMetamodelError``
- ``LLFSMMetamodelsError``
- ``OriginAnnotationsError``
- ``StructuralTemplateGeneratorError``
- ``TemplateBindingError``
- ``StructuralTemplateServicesError``

### Tutorials

- <doc:Table-of-Contents>
