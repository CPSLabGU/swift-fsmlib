//
//  StructuralTemplateEngine.swift
//  FSMEcore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import FSM
import Foundation
import MTL

/// A set of templates that writes machines and arrangements in one output format.
///
/// Each set lives in its own directory below the structural template root and
/// describes itself in a manifest. The manifest names the formats the set writes,
/// the language name that the written bundles declare, the module and templates
/// to run, and whether the set writes a single file instead of a bundle.
public struct StructuralTemplateSet: Sendable, Equatable, Decodable {
    /// The name of the set.
    public let name: String

    /// The language name of the bundles that the set writes.
    public let language: String

    /// The raw values of the formats that the set writes.
    public let formats: [String]

    /// The name of the module that holds the templates to run.
    public let mainModule: String

    /// The name of the template that writes a machine.
    public let machineTemplate: String

    /// The name of the template that writes an arrangement, if the set writes arrangements.
    public let arrangementTemplate: String?

    /// Whether the set writes a machine as a single file rather than a bundle.
    public let isSingleFile: Bool

    /// Create a template set description.
    ///
    /// - Parameters:
    ///   - name: The name of the set.
    ///   - language: The language name of the bundles that the set writes.
    ///   - formats: The raw values of the formats that the set writes.
    ///   - mainModule: The name of the module that holds the templates to run.
    ///   - machineTemplate: The name of the template that writes a machine.
    ///   - arrangementTemplate: The name of the template that writes an arrangement, if any.
    ///   - isSingleFile: Whether a machine is written as a single file.
    public init(
        name: String,
        language: String,
        formats: [String],
        mainModule: String,
        machineTemplate: String,
        arrangementTemplate: String?,
        isSingleFile: Bool
    ) {
        self.name = name
        self.language = language
        self.formats = formats
        self.mainModule = mainModule
        self.machineTemplate = machineTemplate
        self.arrangementTemplate = arrangementTemplate
        self.isSingleFile = isSingleFile
    }

    /// Tell whether the set writes the given format.
    ///
    /// - Parameter format: The output format.
    /// - Returns: `true` if the manifest lists the format.
    public func writes(_ format: Format) -> Bool {
        formats.contains(format.rawValue)
    }
}

/// Runs the structural templates over machines and arrangements.
///
/// The engine encodes a machine or an arrangement in the structural metamodel,
/// runs the template set for the requested format, and returns the written
/// files as bytes keyed by their paths relative to the bundle.
@MainActor
struct StructuralTemplateEngine {
    /// The name of the manifest file of a template set.
    static let manifestName = "templateset.json"

    /// The file extension of template modules.
    static let moduleExtension = "mtl"

    /// The alias under which the encoded model is passed to the templates.
    static let modelAlias = "IN"

    /// The resource directory that holds the structural template root.
    static let resourceDirectory = "Resources/Templates"

    /// The name of the structural template root directory.
    static let rootName = "structural"

    /// The directory that holds the template sets.
    let root: URL

    /// The settings with which the templates run.
    let settings: TemplateSettings

    /// Create an engine for the bundled template sets.
    ///
    /// - Parameter settings: The settings with which the templates run (default settings).
    /// - Throws: ``StructuralTemplateGeneratorError/missingTemplate(_:)`` if the
    ///   bundled template root cannot be found.
    init(settings: TemplateSettings = TemplateSettings()) throws {
        guard let root = Self.bundledRoot else {
            throw StructuralTemplateGeneratorError.missingTemplate(Self.rootName)
        }
        self.init(root: root, settings: settings)
    }

    /// Create an engine for the template sets below a directory.
    ///
    /// - Parameters:
    ///   - root: The directory whose subdirectories hold the template sets.
    ///   - settings: The settings with which the templates run (default settings).
    init(root: URL, settings: TemplateSettings = TemplateSettings()) {
        self.root = root
        self.settings = settings
    }

    /// The bundled directory that holds the structural template sets, if it is present.
    static var bundledRoot: URL? {
        BundledResources.url(
            forResource: rootName,
            withExtension: nil,
            subdirectory: resourceDirectory,
            in: .module,
            bundleName: LLFSMMetamodels.bundleName
        )
    }

    /// Read the manifests of all template sets.
    ///
    /// - Returns: The template sets together with their directories, ordered by name.
    /// - Throws: ``StructuralTemplateGeneratorError/invalidTemplateSet(_:)`` if a manifest
    ///   cannot be read.
    func templateSets() throws -> [(set: StructuralTemplateSet, directory: URL)] {
        let fileManager = FileManager.default
        let entries = try fileManager.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        var sets: [(set: StructuralTemplateSet, directory: URL)] = []
        for directory in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let manifest = directory.appendingPathComponent(Self.manifestName)
            guard fileManager.fileExists(atPath: manifest.path) else { continue }
            do {
                let set = try JSONDecoder().decode(StructuralTemplateSet.self, from: Data(contentsOf: manifest))
                sets.append((set, directory))
            } catch {
                throw StructuralTemplateGeneratorError.invalidTemplateSet(directory.lastPathComponent)
            }
        }
        return sets
    }

    /// Tell whether a template set writes a format.
    ///
    /// - Parameters:
    ///   - format: The output format.
    ///   - arrangements: Whether the set must also write arrangements.
    /// - Returns: `true` if a set writes the format, and arrangements if asked for.
    func writes(_ format: Format, arrangements: Bool = false) -> Bool {
        guard let match = try? templateSet(for: format) else { return false }
        return !arrangements || match.set.arrangementTemplate != nil
    }

    /// Find the template set that writes a format.
    ///
    /// - Parameter format: The output format.
    /// - Returns: The template set and its directory.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if no set writes the format.
    func templateSet(for format: Format) throws -> (set: StructuralTemplateSet, directory: URL) {
        guard let match = try templateSets().first(where: { $0.set.writes(format) }) else {
            throw StructuralTemplateGeneratorError.unsupportedFormat(format.rawValue)
        }
        return match
    }

    /// Render the files of a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine to render.
    ///   - name: The machine name that the files refer to.
    ///   - format: The output format.
    ///   - isSuspensible: Whether to write the suspensible variant of the files.
    /// - Returns: The rendered set and the file contents keyed by relative path.
    /// - Throws: An error if the template set cannot be found or the templates fail.
    func renderMachine(
        _ machine: Machine,
        named name: String,
        format: Format,
        isSuspensible: Bool
    ) async throws -> (set: StructuralTemplateSet, files: [String: Data]) {
        let (set, directory) = try templateSet(for: format)
        let metamodel = try await LLFSMMetamodel()
        let resource = Resource(uri: "memory:/\(name).xmi")
        let object = await MachineEcoreCodec(metamodel: metamodel).encode(machine, name: name, into: resource)
        let files = try await render(
            template: set.machineTemplate, of: set, in: directory,
            arguments: [object, name, isSuspensible], resource: resource)
        return (set, files)
    }

    /// Render the files of an arrangement, including the bundles of its machines.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to render.
    ///   - name: The arrangement name that the files refer to.
    ///   - format: The output format.
    ///   - isSuspensible: Whether to write the suspensible variant of the files.
    /// - Returns: The rendered set and the file contents keyed by relative path.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if the set for the
    ///   format does not write arrangements, or an error if the templates fail.
    func renderArrangement(
        _ arrangement: Arrangement,
        named name: String,
        format: Format,
        isSuspensible: Bool
    ) async throws -> (set: StructuralTemplateSet, files: [String: Data]) {
        let (set, directory) = try templateSet(for: format)
        guard let template = set.arrangementTemplate else {
            throw StructuralTemplateGeneratorError.unsupportedFormat(format.rawValue)
        }
        let metamodel = try await LLFSMMetamodel()
        let resource = Resource(uri: "memory:/\(name).xmi")
        let object = await ArrangementEcoreCodec(metamodel: metamodel).encode(arrangement, into: resource)
        let files = try await render(
            template: template, of: set, in: directory,
            arguments: [object, name, isSuspensible], resource: resource)
        return (set, files)
    }

    /// Run one template of a set and collect the files it writes.
    ///
    /// The templates write into a fresh temporary directory, so that the
    /// character set of every file block is honoured byte for byte; the
    /// directory is removed afterwards.
    ///
    /// - Parameters:
    ///   - template: The name of the template to run.
    ///   - set: The template set.
    ///   - directory: The directory of the template set.
    ///   - arguments: The template arguments.
    ///   - resource: The resource holding the encoded model.
    /// - Returns: The file contents keyed by relative path.
    /// - Throws: An error if parsing, generation or reading the output fails.
    private func render(
        template: String,
        of set: StructuralTemplateSet,
        in directory: URL,
        arguments: [(any EcoreValue)?],
        resource: Resource
    ) async throws -> [String: Data] {
        let moduleURL = directory.appendingPathComponent(set.mainModule)
            .appendingPathExtension(Self.moduleExtension)
        let parser = MTLParser(searchPaths: settings.searchPaths + [root])
        let module = try await parser.parse(moduleURL)
        let parameters = try MTLParameterServices(parameters: settings.parameters)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("fsmecore-templates-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: output) }
        let strategy = MTLFileSystemStrategy(basePath: output.path)
        let generator = MTLGenerator(
            module: module,
            generationStrategy: strategy,
            serviceProviders: [StructuralTemplateServices(), MTLResourceServices(roots: [directory])],
            unsetFeatureReads: settings.unsetFeatureReads
        )
        parameters.bind(to: generator)
        generator.register(parameters)
        try await generator.generate(
            mainTemplate: template, arguments: arguments, models: [Self.modelAlias: resource])
        return try Self.files(below: output)
    }

    /// Read every regular file below a directory.
    ///
    /// - Parameter directory: The directory to read.
    /// - Returns: The file contents keyed by their path relative to the directory.
    /// - Throws: An error if a file cannot be read.
    nonisolated static func files(below directory: URL) throws -> [String: Data] {
        let base = directory.standardizedFileURL.resolvingSymlinksInPath()
        let baseComponents = base.pathComponents
        let keys: Set<URLResourceKey> = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: base, includingPropertiesForKeys: Array(keys)) else { return [:] }
        var files: [String: Data] = [:]
        for case let url as URL in enumerator {
            guard try url.resourceValues(forKeys: keys).isRegularFile == true else { continue }
            let components = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            let relative = components.dropFirst(baseComponents.count).joined(separator: "/")
            files[relative] = try Data(contentsOf: url)
        }
        return files
    }
}
