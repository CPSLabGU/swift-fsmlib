//
//  KernelTestSupport.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// A kernel model used by the generation tests: a fixture or a HostTally model.
enum KernelTestModel: Sendable, Hashable, CustomStringConvertible {
    /// One of the kernel fixtures.
    case fixture(KernelFixture)
    /// The HostTally model of one language.
    case host(KernelHostFixture)

    /// The kernel fixtures, excluding the sectioned ones.
    static let fixtures: [KernelTestModel] = KernelFixture.allCases.filter { !$0.isSectioned }.map { .fixture($0) }

    /// The HostTally models.
    static let hosts: [KernelTestModel] = KernelHostFixture.allCases.map { .host($0) }

    /// The name of the arrangement, which names the generated files and the expected trace.
    var name: String {
        switch self {
        case .fixture(let fixture): return fixture.rawValue
        case .host: return KernelHostFixture.arrangementName
        }
    }

    /// The name of the model in test reports.
    var description: String {
        switch self {
        case .fixture(let fixture): return fixture.rawValue
        case .host(let host): return KernelHostFixture.arrangementName + "-" + host.rawValue
        }
    }

    /// The directory below an expected-output directory that holds this model's files, if any.
    var expectedSubdirectory: String? {
        switch self {
        case .fixture: return nil
        case .host(let host): return host.rawValue
        }
    }

    /// Whether the model declares external variables and therefore needs an inputs file.
    var isOpen: Bool {
        self == .fixture(.crossingController) || self == .fixture(.doorInterlock)
    }

    /// Whether the model satisfies the strict profile.
    var isStrict: Bool {
        switch self {
        case .fixture(let fixture): return fixture.isStrict
        case .host: return false
        }
    }

    /// The code targets whose programs can run the model.
    var executionTargets: [KernelTarget] {
        switch self {
        case .fixture(.opaqueSampler): return [.c]
        case .fixture: return KernelTarget.allCases.filter(\.isExecutionTarget)
        case .host(let host): return [host.target]
        }
    }

    /// Load the model into a resource.
    func resource() async throws -> Resource {
        switch self {
        case .fixture(let fixture): return try await KernelFixtureTests.load(fixture).resource
        case .host(let host): return try await KernelHostFixtureTests.load(host).resource
        }
    }
}

extension KernelHostFixture {
    /// The code target that compiles the model.
    var target: KernelTarget {
        switch self {
        case .c: return .c
        case .cpp: return .cpp
        case .swift: return .swift
        case .java: return .java
        }
    }
}

/// Locations of the kernel test resources and helpers to run external tools.
enum KernelTestSupport {
    /// The bundle directory that holds the test resources.
    static let resourcesDirectory = "Resources"

    /// The directory of the kernel test resources within ``resourcesDirectory``.
    static let kernelDirectory = "Kernel"

    /// The bundle subdirectory of the kernel test resources.
    static let resourcesSubdirectory = resourcesDirectory + "/" + kernelDirectory

    /// The directory of expected outputs below the kernel resources.
    static let expectedDirectory = "expected"

    /// The directory of inputs files below the kernel resources.
    static let inputsDirectory = "inputs"

    /// The directory of host-language implementations below the kernel resources.
    static let hostDirectory = "host"

    /// The file extension of expected traces.
    static let traceExtension = "trace"

    /// The file extension of inputs files.
    static let inputsExtension = "inputs"

    /// The bundled kernel test resources.
    static var bundledResources: URL {
        TestResources.url(forResource: kernelDirectory, withExtension: nil, subdirectory: resourcesDirectory)!
    }

    /// The kernel test resources in the source tree, where recorded files are written.
    static func sourceResources(testFile: String = #filePath) -> URL {
        URL(fileURLWithPath: testFile)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(resourcesSubdirectory, isDirectory: true)
    }

    /// The expected canonical trace of a model.
    static func expectedTrace(of model: KernelTestModel) throws -> String {
        let url = bundledResources.appendingPathComponent(expectedDirectory)
            .appendingPathComponent(model.name).appendingPathExtension(traceExtension)
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// The inputs file of an open model, if it has one.
    static func inputs(of model: KernelTestModel) -> URL? {
        let url = bundledResources.appendingPathComponent(inputsDirectory)
            .appendingPathComponent(model.name).appendingPathExtension(inputsExtension)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// The host-language implementation files of a model for a target directory, if any.
    static func hostSources(of model: KernelTestModel, for target: KernelTarget) -> [URL] {
        let directory = bundledResources.appendingPathComponent(hostDirectory)
            .appendingPathComponent(target.templateDirectory, isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.deletingPathExtension().lastPathComponent == model.name + "Host" }
            .sorted { $0.path < $1.path }
    }

    /// The number of rounds a trace covers: the round of its last resting-state line.
    ///
    /// - Parameter trace: A canonical trace.
    /// - Returns: The round number, or `nil` if the trace has no resting-state line.
    static func rounds(of trace: String) -> Int? {
        trace.split(separator: "\n").reversed().lazy.compactMap { line -> Int? in
            guard line.hasPrefix("R"), let space = line.firstIndex(of: " ") else { return nil }
            return Int(line[line.index(after: line.startIndex)..<space])
        }.first
    }

    /// The resting-state and halt lines of a trace.
    static func restingLines(of trace: String) -> [String] {
        trace.split(separator: "\n").map(String.init).filter { line in
            guard let first = line.split(separator: " ").first else { return false }
            return first == "halt" || (first.hasPrefix("R") && Int(first.dropFirst()) != nil)
        }
    }

    /// Whether this platform can run other programs.
    ///
    /// WASI cannot spawn processes, so no program or tool file is found
    /// there, and the tests that need one are skipped by their traits.
    static var canRunPrograms: Bool {
        #if os(WASI)
        false
        #else
        true
        #endif
    }

    /// Finds a program on the search path.
    ///
    /// - Parameter name: The name of the program, without the extension of the platform.
    /// - Returns: The location of the program, or `nil` if the search path has none.
    static func executable(_ name: String) -> URL? {
        guard canRunPrograms else { return nil }
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
            let file = name + ".exe"
        #else
            let separator: Character = ":"
            let file = name
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(file)
            if FileManager.default.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// Finds a file on the search path, whether or not it is executable.
    static func fileOnPath(_ name: String) -> URL? {
        guard canRunPrograms else { return nil }
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
        #else
            let separator: Character = ":"
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// Creates an empty scratch directory below the temporary directory.
    ///
    /// - Parameter purpose: A word that names the directory's use.
    /// - Returns: The location of the directory; the caller removes it.
    static func makeScratch(_ purpose: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-fsmlib-kernel-\(purpose)")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The outcome of running a program.
    struct Outcome: Sendable {
        /// The exit status.
        let status: Int32
        /// The text written to standard output.
        let output: String
        /// The text written to standard error.
        let errors: String
    }

    /// Runs a program and collects its output.
    ///
    /// Standard output and standard error go to files in the working directory, so that a
    /// program that writes much to both cannot block on a full pipe.
    ///
    /// - Parameters:
    ///   - executable: The program to run.
    ///   - arguments: The arguments of the program.
    ///   - directory: The directory to run in; it receives the two output files.
    /// - Returns: The exit status and the text that the program wrote.
    static func run(_ executable: URL, _ arguments: [String], in directory: URL) throws -> Outcome {
        #if os(WASI)
        throw CocoaError(.featureUnsupported)
        #else
        let name = UUID().uuidString
        let outputURL = directory.appendingPathComponent(name + ".stdout")
        let errorsURL = directory.appendingPathComponent(name + ".stderr")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        FileManager.default.createFile(atPath: errorsURL.path, contents: nil)
        defer {
            try? FileManager.default.removeItem(at: outputURL)
            try? FileManager.default.removeItem(at: errorsURL)
        }
        let output = try FileHandle(forWritingTo: outputURL)
        let errors = try FileHandle(forWritingTo: errorsURL)
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = errors
        try process.run()
        process.waitUntilExit()
        try output.close()
        try errors.close()
        return Outcome(status: process.terminationStatus,
                       output: try String(contentsOf: outputURL, encoding: .utf8),
                       errors: try String(contentsOf: errorsURL, encoding: .utf8))
        #endif
    }

    /// Generate the files of a model for a target into a new scratch directory.
    @MainActor
    static func generate(_ model: KernelTestModel, _ target: KernelTarget,
                         parameters: [String: String] = [:]) async throws -> URL {
        let directory = try makeScratch(target.rawValue)
        let generator = KernelTemplateGenerator(metamodel: try await KernelMetamodel())
        try await generator.generate(target, resource: try await model.resource(), parameters: parameters,
                                     to: directory)
        return directory
    }
}
