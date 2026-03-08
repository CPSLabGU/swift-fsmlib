import ArgumentParser
import ECore
import Foundation
import FSM
import FSMEcore

/// Command-line tool for converting FSMs and arrangements.
///
/// This struct implements the main entry point for the `fsmconvert` tool, which
/// reads FSM machine files or arrangements, optionally combines them, and writes
/// the output in the specified format. It supports options for arrangement,
/// output format, introspection, verbosity, and more.
///
/// - Note: Designed for use in automated build systems and scripting.
@main
struct FSMConvert: AsyncParsableCommand {
    /// Whether to create an arrangement of a single FSM.
    ///
    /// This option enables the creation of an arrangement of a single FSM.
    @Flag(name: .shortAndLong, help: "Create an arrangement of a single FSM.")
    var arrangement = false

    /// The output machine format.
    ///
    /// This option specifies the output machine format. It can be an empty string
    /// to use the default format, or a valid format name.
    @Option(name: .shortAndLong, help: "The output machine format.", transform: {
        if $0.isEmpty { return $0 }
        if $0.lowercased() == "xmi" { return "xmi" }
        guard let format = Format(rawValue: $0.lowercased()) else {
            throw ValidationError("Unknown format '\($0)'")
        }
        return format.rawValue
    })
    var format = ""

    /// Make the generated code introspectable.
    ///
    /// This option enables introspection, which allows the generated code to
    /// provide additional information about the machine.
    @Flag(name: .shortAndLong, help: "Make the generated code introspectable.")
    var introspectable = false

    /// Make the generated machine non-suspensible.
    ///
    /// This option disables suspensibility, which means the generated machine
    /// cannot be suspended.
    @Flag(name: .shortAndLong, help: "Make the generated machine non-suspensible.")
    var nonSuspensible = false

    /// The output machine/arrangement.
    ///
    /// This option specifies the output machine/arrangement. It can be a file
    /// or a directory.
    @Option(name: .shortAndLong, help: "The output machine/arrangement.")
    var output = "fsm.out"

    /// Turn on verbose output.
    ///
    /// This option enables verbose output, which provides additional information
    /// about the conversion process.
    @Flag(name: .shortAndLong, help: "Turn on verbose output.")
    var verbose = false

    /// Turn on debug output.
    ///
    /// This option enables debug output, which provides detailed debugging
    /// information about the conversion process.
    @Flag(name: .long, help: "Turn on debug output.")
    var debug = false

    /// Use metamodel-backed XMI conversion paths.
    ///
    /// This option selects the model level used for metamodel-backed import,
    /// export, ATL, and MTL operations.
    @Option(name: .long, help: "Use metamodel-backed conversion at the selected model level.")
    var metamodel: MetamodelLevel?

    /// The MTL template to apply after metamodel loading.
    ///
    /// This option is reserved for template-driven generation from metamodel
    /// models. Current support is limited to the built-in structural pipeline.
    @Option(name: .long, help: "Apply an MTL template after metamodel loading.")
    var transform: String?

    /// The ATL transformation to apply after metamodel loading.
    ///
    /// This option is reserved for metamodel-to-metamodel transformations.
    @Option(name: .long, help: "Apply an ATL transformation after metamodel loading.")
    var atl: String?

    /// Additional search paths for ATL `@path` metamodel resolution.
    @Option(name: .long, help: "Metamodel search path for ATL `@path` resolution.")
    var metamodelPath: [String] = []

    /// The input machines to read.
    ///
    /// This argument specifies the input machines to read. It can be a directory
    /// containing machine files or arrangements, or a list of machine files.
    @Argument(help: "The input machines to read.", completion: .directory)
    var inputMachines: [String]

    /// Run the command.
    ///
    /// This method implements the main logic of the `fsmconvert` tool, reading
    /// input machines, creating an arrangement if specified, and writing the
    /// output in the specified format.
    ///
    /// - Note: Designed for use in automated build systems and scripting.
    mutating func run() async throws {
        if let metamodel {
            try await runWithMetamodel(level: metamodel)
            return
        }

        if transform != nil || atl != nil || !metamodelPath.isEmpty {
            throw ValidationError(
                "`--transform`, `--atl`, and `--metamodel-path` require `--metamodel structural|executable`"
            )
        }

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

        if arrangement || storageInstances.count > 1 {
            // For arrangements, create directory wrappers (arrangements are always directory-based)
            // We need to convert machines to directory wrappers with the output language
            var instances: [Instance] = []
            var wrapperMappings: [String: FileWrapper] = [:]

            for item in storageInstances {
                let machine = item.1.machine
                // For directory-based machines, use the name as-is
                // For single-file machines (like SCXML), strip extension and add .machine
                let machineName: String
                let instanceName: String
                if item.0.hasSuffix(MachineDirectoryWrapper.dottedSuffix) {
                    machineName = item.0
                    // Instance name without .machine suffix
                    instanceName = String(item.0.dropLast(MachineDirectoryWrapper.dottedSuffix.count))
                } else {
                    // Strip any extension for instance name
                    instanceName = URL(fileURLWithPath: item.0).deletingPathExtension().lastPathComponent
                    machineName = instanceName + MachineDirectoryWrapper.dottedSuffix
                }
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
            try arrangementWrapper.write(to: outputURL)
        } else if let firstStorage = storageInstances.first {
            // Single machine: use factory to create appropriate storage format
            let storage = MachineStorageFactory.create(
                for: firstStorage.1.machine,
                format: outputFormat,
                at: outputURL
            )
            try storage.write(to: outputURL)
        }
    }

    /// Run the command through the metamodel-backed XMI pipeline.
    ///
    /// This path uses `FSMEcore` for structural and executable model handling
    /// while preserving the existing Swift readers and writers as the native
    /// format boundary.
    @MainActor
    private mutating func runWithMetamodel(level: MetamodelLevel) async throws {
        let outputURL = URL(fileURLWithPath: output)
        let xmiRequested = format.lowercased() == "xmi" || outputURL.pathExtension.lowercased() == "xmi"

        if transform != nil || atl != nil {
            try await runMetamodelPipeline(level: level, outputURL: outputURL, xmiRequested: xmiRequested)
            return
        }

        let input = try await loadMetamodelInput(level: level)
        if xmiRequested {
            try await writeXMI(input, level: level, to: outputURL)
            return
        }

        try writeNative(input, outputURL: outputURL)
    }

    @MainActor
    private mutating func runMetamodelPipeline(
        level: MetamodelLevel,
        outputURL: URL,
        xmiRequested: Bool
    ) async throws {
        var currentLevel = level
        var currentResource = try await loadMetamodelResource(
            level: level,
            arrangementName: defaultArrangementName(for: outputURL)
        )

        if let atl {
            let transformer = LLFSMATLTransformer()
            let atlURL = try resolveATLURL(atl, using: transformer)
            currentResource = try await transformer.transform(
                atlURL: atlURL,
                sourceResource: currentResource,
                searchPaths: metamodelPath
            )
            currentLevel = await inferredMetamodelLevel(
                afterApplying: atlURL,
                to: currentResource,
                default: level
            )
        }

        if let transform {
            try await applyTemplate(
                named: transform,
                level: currentLevel,
                resource: currentResource,
                outputURL: outputURL
            )
            return
        }

        if xmiRequested {
            try await writeResource(currentResource, level: currentLevel, to: outputURL)
            return
        }

        let input = try await decodeMetamodelResource(
            currentResource,
            level: currentLevel,
            preferArrangement: arrangement || inputMachines.count > 1
        )
        try writeNative(input, outputURL: outputURL)
    }

    private func loadMetamodelInput(level: MetamodelLevel) async throws -> MetamodelInput {
        if arrangement || inputMachines.count > 1 {
            return .arrangement(try await loadArrangement(level: level))
        }

        guard inputMachines.count == 1 else {
            throw ValidationError("Metamodel conversion requires exactly one input machine")
        }

        let inputURL = try resolvedInputURL(inputMachines[0])
        if inputURL.pathExtension.lowercased() == "xmi" {
            return try await loadSingleXMIInput(level: level, from: inputURL)
        }

        let storage = try MachineStorageFactory.read(from: inputURL)
        return .machine(name: fileStem(for: inputURL), storage.machine)
    }

    /// Load an arrangement either from XMI or by composing machine inputs.
    private func loadArrangement(level: MetamodelLevel) async throws -> Arrangement {
        if inputMachines.count == 1 {
            let inputURL = try resolvedInputURL(inputMachines[0])
            if inputURL.pathExtension.lowercased() == "xmi" {
                switch level {
                case .structural:
                    let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
                    return try await roundTrip.readArrangement(from: inputURL)
                case .executable:
                    let roundTrip = ExecutableXMIRoundTrip(metamodel: try await ExecutableLLFSMMetamodel())
                    return try await roundTrip.readArrangement(from: inputURL)
                }
            }
        }

        let storages = try inputMachines.map { path -> (String, MachineStorage) in
            let url = try resolvedInputURL(path)
            return (url.lastPathComponent, try MachineStorageFactory.read(from: url))
        }

        let instances = storages.map { item -> Instance in
            let instanceName: String
            let machineName: String
            if item.0.hasSuffix(MachineDirectoryWrapper.dottedSuffix) {
                machineName = item.0
                instanceName = String(item.0.dropLast(MachineDirectoryWrapper.dottedSuffix.count))
            } else {
                instanceName = URL(fileURLWithPath: item.0).deletingPathExtension().lastPathComponent
                machineName = instanceName + MachineDirectoryWrapper.dottedSuffix
            }
            return Instance(name: instanceName, typeFile: machineName, machine: item.1.machine)
        }
        return Arrangement(namedInstances: instances)
    }

    /// Attempt to load a single XMI input as either a machine or an arrangement.
    private func loadSingleXMIInput(level: MetamodelLevel, from inputURL: URL) async throws -> MetamodelInput {
        switch level {
        case .structural:
            let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
            do {
                let decoded = try await roundTrip.readMachine(from: inputURL)
                return .machine(name: decoded.name, decoded.machine)
            } catch {
                return .arrangement(try await roundTrip.readArrangement(from: inputURL))
            }
        case .executable:
            let roundTrip = ExecutableXMIRoundTrip(metamodel: try await ExecutableLLFSMMetamodel())
            do {
                let decoded = try await roundTrip.readMachine(from: inputURL)
                return .machine(name: decoded.name, decoded.machine)
            } catch {
                return .arrangement(try await roundTrip.readArrangement(from: inputURL))
            }
        }
    }

    private func loadMetamodelResource(
        level: MetamodelLevel,
        arrangementName: String
    ) async throws -> Resource {
        if arrangement || inputMachines.count > 1 {
            if inputMachines.count == 1 {
                let inputURL = try resolvedInputURL(inputMachines[0])
                if inputURL.pathExtension.lowercased() == "xmi" {
                    return try await loadResourceFromXMI(inputURL, level: level)
                }
            }
            return try await encode(
                arrangement: try await loadArrangement(level: level),
                name: arrangementName,
                level: level
            )
        }

        guard inputMachines.count == 1 else {
            throw ValidationError("Metamodel conversion requires exactly one input machine")
        }

        let inputURL = try resolvedInputURL(inputMachines[0])
        if inputURL.pathExtension.lowercased() == "xmi" {
            if level == .structural, atl != nil {
                return try await encode(
                    input: try await loadSingleXMIInput(level: level, from: inputURL),
                    fallbackName: fileStem(for: inputURL),
                    arrangementName: arrangementName
                )
            }
            return try await loadResourceFromXMI(inputURL, level: level)
        }

        let storage = try MachineStorageFactory.read(from: inputURL)
        return try await encode(machine: storage.machine, name: fileStem(for: inputURL), level: level)
    }

    private func loadResourceFromXMI(_ inputURL: URL, level: MetamodelLevel) async throws -> Resource {
        switch level {
        case .structural:
            let parser = XMIParser()
            return try await parser.parse(inputURL)
        case .executable:
            let roundTrip = ExecutableXMIRoundTrip(metamodel: try await ExecutableLLFSMMetamodel())
            return try await roundTrip.loadResource(from: inputURL)
        }
    }

    private func encode(machine: Machine, name: String, level: MetamodelLevel) async throws -> Resource {
        let resource = Resource(uri: "memory:/\(name).xmi")
        switch level {
        case .structural:
            let codec = MachineEcoreCodec(metamodel: try await LLFSMMetamodel())
            _ = await codec.encode(machine, name: name, into: resource)
        case .executable:
            let codec = ExecutableMachineCodec(metamodel: try await ExecutableLLFSMMetamodel())
            _ = await codec.encode(machine, name: name, arrangementName: name, into: resource)
        }
        return resource
    }

    private func encode(arrangement: Arrangement, name: String, level: MetamodelLevel) async throws -> Resource {
        let resource = Resource(uri: "memory:/\(name).xmi")
        switch level {
        case .structural:
            let codec = ArrangementEcoreCodec(metamodel: try await LLFSMMetamodel())
            _ = await codec.encode(arrangement, into: resource)
        case .executable:
            let codec = ExecutableArrangementCodec(metamodel: try await ExecutableLLFSMMetamodel())
            _ = await codec.encode(arrangement, name: name, into: resource)
        }
        return resource
    }

    private func encode(
        input: MetamodelInput,
        fallbackName: String,
        arrangementName: String,
        level: MetamodelLevel? = nil
    ) async throws -> Resource {
        let resolvedLevel = level ?? metamodel ?? .structural
        switch input {
        case .machine(let name, let machine):
            return try await encode(
                machine: machine,
                name: name.isEmpty ? fallbackName : name,
                level: resolvedLevel
            )
        case .arrangement(let arrangement):
            return try await encode(arrangement: arrangement, name: arrangementName, level: resolvedLevel)
        }
    }

    private func writeXMI(_ input: MetamodelInput, level: MetamodelLevel, to outputURL: URL) async throws {
        switch level {
        case .structural:
            let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
            switch input {
            case .machine(_, let machine):
                try await roundTrip.write(machine: machine, name: machineName(for: outputURL), to: outputURL)
            case .arrangement(let arrangement):
                try await roundTrip.write(arrangement: arrangement, to: outputURL)
            }
        case .executable:
            let roundTrip = ExecutableXMIRoundTrip(metamodel: try await ExecutableLLFSMMetamodel())
            switch input {
            case .machine(_, let machine):
                let name = machineName(for: outputURL)
                try await roundTrip.write(machine: machine, name: name, arrangementName: name, to: outputURL)
            case .arrangement(let arrangement):
                try await roundTrip.write(arrangement: arrangement, name: defaultArrangementName(for: outputURL), to: outputURL)
            }
        }
    }

    private func writeResource(_ resource: Resource, level: MetamodelLevel, to outputURL: URL) async throws {
        switch level {
        case .structural:
            let serialiser = XMISerializer()
            let xmi = try await serialiser.serialize(resource)
            try xmi.write(to: outputURL, atomically: true, encoding: .utf8)
        case .executable:
            let roundTrip = ExecutableXMIRoundTrip(metamodel: try await ExecutableLLFSMMetamodel())
            try await roundTrip.write(resource: resource, to: outputURL)
        }
    }

    private func decodeMetamodelResource(
        _ resource: Resource,
        level: MetamodelLevel,
        preferArrangement: Bool
    ) async throws -> MetamodelInput {
        switch level {
        case .structural:
            let metamodel = try await LLFSMMetamodel()
            let machineCodec = MachineEcoreCodec(metamodel: metamodel)
            let arrangementCodec = ArrangementEcoreCodec(metamodel: metamodel)

            if preferArrangement,
               let arrangementObject = await findObject(named: metamodel.arrangementClass.name, in: resource) {
                return .arrangement(try await arrangementCodec.decode(arrangementObject, from: resource))
            }

            if let machineObject = await findObject(named: metamodel.machineClass.name, in: resource) {
                let decoded = try await machineCodec.decode(machineObject, from: resource)
                return .machine(name: decoded.name, decoded.machine)
            }

            if let arrangementObject = await findObject(named: metamodel.arrangementClass.name, in: resource) {
                return .arrangement(try await arrangementCodec.decode(arrangementObject, from: resource))
            }

            throw ValidationError("Unable to decode structural metamodel resource")

        case .executable:
            let metamodel = try await ExecutableLLFSMMetamodel()
            let machineCodec = ExecutableMachineCodec(metamodel: metamodel)
            let arrangementCodec = ExecutableArrangementCodec(metamodel: metamodel)

            if preferArrangement,
               let arrangementObject = await findObject(named: metamodel.arrangementClass.name, in: resource) {
                return .arrangement(try await arrangementCodec.decode(arrangementObject, from: resource))
            }

            if let root = await findExecutableRoot(in: resource, metamodel: metamodel) {
                let decoded = try await machineCodec.decode(root, from: resource)
                return .machine(name: decoded.name, decoded.machine)
            }

            if let arrangementObject = await findObject(named: metamodel.arrangementClass.name, in: resource) {
                return .arrangement(try await arrangementCodec.decode(arrangementObject, from: resource))
            }

            throw ValidationError("Unable to decode executable metamodel resource")
        }
    }

    @MainActor
    private func applyTemplate(
        named template: String,
        level: MetamodelLevel,
        resource: Resource,
        outputURL: URL
    ) async throws {
        switch level {
        case .structural:
            try await applyStructuralTemplate(named: template, resource: resource, outputURL: outputURL)
        case .executable:
            try await applyExecutableTemplate(named: template, resource: resource, outputURL: outputURL)
        }
    }

    @MainActor
    private func applyStructuralTemplate(
        named template: String,
        resource: Resource,
        outputURL: URL
    ) async throws {
        let decoded = try await decodeMetamodelResource(resource, level: .structural, preferArrangement: false)
        guard case let .machine(name, machine) = decoded else {
            throw ValidationError("Structural templates require a single machine")
        }

        let templateName = URL(fileURLWithPath: template).deletingPathExtension().lastPathComponent
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
    }

    @MainActor
    private func applyExecutableTemplate(
        named template: String,
        resource: Resource,
        outputURL: URL
    ) async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let generator = ExecutableTemplateGenerator(metamodel: metamodel)
        let templateURL = try resolveExecutableTemplateURL(template, using: generator)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        try await generator.generate(templateURL: templateURL, resource: resource, outputDirectory: outputURL)
    }

    private func writeNative(_ input: MetamodelInput, outputURL: URL) throws {
        switch input {
        case .machine(_, let machine):
            let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
            guard let outputLanguage = outputLanguage(for: outputFormat, default: machine.language) else {
                throw ValidationError("No output language for format '\(format)'")
            }
            let storage = MachineStorageFactory.create(for: machine, format: outputFormat, at: outputURL)
            storage.machine.language = outputLanguage
            storage.isSuspensible = !nonSuspensible
            try storage.write(to: outputURL)

        case .arrangement(let arrangement):
            let outputLanguage = try outputLanguageForArrangement(arrangement)
            try writeArrangement(arrangement, outputURL: outputURL, outputLanguage: outputLanguage)
        }
    }

    /// Write an arrangement with the existing Swift wrapper pipeline.
    private func writeArrangement(
        _ arrangement: Arrangement,
        outputURL: URL,
        outputLanguage: any LanguageBinding
    ) throws {
        var wrapperMappings: [String: FileWrapper] = [:]
        for instance in arrangement.namedInstances {
            let machineName = instance.typeFile.hasSuffix(MachineDirectoryWrapper.dottedSuffix)
                ? instance.typeFile
                : instance.name + MachineDirectoryWrapper.dottedSuffix
            let dirWrapper = MachineDirectoryWrapper(machine: instance.machine, named: machineName)
            dirWrapper.language = outputLanguage
            dirWrapper.isSuspensible = !nonSuspensible
            wrapperMappings[machineName] = dirWrapper
        }

        let wrapper = ArrangementWrapper(
            directoryWithFileWrappers: wrapperMappings,
            for: arrangement,
            named: outputURL.lastPathComponent,
            language: outputLanguage
        )
        try wrapper.write(to: outputURL)
    }

    @MainActor
    private func resolveATLURL(_ atl: String, using transformer: LLFSMATLTransformer) throws -> URL {
        if FileManager.default.fileExists(atPath: atl) {
            return URL(fileURLWithPath: atl)
        }
        return try transformer.bundledTransformURL(
            named: URL(fileURLWithPath: atl).deletingPathExtension().lastPathComponent
        )
    }

    @MainActor
    private func resolveExecutableTemplateURL(
        _ template: String,
        using generator: ExecutableTemplateGenerator
    ) throws -> URL {
        if FileManager.default.fileExists(atPath: template) {
            return URL(fileURLWithPath: template)
        }
        return try generator.bundledTemplateURL(
            named: URL(fileURLWithPath: template).deletingPathExtension().lastPathComponent
        )
    }

    private func inferredMetamodelLevel(
        afterApplying atlURL: URL,
        to resource: Resource,
        default defaultLevel: MetamodelLevel
    ) async -> MetamodelLevel {
        let moduleName = atlURL.deletingPathExtension().lastPathComponent
        switch moduleName {
        case "structural2executable":
            return .executable
        case "executable2structural":
            return .structural
        default:
            break
        }

        let hasExecutableMachine = await findObject(named: "StateMachine", in: resource) != nil
        let hasInitialState = await findObject(named: "InitialState", in: resource) != nil
        if hasExecutableMachine || hasInitialState {
            return .executable
        }
        let hasStructuralMachine = await findObject(named: "Machine", in: resource) != nil
        let hasStructuralGraph = await findObject(named: "LLFSM", in: resource) != nil
        if hasStructuralMachine || hasStructuralGraph {
            return .structural
        }
        return defaultLevel
    }

    private func findExecutableRoot(
        in resource: Resource,
        metamodel: ExecutableLLFSMMetamodel
    ) async -> DynamicEObject? {
        if let arrangement = await findObject(named: metamodel.arrangementClass.name, in: resource) {
            return arrangement
        }
        return await findObject(named: metamodel.stateMachineClass.name, in: resource)
    }

    private func findObject(named className: String, in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let root = roots.first(where: { $0.eClass.name == className }) {
            return root
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first(where: { $0.eClass.name == className })
    }

    /// Resolve an input path, adding the `.machine` suffix when needed.
    private func resolvedInputURL(_ input: String) throws -> URL {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: input) {
            return URL(fileURLWithPath: input)
        }

        let machinePath = input + MachineDirectoryWrapper.dottedSuffix
        guard fileManager.fileExists(atPath: machinePath) else {
            throw ValidationError("File '\(input)' does not exist")
        }
        return URL(fileURLWithPath: machinePath)
    }

    /// Derive the XMI root name from an output URL.
    private func machineName(for outputURL: URL) -> String {
        let stem = outputURL.deletingPathExtension().lastPathComponent
        return stem.isEmpty ? "Machine" : stem
    }

    private func fileStem(for url: URL) -> String {
        if url.lastPathComponent.hasSuffix(MachineDirectoryWrapper.dottedSuffix) {
            return String(url.lastPathComponent.dropLast(MachineDirectoryWrapper.dottedSuffix.count))
        }
        let stem = url.deletingPathExtension().lastPathComponent
        return stem.isEmpty ? "Machine" : stem
    }

    private func defaultArrangementName(for outputURL: URL) -> String {
        let stem = outputURL.deletingPathExtension().lastPathComponent
        return stem.isEmpty ? "Arrangement" : stem
    }

    /// Resolve the language binding to use when writing a metamodel-backed arrangement.
    private func outputLanguageForArrangement(_ arrangement: Arrangement) throws -> any LanguageBinding {
        let defaultLanguage = arrangement.namedInstances.first?.machine.language
        let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
        guard let outputLanguage = outputLanguage(for: outputFormat, default: defaultLanguage ?? ObjCPPBinding()) else {
            throw ValidationError("No output language for format '\(format)'")
        }
        return outputLanguage
    }
}

enum MetamodelLevel: String, ExpressibleByArgument {
    /// Structural LLFSM model that mirrors the native Swift runtime shape.
    case structural
    /// Executable LLFSM model used by the legacy typed templates.
    case executable
}

private enum MetamodelInput {
    /// Native machine input with its preserved machine name.
    case machine(name: String, Machine)
    /// Native arrangement input.
    case arrangement(Arrangement)
}
