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
    /// export, and MTL template operations.
    @Option(name: .long, help: "Use metamodel-backed conversion at the selected model level.")
    var metamodel: MetamodelLevel?

    /// The MTL template to apply after metamodel loading.
    ///
    /// This option selects one of the bundled structural templates
    /// (`structural2machine`, `structural2scxml`, `structural2cmake`, or
    /// `structural2layout`) and requires `--metamodel structural`.
    @Option(name: .long, help: "Apply a bundled structural MTL template after metamodel loading.")
    var transform: String?

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

        if transform != nil {
            throw ValidationError("`--transform` requires `--metamodel structural`")
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
    /// This path uses `FSMEcore` for structural model handling while
    /// preserving the existing Swift readers and writers as the native format
    /// boundary.
    ///
    /// - Parameter level: The metamodel level selected on the command line.
    /// - Throws: ``FSMConvertError/metamodelLevelUnavailable(_:)`` if the
    ///   selected level is not available in this release, or any error raised
    ///   while reading, converting, or writing models.
    @MainActor
    private mutating func runWithMetamodel(level: MetamodelLevel) async throws {
        guard level.isAvailable else {
            throw FSMConvertError.metamodelLevelUnavailable(level)
        }
        let outputURL = URL(fileURLWithPath: output)
        let xmiRequested = format.lowercased() == "xmi" || outputURL.pathExtension.lowercased() == "xmi"

        if let transform {
            let resource = try await loadMetamodelResource(arrangementName: defaultArrangementName(for: outputURL))
            try await applyStructuralTemplate(named: transform, resource: resource, outputURL: outputURL)
            return
        }

        let input = try await loadMetamodelInput()
        if xmiRequested {
            try await writeXMI(input, to: outputURL)
            return
        }

        try writeNative(input, outputURL: outputURL)
    }

    /// Load the command-line inputs as a machine or an arrangement.
    ///
    /// - Returns: The decoded metamodel input.
    /// - Throws: An error if an input cannot be found, read, or decoded.
    private func loadMetamodelInput() async throws -> MetamodelInput {
        if arrangement || inputMachines.count > 1 {
            return .arrangement(try await loadArrangement())
        }

        guard inputMachines.count == 1 else {
            throw ValidationError("Metamodel conversion requires exactly one input machine")
        }

        let inputURL = try resolvedInputURL(inputMachines[0])
        if inputURL.pathExtension.lowercased() == "xmi" {
            return try await loadSingleXMIInput(from: inputURL)
        }

        let storage = try MachineStorageFactory.read(from: inputURL)
        return .machine(name: fileStem(for: inputURL), storage.machine)
    }

    /// Load an arrangement either from XMI or by composing machine inputs.
    ///
    /// - Returns: The arrangement read from XMI or composed from the inputs.
    /// - Throws: An error if an input cannot be found, read, or decoded.
    private func loadArrangement() async throws -> Arrangement {
        if inputMachines.count == 1 {
            let inputURL = try resolvedInputURL(inputMachines[0])
            if inputURL.pathExtension.lowercased() == "xmi" {
                let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
                return try await roundTrip.readArrangement(from: inputURL)
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

    /// Load a single XMI input as either a machine or an arrangement.
    ///
    /// A document that contains an arrangement is read as an arrangement,
    /// including the machines of its instances; any other document is read
    /// as a single machine.
    ///
    /// - Parameter inputURL: The XMI document to read.
    /// - Returns: The decoded machine or arrangement.
    /// - Throws: An error if the document contains neither.
    private func loadSingleXMIInput(from inputURL: URL) async throws -> MetamodelInput {
        let resource = try await loadResourceFromXMI(inputURL)
        return try await decodeMetamodelResource(resource, preferArrangement: true)
    }

    /// Load the command-line inputs as a structural metamodel resource.
    ///
    /// - Parameter arrangementName: The name to use for composed arrangements.
    /// - Returns: A resource containing the structural object graph.
    /// - Throws: An error if an input cannot be found, read, or encoded.
    private func loadMetamodelResource(arrangementName: String) async throws -> Resource {
        if arrangement || inputMachines.count > 1 {
            if inputMachines.count == 1 {
                let inputURL = try resolvedInputURL(inputMachines[0])
                if inputURL.pathExtension.lowercased() == "xmi" {
                    return try await loadResourceFromXMI(inputURL)
                }
            }
            return try await encode(arrangement: try await loadArrangement(), name: arrangementName)
        }

        guard inputMachines.count == 1 else {
            throw ValidationError("Metamodel conversion requires exactly one input machine")
        }

        let inputURL = try resolvedInputURL(inputMachines[0])
        if inputURL.pathExtension.lowercased() == "xmi" {
            return try await loadResourceFromXMI(inputURL)
        }

        let storage = try MachineStorageFactory.read(from: inputURL)
        return try await encode(machine: storage.machine, name: fileStem(for: inputURL))
    }

    /// Parse an XMI document against the structural metamodel.
    ///
    /// - Parameter inputURL: The XMI document to parse.
    /// - Returns: The parsed resource.
    /// - Throws: An error if the document cannot be parsed.
    private func loadResourceFromXMI(_ inputURL: URL) async throws -> Resource {
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        var diagnostics = ConversionDiagnostics()
        return try await roundTrip.loadResource(from: inputURL, diagnostics: &diagnostics)
    }

    /// Encode a machine into a new in-memory structural resource.
    ///
    /// - Parameters:
    ///   - machine: The machine to encode.
    ///   - name: The machine name to record.
    /// - Returns: The resource containing the encoded machine.
    /// - Throws: An error if the structural metamodel cannot be loaded.
    private func encode(machine: Machine, name: String) async throws -> Resource {
        let resource = Resource(uri: "memory:/\(name).xmi")
        let codec = MachineEcoreCodec(metamodel: try await LLFSMMetamodel())
        _ = await codec.encode(machine, name: name, into: resource)
        return resource
    }

    /// Encode an arrangement into a new in-memory structural resource.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to encode.
    ///   - name: The arrangement name used for the resource URI.
    /// - Returns: The resource containing the encoded arrangement.
    /// - Throws: An error if the structural metamodel cannot be loaded.
    private func encode(arrangement: Arrangement, name: String) async throws -> Resource {
        let resource = Resource(uri: "memory:/\(name).xmi")
        let codec = ArrangementEcoreCodec(metamodel: try await LLFSMMetamodel())
        _ = await codec.encode(arrangement, into: resource)
        return resource
    }

    /// Write a machine or arrangement as a structural XMI document.
    ///
    /// - Parameters:
    ///   - input: The machine or arrangement to write.
    ///   - outputURL: The destination XMI document.
    /// - Throws: An error if encoding or writing fails.
    private func writeXMI(_ input: MetamodelInput, to outputURL: URL) async throws {
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        switch input {
        case .machine(_, let machine):
            try await roundTrip.write(machine: machine, name: machineName(for: outputURL), to: outputURL)
        case .arrangement(let arrangement):
            try await roundTrip.write(arrangement: arrangement, to: outputURL)
        }
    }

    /// Decode a structural resource into a machine or an arrangement.
    ///
    /// - Parameters:
    ///   - resource: The resource to decode.
    ///   - preferArrangement: Whether to prefer an arrangement root when present.
    /// - Returns: The decoded machine or arrangement.
    /// - Throws: An error if the resource contains neither.
    private func decodeMetamodelResource(
        _ resource: Resource,
        preferArrangement: Bool
    ) async throws -> MetamodelInput {
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
    }

    /// Apply one of the bundled structural MTL templates.
    ///
    /// - Parameters:
    ///   - template: The template name or path (only its basename is used).
    ///   - resource: The structural resource holding the machine to render.
    ///   - outputURL: The destination file or directory.
    /// - Throws: An error if the template is unknown or generation fails.
    @MainActor
    private func applyStructuralTemplate(
        named template: String,
        resource: Resource,
        outputURL: URL
    ) async throws {
        let decoded = try await decodeMetamodelResource(resource, preferArrangement: false)
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

/// The model level used by metamodel-backed conversion.
///
/// Each level corresponds to a metamodel that `fsmconvert` can use for XMI
/// import, export, and template generation. Only the structural level is
/// available in this release; the remaining cases are accepted on the command
/// line so that scripts receive a clear diagnostic rather than a parse error.
enum MetamodelLevel: String, CaseIterable, ExpressibleByArgument {
    /// Structural LLFSM model that mirrors the native Swift runtime shape.
    case structural
    /// Sectioned LLFSM model with language-neutral code sections.
    ///
    /// This level is not yet available in this release.
    case sectioned

    /// The deprecated command-line spelling that now maps to ``sectioned``.
    static let deprecatedExecutableArgument = "executable"

    /// Whether this level can be used in the current release.
    var isAvailable: Bool {
        self == .structural
    }

    /// Parse a metamodel level from a command-line argument.
    ///
    /// The deprecated value `executable` is accepted for compatibility and
    /// mapped to ``sectioned`` after printing a deprecation warning to the
    /// standard error stream.
    ///
    /// - Parameter argument: The command-line value to parse.
    init?(argument: String) {
        let value = argument.lowercased()
        if value == Self.deprecatedExecutableArgument {
            FileHandle.standardError.write(Data(
                "warning: '--metamodel \(Self.deprecatedExecutableArgument)' is deprecated; use '--metamodel \(Self.sectioned.rawValue)' instead\n".utf8
            ))
            self = .sectioned
            return
        }
        guard let level = MetamodelLevel(rawValue: value) else { return nil }
        self = level
    }
}

/// Errors reported by `fsmconvert`.
enum FSMConvertError: Error, CustomStringConvertible {
    /// The selected metamodel level is not available in this release.
    ///
    /// - Parameter level: The level that was requested.
    case metamodelLevelUnavailable(MetamodelLevel)

    /// A human-readable description of the error.
    var description: String {
        switch self {
        case .metamodelLevelUnavailable(let level):
            return "The '\(level.rawValue)' metamodel level is not yet available in this release; use '--metamodel \(MetamodelLevel.structural.rawValue)'"
        }
    }
}

private enum MetamodelInput {
    /// Native machine input with its preserved machine name.
    case machine(name: String, Machine)
    /// Native arrangement input.
    case arrangement(Arrangement)
}
