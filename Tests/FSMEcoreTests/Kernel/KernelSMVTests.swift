//
//  KernelSMVTests.swift
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

/// Runs nuXmv, or NuSMV when nuXmv is absent, on generated models.
enum KernelModelChecker {
    /// The model checker found on the search path.
    static let executable = KernelTestSupport.executable("nuXmv") ?? KernelTestSupport.executable("NuSMV")

    /// The suffix that the smv target appends to names that clash with reserved words.
    static let escapeSuffix = "_smv"

    /// The verdicts that a run reports, by the text of the property.
    struct Report {
        /// The complete output of the run.
        let log: String

        /// The verdict lines, such as `-- invariant (x >= 0)  is true`.
        var verdicts: [String] { log.split(separator: "\n").map(String.init).filter { $0.hasPrefix("-- ") && ($0.hasSuffix(" is true") || $0.hasSuffix(" is false")) } }

        /// Whether every reported property holds.
        var allHold: Bool { !verdicts.isEmpty && verdicts.allSatisfy { $0.hasSuffix(" is true") } }

        /// Whether the run reported an error.
        var hasErrors: Bool { log.contains("rror") }

        /// Whether `check_fsm` failed to show that no reachable state lacks a successor.
        var hasDeadlock: Bool { !(log.contains("No deadlock state exists") || log.contains("so the machine is deadlock-free")) }
    }

    /// Run the model checker on a model with a script of interactive commands.
    ///
    /// - Parameters:
    ///   - model: The generated model file.
    ///   - commands: The commands to run after the model has been built.
    /// - Returns: The output of the run.
    static func run(_ model: URL, _ commands: [String]) throws -> Report {
        let checker = try #require(executable)
        let directory = model.deletingLastPathComponent()
        let script = directory.appendingPathComponent("commands.txt")
        let lines = ["read_model -i \(model.lastPathComponent)", "flatten_hierarchy", "encode_variables", "build_model"]
            + commands + ["quit"]
        try lines.joined(separator: "\n").appending("\n").write(to: script, atomically: true, encoding: .utf8)
        let outcome = try KernelTestSupport.run(checker, ["-int", "-source", script.lastPathComponent], in: directory)
        #expect(outcome.status == 0, "\(outcome.output)\(outcome.errors)")
        return Report(log: outcome.output + outcome.errors)
    }

    /// The resting-state lines of a simulation of a closed model.
    ///
    /// Every micro-step that advances the turn ends a ringlet: its instance rests in the
    /// state that the next step shows. The round is counted locally, one round per ringlet
    /// of the last instance, and the trace ends with `halt R<round>` when the arrangement
    /// halts.
    ///
    /// - Parameters:
    ///   - model: The text of the generated model.
    ///   - simulation: The output of `simulate -v`.
    ///   - rounds: The number of rounds to report.
    /// - Returns: The `R` and `halt` lines.
    static func restingLines(model: String, simulation: String, rounds: Int) -> [String] {
        var instances: [(turn: Int, name: String)] = []
        for line in model.split(separator: "\n") {
            guard let range = line.range(of: "(sch.executing_"), let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces)
            let digits = line[range.upperBound...].prefix { $0.isNumber }
            if let turn = Int(digits) { instances.append((turn, name)) }
        }
        let names = instances.sorted { $0.turn < $1.turn }.map(\.name)
        var states: [[String: String]] = []
        for line in simulation.split(separator: "\n") {
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("-> State:") {
                states.append(states.last ?? [:])
            } else if !states.isEmpty, let equals = text.range(of: " = ") {
                states[states.count - 1][String(text[..<equals.lowerBound])] = String(text[equals.upperBound...])
            }
        }
        var lines: [String] = []
        var completed = 0
        for (current, following) in zip(states, states.dropFirst()) where current["advance"] == "TRUE" {
            guard completed < rounds, let turn = current["sch.turn"].flatMap(Int.init), turn < names.count else { break }
            let name = names[turn]
            let resting = following[name + ".pc"] ?? ""
            lines.append("R\(completed + 1) \(unescaped(name)) \(unescaped(resting))")
            if turn == names.count - 1 {
                completed += 1
                if following["halted"] == "TRUE" {
                    lines.append("halt R\(completed)")
                    break
                }
            }
        }
        return lines
    }

    /// A model name without the escape suffix of the smv target.
    static func unescaped(_ name: String) -> String {
        name.hasSuffix(escapeSuffix) ? String(name.dropLast(escapeSuffix.count)) : name
    }
}

/// One model checked by nuXmv, with the parameters it is generated with.
struct KernelVerificationCase: Sendable, CustomTestStringConvertible {
    /// The model.
    let model: KernelTestModel
    /// The template parameters.
    let parameters: [String: String]
    /// Whether an integer variable can leave its range.
    ///
    /// With havocked labels, HostTally may never see its tally reach 6, so the self loop of
    /// Work increments n beyond 9: a state without successors for nuXmv and a violation of
    /// TypeOK for TLC.
    let escapesRange: Bool

    /// Create a verification case.
    ///
    /// - Parameters:
    ///   - model: The model to generate.
    ///   - parameters: The template parameters.
    ///   - escapesRange: Whether an integer variable can leave its range.
    init(model: KernelTestModel, parameters: [String: String], escapesRange: Bool = false) {
        self.model = model
        self.parameters = parameters
        self.escapesRange = escapesRange
    }

    /// The description of the case in test reports.
    var testDescription: String { "\(model)" + (parameters.isEmpty ? "" : " \(parameters.sorted { $0.key < $1.key })") }

    /// The havoc treatment of opaque nodes.
    static let havoc = [KernelTemplateParameter.opaque: KernelOpaqueTreatment.havoc.rawValue]

    /// The models whose generated verification models are checked.
    static let all: [KernelVerificationCase] =
        KernelTestModel.fixtures.filter(\.isStrict).map { KernelVerificationCase(model: $0, parameters: [:]) }
        + [
            KernelVerificationCase(model: .fixture(.opaqueSampler), parameters: havoc),
            KernelVerificationCase(model: .host(.c), parameters: havoc, escapesRange: true)
        ]
}

/// Tests of the smv target with nuXmv or NuSMV.
///
/// The tests that run the model checker are skipped, with a message, when
/// neither `nuXmv` nor `NuSMV` can be found on the search path.
@Suite("Kernel smv target with a model checker")
@MainActor
struct KernelSMVTests {
    /// The models whose simulation is deterministic, so that it reproduces the expected trace.
    static let closedModels: [KernelTestModel] = [.fixture(.turnTakingRelay), .fixture(.schedulerPool)]

    /// Generate the smv model of a model into a scratch directory.
    func generate(_ model: KernelTestModel, _ parameters: [String: String]) async throws -> URL {
        let directory = try await KernelTestSupport.generate(model, .smv, parameters: parameters)
        return directory.appendingPathComponent(model.name).appendingPathExtension("smv")
    }

    /// Simulate a closed model and return its resting-state lines.
    func simulate(_ model: KernelTestModel, parameters: [String: String] = [:]) async throws -> (expected: [String], simulated: [String]) {
        let expected = try KernelTestSupport.expectedTrace(of: model)
        let rounds = try #require(KernelTestSupport.rounds(of: expected))
        let file = try await generate(model, parameters)
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let text = try String(contentsOf: file, encoding: .utf8)
        let instances = text.components(separatedBy: "(sch.executing_").count - 1
        let states = text.components(separatedBy: "\npc : ").count - 1
        let steps = (rounds + 1) * instances * 2 * (states * 4 + 2)
        let report = try KernelModelChecker.run(file, ["pick_state", "simulate -k \(steps) -v"])
        #expect(!report.hasErrors, "\(report.log.suffix(2000))")
        return (KernelTestSupport.restingLines(of: expected),
                KernelModelChecker.restingLines(model: text, simulation: report.log, rounds: rounds))
    }

    /// Verify that the range invariants hold and that only a model that can leave a range has a state without successors.
    ///
    /// - Parameter verification: The model and parameters to check.
    @Test("the range invariants hold, and only a model that can leave a range has a state without successors",
          .enabled(if: KernelModelChecker.executable != nil, "Neither nuXmv nor NuSMV found on the search path; skipping"),
          arguments: KernelVerificationCase.all)
    func invariantsHold(_ verification: KernelVerificationCase) async throws {
        let file = try await generate(verification.model, verification.parameters)
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let text = try String(contentsOf: file, encoding: .utf8)
        let report = try KernelModelChecker.run(file, ["check_invar", "check_fsm"])
        #expect(!report.hasErrors, "\(report.log.suffix(2000))")
        #expect(report.verdicts.count == text.components(separatedBy: "\nINVARSPEC\n").count - 1)
        #expect(report.verdicts.allSatisfy { $0.hasSuffix(" is true") }, "\(report.verdicts)")
        if verification.escapesRange {
            #expect(report.hasDeadlock, "the increment beyond the range is not detected")
            #expect(report.log.contains("counter.n = 9") && report.log.contains("counter.pc = Work"),
                    "\(report.log.suffix(2000))")
        } else {
            #expect(!report.hasDeadlock, "\(report.log.suffix(2000))")
        }
    }

    /// Verify that a deterministic simulation rests in the states of the expected trace.
    ///
    /// - Parameter model: The closed model to simulate.
    @Test("a deterministic simulation rests in the states of the expected trace",
          .enabled(if: KernelModelChecker.executable != nil, "Neither nuXmv nor NuSMV found on the search path; skipping"),
          arguments: closedModels)
    func simulationMatchesTrace(_ model: KernelTestModel) async throws {
        let (expected, simulated) = try await simulate(model)
        #expect(simulated == expected)
    }

    /// Verify that fused entry keeps the resting states of the relay.
    @Test("with entry=fused the relay keeps its resting states, as only a print waits for the next ringlet",
          .enabled(if: KernelModelChecker.executable != nil, "Neither nuXmv nor NuSMV found on the search path; skipping"))
    func fusedEntry() async throws {
        let parameters = [KernelTemplateParameter.entry: KernelEntryMode.fused.rawValue]
        let model = KernelTestModel.fixture(.turnTakingRelay)
        let file = try await generate(model, parameters)
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(!text.contains("next(entered) = TRUE"), "a fused transition leaves the action done")
        let report = try KernelModelChecker.run(file, ["check_invar", "check_fsm"])
        #expect(report.allHold, "\(report.verdicts)")
        #expect(!report.hasDeadlock)
        let (expected, simulated) = try await simulate(model, parameters: parameters)
        #expect(simulated == expected)
    }

    /// Verify that sanity mode lets the relay leave every state except where it saturates.
    @Test("with sanity=true the relay can leave every state except where it saturates",
          .enabled(if: KernelModelChecker.executable != nil, "Neither nuXmv nor NuSMV found on the search path; skipping"))
    func sanityOfRelay() async throws {
        let file = try await generate(.fixture(.turnTakingRelay), [KernelTemplateParameter.sanity: "true"])
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let report = try KernelModelChecker.run(file, ["check_ctlspec"])
        let verdicts = report.verdicts
        #expect(verdicts.count == 18)
        // From round 28 on, leftHand rests in Holding with passes = 9 and rightHand in Waiting.
        let expectedFalse = [
            "-- specification AG (leftHand.pc = Holding -> EF leftHand.pc != Holding)  is false",
            "-- specification AG (rightHand.pc = Waiting -> EF rightHand.pc != Waiting)  is false",
        ]
        #expect(verdicts.filter { $0.hasSuffix(" is false") } == expectedFalse)
    }

    /// Verify that sanity mode makes every state of the scheduler pool reachable and every transition fire.
    @Test("with sanity=true every state of the scheduler pool is reachable and can be left, and every transition fires",
          .enabled(if: KernelModelChecker.executable != nil, "Neither nuXmv nor NuSMV found on the search path; skipping"))
    func sanityOfSchedulerPool() async throws {
        let file = try await generate(.fixture(.schedulerPool), [KernelTemplateParameter.sanity: "true"])
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let report = try KernelModelChecker.run(file, ["check_ctlspec"])
        // Scheduler: 2 states, 2 can be left, 2 transitions; each worker: 2, 2 and 2.
        #expect(report.verdicts.count == 6 + 3 * 6)
        #expect(report.allHold, "\(report.verdicts)")
    }

    /// Verify that the default opaque treatment rejects the opaque nodes of the sampler.
    @Test("opaque=reject, the default, rejects the opaque nodes of OpaqueSampler")
    func opaqueRejected() async throws {
        let generator = KernelTemplateGenerator(metamodel: try await KernelMetamodel())
        let resource = try await KernelTestModel.fixture(.opaqueSampler).resource()
        for parameters in [[:], [KernelTemplateParameter.opaque: KernelOpaqueTreatment.reject.rawValue]] {
            await #expect(throws: KernelTemplateGeneratorError.self) {
                _ = try await generator.render(.smv, resource: resource, parameters: parameters)
            }
            do {
                _ = try await generator.render(.smv, resource: resource, parameters: parameters, validating: false)
                Issue.record("the template accepted opaque nodes")
            } catch KernelTemplateGeneratorError.templateErrors(_, let messages) {
                #expect(messages.count == 3, "\(messages)")
                #expect(messages.allSatisfy { $0.contains("opaque=havoc") })
            }
        }
    }
}
