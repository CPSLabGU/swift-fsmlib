import ArgumentParser
import Foundation
import FSM

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
}
