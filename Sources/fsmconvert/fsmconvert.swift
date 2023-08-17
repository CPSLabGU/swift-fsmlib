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
        let urls = fsmURLs.map { $0.1 }
        if verbose {
            print("\(fsms.count) FSMs with \(fsms.reduce(0) { $0 + $1.llfsm.states.count }) states and \(fsms.reduce(0) { $0 + $1.llfsm.transitions.count }) transitions\n")
        }
        let outputURL = URL(fileURLWithPath: output)
        if arrangement || fsms.count > 1 {
            let arrangement = Arrangement(machines: fsms)
            let fsmURLs: [URL] = try arrangement.write(to: outputURL, inputURLs: urls, format: format.isEmpty ? nil : Format(rawValue: format), isSuspensible: !nonSuspensible)
            try zip(fsms, fsmURLs).forEach {
                try $0.0.write(to: $0.1, format: format.isEmpty ? nil : Format(rawValue: format), isSuspensible: !nonSuspensible)
            }
        } else {
            try fsms.first?.write(to: outputURL, format: format.isEmpty ? nil : Format(rawValue: format), isSuspensible: !nonSuspensible)
        }
    }
}

