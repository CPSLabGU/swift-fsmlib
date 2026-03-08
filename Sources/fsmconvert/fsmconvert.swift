import ArgumentParser
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
    /// This option routes `.xmi` import and export through `FSMEcore` while
    /// leaving non-XMI machine and arrangement serialisation unchanged.
    @Flag(name: .long, help: "Use metamodel-backed XMI conversion.")
    var metamodel = false

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
        if transform != nil || atl != nil {
            throw ValidationError(
                "`--transform` and `--atl` are not implemented for this release of fsmconvert"
            )
        }

        if metamodel {
            try await runWithMetamodel()
            return
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
    /// This path uses `FSMEcore` for `.xmi` import and export while still using
    /// the established Swift machine and arrangement writers for other formats.
    private mutating func runWithMetamodel() async throws {
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let outputURL = URL(fileURLWithPath: output)
        let xmiRequested = format.lowercased() == "xmi" || outputURL.pathExtension.lowercased() == "xmi"

        if arrangement || inputMachines.count > 1 {
            let arrangement = try await loadArrangement(roundTrip: roundTrip)
            if xmiRequested {
                try await roundTrip.write(arrangement: arrangement, to: outputURL)
            } else {
                let outputLanguage = try outputLanguageForArrangement(arrangement)
                try writeArrangement(arrangement, outputURL: outputURL, outputLanguage: outputLanguage)
            }
            return
        }

        if inputMachines.count != 1 {
            throw ValidationError("Metamodel conversion requires exactly one input machine")
        }

        if inputMachines[0].lowercased().hasSuffix(".xmi") && !xmiRequested {
            switch try await loadSingleXMIInput(roundTrip: roundTrip) {
            case .machine(let machine):
                let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
                guard let outputLanguage = outputLanguage(
                    for: outputFormat,
                    default: machine.language
                ) else {
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
            return
        }

        let machine = try await loadMachine(roundTrip: roundTrip)
        if xmiRequested {
            try await roundTrip.write(machine: machine, name: machineName(for: outputURL), to: outputURL)
            return
        }

        let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
        guard let outputLanguage = outputLanguage(
            for: outputFormat,
            default: machine.language
        ) else {
            throw ValidationError("No output language for format '\(format)'")
        }

        let storage = MachineStorageFactory.create(for: machine, format: outputFormat, at: outputURL)
        storage.machine.language = outputLanguage
        storage.isSuspensible = !nonSuspensible
        try storage.write(to: outputURL)
    }

    /// Load a machine either from XMI or from the existing Swift readers.
    private func loadMachine(roundTrip: XMIRoundTrip) async throws -> Machine {
        let inputURL = try resolvedInputURL(inputMachines[0])
        if inputURL.pathExtension.lowercased() == "xmi" {
            return try await roundTrip.readMachine(from: inputURL).machine
        }
        return try MachineStorageFactory.read(from: inputURL).machine
    }

    /// Load an arrangement either from XMI or by composing machine inputs.
    private func loadArrangement(roundTrip: XMIRoundTrip) async throws -> Arrangement {
        if inputMachines.count == 1 {
            let inputURL = try resolvedInputURL(inputMachines[0])
            if inputURL.pathExtension.lowercased() == "xmi" {
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

    /// Attempt to load a single XMI input as either a machine or an arrangement.
    private func loadSingleXMIInput(roundTrip: XMIRoundTrip) async throws -> MetamodelInput {
        let inputURL = try resolvedInputURL(inputMachines[0])
        do {
            let decoded = try await roundTrip.readMachine(from: inputURL)
            return .machine(decoded.machine)
        } catch {
            return .arrangement(try await roundTrip.readArrangement(from: inputURL))
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

private enum MetamodelInput {
    case machine(Machine)
    case arrangement(Arrangement)
}
