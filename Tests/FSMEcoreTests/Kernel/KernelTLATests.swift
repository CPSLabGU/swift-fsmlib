//
//  KernelTLATests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSMEcore

/// Runs TLC from `tla2tools.jar` on generated specifications.
enum KernelTLC {
    /// The environment variable that names `tla2tools.jar`.
    static let jarVariable = "TLA2TOOLS_JAR"

    /// The file name of the TLA+ tools archive.
    static let jarName = "tla2tools.jar"

    /// The TLA+ tools archive: the one the environment names, else one on the search path.
    static let jar: URL? = {
        if let path = ProcessInfo.processInfo.environment[jarVariable], FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return KernelTestSupport.fileOnPath(jarName)
    }()

    /// Whether TLC can be run.
    static let isAvailable = jar != nil && KernelToolchain.java != nil

    /// The text with which TLC reports a run that found no error.
    static let successText = "Model checking completed. No error has been found."

    /// Run TLC on a specification with a configuration.
    ///
    /// - Parameters:
    ///   - specification: The generated `.tla` file.
    ///   - configuration: The name of the configuration file next to it.
    /// - Returns: The outcome of the run.
    static func run(_ specification: URL, configuration: String) throws -> KernelTestSupport.Outcome {
        let directory = specification.deletingLastPathComponent()
        let states = directory.appendingPathComponent("states-" + configuration)
        return try KernelTestSupport.run(
            try #require(KernelToolchain.java),
            ["-XX:+UseParallelGC", "-cp", try #require(jar).path, "tlc2.TLC", "-workers", "1", "-nowarning",
             "-metadir", states.path, "-config", configuration, specification.lastPathComponent],
            in: directory)
    }
}

/// Tests of the tla target with TLC.
///
/// The tests run only when the environment variable `TLA2TOOLS_JAR` names
/// `tla2tools.jar`, or the archive is on the search path, and `java` is
/// available; otherwise they are skipped with a message. CrossingController
/// is not checked: its clock ranges over 0..10000 and is unconstrained in
/// every ringlet, which is too large for an explicit-state search.
@Suite("Kernel tla target with TLC")
@MainActor
struct KernelTLATests {
    /// The models whose specifications TLC checks.
    static let checked: [KernelVerificationCase] = KernelVerificationCase.all.filter {
        $0.model != .fixture(.crossingController)
    }

    /// Generate the specification of a model into a scratch directory.
    func generate(_ model: KernelTestModel, _ parameters: [String: String]) async throws -> URL {
        let directory = try await KernelTestSupport.generate(model, .tla, parameters: parameters)
        return directory.appendingPathComponent(model.name).appendingPathExtension("tla")
    }

    @Test("TypeOK and the range invariants hold, unless a havocked label lets a variable leave its range",
          .enabled(if: KernelTLC.isAvailable, "No tla2tools.jar in TLA2TOOLS_JAR or on the search path, or no java; skipping"),
          arguments: checked)
    func invariantsHold(_ verification: KernelVerificationCase) async throws {
        let specification = try await generate(verification.model, verification.parameters)
        defer { try? FileManager.default.removeItem(at: specification.deletingLastPathComponent()) }
        let configuration = verification.model.name + ".cfg"
        let text = try String(contentsOf: specification.deletingLastPathComponent().appendingPathComponent(configuration),
                              encoding: .utf8)
        #expect(text.contains("INVARIANT TypeOK"))
        let outcome = try KernelTLC.run(specification, configuration: configuration)
        if verification.escapesRange {
            #expect(outcome.output.contains("Invariant TypeOK is violated"), "\(outcome.output.suffix(3000))")
        } else {
            #expect(outcome.status == 0, "\(outcome.output.suffix(3000))")
            #expect(outcome.output.contains(KernelTLC.successText), "\(outcome.output.suffix(3000))")
        }
    }

    @Test("with sanity=true every state of the relay is reachable and every transition fires",
          .enabled(if: KernelTLC.isAvailable, "No tla2tools.jar in TLA2TOOLS_JAR or on the search path, or no java; skipping"))
    func sanityOfRelay() async throws {
        let model = KernelTestModel.fixture(.turnTakingRelay)
        let specification = try await generate(model, [KernelTemplateParameter.sanity: "true"])
        let directory = specification.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        let configurations = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix(model.name + ".Sanity_") && $0.hasSuffix(".cfg") }.sorted()
        // Two instances, three states and three transitions each.
        #expect(configurations.count == 12)
        for configuration in configurations {
            let invariant = String(configuration.dropFirst(model.name.count + 1).dropLast(".cfg".count))
            let outcome = try KernelTLC.run(specification, configuration: configuration)
            #expect(outcome.output.contains("Invariant \(invariant) is violated"),
                    "\(invariant) has no witness:\n\(outcome.output.suffix(2000))")
        }
    }
}
