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
        let fsmURLs = try inputMachines.map {
            let path: String
            if fileManager.fileExists(atPath: $0) {
                path = $0
            } else {
                path = $0 + ".machine"
                guard fileManager.fileExists(atPath: path) else {
                    throw ValidationError("File '\($0)' does not exist")
                }
            }
            let url = URL(fileURLWithPath: path)
            let fsm = try Machine(from: url)
            return (fsm, url)
        }
        let fsms = fsmURLs.map { $0.0 }
        let names = fsmURLs.map { $0.1.lastPathComponent }
        if verbose {
            print("\(fsms.count) FSMs with \(fsms.reduce(0) { $0 + $1.llfsm.states.count }) states and \(fsms.reduce(0) { $0 + $1.llfsm.transitions.count }) transitions\n")
        }
        let outputURL = URL(fileURLWithPath: output)
        let outputFormat = format.isEmpty ? nil : Format(rawValue: format)
        guard let outputLanguage = outputLanguage(for: outputFormat, default: fsms.first?.language) else {
            FSMConvert.exit(withError: "No output language for format '\(format)'\n")
        }
        if arrangement || fsms.count > 1 {
            let arrangement = Arrangement(machines: fsms)
            let wrapper = try arrangement.wrapper(for: outputURL, format: outputFormat)
            let fsmNames: [String] = try arrangement.add(to: wrapper, in: outputFormat, machineNames: names, isSuspensible: !nonSuspensible)
            try zip(fsms, fsmNames).forEach {
                let machine = $0.0
                let machineName = $0.1
                let machineWrapper = MachineWrapper(directoryWithFileWrappers: [:])
                machineWrapper.preferredFilename = machineName
                wrapper.addFileWrapper(machineWrapper)
                try machine.add(to: machineWrapper, language: outputLanguage, isSuspensible: !nonSuspensible)
            }
            try outputLanguage.finalise(wrapper, writingTo: outputURL)
        } else {
            try fsms.first?.write(to: outputURL, language: outputLanguage, isSuspensible: !nonSuspensible)
        }
    }
}

extension String: Error {}
