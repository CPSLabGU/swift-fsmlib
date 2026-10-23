import ArgumentParser
import ECore
import Foundation
import FSM
import FSMEcore
import ModellingCommandLine
import ModellingGenerators

extension FSMConvert {
    // MARK: - Native Conversion

    /// Convert native machines without metamodels.
    ///
    /// The machines are read with the Swift readers and written in the requested
    /// native format through the generator that `--generator` selects.
    ///
    /// - Throws: An error if an input cannot be read or the output cannot be written.
    @MainActor
    func runNative() async throws {
        let fileManager = FileManager.default
        // Read machines using the new factory
        let storageInstances = try inputMachines.map {
            let path: String
            if fileManager.fileExists(atPath: $0) {
                path = $0
            } else {
                path = $0 + MachineDirectoryWrapper.dottedSuffix
                guard fileManager.fileExists(atPath: path) else {
                    throw ValidationError("File '\($0)' does not exist")
                }
            }
            let machineURL = URL(fileURLWithPath: path)
            let storage = try MachineStorageFactory.read(from: machineURL)
            return (machineURL.lastPathComponent, storage)
        }

        let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
        guard let outputLanguage = outputLanguage(for: outputFormat, default: storageInstances.first?.1.machine.language) else {
            FSMConvert.exit(withError: ValidationError("No output language for format '\(format)'\n"))
        }
        let outputURL = URL(fileURLWithPath: output)

        if verbose {
            let totalStates = storageInstances.reduce(0) { $0 + $1.1.machine.llfsm.states.count }
            let totalTransitions = storageInstances.reduce(0) { $0 + $1.1.machine.llfsm.transitions.count }
            print("\(storageInstances.count) FSMs with \(totalStates) states and \(totalTransitions) transitions\n")
        }

        let bar = progressBar
        defer { bar?.finish() }
        let pipeline = try await FSMPipeline(options: pipelineOptions, progress: bar?.reporter ?? Self.silentReporter)
        bar?.show(GenerationProgressUpdate(message: "Writing \(outputURL.lastPathComponent)", total: 1))
        if arrangement || storageInstances.count > 1 {
            // For arrangements, create directory wrappers (arrangements are always directory-based)
            // We need to convert machines to directory wrappers with the output language
            var instances: [Instance] = []
            var wrapperMappings: [String: FileWrapper] = [:]

            for item in storageInstances {
                let machine = item.1.machine
                let (instanceName, machineName) = FSMPipeline.instanceNames(forFileNamed: item.0)
                // Create a directory wrapper with the output language
                let dirWrapper = MachineDirectoryWrapper(machine: machine, named: machineName)
                dirWrapper.language = outputLanguage
                dirWrapper.isSuspensible = !nonSuspensible
                wrapperMappings[machineName] = dirWrapper
                instances.append(Instance(name: instanceName, typeFile: machineName, machine: machine))
            }

            let machineArrangement = Arrangement(namedInstances: instances)
            let arrangementWrapper = ArrangementWrapper(
                directoryWithFileWrappers: wrapperMappings,
                for: machineArrangement,
                named: outputURL.lastPathComponent,
                language: outputLanguage
            )
            try await pipeline.write(arrangementWrapper, to: outputURL)
        } else if let firstStorage = storageInstances.first {
            // Single machine: use factory to create appropriate storage format
            let storage = MachineStorageFactory.create(
                for: firstStorage.1.machine,
                format: outputFormat,
                at: outputURL
            )
            try await pipeline.write(storage, to: outputURL, convertedFrom: firstStorage.1.machine)
        }
        bar?.show(GenerationProgressUpdate(message: outputURL.lastPathComponent, completed: 1, total: 1))
    }

    // MARK: - Metamodel Conversion

    /// Convert the inputs through the metamodels.
    ///
    /// The inputs are read at their own level, transformed to the level that the
    /// output target needs, and written.
    ///
    /// - Throws: `ValidationError` for an input that does not exist or a format
    ///   without a language binding, and the errors of the pipeline.
    @MainActor
    func runPipeline() async throws {
        let outputURL = URL(fileURLWithPath: output)
        let bar = progressBar
        defer { bar?.finish() }
        let pipeline = try await FSMPipeline(options: pipelineOptions, progress: bar?.reporter ?? Self.silentReporter)
        let report: FSMPipeline.Report
        do {
            report = try await pipeline.convert(try inputURLs(), to: outputTarget(for: outputURL), output: outputURL)
        } catch let error as FSMPipelineError {
            bar?.finish()
            throw Self.commandLineError(for: error)
        }
        bar?.finish()
        printWarnings(report.warnings)
    }

    /// Validate the inputs at the kernel level and print the diagnostics.
    ///
    /// - Throws: `ExitCode.failure` if a diagnostic is an error, and the errors of the pipeline.
    @MainActor
    func runValidation() async throws {
        let bar = progressBar
        defer { bar?.finish() }
        let pipeline = try await FSMPipeline(options: pipelineOptions, progress: bar?.reporter ?? Self.silentReporter)
        let result: FSMPipeline.Report
        do {
            result = try await pipeline.validate(try inputURLs())
        } catch let error as FSMPipelineError {
            bar?.finish()
            throw Self.commandLineError(for: error)
        }
        bar?.finish()
        printWarnings(result.warnings)
        let lines = result.diagnostics.map(Self.line(for:))
        if !lines.isEmpty {
            FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
        }
        if result.hasErrors { throw ExitCode.failure }
    }

    /// Apply one of the bundled structural MTL templates.
    ///
    /// - Throws: An error if the template is unknown or generation fails.
    @MainActor
    func runStructuralTemplate() async throws {
        guard let transform else { return }
        let outputURL = URL(fileURLWithPath: output)
        var options = pipelineOptions
        options.level = .structural
        let pipeline = try await FSMPipeline(options: options, progress: progressBar?.reporter ?? Self.silentReporter)
        var report = FSMPipeline.Report()
        let model: FSMPipeline.Model
        do {
            model = try await pipeline.load(
                try inputURLs(), arrangementName: FSMPipeline.stem(of: outputURL, fallback: "Arrangement"),
                report: &report)
        } catch let error as FSMPipelineError {
            throw Self.commandLineError(for: error)
        }
        guard let (name, machine) = try? await pipeline.machine(of: model) else {
            throw ValidationError("Structural templates require a single machine")
        }

        let templateName = URL(fileURLWithPath: transform).deletingPathExtension().lastPathComponent
        let generator = StructuralTemplateGenerator()

        switch templateName {
        case "structural2machine":
            let targetName = outputURL.pathExtension.lowercased() == "machine"
                ? outputURL.deletingPathExtension().lastPathComponent
                : name
            let baseURL = outputURL.pathExtension.lowercased() == "machine"
                ? outputURL.deletingLastPathComponent()
                : outputURL
            try await generator.generateMachineBundle(for: machine, named: targetName, to: baseURL)

        case "structural2scxml":
            let fileURL = outputURL.pathExtension.lowercased() == "scxml"
                ? outputURL
                : outputURL.appendingPathComponent(name).appendingPathExtension("scxml")
            try await generator.generateSCXML(for: machine, named: name, to: fileURL)

        case "structural2cmake":
            let fileURL = outputURL.lastPathComponent == "CMakeLists.txt"
                ? outputURL
                : outputURL.appendingPathComponent("CMakeLists.txt")
            try await generator.generateCMakeLists(for: machine, named: name, to: fileURL)

        case "structural2layout":
            let directoryURL = outputURL.pathExtension.isEmpty ? outputURL : outputURL.deletingLastPathComponent()
            try await generator.generateLayoutFiles(for: machine, named: name, to: directoryURL)

        default:
            throw ValidationError(
                "Unsupported structural template '\(templateName)'. Use one of structural2machine, structural2scxml, structural2cmake, or structural2layout."
            )
        }
        printWarnings(report.warnings)
    }

    // MARK: - Options

    /// The options of the pipeline, as given on the command line.
    var pipelineOptions: FSMPipeline.Options {
        FSMPipeline.Options(
            generator: generator,
            level: metamodel,
            profile: profile,
            semantics: (try? semanticOptions()) ?? SectionedToKernelOptions(),
            templates: TemplateSettings(
                searchPaths: templatePaths.urls,
                parameters: (try? parameterTexts()) ?? [:],
                unsetFeatureReads: unsetFeatures.unsetFeatures),
            xmiOptions: referenceStyle.serializationOptions,
            isSuspensible: !nonSuspensible,
            makesArrangement: arrangement)
    }

    /// The semantic options of the encoding into the kernel.
    ///
    /// - Returns: The options, with the defaults for those not given.
    /// - Throws: `ValidationError` if a value of `--semantics` is not valid.
    func semanticOptions() throws -> SectionedToKernelOptions {
        do {
            var options = SectionedToKernelOptions()
            for (name, value) in try SemanticsOption.family.values(from: semantics) {
                guard let key = SectionedToKernelOptions.Key(rawValue: name) else { continue }
                try options.set(key, to: value)
            }
            return options
        } catch {
            throw ValidationError(String(describing: error))
        }
    }

    /// The template parameters as text, including those of the kernel options.
    ///
    /// The options `--entry`, `--max-rounds`, `--sanity` and `--opaque` take
    /// precedence over `--param` pairs of the same names.
    ///
    /// - Returns: The parameters by name.
    /// - Throws: `ValidationError` if a `--param` value is not valid.
    func parameterTexts() throws -> [String: String] {
        var parameters: [String: String]
        do {
            _ = try templateParameters.values
            parameters = try KeyValueOption<String>(noun: TemplateParameterOptions.optionName)
                .values(from: templateParameters.arguments)
        } catch {
            throw ValidationError(String(describing: error))
        }
        if let entry { parameters[KernelTemplateParameter.entry] = entry.rawValue }
        if let maxRounds { parameters[KernelTemplateParameter.maxRounds] = String(maxRounds) }
        if sanity { parameters[KernelTemplateParameter.sanity] = SectionedToKernelOptions.trueText }
        if let opaque { parameters[KernelTemplateParameter.opaque] = opaque.rawValue }
        return parameters
    }

    /// The output target, from `--format` or else from the extension of the output.
    ///
    /// - Parameter outputURL: The output location.
    /// - Returns: The target, or `nil` for the native format of the model's own language.
    func outputTarget(for outputURL: URL) -> OutputTarget? {
        if !format.isEmpty { return OutputTarget.named(format, level: metamodel) }
        guard FSMPipeline.isModelDocument(outputURL) else { return nil }
        return OutputTarget(rawValue: outputURL.pathExtension.lowercased())
    }

    /// The locations of the inputs.
    ///
    /// - Returns: The locations, with `.machine` added where a path does not exist.
    /// - Throws: `ValidationError` if an input does not exist.
    func inputURLs() throws -> [URL] {
        do {
            return try inputMachines.map(FSMPipeline.resolveInput)
        } catch let error as FSMPipelineError {
            throw Self.commandLineError(for: error)
        }
    }

    /// The receiver of progress reports that shows nothing.
    static let silentReporter: GenerationProgressReporter = { _ in }

    /// The progress bar, unless `--quiet` is given.
    ///
    /// The bar is drawn only when standard error is a terminal.
    var progressBar: GenerationProgressBar? {
        quiet ? nil : GenerationProgressBar(verbose: false)
    }

    // MARK: - Reporting

    /// Print warnings to standard error, unless `--quiet` is given.
    ///
    /// - Parameter warnings: The messages of the warnings.
    func printWarnings(_ warnings: [String]) {
        guard !quiet, !warnings.isEmpty else { return }
        let lines = warnings.map { ConversionWarningReport.warningPrefix + $0 }
        FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }

    /// The line that reports a validation diagnostic.
    ///
    /// - Parameter diagnostic: The diagnostic.
    /// - Returns: The severity, rule code, path and message.
    static func line(for diagnostic: KernelDiagnostic) -> String {
        "\(diagnostic.severity.rawValue): \(diagnostic.code) \(diagnostic.path): \(diagnostic.message)"
    }

    /// The command-line error for a problem of the pipeline.
    ///
    /// Problems with the inputs and formats given on the command line are usage errors.
    ///
    /// - Parameter error: The problem.
    /// - Returns: The error to report.
    static func commandLineError(for error: FSMPipelineError) -> any Error {
        switch error {
        case .missingInput, .noOutputLanguage, .noInput:
            return ValidationError(error.description)
        default:
            return error
        }
    }
}
