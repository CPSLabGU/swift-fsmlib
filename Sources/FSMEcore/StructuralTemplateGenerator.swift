import Foundation
import FSM
import ECore
import MTL

/// Generate LLFSM artefacts through the bundled structural templates.
///
/// `StructuralTemplateGenerator` writes machines with the MTL templates that
/// ship with `FSMEcore`. The templates read a machine in the structural
/// metamodel and write the same files as the Swift language bindings, so a
/// bundle written here can be read back with `Machine(from:)`.
///
/// Each method renders the files once and writes either the whole result or
/// the requested part of it. Machines are written in the format of their own
/// language binding, as suspensible machines.
@MainActor
public struct StructuralTemplateGenerator {
    /// The file name of the CMake build description in a machine bundle.
    static let cmakeListsName = "CMakeLists.txt"

    /// The file names of the layout files in a machine bundle.
    static let layoutFileNames = ["Layout.plist", "WindowLayout.plist"]

    /// The file extension of a single SCXML document.
    static let scxmlExtension = Format.scxml.fileExtension

    /// Create the template generator.
    public init() {}

    /// Generate a `.machine` bundle with the structural machine templates.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination directory for the rendered bundle.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if no template set
    ///   writes the language of the machine, or an error if rendering or writing fails.
    public func generateMachineBundle(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let bundleURL = url.appendingPathComponent(name + MachineDirectoryWrapper.dottedSuffix, isDirectory: true)
        let binding = try await TemplateBinding.make(
            for: machine, named: name, format: try Self.format(of: machine), isSuspensible: true)
        try machine.write(to: bundleURL, language: binding, isSuspensible: true)
    }

    /// Generate an SCXML file with the structural SCXML templates.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name.
    ///   - url: Destination file URL.
    /// - Throws: An error if rendering or writing fails.
    public func generateSCXML(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let binding = try await TemplateBinding.make(for: machine, named: name, format: .scxml, isSuspensible: true)
        try machine.write(to: url, language: binding, isSuspensible: true)
    }

    /// Generate a CMake file with the structural machine templates.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination file URL.
    /// - Throws: ``StructuralTemplateGeneratorError/missingGeneratedFile(_:)`` if the templates
    ///   of the machine language write no CMake file, or an error if rendering or writing fails.
    public func generateCMakeLists(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let files = try await machineFiles(for: machine, named: name)
        guard let cmake = files[Self.cmakeListsName] else {
            throw StructuralTemplateGeneratorError.missingGeneratedFile(Self.cmakeListsName)
        }
        try cmake.write(to: url, options: FileWritingSupport.atomicWritingOptions)
    }

    /// Generate layout plist files with the structural machine templates.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination directory for the rendered layout files.
    /// - Throws: An error if rendering or writing fails.
    public func generateLayoutFiles(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let files = try await machineFiles(for: machine, named: name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for fileName in Self.layoutFileNames {
            guard let data = files[fileName] else { continue }
            try data.write(to: url.appendingPathComponent(fileName), options: FileWritingSupport.atomicWritingOptions)
        }
    }

    /// Render the files of a machine bundle in the format of the machine language.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    /// - Returns: The rendered files keyed by their path relative to the bundle.
    /// - Throws: An error if the format has no template set or rendering fails.
    private func machineFiles(for machine: Machine, named name: String) async throws -> [String: Data] {
        let binding = try await TemplateBinding.make(
            for: machine, named: name, format: try Self.format(of: machine), isSuspensible: true)
        return binding.files
    }

    /// Determine the output format of the language a machine is written in.
    ///
    /// - Parameter machine: The machine.
    /// - Returns: The format named by the language of the machine.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if the language
    ///   does not name a format.
    static func format(of machine: Machine) throws -> Format {
        guard let format = Format(rawValue: machine.language.name) else {
            throw StructuralTemplateGeneratorError.unsupportedFormat(machine.language.name)
        }
        return format
    }
}

/// Errors raised while rendering structural templates.
public enum StructuralTemplateGeneratorError: Error, Equatable {
    /// A bundled template resource could not be found.
    case missingTemplate(String)

    /// A required generated file was not present in the rendered output.
    case missingGeneratedFile(String)

    /// No template set writes the named format.
    case unsupportedFormat(String)

    /// The manifest of the named template set cannot be read.
    case invalidTemplateSet(String)
}
