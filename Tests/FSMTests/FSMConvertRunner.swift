//
//  FSMConvertRunner.swift
//  FSMTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
// These tests run the fsmconvert executable, and WASI cannot spawn processes.
#if !os(WASI)
import Foundation
import Synchronization

/// Builds the `fsmconvert` executable once and runs it for end-to-end tests.
///
/// The tool is built into the scratch build directory of
/// ``CLIIntegrationTests/buildPath``, so that it is built against the same
/// dependency checkouts as the tests.
enum FSMConvertRunner {
    /// The outcome of one run of the tool.
    struct Result: Sendable {
        /// The exit status.
        let status: Int32
        /// What the tool wrote to standard output.
        let standardOutput: String
        /// What the tool wrote to standard error.
        let standardError: String
    }

    /// The exit status of a run that succeeded.
    static let successStatus: Int32 = 0

    /// The exit status of a run that failed.
    static let failureStatus: Int32 = 1

    /// The exit status of a run with invalid command-line arguments (`EX_USAGE`).
    static let usageStatus: Int32 = 64

    /// The output of a failed build, or `nil` once the tool has been built.
    static let buildFailure: String? = build()

    /// The location of the built tool.
    static var executable: URL {
        URL(fileURLWithPath: SwiftToolchain.productPath(SwiftToolchain.productName, in: CLIIntegrationTests.buildPath))
    }

    /// The directory of the test sources.
    static var testsDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    /// The resources of the `FSMEcore` tests, which hold the kernel and sectioned fixtures.
    static var ecoreResources: URL {
        testsDirectory.appendingPathComponent("FSMEcoreTests/Resources", isDirectory: true)
    }

    /// The bundled traffic light machine of these tests.
    static var trafficLight: URL {
        testsDirectory.appendingPathComponent("FSMTests/Resources/TrafficLight.machine", isDirectory: true)
    }

    /// The example machines and arrangements of the package.
    static var examples: URL {
        testsDirectory.deletingLastPathComponent().appendingPathComponent("examples", isDirectory: true)
    }

    /// A kernel fixture.
    ///
    /// - Parameter name: The name of the fixture, such as `DoorInterlock`.
    /// - Returns: The location of its XMI document.
    static func kernelModel(_ name: String) -> URL {
        ecoreResources.appendingPathComponent("Kernel/models/\(name).xmi")
    }

    /// A sectioned fixture.
    ///
    /// - Parameter name: The name of the fixture, such as `SectionedCrossing`.
    /// - Returns: The location of its XMI document.
    static func sectionedModel(_ name: String) -> URL {
        ecoreResources.appendingPathComponent("Sectioned/models/\(name).xmi")
    }

    /// The expected files of a kernel target.
    ///
    /// - Parameter target: The directory of the target below the expected files, such as `smv`.
    /// - Returns: The directory.
    static func expected(_ target: String) -> URL {
        ecoreResources.appendingPathComponent("Kernel/expected/\(target)", isDirectory: true)
    }

    /// Build the tool.
    ///
    /// - Returns: The output of the build if it failed, or `nil`.
    private static func build() -> String? {
        let log = FileManager.default.temporaryDirectory.appendingPathComponent("fsmconvert-build-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: log) }
        guard let handle = try? FileHandle(forWritingTo: log) else { return "Cannot create the build log" }
        let process = SwiftToolchain.process(
            arguments: ["build", "--product", SwiftToolchain.productName, "--build-path", CLIIntegrationTests.buildPath])
        if CLIIntegrationTests.overriddenBuildPath != nil {
            // The running test command holds the lock of its own scratch path.
            process.arguments?.append("--ignore-lock")
        }
        process.standardOutput = handle
        process.standardError = handle
        do {
            try process.run()
        } catch {
            return "Cannot run the build: \(error)"
        }
        process.waitUntilExit()
        try? handle.close()
        guard process.terminationStatus != 0 else { return nil }
        return (try? String(contentsOf: log, encoding: .utf8)) ?? "The build failed"
    }

    /// Run the tool.
    ///
    /// - Parameter arguments: The command-line arguments.
    /// - Returns: The exit status and output.
    /// - Throws: An error if the tool cannot be built or started.
    static func run(_ arguments: [String]) throws -> Result {
        if let buildFailure { throw RunnerError.buildFailed(buildFailure) }
        let directory = try makeTemporaryDirectory(prefix: "run")
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("stdout")
        let errorURL = directory.appendingPathComponent("stderr")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        FileManager.default.createFile(atPath: errorURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        let error = try FileHandle(forWritingTo: errorURL)
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        try output.close()
        try error.close()
        return Result(
            status: process.terminationStatus,
            standardOutput: try String(contentsOf: outputURL, encoding: .utf8),
            standardError: try String(contentsOf: errorURL, encoding: .utf8))
    }

    /// Create a new temporary directory.
    ///
    /// - Parameter prefix: A label for the directory name.
    /// - Returns: The directory.
    /// - Throws: An error if the directory cannot be created.
    static func makeTemporaryDirectory(prefix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSMConvertTests-\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Read every regular file below a directory, or a single file.
    ///
    /// - Parameter url: The directory or file.
    /// - Returns: The contents keyed by path relative to the directory (the file name for a file).
    static func files(at url: URL) -> [String: Data] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return [:] }
        guard isDirectory.boolValue else { return [url.lastPathComponent: (try? Data(contentsOf: url)) ?? Data()] }
        let base = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents.count
        var files: [String: Data] = [:]
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey])
        while let file = enumerator?.nextObject() as? URL {
            guard (try? file.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { continue }
            let relative = file.standardizedFileURL.resolvingSymlinksInPath().pathComponents.dropFirst(base)
            files[relative.joined(separator: "/")] = try? Data(contentsOf: file)
        }
        return files
    }

    /// The problems of the runner.
    enum RunnerError: Error, CustomStringConvertible {
        /// The tool could not be built; the associated value is the build output.
        case buildFailed(String)

        /// A sentence that describes the problem.
        var description: String {
            switch self {
            case .buildFailed(let output):
                return "\(SwiftToolchain.productName) could not be built:\n\(output)"
            }
        }
    }
}

/// The Swift toolchain that builds the command-line tool under test.
///
/// The driver is located through the `PATH` of the test process, so that the
/// tests run on every host platform, including Windows, where executables carry
/// a suffix and `env` is not available.
enum SwiftToolchain {
    /// The name of the Swift driver.
    static let driverName = "swift"

    /// The product that the tests build and run.
    static let productName = "fsmconvert"

    /// The build configuration whose products the tests run.
    static let configuration = "debug"

    /// The suffix of executable files on the host platform.
    static var executableSuffix: String {
        #if os(Windows)
        return ".exe"
        #else
        return ""
        #endif
    }

    /// The separator between the entries of the `PATH` environment variable.
    static var pathSeparator: Character {
        #if os(Windows)
        return ";"
        #else
        return ":"
        #endif
    }

    /// The name of the environment variable that lists the executable directories.
    static let pathVariable = "PATH"

    /// The executable directories of the test process.
    ///
    /// Windows names the variable `Path`, so the lookup ignores case.
    static var searchPath: String {
        let environment = ProcessInfo.processInfo.environment
        let key = environment.keys.first { $0.caseInsensitiveCompare(pathVariable) == .orderedSame }
        return key.flatMap { environment[$0] } ?? ""
    }

    /// Find the Swift driver through the executable directories of the test process.
    ///
    /// - Returns: The driver, or `nil` if no directory on the path holds one.
    static func findDriver() -> URL? {
        let path = searchPath
        let fileName = driverName + executableSuffix
        for directory in path.split(separator: pathSeparator) where !directory.isEmpty {
            let candidate = URL(fileURLWithPath: String(directory), isDirectory: true).appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// Create a process that runs the Swift driver in the current directory.
    ///
    /// Where the driver is not on the path, `env` resolves it when the process starts.
    ///
    /// - Parameter arguments: The arguments of the driver.
    /// - Returns: The configured process, not yet started.
    static func process(arguments: [String]) -> Process {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let driver = findDriver() {
            process.executableURL = driver
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [driverName] + arguments
        }
        return process
    }

    /// The directory that holds the products built into a scratch build directory.
    ///
    /// The directory is asked from the package manager, because its layout
    /// differs between host platforms.  Where it cannot be asked, the
    /// configuration directory below the scratch build directory is used.
    ///
    /// - Parameter buildPath: The scratch build directory.
    /// - Returns: The directory of the built products.
    static func binPath(for buildPath: String) -> String {
        let fallback = buildPath + "/" + configuration
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("bin-path-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: output.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: output) }
        guard let handle = try? FileHandle(forWritingTo: output) else { return fallback }
        var arguments = ["build", "--build-path", buildPath, "--show-bin-path"]
        if CLIIntegrationTests.overriddenBuildPath != nil { arguments.append("--ignore-lock") }
        let process = process(arguments: arguments)
        process.standardOutput = handle
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return fallback }
        process.waitUntilExit()
        try? handle.close()
        let text = (try? String(contentsOf: output, encoding: .utf8)) ?? ""
        let path = text.split(whereSeparator: \.isNewline).last.map(String.init) ?? ""
        return process.terminationStatus == 0 && !path.isEmpty ? path : fallback
    }

    /// The path of a built executable product.
    ///
    /// - Parameters:
    ///   - product: The name of the product.
    ///   - buildPath: The scratch build directory.
    /// - Returns: The path of the executable.
    static func productPath(_ product: String, in buildPath: String) -> String {
        resolvedBinPath(for: buildPath) + "/" + product + executableSuffix
    }

    /// The directory of the built products, asked once per scratch build directory.
    ///
    /// - Parameter buildPath: The scratch build directory.
    /// - Returns: The directory of the built products.
    static func resolvedBinPath(for buildPath: String) -> String {
        binPathCache.withLock { cache in
            if let path = cache[buildPath] { return path }
            let path = binPath(for: buildPath)
            cache[buildPath] = path
            return path
        }
    }

    /// The directories of the built products asked so far, by scratch build directory.
    static let binPathCache = Mutex<[String: String]>([:])
}
#endif
