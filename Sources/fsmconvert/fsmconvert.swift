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

    @Option(name: .shortAndLong, help: "The output machine/arrangement.")
    var output = "fsm.out"

    @Flag(name: .shortAndLong, help: "Turn on verbose output.")
    var verbose = false

    @Argument(help: "The input machines to read.", completion: .directory)
    var inputMachines: [String]

    mutating func run() async throws {
        let fileManager = FileManager.default
        let fsms = try inputMachines.map {
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
            return fsm
        }
        if verbose {
            print("\(fsms.count) FSMs with \(fsms.reduce(0) { $0 + $1.llfsm.states.count }) states and \(fsms.reduce(0) { $0 + $1.llfsm.transitions.count }) transitions\n")
        }
    }
}

