import Foundation
import FSM
import ECore
import MTL

/// Generate LLFSM artefacts through bundled MTL templates.
///
/// `StructuralTemplateGenerator` bridges the existing Swift serialisers into an
/// MTL execution pipeline by materialising generated files as a small descriptor
/// model and then letting a template write those descriptors to disk. This keeps
/// the current output semantics intact while providing a template-driven surface
/// for phase 4 validation and later replacement.
@MainActor
public struct StructuralTemplateGenerator {
    private let descriptorPackage: EPackage
    private let fileSetClass: EClass
    private let fileClass: EClass

    /// Create the template generator.
    ///
    /// This initialiser constructs the small in-memory metamodel used to expose
    /// generated file descriptors to the MTL runtime.
    public init() {
        let stringType = EDataType(name: "EString")
        let pathAttribute = EAttribute(name: "path", eType: stringType, lowerBound: 1)
        let contentAttribute = EAttribute(name: "content", eType: stringType, lowerBound: 1)

        fileClass = EClass(
            name: "GeneratedFile",
            eStructuralFeatures: [pathAttribute, contentAttribute]
        )

        let filesReference = EReference(
            name: "files",
            eType: fileClass,
            lowerBound: 0,
            upperBound: -1,
            containment: true
        )
        fileSetClass = EClass(
            name: "GeneratedFileSet",
            eStructuralFeatures: [filesReference]
        )

        descriptorPackage = EPackage(
            name: "GeneratedFiles",
            nsURI: "http://www.cpslabgu.org/GeneratedFiles",
            nsPrefix: "gfiles",
            eClassifiers: [fileSetClass, fileClass]
        )
    }

    /// Generate a `.machine` bundle with the structural machine template.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination directory for the rendered bundle.
    public func generateMachineBundle(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let bundleName = name + MachineDirectoryWrapper.dottedSuffix
        let bundleURL = url.appendingPathComponent(bundleName, isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let descriptors = try makeMachineDescriptors(for: machine, named: bundleName).map {
            GeneratedFileDescriptor(path: URL(fileURLWithPath: $0.path).lastPathComponent, content: $0.content)
        }
        try await render(templateNamed: "structural2machine", descriptors: descriptors, to: bundleURL)
    }

    /// Generate an SCXML file with the structural SCXML template.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name.
    ///   - url: Destination file URL.
    public func generateSCXML(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let tempDirectory = try makeTemporaryDirectory(prefix: "fsmecore-scxml")
        let tempFile = tempDirectory.appendingPathComponent(name).appendingPathExtension("scxml")
        let storage = MachineStorageFactory.create(for: machine, format: .scxml, at: tempFile)
        try storage.write(to: tempFile)

        let descriptors = [try GeneratedFileDescriptor(
            path: url.lastPathComponent,
            content: String(contentsOf: tempFile, encoding: .utf8)
        )]
        try await render(templateNamed: "structural2scxml", descriptors: descriptors, to: url.deletingLastPathComponent())
    }

    /// Generate a CMake file with the structural CMake template.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination file URL.
    public func generateCMakeLists(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let descriptors = try makeMachineDescriptors(for: machine, named: name + MachineDirectoryWrapper.dottedSuffix)
        let cmake = descriptors.first(where: { $0.path.hasSuffix("/CMakeLists.txt") || $0.path == "CMakeLists.txt" })
        guard let cmake else {
            throw StructuralTemplateGeneratorError.missingGeneratedFile("CMakeLists.txt")
        }
        try await render(
            templateNamed: "structural2cmake",
            descriptors: [GeneratedFileDescriptor(path: url.lastPathComponent, content: cmake.content)],
            to: url.deletingLastPathComponent()
        )
    }

    /// Generate layout plist files with the structural layout template.
    ///
    /// - Parameters:
    ///   - machine: Machine to render.
    ///   - name: Output machine name without the `.machine` suffix.
    ///   - url: Destination directory for the rendered layout files.
    public func generateLayoutFiles(
        for machine: Machine,
        named name: String,
        to url: URL
    ) async throws {
        let descriptors = try makeMachineDescriptors(for: machine, named: name + MachineDirectoryWrapper.dottedSuffix)
        let layoutDescriptors = descriptors.filter {
            $0.path.hasSuffix("/Layout.plist")
                || $0.path.hasSuffix("/WindowLayout.plist")
                || $0.path == "Layout.plist"
                || $0.path == "WindowLayout.plist"
        }.map {
            GeneratedFileDescriptor(path: URL(fileURLWithPath: $0.path).lastPathComponent, content: $0.content)
        }
        try await render(templateNamed: "structural2layout", descriptors: layoutDescriptors, to: url)
    }

    private func render(
        templateNamed name: String,
        descriptors: [GeneratedFileDescriptor],
        to url: URL
    ) async throws {
        guard let templateURL = Bundle.module.url(forResource: name, withExtension: "mtl", subdirectory: "Resources/Templates") else {
            throw StructuralTemplateGeneratorError.missingTemplate(name)
        }

        let parser = MTLParser(enableDebugging: false)
        let module = try await parser.parse(templateURL)
        let strategy = MTLInMemoryStrategy()
        let generator = MTLGenerator(module: module, generationStrategy: strategy)
        let root = descriptorRoot(for: descriptors)
        let resource = Resource(uri: "memory:/\(name).xmi")
        await resource.add(root)

        try await generator.generate(
            mainTemplate: "main",
            arguments: [root],
            models: ["IN": resource]
        )

        let generatedFiles = await strategy.getGeneratedFiles()
        try writeGeneratedFiles(generatedFiles, to: url)
    }

    private func descriptorRoot(for descriptors: [GeneratedFileDescriptor]) -> DynamicEObject {
        var root = DynamicEObject(eClass: fileSetClass)
        root.eSet("files", value: descriptors.map { descriptor in
            var file = DynamicEObject(eClass: fileClass)
            file.eSet("path", value: descriptor.path)
            file.eSet("content", value: descriptor.content)
            return file
        })
        return root
    }

    private func makeMachineDescriptors(
        for machine: Machine,
        named bundleName: String
    ) throws -> [GeneratedFileDescriptor] {
        let tempDirectory = try makeTemporaryDirectory(prefix: "fsmecore-machine")
        let bundleURL = tempDirectory.appendingPathComponent(bundleName, isDirectory: true)
        try machine.write(to: bundleURL, isSuspensible: true)
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: keys)
        var descriptors: [GeneratedFileDescriptor] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            guard values.isDirectory != true else { continue }

            descriptors.append(
                GeneratedFileDescriptor(
                    path: fileURL.lastPathComponent,
                    content: try String(contentsOf: fileURL, encoding: .utf8)
                )
            )
        }

        return descriptors.sorted { $0.path < $1.path }
    }

    private func readDescriptors(from url: URL, relativeTo baseURL: URL) throws -> [GeneratedFileDescriptor] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: keys)
        var descriptors: [GeneratedFileDescriptor] = []
        let normalisedBasePath = baseURL.standardizedFileURL.resolvingSymlinksInPath().path

        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            guard values.isDirectory != true else { continue }

            let normalisedFilePath = fileURL.standardizedFileURL.resolvingSymlinksInPath().path
            let relativePath = normalisedFilePath.replacingOccurrences(of: normalisedBasePath + "/", with: "")
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            descriptors.append(GeneratedFileDescriptor(path: relativePath, content: content))
        }

        return descriptors.sorted { $0.path < $1.path }
    }

    private func makeTemporaryDirectory(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(prefix)-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.standardizedFileURL.resolvingSymlinksInPath()
    }

    private func writeGeneratedFiles(_ files: [String: String], to baseURL: URL) throws {
        for (rawPath, content) in files {
            guard rawPath != "stdout" else { continue }

            let relativePath = normalisedGeneratedPath(rawPath)
            let destination = baseURL.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try content.write(to: destination, atomically: true, encoding: .utf8)
        }
    }

    private func normalisedGeneratedPath(_ rawPath: String) -> String {
        if rawPath.hasPrefix("/private") {
            return String(rawPath.dropFirst("/private".count))
        }
        if rawPath.hasPrefix("private") {
            return String(rawPath.dropFirst("private".count))
        }
        if rawPath.hasPrefix("/") {
            return String(rawPath.dropFirst())
        }
        return rawPath
    }
}

/// Generated file descriptor exposed to the MTL runtime.
public struct GeneratedFileDescriptor: Sendable, Equatable {
    /// Relative output path for the rendered file.
    public let path: String

    /// Textual content to write to the output path.
    public let content: String

    /// Create a file descriptor.
    ///
    /// - Parameters:
    ///   - path: Relative output path.
    ///   - content: Textual file content.
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

/// Errors raised while rendering structural templates.
public enum StructuralTemplateGeneratorError: Error {
    /// A bundled template resource could not be found.
    case missingTemplate(String)

    /// A required generated file was not present in the source snapshot.
    case missingGeneratedFile(String)
}
