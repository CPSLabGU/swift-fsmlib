import ArgumentParser

@main
struct FSMConvert: AsyncParsableCommand {
    @Flag(help: "Verbose output.")
    var verbose = false
    
    mutating func run() async throws {
        if verbose {
            print("Verbose.")
        }
    }
}

