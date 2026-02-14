# Changelog

All notable changes to the swift-fsmlib project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

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

- **Platform Support**: Extended platform support to include:
  - macOS 13+
  - Mac Catalyst 16+
  - iOS 16+
  - tvOS 16+
  - watchOS 9+

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

- **Modernised Arrangement Structure**: Refactored arrangement file organisation and code generation for improved maintainability and clearer separation of concerns.

- **Improved C Binding Transition Parsing**: Enhanced transition expression parsing in `CBinding` to handle edge cases and malformed expressions more robustly.

- **CamelCase Naming Conventions**: Updated C++ generated code to use camelCase for member names, improving consistency with modern C++ coding standards.

- **Package Dependencies**: Updated to latest versions of upstream packages:
  - swift-argument-parser 1.2.0+
  - swift-system 1.2.0+
  - swift-docc-plugin 1.0.0+

- **Layout Width/Height Handling**: Default to closed width/height values when expanded values are not present in layout property lists.

- **Platform Requirements**: Updated minimum Swift tools version remains at 5.8, with expanded platform support for iOS/tvOS/watchOS ecosystems.

### Fixed

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
