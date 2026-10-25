//
//  KernelGoldenTests.swift
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

/// One generation run whose output is checked in: a model, a target and its parameters.
struct KernelGoldenCase: Sendable, CustomTestStringConvertible {
    /// The model to generate.
    let model: KernelTestModel
    /// The target to generate.
    let target: KernelTarget
    /// The name of a parameter variant, which selects its own expected directory.
    let variant: String?
    /// The template parameters.
    let parameters: [String: String]

    /// Create a generation run.
    ///
    /// - Parameters:
    ///   - model: The model to generate.
    ///   - target: The target to generate.
    ///   - variant: The name of a parameter variant, if any.
    ///   - parameters: The template parameters.
    init(
        _ model: KernelTestModel,
        _ target: KernelTarget,
        variant: String? = nil,
        parameters: [String: String] = [:]
    ) {
        self.model = model
        self.target = target
        self.variant = variant
        self.parameters = parameters
    }

    /// The directory of the expected files, relative to the expected-output directory.
    var expectedPath: String {
        [target.rawValue + (variant.map { "-" + $0 } ?? ""), model.expectedSubdirectory]
            .compactMap { $0 }.joined(separator: "/")
    }

    /// The description of the run in test reports.
    var testDescription: String { "\(model) \(target.rawValue)" + (variant.map { " " + $0 } ?? "") }

    /// The havoc treatment of opaque nodes.
    static let havoc = [KernelTemplateParameter.opaque: KernelOpaqueTreatment.havoc.rawValue]

    /// Every checked-in generation run.
    static let all: [KernelGoldenCase] = {
        var cases: [KernelGoldenCase] = []
        for model in KernelTestModel.fixtures where model.isStrict {
            cases += KernelTarget.allCases.map { KernelGoldenCase(model, $0) }
        }
        let sampler = KernelTestModel.fixture(.opaqueSampler)
        cases += [
            KernelGoldenCase(sampler, .c),
            KernelGoldenCase(sampler, .dot),
            KernelGoldenCase(sampler, .smv, variant: "havoc", parameters: havoc),
            KernelGoldenCase(sampler, .tla, variant: "havoc", parameters: havoc)
        ]
        for case .host(let host) in KernelTestModel.hosts {
            cases.append(KernelGoldenCase(.host(host), host.target))
        }
        cases += [
            KernelGoldenCase(.host(.c), .smv, variant: "havoc", parameters: havoc),
            KernelGoldenCase(.host(.c), .tla, variant: "havoc", parameters: havoc)
        ]
        let relay = KernelTestModel.fixture(.turnTakingRelay)
        for target in [KernelTarget.smv, .tla] {
            cases += [
                KernelGoldenCase(
                    relay,
                    target,
                    variant: "fused",
                    parameters: [KernelTemplateParameter.entry: KernelEntryMode.fused.rawValue]
                ),
                KernelGoldenCase(relay, target, variant: "sanity", parameters: [KernelTemplateParameter.sanity: "true"]),
                KernelGoldenCase(relay, target, variant: "rounds", parameters: [KernelTemplateParameter.maxRounds: "40"]),
            ]
        }
        return cases
    }()
}

/// Golden tests: generation is deterministic and reproduces the checked-in files.
///
/// Set the environment variable named by ``recordVariable`` to rewrite the
/// expected files in the source tree from the current templates.
@Suite("Kernel template golden files")
@MainActor
struct KernelGoldenTests {
    /// The environment variable that asks the tests to record the expected files.
    static let recordVariable = "FSMECORE_RECORD_KERNEL_GOLDEN"

    /// Verify that generation is deterministic and matches the checked-in files.
    ///
    /// - Parameter golden: The generation run to check.
    @Test("generation is deterministic and matches the expected files", arguments: KernelGoldenCase.all)
    func golden(_ golden: KernelGoldenCase) async throws {
        let generator = KernelTemplateGenerator(metamodel: try await KernelMetamodel())
        let resource = try await golden.model.resource()
        let first = try await generator.render(golden.target, resource: resource, parameters: golden.parameters)
        let second = try await generator.render(golden.target, resource: resource, parameters: golden.parameters)
        #expect(first == second, "generation is not deterministic")
        let relative = KernelTestSupport.expectedDirectory + "/" + golden.expectedPath
        if ProcessInfo.processInfo.environment[Self.recordVariable] != nil {
            let directory = KernelTestSupport.sourceResources().appendingPathComponent(relative, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for file in first {
                try file.content.write(to: directory.appendingPathComponent(file.path), atomically: true, encoding: .utf8)
            }
        }
        let expected = KernelTestSupport.bundledResources.appendingPathComponent(relative, isDirectory: true)
        let names = try FileManager.default.contentsOfDirectory(atPath: expected.path)
            .filter { name in
                name.hasPrefix(golden.model.name + ".")
            }.sorted()
        #expect(names == first.map(\.path))
        for file in first {
            let url = expected.appendingPathComponent(file.path)
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(text == file.content, "\(golden.expectedPath)/\(file.path) differs from the generated file")
        }
    }
}
