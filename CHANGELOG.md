# Changelog

All notable changes to the swift-fsmlib project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- **Structural Template Generation**: `StructuralTemplateGenerator` now renders machines through the bundled template sets instead of copying files written by the Swift bindings, and gains the `unsupportedFormat` and `invalidTemplateSet` errors. Boilerplate sections and state activities that a machine does not have are no longer stored as empty strings in structural models.

### Removed

- **Pass-Through Templates**: Removed `GeneratedFileDescriptor` and the `structural2machine`, `structural2scxml`, `structural2cmake` and `structural2layout` template files; the `fsmconvert --transform` values of the same names now run the bundled template sets.

- **Executable and Formal Metamodel Levels**: Removed the executable and formal LLFSM metamodels together with `ExecutableLLFSMMetamodel`, `ExecutableMachineCodec`, `ExecutableArrangementCodec`, `ExecutableXMIRoundTrip`, `ExecutableTemplateGenerator`, `FormalLLFSMMetamodel`, `LLFSMATLTransformer` and their error types, the bundled `llfsm2*` MTL templates, the bundled ATL transforms and the executable artefact tutorial. `FSMEcore` now provides the structural level only; a `sectioned` level and a `kernel` level are planned.

- **fsmconvert ATL Options**: Removed the `--atl` and `--metamodel-path` options. The value `--metamodel executable` is deprecated: it maps to the planned `sectioned` level, prints a deprecation warning and exits with an error, as does `--metamodel sectioned`, because that level is not yet available in this release.

### Added

- **Template Engine**: Bundled MTL template sets for C, Objective-C++ and SCXML write machine and arrangement bundles from structural models byte for byte as the Swift language bindings do, including CMake files, layout files and the Objective-C++ infrastructure headers. `TemplateBinding` is an `OutputLanguage` that holds the rendered files and places them into the bundles that `Machine.write(to:language:isSuspensible:)` and `ArrangementWrapper` write; `TemplateBinding.make(for:named:format:isSuspensible:)` renders a machine or an arrangement. `TemplateFileStorage` writes single-file formats such as SCXML. `StructuralTemplateSet` describes the `templateset.json` manifest of a template set, and `StructuralTemplateServices` offers the template services `formatted`, `base64Decoded` and `eIsSet`.

- **Typed Layout Properties**: The structural metamodel stores additional state layout properties as typed `PropertyListEntry` and `PropertyListValue` objects, so that real, integer, Boolean, string, data, date, array and dictionary values keep their property list types; `LLFSMMetamodel` exposes the new classes. Documents that store these properties as JSON text are still read.

- **XMI Conversion Diagnostics**: `XMIRoundTrip` gains `readMachine(from:diagnostics:)`, `readArrangement(from:diagnostics:)`, `write(machine:name:to:diagnostics:)` and `write(arrangement:to:diagnostics:)`, which collect the `ConversionDiagnostics` reported by the XMI parser and serialiser, and `loadResource(from:diagnostics:)`, which returns the parsed structural object graph. The existing methods are unchanged.

- **Metamodel Registration**: `LLFSMMetamodel.register(in:)` registers the structural metamodel with a `ResourceSet`.

- **Objective-C++ Language Binding Support**: Complete implementation of `ObjCPPBinding` for reading and writing FSM machines in Objective-C++ format, enabling seamless integration with Objective-C++ codebases.

- **C++ Infrastructure Headers**: Added comprehensive C++ infrastructure including:
  - `CLAction`: Base class for state machine actions
  - `CLMachine`: Base class for state machine implementations
  - `CLState`: Base class for state representations
  - `CLTransition`: Base class for transition logic
  - `StateMachineVector`: Coordinated multi-machine executor for running multiple FSMs synchronously

- **Arrangement Code Generation**: Enhanced arrangement support with dual-interface code generation:
  - C struct-based API for low-level access
  - C++ RAII wrapper classes for safe resource management
  - `Static_Arrangement.h` as the generic arrangement include file
  - CMake build system integration for arrangements

- **Suspensible Machine Support**: Complete implementation of suspend/resume/restart operations for state machines:
  - Dedicated `SUSPENDED` state handling
  - `OnSuspend` and `OnResume` state callbacks
  - Integration with arrangement-level suspend/resume coordination

- **Layout Serialisation Improvements**:
  - Round-trip layout preservation for states and transitions
  - Robust `TransitionLayout` PList parsing with better error handling
  - Default grid layout generation for states at position (0,0)
  - Colour preservation for states and transitions
  - Support for unknown layout properties

- **Transition Source/Target Accessors**: Added getter and setter methods in `LLFSM` for accessing and modifying transition source and target states:
  - `sourceState(for:)` and `setSourceState(for:to:)`
  - `targetState(for:)` and `setTargetState(for:to:)`

- **Boilerplate Enhancements**:
  - `sectionNames` property for enumerating boilerplate sections
  - Setter methods for programmatic boilerplate modification

- **Platform Support**: Supported platforms are:
  - macOS 15+
  - Mac Catalyst 18+
  - iOS 18+
  - tvOS 18+
  - watchOS 11+

- **Example Machines and Arrangements**:
  - `Counter.machine`: Basic counter FSM
  - `CounterC.machine`: C-based counter implementation
  - `SuspendCounter.arrangement`: Multi-machine arrangement demonstrating suspend/resume
  - `SuspendCounter.machine`: Suspensible counter FSM
  - `TrafficLight.machine`: Complete traffic light FSM with transitions

- **Comprehensive Test Coverage**:
  - `StateNameLayoutsRoundTripTests`: Validates layout serialisation round-trips
  - Layout preservation tests for round-trip read-write operations
  - Enhanced `MachineSerialisationTests` with layout verification
  - `ObjCPPBindingArrangementCodeTests` for arrangement code generation

### Changed

- **Structural XMI Namespace**: XMI documents written by `XMIRoundTrip` and `fsmconvert` now declare the `LLFSMStructural` package namespace (`http://cpslabgu.github.io/LLFSMStructural`, prefix `llfsm`) instead of a namespace derived from the root class name, and documents are read against the structural metamodel. Documents written by earlier releases remain readable; reading them reports their untyped classes as diagnostics.

- **fsmconvert XMI Input Detection**: A single XMI input is read as an arrangement whenever the document contains an arrangement, and as a machine otherwise.

- **Modelling Library Dependencies**: `swift-ecore`, `swift-mtl` and `swift-atl` are now tracked from their `main` branches instead of the 0.1 releases.

- **Modernised Arrangement Structure**: Refactored arrangement file organisation and code generation for improved maintainability and clearer separation of concerns.

- **Improved C Binding Transition Parsing**: Enhanced transition expression parsing in `CBinding` to handle edge cases and malformed expressions more robustly.

- **CamelCase Naming Conventions**: Updated C++ generated code to use camelCase for member names, improving consistency with modern C++ coding standards.

- **Package Dependencies**: Updated to latest versions of upstream packages:
  - swift-argument-parser 1.2.0+
  - swift-system 1.2.0+
  - swift-docc-plugin 1.0.0+

- **Layout Width/Height Handling**: Default to closed width/height values when expanded values are not present in layout property lists.

- **Platform Requirements**: The package requires Swift tools version 6.0, with the platform minimums listed above.

### Fixed
- Arrangement code, static arrangement code and CMake files now list machine
  types in the order in which their first instances appear, instead of an
  order that varied between runs. `machineTypeNames` and
  `firstInstancesByType` on sequences of `Instance` expose that order.

- **Const Correctness**: Added missing `const` qualifiers to arrangement validation functions and test methods, ensuring proper const-correctness in generated C/C++ code.

- **Transition Layout PList Parsing**: Resolved edge cases in PList parsing that could cause layout information loss during serialisation round-trips.

- **SwiftLint Warnings**: Addressed various code quality issues and SwiftLint warnings throughout the codebase.

- **Unknown Property Preservation**: Fixed issue where unknown properties (such as custom colours) were being dropped during machine serialisation, now properly preserved in layout property lists.

- **Layout Round-Trip Stability**: Ensured graphical layout information (state positions, transition routing) is reliably preserved across read-write cycles.

### Development Notes

- Multiple commits marked as work-in-progress (wip) represent incremental development of the C++ arrangement infrastructure and camelCase naming migration.
- Removed generated build artefacts and Xcode project files from version control.
- Added `.gitignore` entries for coverage files and temporary example directories.
- VSCode configuration updates for improved development experience.

---

*Note: This changelog documents changes in the `development` branch not yet released to `main`.*
