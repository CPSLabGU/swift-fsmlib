//
//  FSMPipeline.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
@preconcurrency import FSM
import Foundation
import ModellingGenerators
import ModellingPipeline

/// Reads, transforms, validates and writes LLFSMs at any of their levels.
///
/// A pipeline reads native machines, arrangements and SCXML documents with
/// the Swift readers, and XMI or JSON documents at the structural, sectioned
/// or kernel level, recognising the level by the namespace of the root
/// element. It then runs the shortest chain of ``LevelTransformation``s that
/// takes the model to the level of the requested ``OutputTarget``, and writes
/// the target: native formats through the structural templates or the Swift
/// language bindings (see ``NativeGenerator``), model documents through
/// `ModelIO`, and kernel targets through ``KernelTemplateGenerator``.
///
/// ```swift
/// var options = FSMPipeline.Options()
/// options.semantics.selfLoop = .reentry
/// let pipeline = try await FSMPipeline(options: options)
/// let report = try await pipeline.convert([machineURL], to: .smv, output: outputDirectory)
/// for warning in report.warnings { print("warning:", warning) }
/// ```
///
/// What the reading, writing and transformations could not keep is collected
/// in the ``Report`` as warnings, and progress is reported to a
/// `GenerationProgressReporter`.
@MainActor
public struct FSMPipeline {
    /// The options of a pipeline.
    public struct Options: Sendable {
        /// The generator of native formats (default ``NativeGenerator/templates``).
        public var generator: NativeGenerator

        /// The level of `xmi` and `json` output, or `nil` to keep the level of the model.
        public var level: LLFSMLevel?

        /// The profile that a kernel model must satisfy before a kernel target is
        /// generated from it, in addition to the profile the target requires.
        ///
        /// `nil` applies the profile of the target alone. ``validate(_:)`` uses
        /// this profile, or ``ValidationProfile/strict`` if it is `nil`.
        public var profile: ValidationProfile?

        /// The semantic options of the encoding of sectioned models into the kernel.
        public var semantics: SectionedToKernelOptions

        /// The settings with which the structural and kernel templates run.
        public var templates: TemplateSettings

        /// The options with which XMI documents are written.
        public var xmiOptions: XMISerializationOptions

        /// Whether native machines and arrangements are written as suspensible.
        public var isSuspensible: Bool

        /// Whether a single native input is read as an arrangement of one machine.
        public var makesArrangement: Bool

        /// Create options.
        ///
        /// - Parameters:
        ///   - generator: The generator of native formats.
        ///   - level: The level of `xmi` and `json` output, or `nil` for the level of the model.
        ///   - profile: The profile kernel models must satisfy, or `nil` for that of the target.
        ///   - semantics: The options of the encoding into the kernel.
        ///   - templates: The settings of the templates.
        ///   - xmiOptions: The options with which XMI is written.
        ///   - isSuspensible: Whether native output is suspensible.
        ///   - makesArrangement: Whether a single native input becomes an arrangement.
        public init(
            generator: NativeGenerator = .templates,
            level: LLFSMLevel? = nil,
            profile: ValidationProfile? = nil,
            semantics: SectionedToKernelOptions = SectionedToKernelOptions(),
            templates: TemplateSettings = TemplateSettings(),
            xmiOptions: XMISerializationOptions = .legacy,
            isSuspensible: Bool = true,
            makesArrangement: Bool = false
        ) {
            self.generator = generator
            self.level = level
            self.profile = profile
            self.semantics = semantics
            self.templates = templates
            self.xmiOptions = xmiOptions
            self.isSuspensible = isSuspensible
            self.makesArrangement = makesArrangement
        }
    }

    /// A step of a conversion.
    public enum Step: Hashable, Sendable {
        /// Transform the model to another level.
        case transform(LevelTransformation)
        /// Validate the kernel model under a profile, stopping on errors.
        case validate(ValidationProfile)
        /// Generate a kernel target into the output directory.
        case generate(KernelTarget)
        /// Write the structural model in a native format, or in the format of its
        /// own language for `nil`.
        case writeNative(Format?)
        /// Save the model as a document in a model format.
        case save(ModelFormat)
    }

    /// What a model of a pipeline holds, also available as ``Model/Content``.
    public enum ModelContent {
        /// A native machine with its name.
        case machine(name: String, Machine)
        /// A native arrangement with its name.
        case arrangement(name: String, Arrangement)
        /// A sectioned or kernel model.
        case resource(Resource)
    }

    /// A model held by a pipeline.
    public struct Model {
        /// The level of the model.
        public let level: LLFSMLevel

        /// The machine, arrangement or resource of the model.
        public let content: Content

        /// Create a model.
        ///
        /// - Parameters:
        ///   - level: The level of the model.
        ///   - content: The machine, arrangement or resource of the model.
        public init(level: LLFSMLevel, content: Content) {
            self.level = level
            self.content = content
        }
    }

    /// What a pipeline run found and wrote.
    public struct Report: Sendable {
        /// The distinct warnings of reading, transforming and writing, in the order found.
        public internal(set) var warnings: [String] = []

        /// The diagnostics of the validation of the kernel model, if it was validated.
        public internal(set) var diagnostics: [KernelDiagnostic] = []

        /// The files that were written, in order; a written bundle counts as one file.
        public internal(set) var files: [URL] = []

        /// Create an empty report.
        public init() {}

        /// Whether a diagnostic of the validation is an error.
        public var hasErrors: Bool { KernelValidator.containsErrors(diagnostics) }

        /// Add warnings that were not reported before.
        ///
        /// - Parameter messages: The messages of the warnings.
        mutating func warn<Messages: Sequence>(_ messages: Messages) where Messages.Element == String {
            for message in messages where !warnings.contains(message) {
                warnings.append(message)
            }
        }
    }

    /// The file extension of arrangement bundles.
    nonisolated public static let arrangementExtension = "arrangement"

    /// The name under which a loaded document is kept by the model pipeline.
    nonisolated static let inputModelName = "IN"

    /// The scheme of the URIs of models that exist only in memory.
    nonisolated static let memoryScheme = "memory:/"

    /// The name given to a machine or arrangement whose file name has no stem.
    nonisolated static let fallbackMachineName = "Machine"

    /// The name given to an arrangement composed of several inputs without an output name.
    nonisolated static let fallbackArrangementName = "Arrangement"

    /// The options of the pipeline.
    public let options: Options

    /// The receiver of progress reports.
    public let progress: GenerationProgressReporter

    /// The structural metamodel.
    let structural: LLFSMMetamodel

    /// The sectioned and kernel metamodels.
    let metamodels: LLFSMMetamodels

    /// The transformations between the levels.
    let transformations: LLFSMTransformations

    /// Load the metamodels and transformations of a pipeline.
    ///
    /// - Parameters:
    ///   - options: The options of the pipeline (default options).
    ///   - progress: The receiver of progress reports; reports are dropped by default.
    /// - Throws: An error if a bundled metamodel cannot be loaded.
    public init(options: Options = Options(), progress: @escaping GenerationProgressReporter = { _ in }) async throws {
        self.options = options
        self.progress = progress
        let structural = try await LLFSMMetamodel()
        let metamodels = try await LLFSMMetamodels()
        var transformations = LLFSMTransformations(metamodels: metamodels, structural: structural)
        transformations.unsetFeatureReads = options.templates.unsetFeatureReads
        self.structural = structural
        self.metamodels = metamodels
        self.transformations = transformations
    }

    // MARK: - Planning

    /// The steps that take a model from its level to an output target.
    ///
    /// The model is transformed along the shortest chain of
    /// ``LevelTransformation``s to the level of the target. A target without a
    /// level of its own (`xmi`, `json`) is written at ``Options/level`` or, if
    /// that is `nil`, at the level of the model. A kernel target is preceded by
    /// a validation under ``Options/profile`` if one is given.
    ///
    /// - Parameters:
    ///   - source: The level of the model.
    ///   - target: The output target, or `nil` for the native format of the model's own language.
    ///   - options: The options of the conversion.
    /// - Returns: The steps in the order in which they run.
    nonisolated public static func steps(from source: LLFSMLevel, to target: OutputTarget?, options: Options) -> [Step] {
        let level = target.map { $0.level ?? options.level ?? source } ?? .structural
        let transforms = LevelTransformation.chain(from: source, to: level).map(Step.transform)
        switch target?.kind {
        case nil:
            return transforms + [.writeNative(nil)]
        case .native(let format):
            return transforms + [.writeNative(format)]
        case .model(let format, _):
            return transforms + [.save(format)]
        case .kernel(let kernelTarget):
            return transforms + (options.profile.map { [Step.validate($0)] } ?? []) + [.generate(kernelTarget)]
        }
    }

    // MARK: - Running

    /// Read the inputs, convert them and write an output target.
    ///
    /// - Parameters:
    ///   - inputs: The locations of the inputs; several inputs form an arrangement.
    ///   - target: The output target, or `nil` for the native format of the model's own language.
    ///   - output: The file or bundle to write, or the directory that receives
    ///     the files of a kernel target.
    /// - Returns: The warnings and the written files.
    /// - Throws: ``FSMPipelineError`` if an input cannot be read or the model is
    ///   not valid, and the errors of the transformations, templates and writers.
    @discardableResult
    public func convert(_ inputs: [URL], to target: OutputTarget?, output: URL) async throws -> Report {
        var report = Report()
        let model = try await load(inputs, arrangementName: Self.stem(of: output, fallback: Self.fallbackArrangementName), report: &report)
        try await run(Self.steps(from: model.level, to: target, options: options), on: model, output: output, report: &report)
        return report
    }

    /// Read the inputs, transform them to the kernel and validate the kernel model.
    ///
    /// The model is validated under ``Options/profile``, or under
    /// ``ValidationProfile/strict`` if no profile is given. Validation errors
    /// do not stop the run; they are returned in ``Report/diagnostics``.
    ///
    /// - Parameter inputs: The locations of the inputs; several inputs form an arrangement.
    /// - Returns: The warnings and the diagnostics of the validation.
    /// - Throws: ``FSMPipelineError`` if an input cannot be read, and the errors of
    ///   the transformations.
    public func validate(_ inputs: [URL]) async throws -> Report {
        var report = Report()
        let model = try await load(inputs, arrangementName: Self.fallbackArrangementName, report: &report)
        let steps = LevelTransformation.chain(from: model.level, to: .kernel).map(Step.transform)
        let kernel = try await run(steps, on: model, output: URL(fileURLWithPath: Self.fallbackArrangementName), report: &report)
        let profile = options.profile ?? .strict
        progress(GenerationProgressUpdate(message: "Validating under the \(profile.rawValue) profile"))
        report.diagnostics = await KernelValidator(metamodel: metamodels.kernel, profile: profile)
            .validate(try resource(of: kernel))
        return report
    }

    /// Run steps on a model.
    ///
    /// - Parameters:
    ///   - steps: The steps, as planned by ``steps(from:to:options:)``.
    ///   - model: The model to start from.
    ///   - output: The file, bundle or directory to write.
    ///   - report: Receives the warnings, diagnostics and written files.
    /// - Returns: The model after the last step.
    /// - Throws: ``FSMPipelineError/invalidModel(_:)`` if a validation finds errors,
    ///   and the errors of the steps.
    @discardableResult
    public func run(_ steps: [Step], on model: Model, output: URL, report: inout Report) async throws -> Model {
        var model = model
        for step in steps {
            switch step {
            case .transform(let transformation):
                model = try await transform(model, with: transformation, report: &report)
            case .validate(let profile):
                progress(GenerationProgressUpdate(message: "Validating under the \(profile.rawValue) profile"))
                let diagnostics = await KernelValidator(metamodel: metamodels.kernel, profile: profile)
                    .validate(try resource(of: model))
                report.diagnostics += diagnostics
                if KernelValidator.containsErrors(diagnostics) { throw FSMPipelineError.invalidModel(diagnostics) }
            case .generate(let target):
                try await generate(target, from: model, into: output, report: &report)
            case .writeNative(let format):
                try await writeNative(model, format: format, to: output)
                report.files.append(output)
            case .save(let format):
                try await save(model, format: format, to: output, report: &report)
                report.files.append(output)
            }
        }
        return model
    }

    // MARK: - Reading

    /// Resolve the location of an input given on the command line.
    ///
    /// A path that does not exist is tried again with the `.machine` suffix.
    ///
    /// - Parameter path: The path as given.
    /// - Returns: The location of the input.
    /// - Throws: ``FSMPipelineError/missingInput(_:)`` if neither path exists.
    nonisolated public static func resolveInput(_ path: String) throws -> URL {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) { return URL(fileURLWithPath: path) }
        let machinePath = path + MachineDirectoryWrapper.dottedSuffix
        guard fileManager.fileExists(atPath: machinePath) else { throw FSMPipelineError.missingInput(path) }
        return URL(fileURLWithPath: machinePath)
    }

    /// Read the inputs as one model.
    ///
    /// A single XMI or JSON document is read at the level its root namespace
    /// names; structural documents are decoded into machines or arrangements.
    /// A single `.arrangement` bundle is read as an arrangement, and any other
    /// single input as a machine, unless ``Options/makesArrangement`` asks for an
    /// arrangement. Several inputs are composed into an arrangement.
    ///
    /// - Parameters:
    ///   - inputs: The locations of the inputs.
    ///   - arrangementName: The name of an arrangement composed of several inputs.
    ///   - report: Receives the warnings of reading.
    /// - Returns: The model.
    /// - Throws: ``FSMPipelineError`` if no input is given, a document has no
    ///   LLFSM root, or an input cannot be read.
    public func load(_ inputs: [URL], arrangementName: String, report: inout Report) async throws -> Model {
        guard let first = inputs.first else { throw FSMPipelineError.noInput }
        if inputs.count == 1, Self.isModelDocument(first) {
            let model = try await loadDocument(first, report: &report)
            guard options.makesArrangement, case .machine = model.content else { return model }
            throw LLFSMMetamodelError.missingFeature("root Arrangement object")
        }
        if inputs.count == 1, !options.makesArrangement {
            progress(GenerationProgressUpdate(message: "Reading \(first.lastPathComponent)"))
            if first.pathExtension == Self.arrangementExtension {
                let arrangement = try ArrangementWrapper(url: first).arrangement
                return Model(level: .structural, content: .arrangement(name: Self.fileStem(of: first), arrangement))
            }
            let storage = try MachineStorageFactory.read(from: first)
            return Model(level: .structural, content: .machine(name: Self.fileStem(of: first), storage.machine))
        }
        var instances: [Instance] = []
        for url in inputs {
            progress(GenerationProgressUpdate(message: "Reading \(url.lastPathComponent)"))
            let machine = try MachineStorageFactory.read(from: url).machine
            let (instanceName, machineName) = Self.instanceNames(forFileNamed: url.lastPathComponent)
            instances.append(Instance(name: instanceName, typeFile: machineName, machine: machine))
        }
        return Model(level: .structural, content: .arrangement(name: arrangementName, Arrangement(namedInstances: instances)))
    }

    /// Read an XMI or JSON document at the level its root namespace names.
    ///
    /// - Parameters:
    ///   - url: The location of the document.
    ///   - report: Receives the warnings of reading.
    /// - Returns: The model.
    /// - Throws: ``FSMPipelineError/unknownLevel(_:)`` if the document has no
    ///   LLFSM root, and the errors of the parser.
    func loadDocument(_ url: URL, report: inout Report) async throws -> Model {
        let resourceSet = ResourceSet()
        await register(in: resourceSet)
        let pipeline = ModelPipeline(steps: [.load(name: Self.inputModelName, url: url)])
        let result = try await pipeline.run(in: resourceSet, progress: progress)
        report.warn(result.diagnostics.warnings.map(\.message))
        guard let resource = result.models[Self.inputModelName], let level = await level(of: resource) else {
            throw FSMPipelineError.unknownLevel(url.path)
        }
        guard level == .structural else { return Model(level: level, content: .resource(resource)) }
        return Model(level: .structural, content: try await decodeStructural(resource, preferArrangement: true))
    }

    /// The level of the model that a resource holds.
    ///
    /// The level is the one whose namespace contains the class of the first root
    /// object that belongs to an LLFSM metamodel.
    ///
    /// - Parameter resource: The resource.
    /// - Returns: The level, or `nil` if no root object belongs to an LLFSM metamodel.
    public func level(of resource: Resource) async -> LLFSMLevel? {
        let packages = [structural.package, metamodels.sectioned.package, metamodels.kernel.package]
        for root in await resource.getRootObjects() {
            guard let eClass = root.eClass as? EClass else { continue }
            for package in packages where package.getEClass(eClass.name)?.id == eClass.id {
                if let level = LLFSMLevel(namespaceURI: package.nsURI) { return level }
            }
        }
        return nil
    }

    /// Register every LLFSM metamodel with a resource set.
    ///
    /// - Parameter resourceSet: The resource set.
    func register(in resourceSet: ResourceSet) async {
        await structural.register(in: resourceSet)
        await metamodels.register(in: resourceSet)
    }

    /// Decode a structural resource into a machine or an arrangement.
    ///
    /// - Parameters:
    ///   - resource: The resource that holds the structural model.
    ///   - preferArrangement: Whether an arrangement is preferred to a machine.
    /// - Returns: The machine or arrangement.
    /// - Throws: ``FSMPipelineError/noStructuralRoot`` if the resource holds neither.
    func decodeStructural(_ resource: Resource, preferArrangement: Bool) async throws -> Model.Content {
        let machineCodec = MachineEcoreCodec(metamodel: structural)
        let arrangementCodec = ArrangementEcoreCodec(metamodel: structural)
        let arrangementName = Self.stem(ofURI: resource.uri, fallback: Self.fallbackArrangementName)
        if preferArrangement, let object = await findObject(named: structural.arrangementClass.name, in: resource) {
            return .arrangement(name: arrangementName, try await arrangementCodec.decode(object, from: resource))
        }
        if let object = await findObject(named: structural.machineClass.name, in: resource) {
            let decoded = try await machineCodec.decode(object, from: resource)
            return .machine(name: decoded.name, decoded.machine)
        }
        if let object = await findObject(named: structural.arrangementClass.name, in: resource) {
            return .arrangement(name: arrangementName, try await arrangementCodec.decode(object, from: resource))
        }
        throw FSMPipelineError.noStructuralRoot
    }

    /// Find the first object of a class, among the roots first.
    ///
    /// - Parameters:
    ///   - className: The name of the class.
    ///   - resource: The resource to search.
    /// - Returns: The object, or `nil` if there is none.
    private func findObject(named className: String, in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let root = roots.first(where: { $0.eClass.name == className }) { return root }
        return await resource.getAllObjects().compactMap { $0 as? DynamicEObject }.first { $0.eClass.name == className }
    }

    /// The machine of a structural model.
    ///
    /// - Parameter model: The structural model.
    /// - Returns: The machine with its name, or the first machine of an arrangement.
    /// - Throws: ``FSMPipelineError/levelMismatch(expected:found:)`` if the model is
    ///   not structural, and ``FSMPipelineError/noStructuralRoot`` if it holds no machine.
    public func machine(of model: Model) async throws -> (name: String, machine: Machine) {
        switch model.content {
        case .machine(let name, let machine):
            return (name, machine)
        case .arrangement:
            let (resource, _) = await encodeStructural(model, uri: Self.memoryScheme + "structural.xmi")
            guard case .machine(let name, let machine) = try await decodeStructural(resource, preferArrangement: false) else {
                throw FSMPipelineError.noStructuralRoot
            }
            return (name, machine)
        case .resource:
            throw FSMPipelineError.levelMismatch(expected: .structural, found: model.level)
        }
    }

    // MARK: - Transforming

    /// Transform a model to another level.
    ///
    /// - Parameters:
    ///   - model: The model, at the source level of the transformation.
    ///   - transformation: The transformation to run.
    ///   - report: Receives the warnings of the transformation.
    /// - Returns: The model at the target level.
    /// - Throws: ``FSMPipelineError/levelMismatch(expected:found:)`` if the model is
    ///   not at the source level, and the errors of the transformation.
    func transform(_ model: Model, with transformation: LevelTransformation, report: inout Report) async throws -> Model {
        guard model.level == transformation.source else {
            throw FSMPipelineError.levelMismatch(expected: transformation.source, found: model.level)
        }
        progress(GenerationProgressUpdate(
            message: "Transforming from \(transformation.source.rawValue) to \(transformation.target.rawValue)"))
        let result: TransformationResult
        switch transformation {
        case .structuralToSectioned:
            let (resource, name) = await encodeStructural(model, uri: Self.memoryScheme + "structural.xmi")
            result = try await transformations.structuralToSectioned(resource, arrangementName: name)
        case .sectionedToKernel:
            result = try await transformations.sectionedToKernel(try resource(of: model), options: options.semantics)
        case .kernelToSectioned:
            result = try await transformations.kernelToSectioned(try resource(of: model))
        case .sectionedToStructural, .kernelToStructural:
            result = try await writeNativeFromSectioned(try resource(of: model), level: model.level)
        }
        report.warn(result.diagnostics.warnings.map(\.message))
        guard transformation.target == .structural else {
            return Model(level: transformation.target, content: .resource(result.resource))
        }
        return Model(level: .structural, content: try await decodeStructural(result.resource, preferArrangement: true))
    }

    /// Transform a sectioned or kernel model to the structural level, from which native formats are written.
    ///
    /// This is the single place where sectioned and kernel models reach the
    /// structural level.
    ///
    /// - Parameters:
    ///   - resource: The resource that holds the sectioned or kernel model.
    ///   - level: The level of the model.
    /// - Returns: The structural model and the warnings of the transformation.
    /// - Throws: ``FSMPipelineError/transformationUnavailable(from:to:)`` while the
    ///   transformation to the structural level is not available.
    func writeNativeFromSectioned(_ resource: Resource, level: LLFSMLevel) async throws -> TransformationResult {
        level == .kernel
            ? try await transformations.kernelToStructural(resource)
            : try await transformations.sectionedToStructural(resource)
    }

    /// The resource of a sectioned or kernel model.
    ///
    /// - Parameter model: The model.
    /// - Returns: Its resource.
    /// - Throws: ``FSMPipelineError/levelMismatch(expected:found:)`` if the model is structural.
    func resource(of model: Model) throws -> Resource {
        guard case .resource(let resource) = model.content else {
            throw FSMPipelineError.levelMismatch(expected: .sectioned, found: model.level)
        }
        return resource
    }

    /// Encode a structural model into a new resource.
    ///
    /// - Parameters:
    ///   - model: The structural model.
    ///   - uri: The URI of the new resource.
    ///   - machineName: The name to give a machine, or `nil` for its own name.
    /// - Returns: The resource and the name of the machine or arrangement.
    func encodeStructural(_ model: Model, uri: String, machineName: String? = nil) async -> (Resource, String) {
        let resourceSet = ResourceSet()
        await structural.register(in: resourceSet)
        let resource = await resourceSet.createResource(uri: uri)
        switch model.content {
        case .machine(let name, let machine):
            let name = machineName ?? name
            _ = await MachineEcoreCodec(metamodel: structural).encode(machine, name: name, into: resource)
            return (resource, name)
        case .arrangement(let name, let arrangement):
            _ = await ArrangementEcoreCodec(metamodel: structural).encode(arrangement, into: resource)
            return (resource, name)
        case .resource(let existing):
            return (existing, Self.fallbackArrangementName)
        }
    }

    // MARK: - Writing

    /// Generate a kernel target into a directory.
    ///
    /// - Parameters:
    ///   - target: The kernel target.
    ///   - model: The kernel model.
    ///   - directory: The directory that receives the files.
    ///   - report: Receives the written files.
    /// - Throws: The errors of ``KernelTemplateGenerator`` and of the file system.
    func generate(_ target: KernelTarget, from model: Model, into directory: URL, report: inout Report) async throws {
        progress(GenerationProgressUpdate(message: "Generating \(target.rawValue)"))
        let generator = KernelTemplateGenerator(metamodel: metamodels.kernel, settings: options.templates)
        let files = try await generator.render(target, resource: try resource(of: model))
        for (index, file) in files.enumerated() {
            let url = directory.appendingPathComponent(file.path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.content.write(to: url, atomically: FileWritingSupport.writesAtomically, encoding: .utf8)
            report.files.append(url)
            progress(GenerationProgressUpdate(message: file.path, completed: index + 1, total: files.count))
        }
    }

    /// Save a model as a document.
    ///
    /// A machine is named after the document, as when it is written as structural XMI.
    ///
    /// - Parameters:
    ///   - model: The model.
    ///   - format: The format of the document.
    ///   - url: The location of the document.
    ///   - report: Receives the warnings of writing.
    /// - Throws: The errors of the serialiser and of the file system.
    func save(_ model: Model, format: ModelFormat, to url: URL, report: inout Report) async throws {
        progress(GenerationProgressUpdate(message: "Writing \(url.lastPathComponent)"))
        var diagnostics = ConversionDiagnostics()
        if case .resource(let resource) = model.content {
            try await ModelIO.save(resource, to: url, format: format, xmiOptions: options.xmiOptions, diagnostics: &diagnostics)
        } else {
            let (resource, _) = await encodeStructural(
                model, uri: url.absoluteString, machineName: Self.stem(of: url, fallback: Self.fallbackMachineName))
            let text = try await ModelIO.serialise(
                resource, format: format, xmiOptions: options.xmiOptions, diagnostics: &diagnostics)
            try text.write(to: url, atomically: FileWritingSupport.writesAtomically, encoding: .utf8)
        }
        report.warn(diagnostics.warnings.map(\.message))
        progress(GenerationProgressUpdate(message: url.lastPathComponent, completed: 1, total: 1))
    }

    /// Write a structural model in a native format.
    ///
    /// - Parameters:
    ///   - model: The structural model.
    ///   - format: The native format, or `nil` for the format of the model's own language.
    ///   - url: The file or bundle to write.
    /// - Throws: ``FSMPipelineError/noOutputLanguage(_:)`` if the format has no
    ///   language binding, and the errors of the writers.
    func writeNative(_ model: Model, format: Format?, to url: URL) async throws {
        progress(GenerationProgressUpdate(message: "Writing \(url.lastPathComponent)"))
        switch model.content {
        case .machine(_, let machine):
            guard let language = outputLanguage(for: format, default: machine.language) else {
                throw FSMPipelineError.noOutputLanguage(format?.rawValue ?? "")
            }
            let storage = MachineStorageFactory.create(for: machine, format: format, at: url)
            storage.machine.language = language
            storage.isSuspensible = options.isSuspensible
            try await write(storage, to: url, convertedFrom: machine)
        case .arrangement(_, let arrangement):
            let defaultLanguage = arrangement.namedInstances.first?.machine.language ?? ObjCPPBinding()
            guard let language = outputLanguage(for: format, default: defaultLanguage) else {
                throw FSMPipelineError.noOutputLanguage(format?.rawValue ?? "")
            }
            var wrappers: [String: FileWrapper] = [:]
            for instance in arrangement.namedInstances {
                let machineName = instance.typeFile.hasSuffix(MachineDirectoryWrapper.dottedSuffix)
                    ? instance.typeFile
                    : instance.name + MachineDirectoryWrapper.dottedSuffix
                let wrapper = MachineDirectoryWrapper(machine: instance.machine, named: machineName)
                wrapper.language = language
                wrapper.isSuspensible = options.isSuspensible
                wrappers[machineName] = wrapper
            }
            let wrapper = ArrangementWrapper(
                directoryWithFileWrappers: wrappers, for: arrangement, named: url.lastPathComponent, language: language)
            try await write(wrapper, to: url)
        case .resource:
            throw FSMPipelineError.levelMismatch(expected: .structural, found: model.level)
        }
        progress(GenerationProgressUpdate(message: url.lastPathComponent, completed: 1, total: 1))
    }

    /// Write machine storage with the native generator of the options.
    ///
    /// With ``NativeGenerator/templates``, the files come from the structural
    /// templates of the storage's language, if a template set writes it, and
    /// otherwise from the Swift language binding of the storage. A single-file
    /// format records the language of the machine it was converted from, so the
    /// templates render the original machine where one is given.
    ///
    /// - Parameters:
    ///   - storage: The storage, with the language and suspensibility to write.
    ///   - url: The file or bundle to write.
    ///   - original: The machine that the storage was converted from, if any.
    /// - Throws: The errors of the templates and of the writers.
    public func write(_ storage: any MachineStorage, to url: URL, convertedFrom original: Machine? = nil) async throws {
        guard let format = templateFormat(of: storage.language, arrangements: false) else {
            try storage.write(to: url)
            return
        }
        let machine = format.isSingleFile ? original ?? storage.machine : storage.machine
        let binding = try await TemplateBinding.make(
            for: machine,
            named: storage.name,
            format: format,
            isSuspensible: storage.isSuspensible,
            settings: options.templates
        )
        if let directory = storage as? MachineDirectoryWrapper {
            directory.language = binding
            try directory.write(to: url)
        } else {
            let templateStorage = try binding.createWrapper(at: url, for: machine)
            templateStorage.isSuspensible = storage.isSuspensible
            try templateStorage.write(to: url)
        }
    }

    /// Write an arrangement bundle with the native generator of the options.
    ///
    /// With ``NativeGenerator/templates``, the files come from the structural
    /// templates of the bundle's language, if a template set writes its
    /// arrangements, and otherwise from the Swift language binding of the bundle.
    ///
    /// - Parameters:
    ///   - wrapper: The arrangement bundle, with the language and suspensibility to write.
    ///   - url: The bundle to write.
    /// - Throws: The errors of the templates and of the writers.
    public func write(_ wrapper: ArrangementWrapper, to url: URL) async throws {
        if let format = templateFormat(of: wrapper.language, arrangements: true) {
            wrapper.language = try await TemplateBinding.make(
                for: wrapper.arrangement,
                named: Self.stem(of: url, fallback: Self.fallbackArrangementName),
                format: format,
                isSuspensible: wrapper.isSuspensible,
                settings: options.templates
            )
        }
        try wrapper.write(to: url)
    }

    /// The format in which the templates write a language, if they are to write it.
    ///
    /// - Parameters:
    ///   - language: The language binding that would write the files.
    ///   - arrangements: Whether arrangements are written.
    /// - Returns: The format, or `nil` if the Swift binding writes the files.
    private func templateFormat(of language: any LanguageBinding, arrangements: Bool) -> Format? {
        guard options.generator == .templates, language is any OutputLanguage,
              let format = Format(rawValue: language.name),
              TemplateBinding.supports(format, arrangements: arrangements)
        else { return nil }
        return format
    }

}

/// The content of a model, under its original name.
extension FSMPipeline.Model {
    /// What a model holds.
    public typealias Content = FSMPipeline.ModelContent
}

/// The naming conventions for the files that a pipeline reads and writes.
extension FSMPipeline {
    // MARK: - Names

    /// Whether a file is an XMI or JSON model document, judged by its extension.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: `true` for the extensions of ``ECore/ModelFormat/xmi`` and ``ECore/ModelFormat/json``.
    nonisolated public static func isModelDocument(_ url: URL) -> Bool {
        let format = ModelFormat.detect(url: url)
        return format == .xmi || format == .json
    }

    /// The instance and machine bundle names of an input file in an arrangement.
    ///
    /// - Parameter fileName: The file name of the input, such as `Counter.machine` or `Light.scxml`.
    /// - Returns: The name of the instance and the file name of its machine bundle.
    nonisolated public static func instanceNames(forFileNamed fileName: String) -> (instance: String, machine: String) {
        let suffix = MachineDirectoryWrapper.dottedSuffix
        if fileName.hasSuffix(suffix) { return (String(fileName.dropLast(suffix.count)), fileName) }
        let instance = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        return (instance, instance + suffix)
    }

    /// The name of a machine read from a file: the file name without its `.machine` suffix or extension.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: The name, or `Machine` if the file name has no stem.
    nonisolated public static func fileStem(of url: URL) -> String {
        let suffix = MachineDirectoryWrapper.dottedSuffix
        if url.lastPathComponent.hasSuffix(suffix) { return String(url.lastPathComponent.dropLast(suffix.count)) }
        return stem(of: url, fallback: fallbackMachineName)
    }

    /// The file name of a location without its extension.
    ///
    /// - Parameters:
    ///   - url: The location.
    ///   - fallback: The name to use if the stem is empty.
    /// - Returns: The stem, or the fallback.
    nonisolated public static func stem(of url: URL, fallback: String) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        return stem.isEmpty ? fallback : stem
    }

    /// The stem of the last path component of a URI.
    ///
    /// - Parameters:
    ///   - uri: The URI.
    ///   - fallback: The name to use if the stem is empty.
    /// - Returns: The stem, or the fallback.
    nonisolated static func stem(ofURI uri: String, fallback: String) -> String {
        guard let last = uri.split(separator: "/").last else { return fallback }
        return stem(of: URL(fileURLWithPath: String(last)), fallback: fallback)
    }
}
