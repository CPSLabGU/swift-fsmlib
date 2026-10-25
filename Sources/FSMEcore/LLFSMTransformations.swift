//
//  LLFSMTransformations.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation

/// The model-to-model transformations between the structural, sectioned and
/// kernel levels of LLFSMs.
///
/// Each transformation reads a model from a resource and returns a new
/// resource with the transformed model, together with the warnings that
/// describe what the target level could not keep. The transformations are
/// bundled ATL modules; see <doc:Transformations> for what each level keeps.
///
/// ```swift
/// let transformations = try await LLFSMTransformations()
/// let sectioned = try await transformations.structuralToSectioned(structuralResource)
/// let kernel = try await transformations.sectionedToKernel(sectioned.resource)
/// for warning in kernel.diagnostics.warnings { print(warning) }
/// ```
@MainActor
public struct LLFSMTransformations {
    /// The kernel and sectioned metamodels that type the sectioned and kernel models.
    public let metamodels: LLFSMMetamodels

    /// The structural metamodel that types structural models.
    public let structural: LLFSMMetamodel

    /// How the transformations read features that a model does not set.
    public var unsetFeatureReads: UnsetFeatureReads = .defaults

    /// Load the bundled metamodels.
    ///
    /// - Throws: An error if a bundled metamodel cannot be found or parsed.
    public init() async throws {
        self.init(metamodels: try await LLFSMMetamodels(), structural: try await LLFSMMetamodel())
    }

    /// Use already loaded metamodels.
    ///
    /// - Parameters:
    ///   - metamodels: The kernel and sectioned metamodels.
    ///   - structural: The structural metamodel.
    public init(metamodels: LLFSMMetamodels, structural: LLFSMMetamodel) {
        self.metamodels = metamodels
        self.structural = structural
    }

    // MARK: - Transformations

    /// Transform a structural machine or arrangement into the sectioned level.
    ///
    /// Every non-empty section and every label becomes an opaque node that
    /// carries its exact text, even if it holds only white space, and the
    /// machine language. The boilerplate of a machine becomes host
    /// declarations of the machine, with its include path, includes,
    /// variables and functions, and the boilerplate of a state host
    /// declarations of the state. A typing pass then declares the simple
    /// variables of each machine (see ``VariableDeclarationScanner``),
    /// recording the comment, text and line of each declaration in its
    /// variable, and replaces every label and section that
    /// ``ExpressionTyper`` types, except for sections that hold only white
    /// space.
    ///
    /// - Parameters:
    ///   - source: The resource whose root is a structural machine or arrangement.
    ///   - arrangementName: The name of the sectioned arrangement made from a
    ///     structural arrangement, which has no name of its own. A single
    ///     machine gives the arrangement its own name.
    ///   - uri: The URI of the resource to create.
    /// - Returns: The sectioned model and the warnings of the transformation.
    /// - Throws: ``LLFSMTransformationError`` if the transformation cannot be loaded or fails.
    public func structuralToSectioned(
        _ source: Resource,
        arrangementName: String = LLFSMTransformations.defaultArrangementName,
        uri: String = LLFSMTransformations.defaultSectionedURI
    ) async throws -> TransformationResult {
        let roots = await source.getRootObjects().compactMap { $0 as? DynamicEObject }
        let rootClasses = [structural.machineClass, structural.arrangementClass]
        guard roots.contains(where: { root in rootClasses.contains { StructuralDeclarations.matches(root.eClass, $0) } })
        else {
            throw LLFSMTransformationError.missingRoot(structural.arrangementClass.name)
        }
        let target = await makeTarget(uri: uri)
        try await run(
            .structuralToSectioned,
            sources: [Alias.source: source],
            targets: [Alias.target: target, Alias.kernelTarget: target],
            parameters: LLFSMTransformationNames.parameters(arrangementName: arrangementName))
        let variables = await StructuralDeclarations(metamodel: structural).variables(of: source)
        await SectionedTypingPass(metamodels: metamodels).run(on: target, variables: variables)
        return TransformationResult(resource: target, diagnostics: TransformationDiagnostics())
    }

    /// Encode a sectioned model into the kernel.
    ///
    /// The host declarations of the states of a machine are added to those
    /// of the machine, which the diagnostics report as
    /// ``TransformationWarning/StructuralInformation/stateBoilerplate``.
    /// Opaque statements that hold only white space have no effect and are
    /// left out, so a section that holds only such statements counts as empty.
    ///
    /// - Parameters:
    ///   - source: The resource whose root is a sectioned arrangement.
    ///   - options: The semantic options of the encoding.
    ///   - uri: The URI of the resource to create.
    /// - Returns: The kernel model and the warnings of the encoding.
    /// - Throws: ``LLFSMTransformationError`` if the transformation cannot be loaded or fails.
    public func sectionedToKernel(
        _ source: Resource,
        options: SectionedToKernelOptions = SectionedToKernelOptions(),
        uri: String = LLFSMTransformations.defaultKernelURI
    ) async throws -> TransformationResult {
        let target = await makeTarget(uri: uri)
        var parameters = LLFSMTransformationNames.parameters()
        parameters.merge(options.parameters) { _, option in option }
        try await run(
            .sectionedToKernel,
            sources: [Alias.source: source, Alias.kernelSource: source],
            targets: [Alias.target: target],
            parameters: parameters)
        let diagnostics = await SectionedEncodingDiagnostics(metamodels: metamodels)
            .diagnose(source, options: options)
        return TransformationResult(resource: target, diagnostics: diagnostics)
    }

    /// Rebuild a sectioned model from a kernel model.
    ///
    /// A kernel machine whose states record their origins is rebuilt exactly
    /// as the sectioned machine it encodes. A kernel machine without origin
    /// records is mapped flatly, which the diagnostics report.
    ///
    /// - Parameters:
    ///   - source: The resource whose root is a kernel arrangement.
    ///   - uri: The URI of the resource to create.
    /// - Returns: The sectioned model and the warnings of the mapping.
    /// - Throws: ``LLFSMTransformationError`` if the transformation cannot be loaded or fails.
    public func kernelToSectioned(
        _ source: Resource,
        uri: String = LLFSMTransformations.defaultSectionedURI
    ) async throws -> TransformationResult {
        let target = await makeTarget(uri: uri)
        try await run(
            .kernelToSectioned,
            sources: [Alias.source: source],
            targets: [Alias.target: target, Alias.kernelTarget: target],
            parameters: LLFSMTransformationNames.parameters())
        var diagnostics = TransformationDiagnostics()
        let index = await KernelModelIndex(resource: source)
        let kernel = metamodels.kernel
        for case let machine? in index.order.map(index.object) where machine.eClass.id == kernel.machineClass.id {
            let hasOrigins = machine.identifiers(.states).contains { index.object($0)?.identifier(.origin) != nil }
            if !hasOrigins {
                diagnostics.record(.flatMapping(machine: machine.string(.name) ?? ""))
            }
        }
        return TransformationResult(resource: target, diagnostics: diagnostics)
    }

    /// Transform a sectioned arrangement back into a structural machine or arrangement.
    ///
    /// The transformation inverts ``structuralToSectioned(_:arrangementName:uri:)``.
    /// An arrangement whose language is set and whose only instance and only
    /// machine carry its name becomes a single structural machine; any other
    /// arrangement becomes a structural arrangement that holds one copy of a
    /// machine per instance. The initial state of each machine comes first.
    ///
    /// Every section and label becomes host-language text in the language of
    /// its machine, else of its arrangement, else
    /// ``LLFSMTransformations/defaultLanguage``. Opaque text is kept byte for
    /// byte. Typed nodes are written in the form that ``ExpressionTyper``
    /// reads back: a comparison of the state time with `after(…)`,
    /// `after_ms(…)` or `timeout(…)`, a line of output with the print call of
    /// the language, and operators with only the parentheses they need.
    /// The host declarations of a machine become its boilerplate and those
    /// of a state the boilerplate of the state. The variables of a machine
    /// are declared again in its variables: a variable with a declaration
    /// text is written as that text at its original line, provided that the
    /// first host declarations of the machine are in the language of the
    /// machine; any other variable is declared in canonical form after them.
    /// A structural model made by ``structuralToSectioned(_:arrangementName:uri:)``
    /// therefore comes back byte for byte apart from its layouts, which
    /// ``restoreLayouts(into:from:)`` can copy from the original.
    ///
    /// Some structural information cannot be recovered and is reported as
    /// ``TransformationWarning/Kind/notRecovered(_:owner:)``: layouts are
    /// not kept by the sectioned level; a machine whose host declarations
    /// carry no include paths gets an empty include path; several host
    /// declarations of one machine, as the encoding into the kernel leaves
    /// the boilerplate of states, are merged into the machine boilerplate;
    /// variables without a declaration text in the language of the machine
    /// are written in canonical form; and shared declarations, instance
    /// bindings and machines without instances have no place in structural
    /// models.
    ///
    /// - Parameters:
    ///   - source: The resource whose root is a sectioned arrangement.
    ///   - uri: The URI of the resource to create.
    /// - Returns: The structural model and the warnings of the transformation.
    /// - Throws: ``LLFSMTransformationError`` if the source has no sectioned
    ///   arrangement, or if the transformation cannot be loaded or fails, for
    ///   example because a typed node belongs to a language that no bundled
    ///   module writes.
    public func sectionedToStructural(
        _ source: Resource,
        uri: String = LLFSMTransformations.defaultStructuralURI
    ) async throws -> TransformationResult {
        let index = await KernelModelIndex(resource: source)
        let arrangementClass = metamodels.sectioned.arrangementClass
        guard index.roots.compactMap(index.object).contains(where: {
            StructuralDeclarations.matches($0.eClass, arrangementClass)
        }) else {
            throw LLFSMTransformationError.missingRoot(arrangementClass.name)
        }
        let renderer = try await HostTextRenderer(resource: source)
        let target = await makeTarget(uri: uri)
        try await run(
            .sectionedToStructural,
            sources: [Alias.source: source, Alias.kernelSource: source],
            targets: [Alias.target: target],
            parameters: LLFSMTransformationNames.parameters(),
            nativeHelpers: renderer.nativeHelpers)
        let diagnostics = await StructuralRecoveryDiagnostics(metamodels: metamodels).diagnose(source)
        return TransformationResult(resource: target, diagnostics: diagnostics)
    }

    /// Transform a kernel arrangement into a structural machine or arrangement.
    ///
    /// The kernel model is first rebuilt as a sectioned model with
    /// ``kernelToSectioned(_:uri:)`` and then transformed with
    /// ``sectionedToStructural(_:uri:)``. The warnings of both steps are
    /// reported, those of the first step first.
    ///
    /// - Parameters:
    ///   - source: The resource whose root is a kernel arrangement.
    ///   - uri: The URI of the resource to create.
    /// - Returns: The structural model and the warnings of both steps.
    /// - Throws: ``LLFSMTransformationError`` if a step cannot be loaded or fails.
    public func kernelToStructural(
        _ source: Resource,
        uri: String = LLFSMTransformations.defaultStructuralURI
    ) async throws -> TransformationResult {
        let sectioned = try await kernelToSectioned(source)
        let structural = try await sectionedToStructural(sectioned.resource, uri: uri)
        var diagnostics = sectioned.diagnostics
        diagnostics.merge(structural.diagnostics)
        return TransformationResult(resource: structural.resource, diagnostics: diagnostics)
    }

    // MARK: - Running Modules

    /// The name given to a sectioned arrangement made from a structural arrangement by default.
    nonisolated public static let defaultArrangementName = LLFSMTransformationNames.defaultArrangementName

    /// The URI given to kernel models by default.
    nonisolated public static let defaultKernelURI = "memory:/kernel.xmi"

    /// The URI given to sectioned models by default.
    nonisolated public static let defaultSectionedURI = "memory:/sectioned.xmi"

    /// The URI given to structural models by default.
    nonisolated public static let defaultStructuralURI = "memory:/structural.xmi"

    /// The language of structural machines made from sectioned machines that name none.
    nonisolated public static let defaultLanguage = LLFSMTransformationNames.defaultLanguage

    /// The model aliases of the transformation headers.
    private typealias Alias = LLFSMTransformationNames.Alias

    /// Create the resource that receives a transformed model.
    ///
    /// The resource belongs to a new resource set in which the kernel,
    /// sectioned and structural metamodels are registered.
    ///
    /// - Parameter uri: The URI of the resource.
    /// - Returns: The empty resource.
    func makeTarget(uri: String) async -> Resource {
        let resourceSet = ResourceSet()
        await metamodels.register(in: resourceSet)
        await structural.register(in: resourceSet)
        return await resourceSet.createResource(uri: uri)
    }

    /// The registry that binds the metamodel names of the transformation headers.
    var registry: ATLMetamodelRegistry {
        ATLMetamodelRegistry(packages: [metamodels.kernel.package, metamodels.sectioned.package, structural.package])
    }

    /// Parse a bundled transformation.
    ///
    /// - Parameter module: The transformation to parse.
    /// - Returns: The parsed module.
    /// - Throws: ``LLFSMTransformationError`` if the module is missing or malformed.
    func load(_ module: LLFSMTransformationNames.Module) async throws -> ATLModule {
        guard let url = BundledResources.url(
            forResource: module.rawValue,
            withExtension: LLFSMTransformationNames.moduleExtension,
            subdirectory: LLFSMTransformationNames.moduleSubdirectory,
            in: .module,
            bundleName: LLFSMMetamodels.bundleName
        ), let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw LLFSMTransformationError.missingTransformation(module.rawValue)
        }
        do {
            return try await ATLParser().parseContent(
                text, filename: url.path, continueAfterErrors: false, metamodelRegistry: registry)
        } catch {
            throw LLFSMTransformationError.invalidTransformation(module.rawValue, String(describing: error))
        }
    }

    /// Run a bundled transformation.
    ///
    /// Only the parameters that the module declares are passed to it.
    ///
    /// - Parameters:
    ///   - module: The transformation to run.
    ///   - sources: The source models by alias.
    ///   - targets: The target models by alias.
    ///   - parameters: The values of the module parameters by name.
    ///   - nativeHelpers: The helpers implemented in Swift that the module calls.
    /// - Throws: ``LLFSMTransformationError`` if the module cannot be loaded or fails.
    func run(
        _ module: LLFSMTransformationNames.Module,
        sources: [String: Resource],
        targets: [String: Resource],
        parameters: [String: any EcoreValue],
        nativeHelpers: [ATLNativeHelper] = []
    ) async throws {
        let parsed = try await load(module)
        let declared = Set(parsed.parameters.map(\.name))
        let passed = parameters.filter { declared.contains($0.key) }
        let machine = ATLVirtualMachine(
            module: parsed, unsetFeatureReads: unsetFeatureReads, nativeHelpers: nativeHelpers)
        do {
            try await machine.execute(
                sources: .init(uniqueKeysWithValues: sources.sorted { $0.key < $1.key }),
                targets: .init(uniqueKeysWithValues: targets.sorted { $0.key < $1.key }),
                parameters: passed)
        } catch {
            throw LLFSMTransformationError.transformationFailed(module.rawValue, String(describing: error))
        }
    }
}

/// Errors raised while a bundled transformation is loaded or run.
public enum LLFSMTransformationError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The bundled transformation cannot be found.
    case missingTransformation(String)

    /// The bundled transformation cannot be parsed.
    ///
    /// The associated values are the name of the transformation and the reason.
    case invalidTransformation(String, String)

    /// The transformation failed while it ran.
    ///
    /// The associated values are the name of the transformation and the reason.
    case transformationFailed(String, String)

    /// The source model lacks the root element that the transformation reads.
    ///
    /// The associated value is the name of the expected class.
    case missingRoot(String)

    /// A sentence that describes the error.
    public var description: String {
        switch self {
        case .missingTransformation(let name):
            return "The bundled transformation \(name) cannot be found"
        case .invalidTransformation(let name, let reason):
            return "The bundled transformation \(name) cannot be parsed: \(reason)"
        case .transformationFailed(let name, let reason):
            return "The transformation \(name) failed: \(reason)"
        case .missingRoot(let name):
            return "The source model has no root of class \(name)"
        }
    }
}
