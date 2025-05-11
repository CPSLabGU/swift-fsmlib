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
        let wrapperNames = try inputMachines.map {
            let path: String
            if fileManager.fileExists(atPath: $0) {
                path = $0
            } else {
                path = $0 + MachineWrapper.dottedSuffix
                guard fileManager.fileExists(atPath: path) else {
                    throw ValidationError("File '\($0)' does not exist")
                }
            }
            let machineURL = URL(fileURLWithPath: path)
            let wrapper = try MachineWrapper(url: machineURL)
            return (machineURL.lastPathComponent, wrapper)
        }
        let machineArrangement = Arrangement(namedInstances: wrapperNames.map { Instance(name: $0.0, typeFile: $0.0, machine: $0.1.machine) })
        let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
        guard let outputLanguage = outputLanguage(for: outputFormat, default: wrapperNames.first?.1.machine.language) else {
            FSMConvert.exit(withError: ValidationError("No output language for format '\(format)'\n"))
        }
        let outputURL = URL(fileURLWithPath: output)
        let wrapperMappings = Dictionary(wrapperNames, uniquingKeysWith: { a, _ in a })
        let arrangementWrapper = ArrangementWrapper(directoryWithFileWrappers: wrapperMappings, for: machineArrangement, named: outputURL.lastPathComponent, language: outputLanguage)
        if verbose {
            print("\(wrapperNames.count) FSMs with \(wrapperNames.reduce(0) { $0 + $1.1.machine.llfsm.states.count }) states and \(wrapperNames.reduce(0) { $0 + $1.1.machine.llfsm.transitions.count }) transitions\n")
        }
        if arrangement || wrapperNames.count > 1 {
            try arrangementWrapper.write(to: outputURL)
        } else if let machineWrapper = wrapperNames.first?.1 {
            machineWrapper.language = outputLanguage
            try machineWrapper.write(to: outputURL)
        }
    }
}
