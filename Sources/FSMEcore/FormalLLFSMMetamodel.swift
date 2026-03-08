import ECore
import Foundation

/// LLFSM formal metamodel metadata.
///
/// `FormalLLFSMMetamodel` loads the bundled formal metamodel used by the ATL
/// transformation tests and later formal-model tooling. It keeps the loaded
/// package available for direct classifier lookup.
public struct FormalLLFSMMetamodel: Sendable {
    /// Loaded package for the LLFSM formal metamodel.
    ///
    /// This package contains the adapted formal classifiers used for ATL
    /// structural-to-formal and formal-to-structural transformations.
    public let package: EPackage

    /// Load the bundled formal metamodel.
    ///
    /// - Throws: Throw an error if the bundled `.ecore` resource cannot be found or parsed.
    public init() async throws {
        guard let url = Bundle.module.url(
            forResource: "LLFSMFormal",
            withExtension: "ecore",
            subdirectory: "Resources"
        ) else {
            throw LLFSMMetamodelError.resourceNotFound
        }
        package = try await EPackage(url: url)
    }
}
