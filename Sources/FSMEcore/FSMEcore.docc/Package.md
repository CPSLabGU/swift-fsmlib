# ``FSMEcore``

`FSMEcore` bridges the native `FSM` model to the structural Ecore metamodel, XMI serialisation, and MTL generation, and provides the sectioned and kernel LLFSM metamodels with validation of kernel models.

@Metadata {
  @PageKind(article)
}

## Overview

The module keeps the native Swift readers and writers as the production boundary while exposing metamodel-backed workflows for testing, analysis, and transformation. Structural models mirror the in-memory `swift-fsmlib` types so current file formats can round-trip without semantic drift.

Bundled MTL templates generate machine, SCXML, CMake, and layout artefacts from structural models, and the results match those produced by the native Swift code.

The sectioned and kernel metamodels describe LLFSMs with typed, language-neutral expressions and statements. The sectioned level is the traditional view with code sections; the kernel level is the sectionless core into which sectioned models are encoded, and ``KernelValidator`` checks kernel models against its well-formedness rules.

``KernelTemplateGenerator`` generates C, C++, Swift and Java programs that run a kernel arrangement and print its canonical trace, nuXmv and TLA+ models for model checking, and Graphviz drawings.

## Topics

### Essentials

- <doc:Background>
- <doc:StructuralModels>
- <doc:MetamodelLevels>
- <doc:SectionedSemantics>
- <doc:KernelTargets>

### Structural Models

- ``LLFSMMetamodel``
- ``MachineEcoreCodec``
- ``ArrangementEcoreCodec``
- ``XMIRoundTrip``
- ``StructuralTemplateGenerator``

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

### Kernel Targets

- ``KernelTemplateGenerator``
- ``KernelTarget``
- ``KernelTemplateSet``
- ``KernelTemplateParameter``
- ``KernelEntryMode``
- ``KernelOpaqueTreatment``
- ``GeneratedFileDescriptor``

### Origins

- ``OriginAnnotations``
- ``OriginRecord``
- ``OriginRole``

### Errors

- ``LLFSMMetamodelError``
- ``LLFSMMetamodelsError``
- ``OriginAnnotationsError``
- ``StructuralTemplateGeneratorError``
- ``KernelTemplateGeneratorError``

### Tutorials

- <doc:Table-of-Contents>
