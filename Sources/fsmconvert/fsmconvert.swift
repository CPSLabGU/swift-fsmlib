import ArgumentParser
import Foundation
import FSM

@main
struct FSMConvert: AsyncParsableCommand {
    @Flag(name: .shortAndLong, help: "Create an arrangement of a single FSM.")
    var arrangement = false

    @Option(name: .shortAndLong, help: "The output machine format.", transform: {
        if $0.isEmpty { return $0 }
        guard let format = Format(rawValue: $0.lowercased()) else {
            throw ValidationError("Unknown format '\($0)'")
        }
        return format.rawValue
    })
    var format = ""

    @Flag(name: .shortAndLong, help: "Make the generated code introspectable.")
    var introspectable = false

    @Flag(name: .shortAndLong, help: "Make the generated machine non-suspensible.")
    var nonSuspensible = false

    @Option(name: .shortAndLong, help: "The output machine/arrangement.")
    var output = "fsm.out"

    @Flag(name: .shortAndLong, help: "Turn on verbose output.")
    var verbose = false

    @Argument(help: "The input machines to read.", completion: .directory)
    var inputMachines: [String]

    mutating func run() async throws {
        let fileManager = FileManager.default
        let wrapperNames = try inputMachines.map {
            let path: String
            if fileManager.fileExists(atPath: $0) {
                path = $0
            } else {
                path = $0 + ".machine"
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
