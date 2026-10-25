//
//  KernelTemplateGenerator.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import MTL

/// The description of a bundled kernel template set, read from its `templateset.json`.
public struct KernelTemplateSet: Decodable, Sendable, Equatable {
    /// The options of a template set.
    public struct Options: Decodable, Sendable, Equatable {
        /// The line delimiter of the generated files.
        public let lineDelimiter: String?
    }

    /// The identifier of the template set, the raw value of its ``KernelTarget``.
    public let name: String

    /// A sentence that describes what the template set generates.
    public let summary: String

    /// The name of the module that holds the main template.
    public let mainModule: String

    /// The name of the main template, which takes the arrangement as its argument.
    public let mainTemplate: String

    /// The directories of shared modules, relative to the template set's directory.
    public let imports: [String]

    /// The options of the template set, if it has any.
    public let options: Options?

    /// The keys of a template set description.
    private enum CodingKeys: String, CodingKey {
        /// The `name` key of the description.
        case name
        /// The `summary` key of the description.
        case summary
        /// The `mainModule` key of the description.
        case mainModule
        /// The `mainTemplate` key of the description.
        case mainTemplate
        /// The `imports` key of the description.
        case imports
        /// The `options` key of the description.
        case options
    }

    /// Decode a template set description.
    ///
    /// - Parameter decoder: The decoder to read from; `imports` and `options` are optional.
    /// - Throws: A decoding error if a mandatory key is missing.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decode(String.self, forKey: .summary)
        mainModule = try container.decode(String.self, forKey: .mainModule)
        mainTemplate = try container.decode(String.self, forKey: .mainTemplate)
        imports = try container.decodeIfPresent([String].self, forKey: .imports) ?? []
        options = try container.decodeIfPresent(Options.self, forKey: .options)
    }
}

/// The problems that stop kernel template generation.
public enum KernelTemplateGeneratorError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The template set of the target is not bundled.
    case missingTemplateSet(KernelTarget)

    /// The template set description of the target cannot be read.
    case invalidTemplateSet(KernelTarget, String)

    /// The resource holds no kernel arrangement.
    case noArrangement

    /// The model violates rules of the profile that the target requires.
    ///
    /// The diagnostics are those of the validation run, including warnings.
    case invalidModel(KernelTarget, [KernelDiagnostic])

    /// The templates reported problems with the model or the parameters.
    ///
    /// Each message names the path of the offending element, or the parameter, followed by a
    /// sentence that explains the problem.
    case templateErrors(KernelTarget, [String])

    /// A description of the problem.
    public var description: String {
        switch self {
        case .missingTemplateSet(let target):
            return "The template set of the kernel target \(target.rawValue) is not bundled"
        case .invalidTemplateSet(let target, let reason):
            return "The template set of the kernel target \(target.rawValue) cannot be read: \(reason)"
        case .noArrangement:
            return "The resource holds no kernel arrangement"
        case .invalidModel(let target, let diagnostics):
            return "The model is not valid for the kernel target \(target.rawValue):\n"
                + diagnostics.map(\.description).joined(separator: "\n")
        case .templateErrors(let target, let messages):
            return "The kernel target \(target.rawValue) cannot generate the model:\n"
                + messages.joined(separator: "\n")
        }
    }
}

/// Generates programs, verification models and drawings from kernel models
/// with the bundled kernel template sets.
///
/// The generator validates the arrangement under the profile that the
/// target requires (see ``KernelTarget/validationProfile(parameters:)``),
/// runs the main template of the target's template set with the arrangement
/// as its argument and the given template parameters, and returns or writes
/// the generated files. Problems that the templates detect, such as opaque
/// text written for another language, are reported as
/// ``KernelTemplateGeneratorError/templateErrors(_:_:)``.
///
/// ```swift
/// let generator = KernelTemplateGenerator(metamodel: try await KernelMetamodel())
/// let files = try await generator.generate(.smv, resource: resource,
///                                          parameters: ["maxRounds": "20"], to: directory)
/// ```
@MainActor
public struct KernelTemplateGenerator {
    /// The bundled directory that holds the template directories.
    static let templatesDirectoryName = "Templates"

    /// The directory below the templates directory that holds one template set per target.
    static let kernelDirectory = "kernel"

    /// The name of the file that describes a template set.
    static let templateSetFile = "templateset.json"

    /// The text that starts a problem reported by a template on its standard output.
    static let errorPrefix = "error "

    /// The kernel metamodel that types the generated models.
    public let metamodel: KernelMetamodel

    /// The settings with which the templates run.
    ///
    /// Parameters given to a generation run take precedence over parameters of
    /// the same name in the settings.
    public var settings: TemplateSettings

    /// Create a generator.
    ///
    /// - Parameters:
    ///   - metamodel: The kernel metamodel that types the models to generate.
    ///   - settings: The settings with which the templates run (default settings).
    public init(metamodel: KernelMetamodel, settings: TemplateSettings = TemplateSettings()) {
        self.metamodel = metamodel
        self.settings = settings
    }

    /// The bundled directory that holds the kernel template sets and the shared modules.
    public static var templatesDirectory: URL? {
        BundledResources.url(
            forResource: templatesDirectoryName,
            withExtension: nil,
            subdirectory: LLFSMMetamodels.resourceSubdirectory,
            in: .module,
            bundleName: LLFSMMetamodels.bundleName
        )
    }

    /// The directory of the template set of a target, if it is bundled.
    ///
    /// - Parameter target: The target.
    /// - Returns: The directory that holds the target's `templateset.json` and modules.
    public static func templateSetDirectory(for target: KernelTarget) -> URL? {
        guard let templates = templatesDirectory else { return nil }
        let directory = templates
            .appendingPathComponent(kernelDirectory, isDirectory: true)
            .appendingPathComponent(target.templateDirectory, isDirectory: true)
        let description = directory.appendingPathComponent(templateSetFile)
        return FileManager.default.fileExists(atPath: description.path) ? directory : nil
    }

    /// The targets whose template sets are bundled, in declaration order.
    ///
    /// - Returns: The bundled targets.
    public static func availableTargets() -> [KernelTarget] {
        KernelTarget.allCases.filter { templateSetDirectory(for: $0) != nil }
    }

    /// Read the description of a target's template set.
    ///
    /// - Parameter target: The target.
    /// - Returns: The template set description.
    /// - Throws: ``KernelTemplateGeneratorError/missingTemplateSet(_:)`` if the template set is
    ///   not bundled and ``KernelTemplateGeneratorError/invalidTemplateSet(_:_:)`` if its
    ///   description cannot be read.
    public static func templateSet(for target: KernelTarget) throws -> KernelTemplateSet {
        guard let directory = templateSetDirectory(for: target) else {
            throw KernelTemplateGeneratorError.missingTemplateSet(target)
        }
        do {
            let data = try Data(contentsOf: directory.appendingPathComponent(templateSetFile))
            return try JSONDecoder().decode(KernelTemplateSet.self, from: data)
        } catch {
            throw KernelTemplateGeneratorError.invalidTemplateSet(target, "\(error)")
        }
    }

    /// Generate the files of a target in memory.
    ///
    /// - Parameters:
    ///   - target: The target to generate.
    ///   - resource: The resource whose root object is the kernel arrangement.
    ///   - parameters: The template parameters by name (see ``KernelTemplateParameter``).
    /// - Returns: The generated files, ordered by path.
    /// - Throws: ``KernelTemplateGeneratorError`` if the template set cannot be read, the model
    ///   is not valid under the target's profile or the templates report problems, and any
    ///   error of the template engine.
    public func render(
        _ target: KernelTarget,
        resource: Resource,
        parameters: [String: String] = [:]
    ) async throws -> [GeneratedFileDescriptor] {
        try await render(target, resource: resource, parameters: parameters, validating: true)
    }

    /// Generate the files of a target in memory, optionally without validating the model first.
    ///
    /// - Parameters:
    ///   - target: The target to generate.
    ///   - resource: The resource whose root object is the kernel arrangement.
    ///   - parameters: The template parameters by name.
    ///   - validating: Whether to validate the model under the target's profile first.
    /// - Returns: The generated files, ordered by path.
    /// - Throws: ``KernelTemplateGeneratorError`` and errors of the template engine.
    func render(
        _ target: KernelTarget,
        resource: Resource,
        parameters: [String: String],
        validating: Bool
    ) async throws -> [GeneratedFileDescriptor] {
        let templateSet = try Self.templateSet(for: target)
        guard let directory = Self.templateSetDirectory(for: target), let templates = Self.templatesDirectory else {
            throw KernelTemplateGeneratorError.missingTemplateSet(target)
        }
        let arrangement = try await arrangement(in: resource)
        let parameters = settings.parameters.merging(parameters) { _, given in given }
        if validating {
            let profile = target.validationProfile(parameters: parameters)
            let diagnostics = await KernelValidator(metamodel: metamodel, profile: profile).validate(resource)
            if KernelValidator.containsErrors(diagnostics) {
                throw KernelTemplateGeneratorError.invalidModel(target, diagnostics)
            }
        }
        let moduleURL = directory
            .appendingPathComponent(templateSet.mainModule)
            .appendingPathExtension(MTLSyntax.moduleFileExtension)
        let module = try await MTLParser(searchPaths: settings.searchPaths + [templates]).parse(moduleURL)
        var options = MTLGeneratorOptions()
        if let delimiter = templateSet.options?.lineDelimiter { options.lineDelimiter = delimiter }
        let strategy = MTLInMemoryStrategy(options: options)
        let generator = MTLGenerator(
            module: module, generationStrategy: strategy, unsetFeatureReads: settings.unsetFeatureReads)
        let services = try MTLParameterServices(parameters: parameters)
        services.bind(to: generator)
        generator.register(services)
        try await generator.generate(
            mainTemplate: templateSet.mainTemplate, arguments: [arrangement], models: ["IN": resource])
        var files = await strategy.getGeneratedFiles()
        let output = files.removeValue(forKey: MTLStandardOutput.fileName) ?? ""
        let problems = output.split(separator: "\n", omittingEmptySubsequences: true)
            .filter { $0.hasPrefix(Self.errorPrefix) }
            .map { String($0.dropFirst(Self.errorPrefix.count)) }
        if !problems.isEmpty {
            throw KernelTemplateGeneratorError.templateErrors(target, problems)
        }
        return files
            .map { GeneratedFileDescriptor(path: Self.relativePath($0.key), content: $0.value) }
            .sorted { $0.path < $1.path }
    }

    /// Generate the files of a target into a directory.
    ///
    /// Existing files of the same names are replaced.
    ///
    /// - Parameters:
    ///   - target: The target to generate.
    ///   - resource: The resource whose root object is the kernel arrangement.
    ///   - parameters: The template parameters by name (see ``KernelTemplateParameter``).
    ///   - directory: The directory to write to; it is created if necessary.
    /// - Returns: The locations of the written files, ordered by path.
    /// - Throws: The errors of ``render(_:resource:parameters:)`` and file system errors.
    @discardableResult
    public func generate(
        _ target: KernelTarget,
        resource: Resource,
        parameters: [String: String] = [:],
        to directory: URL
    ) async throws -> [URL] {
        let files = try await render(target, resource: resource, parameters: parameters)
        var urls: [URL] = []
        for file in files {
            let url = directory.appendingPathComponent(file.path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.content.write(to: url, atomically: FileWritingSupport.writesAtomically, encoding: .utf8)
            urls.append(url)
        }
        return urls
    }

    /// The kernel arrangement at the root of a resource.
    ///
    /// - Parameter resource: The resource.
    /// - Returns: The first root object that is an arrangement of the kernel metamodel.
    /// - Throws: ``KernelTemplateGeneratorError/noArrangement`` if there is none.
    private func arrangement(in resource: Resource) async throws -> any EObject {
        let roots = await resource.getRootObjects()
        let arrangementClass = metamodel.arrangementClass
        guard let root = roots.first(where: { ($0.eClass as? EClass)?.id == arrangementClass.id })
            ?? roots.first(where: { $0.eClass.name == arrangementClass.name })
        else {
            throw KernelTemplateGeneratorError.noArrangement
        }
        return root
    }

    /// The path of a generated file relative to the output directory.
    ///
    /// - Parameter path: The path reported by the template engine.
    /// - Returns: The path without a leading separator.
    private static func relativePath(_ path: String) -> String {
        path.hasPrefix("/") ? String(path.drop { $0 == "/" }) : path
    }
}
