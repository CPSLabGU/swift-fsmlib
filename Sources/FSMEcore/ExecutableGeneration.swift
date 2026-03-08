import ATL
import ECore
import EMFBase
import FSM
import Foundation
import MTL

/// Generate artefacts from executable LLFSM models through MTL templates.
///
/// `ExecutableTemplateGenerator` runs the bundled legacy LLFSM templates, or a
/// user-specified template, against executable LLFSM models. It accepts either
/// native `swift-fsmlib` values or pre-loaded executable XMI resources.
@MainActor
public struct ExecutableTemplateGenerator {
    /// Executable metamodel used for model loading and in-memory encoding.
    ///
    /// The generator uses this metamodel both to encode native Swift values and
    /// to resolve already-loaded executable XMI resources.
    public let metamodel: ExecutableLLFSMMetamodel

    /// Create the executable template generator.
    ///
    /// - Parameter metamodel: Loaded executable metamodel to use for model
    ///   loading and encoding.
    public init(metamodel: ExecutableLLFSMMetamodel) {
        self.metamodel = metamodel
    }

    /// Load a bundled executable template.
    ///
    /// - Parameter name: Basename of the bundled `.mtl` file.
    /// - Returns: URL of the bundled template resource.
    /// - Throws: Throw an error if the template resource is missing.
    public func bundledTemplateURL(named name: String) throws -> URL {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "mtl",
            subdirectory: "Resources/Templates/Executable"
        ) else {
            throw StructuralTemplateGeneratorError.missingTemplate(name)
        }
        return url
    }

    /// Generate files from an executable model resource.
    ///
    /// - Parameters:
    ///   - templateURL: URL of the MTL template to execute.
    ///   - resource: Executable model resource to expose as model alias `IN`.
    ///   - outputDirectory: Base directory for generated files.
    ///   - mainTemplate: Optional template name. When omitted, the first main
    ///     template or first declared template is used.
    /// - Throws: Throw an error if parsing or generation fails.
    public func generate(
        templateURL: URL,
        resource: Resource,
        outputDirectory: URL,
        mainTemplate: String? = nil
    ) async throws {
        let parser = MTLParser(enableDebugging: false)
        let module = try await parser.parse(templateURL)
        let templateName = try selectedTemplateName(in: module, requested: mainTemplate)

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let strategy = MTLFileSystemStrategy(basePath: outputDirectory.path)
        let generator = MTLGenerator(module: module, generationStrategy: strategy)

        let rootObjects = await resource.getRootObjects()
        let root: (any EcoreValue)?
        if let firstRoot = rootObjects.first {
            root = firstRoot
        } else {
            let allObjects = await resource.getAllObjects()
            root = allObjects.first
        }
        try await generator.generate(
            mainTemplate: templateName,
            arguments: [root],
            models: ["IN": resource]
        )
    }

    /// Generate files from a native machine value.
    ///
    /// - Parameters:
    ///   - templateURL: URL of the MTL template to execute.
    ///   - machine: Machine to encode as an executable arrangement.
    ///   - name: Machine name to preserve.
    ///   - arrangementName: Optional executable arrangement name.
    ///   - outputDirectory: Base directory for generated files.
    ///   - mainTemplate: Optional template name override.
    /// - Throws: Throw an error if encoding or generation fails.
    public func generate(
        templateURL: URL,
        machine: Machine,
        name: String,
        arrangementName: String? = nil,
        outputDirectory: URL,
        mainTemplate: String? = nil
    ) async throws {
        let resource = Resource(uri: "memory:/\(name).xmi")
        let codec = ExecutableMachineCodec(metamodel: metamodel)
        _ = await codec.encode(machine, name: name, arrangementName: arrangementName, into: resource)
        try await generate(
            templateURL: templateURL,
            resource: resource,
            outputDirectory: outputDirectory,
            mainTemplate: mainTemplate
        )
    }

    /// Generate files from a native arrangement value.
    ///
    /// - Parameters:
    ///   - templateURL: URL of the MTL template to execute.
    ///   - arrangement: Arrangement to encode.
    ///   - name: Arrangement name to preserve in the executable model.
    ///   - outputDirectory: Base directory for generated files.
    ///   - mainTemplate: Optional template name override.
    /// - Throws: Throw an error if encoding or generation fails.
    public func generate(
        templateURL: URL,
        arrangement: Arrangement,
        name: String,
        outputDirectory: URL,
        mainTemplate: String? = nil
    ) async throws {
        let resource = Resource(uri: "memory:/\(name).xmi")
        let codec = ExecutableArrangementCodec(metamodel: metamodel)
        _ = await codec.encode(arrangement, name: name, into: resource)
        try await generate(
            templateURL: templateURL,
            resource: resource,
            outputDirectory: outputDirectory,
            mainTemplate: mainTemplate
        )
    }

    /// Select the template entry point to execute for a parsed MTL module.
    ///
    /// If the caller did not request a specific template, this helper prefers a
    /// template marked as `main` and otherwise falls back to the first declared
    /// template so existing legacy modules continue to work unchanged.
    ///
    /// - Parameters:
    ///   - module: Parsed MTL module.
    ///   - requested: Optional caller-specified template name.
    /// - Returns: Name of the template to execute.
    /// - Throws: Throw an error if the requested template does not exist or the
    ///   module contains no templates.
    private func selectedTemplateName(in module: MTLModule, requested: String?) throws -> String {
        if let requested {
            guard module.templates[requested] != nil else {
                throw MTLExecutionError.templateNotFound("Template '\(requested)' not found in module '\(module.name)'")
            }
            return requested
        }
        if let main = module.templates.first(where: { $0.value.isMain }) {
            return main.key
        }
        guard let first = module.templates.first else {
            throw MTLExecutionError.templateNotFound("No templates found in module '\(module.name)'")
        }
        return first.key
    }
}

/// Execute ATL transformations across the LLFSM structural and executable models.
///
/// `LLFSMATLTransformer` wraps the core `swift-atl` runtime for the one-source
/// and one-target transformation cases used by `fsmconvert` and the regression
/// tests in this package.
@MainActor
public struct LLFSMATLTransformer {
    /// Create the ATL transformer.
    public init() {}

    /// Load a bundled ATL transformation.
    ///
    /// - Parameter name: Basename of the bundled `.atl` file.
    /// - Returns: URL of the bundled transformation resource.
    /// - Throws: Throw an error if the transformation resource is missing.
    public func bundledTransformURL(named name: String) throws -> URL {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "atl",
            subdirectory: "Resources/Transforms"
        ) else {
            throw StructuralTemplateGeneratorError.missingTemplate(name)
        }
        return url
    }

    /// Execute an ATL transformation and optionally persist the target model.
    ///
    /// - Parameters:
    ///   - atlURL: URL of the ATL module.
    ///   - sourceAlias: Source model alias. Defaults to the first alias
    ///     declared by the module.
    ///   - sourceResource: Source resource to expose to the ATL runtime.
    ///   - targetAlias: Target model alias. Defaults to the first alias
    ///     declared by the module.
    ///   - targetURL: Optional output URL. When provided, the target model is
    ///     serialised as XMI after execution.
    ///   - searchPaths: Additional metamodel search paths for ATL `@path`
    ///     resolution.
    /// - Returns: Target resource produced by the transformation.
    /// - Throws: Throw an error if parsing, execution, or serialisation fails.
    public func transform(
        atlURL: URL,
        sourceAlias: String? = nil,
        sourceResource: Resource,
        targetAlias: String? = nil,
        targetURL: URL? = nil,
        searchPaths: [String] = []
    ) async throws -> Resource {
        let parser = ATLParser()
        let source = try String(contentsOf: atlURL, encoding: .utf8)
        let module = try await parser.parseContent(
            source,
            filename: atlURL.path,
            searchPaths: [atlURL.deletingLastPathComponent().path] + searchPaths
        )

        guard let resolvedSourceAlias = sourceAlias ?? module.sourceMetamodels.keys.first,
              let resolvedTargetAlias = targetAlias ?? module.targetMetamodels.keys.first else {
            throw ExecutableGenerationError.missingATLAlias
        }

        let targetResource = Resource(uri: targetURL?.absoluteString ?? "memory:/atl-target.xmi")
        let vm = ATLVirtualMachine(module: module)
        try await vm.execute(
            sources: [resolvedSourceAlias: sourceResource],
            targets: [resolvedTargetAlias: targetResource]
        )
        try await canonicaliseKnownTargetShapes(
            moduleName: module.name,
            sourceResource: sourceResource,
            targetResource: targetResource
        )

        if let targetURL {
            let xmi = try await serialisedModel(for: module.name, resource: targetResource)
            try xmi.write(to: targetURL, atomically: true, encoding: .utf8)
        }
        return targetResource
    }

    /// Canonicalise target resources produced by known bundled ATL modules.
    ///
    /// Some ATL runs intentionally use Swift codec passes after execution so
    /// the final target resource matches the package’s native semantics more
    /// closely than a direct reflective copy would.
    ///
    /// - Parameters:
    ///   - moduleName: Parsed ATL module name.
    ///   - sourceResource: Source resource that drove the transformation.
    ///   - targetResource: Resource produced by the ATL virtual machine.
    /// - Throws: Throw an error if codec-based rebuilding fails.
    private func canonicaliseKnownTargetShapes(
        moduleName: String,
        sourceResource: Resource,
        targetResource: Resource
    ) async throws {
        switch moduleName {
        case "structural2executable":
            try await rebuildExecutableTarget(from: sourceResource, into: targetResource)
        case "executable2structural":
            try await rebuildStructuralTarget(from: sourceResource, into: targetResource)
        default:
            break
        }
    }

    /// Rebuild an executable target resource from a structural source model.
    ///
    /// This helper decodes the structural source with the native codecs and
    /// then re-encodes it as an executable model so the target graph matches
    /// the executable fidelity rules used elsewhere in the package.
    ///
    /// - Parameters:
    ///   - sourceResource: Structural source resource.
    ///   - targetResource: Executable target resource to replace.
    /// - Throws: Throw an error if decoding or encoding fails.
    private func rebuildExecutableTarget(from sourceResource: Resource, into targetResource: Resource) async throws {
        let structuralMetamodel = try await LLFSMMetamodel()
        let executableMetamodel = try await ExecutableLLFSMMetamodel()
        let structuralMachineCodec = MachineEcoreCodec(metamodel: structuralMetamodel)
        let structuralArrangementCodec = ArrangementEcoreCodec(metamodel: structuralMetamodel)
        let executableMachineCodec = ExecutableMachineCodec(metamodel: executableMetamodel)
        let executableArrangementCodec = ExecutableArrangementCodec(metamodel: executableMetamodel)

        await targetResource.clear()

        if let arrangementObject = await findObject(
            named: structuralMetamodel.arrangementClass.name,
            in: sourceResource
        ) {
            let arrangement = try await structuralArrangementCodec.decode(arrangementObject, from: sourceResource)
            _ = await executableArrangementCodec.encode(arrangement, name: "Arrangement", into: targetResource)
            return
        }

        if let machineObject = await findObject(
            named: structuralMetamodel.machineClass.name,
            in: sourceResource
        ) {
            let decoded = try await structuralMachineCodec.decode(machineObject, from: sourceResource)
            _ = await executableMachineCodec.encode(decoded.machine, name: decoded.name, into: targetResource)
        }
    }

    /// Rebuild a structural target resource from an executable source model.
    ///
    /// This helper performs the inverse of `rebuildExecutableTarget(from:into:)`
    /// so executable-to-structural transforms return to the canonical
    /// structural shape used by the native codecs and round-trip tests.
    ///
    /// - Parameters:
    ///   - sourceResource: Executable source resource.
    ///   - targetResource: Structural target resource to replace.
    /// - Throws: Throw an error if decoding or encoding fails.
    private func rebuildStructuralTarget(from sourceResource: Resource, into targetResource: Resource) async throws {
        let structuralMetamodel = try await LLFSMMetamodel()
        let executableMetamodel = try await ExecutableLLFSMMetamodel()
        let structuralMachineCodec = MachineEcoreCodec(metamodel: structuralMetamodel)
        let structuralArrangementCodec = ArrangementEcoreCodec(metamodel: structuralMetamodel)
        let executableMachineCodec = ExecutableMachineCodec(metamodel: executableMetamodel)
        let executableArrangementCodec = ExecutableArrangementCodec(metamodel: executableMetamodel)

        await targetResource.clear()

        if let arrangementObject = await findObject(
            named: executableMetamodel.arrangementClass.name,
            in: sourceResource
        ) {
            let arrangement = try await executableArrangementCodec.decode(arrangementObject, from: sourceResource)
            _ = await structuralArrangementCodec.encode(arrangement, into: targetResource)
            return
        }

        if let machineObject = await findObject(
            named: executableMetamodel.stateMachineClass.name,
            in: sourceResource
        ) {
            let decoded = try await executableMachineCodec.decode(machineObject, from: sourceResource)
            _ = await structuralMachineCodec.encode(decoded.machine, name: decoded.name, into: targetResource)
        }
    }

    private func serialisedModel(for moduleName: String, resource: Resource) async throws -> String {
        if moduleName == "structural2executable" {
            let metamodel = try await ExecutableLLFSMMetamodel()
            return try await ExecutableXMIWriter(metamodel: metamodel).serialise(resource)
        }
        let serialiser = XMISerializer()
        return try await serialiser.serialize(resource)
    }

    private func findObject(named className: String, in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let rootMatch = roots.first(where: { $0.eClass.name == className }) {
            return rootMatch
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first(where: { $0.eClass.name == className })
    }
}

/// Errors raised while executing LLFSM ATL and MTL generation workflows.
public enum ExecutableGenerationError: Error {
    /// The ATL module does not declare both a source and a target alias.
    case missingATLAlias
}
