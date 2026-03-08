import ECore

/// Compatibility wrapper for the executable LLFSM metamodel.
///
/// `FormalLLFSMMetamodel` now forwards to ``ExecutableLLFSMMetamodel`` so the
/// executable typed model remains available through the older entry point while
/// the rest of `FSMEcore` transitions to the explicit executable naming.
@available(*, deprecated, renamed: "ExecutableLLFSMMetamodel")
public struct FormalLLFSMMetamodel: Sendable {
    /// Loaded package for the executable LLFSM metamodel.
    ///
    /// This property preserves the older wrapper surface for callers that only
    /// need access to the loaded executable `EPackage`.
    public let package: EPackage

    /// Load the executable LLFSM metamodel.
    ///
    /// - Throws: Throw an error if the bundled executable metamodel cannot be
    ///   found or parsed.
    public init() async throws {
        package = try await ExecutableLLFSMMetamodel().package
    }
}
