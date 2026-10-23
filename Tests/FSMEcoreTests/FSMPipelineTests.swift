//
//  FSMPipelineTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import ModellingGenerators
import Synchronization
import Testing
@testable import FSM
@testable import FSMEcore

/// Tests of the planning and running of conversions between the levels.
@Suite("FSM pipeline")
@MainActor
struct FSMPipelineTests {
    typealias Step = FSMPipeline.Step

    // MARK: - Planning

    @Test("the steps from each level to each kind of target",
          arguments: [
            (LLFSMLevel.structural, OutputTarget?.some(.smv),
             [Step.transform(.structuralToSectioned), .transform(.sectionedToKernel), .generate(.smv)]),
            (.kernel, .some(.dot), [.generate(.dot)]),
            (.sectioned, .some(.kernelC), [.transform(.sectionedToKernel), .generate(.c)]),
            (.structural, .some(.c), [.writeNative(.c)]),
            (.kernel, .some(.objCPP), [.transform(.kernelToStructural), .writeNative(.objCPP)]),
            (.sectioned, nil, [.transform(.sectionedToStructural), .writeNative(nil)]),
            (.structural, nil, [.writeNative(nil)]),
            (.kernel, .some(.xmi), [.save(.xmi)]),
            (.kernel, .some(.json), [.save(.json)]),
            (.structural, .some(.kernelXMI), [.transform(.structuralToSectioned), .transform(.sectionedToKernel), .save(.xmi)]),
            (.kernel, .some(.sectionedXMI), [.transform(.kernelToSectioned), .save(.xmi)]),
          ])
    func plans(_ source: LLFSMLevel, _ target: OutputTarget?, _ expected: [Step]) {
        #expect(FSMPipeline.steps(from: source, to: target, options: FSMPipeline.Options()) == expected)
    }

    @Test("xmi and json are written at the chosen level")
    func chosenLevel() {
        let options = FSMPipeline.Options(level: .kernel)
        #expect(FSMPipeline.steps(from: .structural, to: .xmi, options: options)
            == [.transform(.structuralToSectioned), .transform(.sectionedToKernel), .save(.xmi)])
        #expect(FSMPipeline.steps(from: .sectioned, to: .json, options: options) == [.transform(.sectionedToKernel), .save(.json)])
        #expect(FSMPipeline.steps(from: .structural, to: .structuralXMI, options: options) == [.save(.xmi)])
    }

    @Test("a chosen profile validates the kernel model before a kernel target is generated")
    func profileStep() {
        let options = FSMPipeline.Options(profile: .strict)
        #expect(FSMPipeline.steps(from: .kernel, to: .kernelC, options: options) == [.validate(.strict), .generate(.c)])
        #expect(FSMPipeline.steps(from: .kernel, to: .c, options: options) == [.transform(.kernelToStructural), .writeNative(.c)])
    }

    // MARK: - Names

    @Test("instance and machine names of arrangement inputs")
    func instanceNames() {
        #expect(FSMPipeline.instanceNames(forFileNamed: "Counter.machine") == ("Counter", "Counter.machine"))
        #expect(FSMPipeline.instanceNames(forFileNamed: "Light.scxml") == ("Light", "Light.machine"))
        #expect(FSMPipeline.fileStem(of: URL(fileURLWithPath: "/a/Counter.machine")) == "Counter")
        #expect(FSMPipeline.fileStem(of: URL(fileURLWithPath: "/a/Light.scxml")) == "Light")
        #expect(FSMPipeline.stem(of: URL(fileURLWithPath: "/a/fsm.out"), fallback: "X") == "fsm")
        #expect(FSMPipeline.stem(ofURI: "memory:/kernel.xmi", fallback: "X") == "kernel")
        #expect(FSMPipeline.isModelDocument(URL(fileURLWithPath: "a.XMI")))
        #expect(FSMPipeline.isModelDocument(URL(fileURLWithPath: "a.json")))
        #expect(!FSMPipeline.isModelDocument(URL(fileURLWithPath: "a.machine")))
    }

    @Test("inputs are found with and without the machine suffix")
    func resolvingInputs() throws {
        let url = try FSMEcoreTestSupport.trafficLightMachineURL()
        #expect(try FSMPipeline.resolveInput(url.path) == url)
        let stem = url.deletingPathExtension().path
        #expect(try FSMPipeline.resolveInput(stem).lastPathComponent == url.lastPathComponent)
        #expect(throws: FSMPipelineError.missingInput("/nonexistent/Machine")) {
            try FSMPipeline.resolveInput("/nonexistent/Machine")
        }
    }

    @Test("reports keep each warning once")
    func reportWarnings() {
        var report = FSMPipeline.Report()
        report.warn(["a", "b", "a"])
        report.warn(["b", "c"])
        #expect(report.warnings == ["a", "b", "c"])
        #expect(!report.hasErrors)
    }

    // MARK: - Running

    @Test("documents are read at the level of their root namespace",
          arguments: [(KernelFixture.doorInterlock, LLFSMLevel.kernel), (.sectionedCrossing, .sectioned)])
    func detectsLevels(_ fixture: KernelFixture, _ level: LLFSMLevel) async throws {
        let pipeline = try await FSMPipeline()
        var report = FSMPipeline.Report()
        let url = try #require(fixture.bundledURL)
        let model = try await pipeline.load([url], arrangementName: "Unused", report: &report)
        #expect(model.level == level)
        #expect(report.warnings.isEmpty)
    }

    @Test("a structural document is read as its machine")
    func detectsStructural() async throws {
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "pipeline-structural")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Light.xmi")
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        try await XMIRoundTrip(metamodel: try await LLFSMMetamodel()).write(machine: machine, name: "Light", to: url)
        let pipeline = try await FSMPipeline()
        var report = FSMPipeline.Report()
        let model = try await pipeline.load([url], arrangementName: "Unused", report: &report)
        #expect(model.level == .structural)
        guard case .machine(let name, let decoded) = model.content else {
            Issue.record("expected a machine")
            return
        }
        #expect(name == "Light")
        #expect(decoded.llfsm.stateNames == machine.llfsm.stateNames)
    }

    @Test("structural XMI is written as by the XMI round trip, up to the order of the layouts")
    func structuralXMIMatchesRoundTrip() async throws {
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "pipeline-xmi")
        defer { try? FileManager.default.removeItem(at: directory) }
        let machineURL = try FSMEcoreTestSupport.trafficLightMachineURL()
        let expected = directory.appendingPathComponent("expected/Light.xmi")
        let written = directory.appendingPathComponent("Light.xmi")
        try FileManager.default.createDirectory(at: expected.deletingLastPathComponent(), withIntermediateDirectories: true)
        try await XMIRoundTrip(metamodel: try await LLFSMMetamodel())
            .write(machine: try Machine(from: machineURL), name: "Light", to: expected)
        let pipeline = try await FSMPipeline(options: FSMPipeline.Options(level: .structural))
        let report = try await pipeline.convert([machineURL], to: .xmi, output: written)
        #expect(report.files == [written])
        // The order of the layouts of a machine follows its dictionaries, so the lines are compared as a set.
        let lines = try String(contentsOf: written, encoding: .utf8).split(separator: "\n")
        let reference = try String(contentsOf: expected, encoding: .utf8).split(separator: "\n")
        #expect(lines.prefix(2) == reference.prefix(2))
        #expect(lines.sorted() == reference.sorted())
    }

    @Test("native formats are not yet written from the sectioned and kernel levels",
          arguments: [(KernelFixture.sectionedCrossing, LLFSMLevel.sectioned), (.doorInterlock, .kernel)])
    func nativeFromUpperLevels(_ fixture: KernelFixture, _ level: LLFSMLevel) async throws {
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "pipeline-native")
        defer { try? FileManager.default.removeItem(at: directory) }
        let pipeline = try await FSMPipeline()
        let output = directory.appendingPathComponent("Out.machine")
        await #expect(throws: FSMPipelineError.transformationUnavailable(from: level, to: .structural)) {
            try await pipeline.convert([try #require(fixture.bundledURL)], to: .c, output: output)
        }
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("validation reports the diagnostics of the chosen profile",
          arguments: [(ValidationProfile.strict, true), (.relaxed, false)])
    func validation(_ profile: ValidationProfile, _ hasErrors: Bool) async throws {
        let pipeline = try await FSMPipeline(options: FSMPipeline.Options(profile: profile))
        let report = try await pipeline.validate([try #require(KernelFixture.opaqueSampler.bundledURL)])
        #expect(report.hasErrors == hasErrors)
        #expect(report.diagnostics.contains { $0.rule == .strictProfile } == hasErrors)
    }

    @Test("a validation step stops the run on errors")
    func validationStep() async throws {
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "pipeline-validate")
        defer { try? FileManager.default.removeItem(at: directory) }
        let pipeline = try await FSMPipeline(options: FSMPipeline.Options(profile: .strict))
        let url = try #require(KernelFixture.opaqueSampler.bundledURL)
        do {
            try await pipeline.convert([url], to: .kernelC, output: directory)
            Issue.record("the opaque sampler is not valid under the strict profile")
        } catch FSMPipelineError.invalidModel(let diagnostics) {
            #expect(diagnostics.contains { $0.rule == .strictProfile })
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    @Test("kernel targets are generated with progress reports for every file")
    func generationProgress() async throws {
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "pipeline-progress")
        defer { try? FileManager.default.removeItem(at: directory) }
        let updates = ProgressRecorder()
        let pipeline = try await FSMPipeline(progress: updates.record)
        let report = try await pipeline.convert([try #require(KernelFixture.doorInterlock.bundledURL)], to: .tla, output: directory)
        #expect(report.files.map(\.lastPathComponent).sorted() == ["DoorInterlock.cfg", "DoorInterlock.tla"])
        let finished = updates.updates.filter { $0.total != nil }
        #expect(finished.map(\.completed) == [1, 2])
        #expect(finished.allSatisfy { $0.total == 2 })
    }

    @Test("template settings reach the kernel templates")
    func templateSettings() async throws {
        let url = try #require(KernelFixture.doorInterlock.bundledURL)
        let resourceSet = ResourceSet()
        let metamodels = try await LLFSMMetamodels()
        await metamodels.register(in: resourceSet)
        let resource = try await XMIParser(resourceSet: resourceSet).parse(url)
        let plain = KernelTemplateGenerator(metamodel: metamodels.kernel)
        let parameters = [KernelTemplateParameter.maxRounds: "3"]
        let configured = KernelTemplateGenerator(metamodel: metamodels.kernel, settings: TemplateSettings(parameters: parameters))
        let given = try await plain.render(.smv, resource: resource, parameters: parameters)
        #expect(try await configured.render(.smv, resource: resource) == given)
        #expect(try await plain.render(.smv, resource: resource) != given)
        let overridden = try await configured.render(.smv, resource: resource, parameters: [KernelTemplateParameter.maxRounds: "0"])
        #expect(overridden == (try await plain.render(.smv, resource: resource)))
    }

    @Test("havocking opaque nodes in the settings relaxes the profile of a verification target")
    func havocSettings() async throws {
        let url = try #require(KernelFixture.opaqueSampler.bundledURL)
        let resourceSet = ResourceSet()
        let metamodels = try await LLFSMMetamodels()
        await metamodels.register(in: resourceSet)
        let resource = try await XMIParser(resourceSet: resourceSet).parse(url)
        let settings = TemplateSettings(parameters: [KernelTemplateParameter.opaque: KernelOpaqueTreatment.havoc.rawValue])
        let files = try await KernelTemplateGenerator(metamodel: metamodels.kernel, settings: settings).render(.smv, resource: resource)
        #expect(!files.isEmpty)
    }

    @Test("the bundled templates write the C, Objective-C++ and SCXML formats")
    func templateSupport() {
        #expect(TemplateBinding.supports(.c, arrangements: true))
        #expect(TemplateBinding.supports(.objCPP, arrangements: true))
        #expect(TemplateBinding.supports(.scxml))
        #expect(!TemplateBinding.supports(.scxml, arrangements: true))
        #expect(!TemplateBinding.supports(.swift))
    }
}

/// Collects progress reports for inspection.
final class ProgressRecorder: Sendable {
    /// The reports received so far.
    private let storage = Mutex<[GenerationProgressUpdate]>([])

    /// The reports received so far, in order.
    var updates: [GenerationProgressUpdate] { storage.withLock { $0 } }

    /// Record a report.
    ///
    /// - Parameter update: The report.
    @Sendable func record(_ update: GenerationProgressUpdate) {
        storage.withLock { $0.append(update) }
    }
}
