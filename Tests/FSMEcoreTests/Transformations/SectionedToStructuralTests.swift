//
//  SectionedToStructuralTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

@Suite("Sectioned to structural transformation")
@MainActor
struct SectionedToStructuralTests {
    /// Every example machine and arrangement, with the test resource machine.
    nonisolated static let examples = StructuralToSectionedTests.examples

    /// The output format of an example, which follows the language of its machines.
    private func format(of model: StructuralRoundTrip.Model) throws -> Format {
        try #require(Format(rawValue: StructuralRoundTrip.language(of: model).name))
    }

    /// Run an example through the sectioned level and back.
    ///
    /// - Parameters:
    ///   - example: The example to run.
    ///   - restoresLayouts: Whether the layouts of the original are laid over the result.
    /// - Returns: The original model and the result of the transformation back.
    private func roundTrip(_ example: ParityExample, restoresLayouts: Bool = false) async throws -> (
        original: StructuralRoundTrip.Model, result: TransformationResult
    ) {
        let original = try StructuralRoundTrip.model(of: example)
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await StructuralRoundTrip.xmiResource(of: original)
        let sectioned = try await transformations.structuralToSectioned(source, arrangementName: example.name)
        let result = try await transformations.sectionedToStructural(sectioned.resource)
        if restoresLayouts {
            await transformations.restoreLayouts(into: result.resource, from: source)
        }
        return (original, result)
    }

    /// The files of the original bundle of an example and of its round trip.
    private func files(of example: ParityExample, restoresLayouts: Bool) async throws -> (
        original: [String: Data], back: [String: Data], format: Format
    ) {
        let (original, result) = try await roundTrip(example, restoresLayouts: restoresLayouts)
        let format = try format(of: original)
        let source = try await StructuralRoundTrip.decode(try await StructuralRoundTrip.xmiResource(of: original))
        let originalFiles = try await StructuralRoundTrip.files(of: source, named: example.name, format: format)
        let back = try await StructuralRoundTrip.decode(result.resource)
        return (originalFiles, try await StructuralRoundTrip.files(of: back, named: example.name, format: format), format)
    }

    @Test("with the layouts restored, every bundle comes back byte for byte", arguments: examples)
    func bundleRoundTrip(_ example: ParityExample) async throws {
        let (original, back, format) = try await files(of: example, restoresLayouts: true)
        let parityCase = ParityCase(example: example, format: format, isSuspensible: true)
        TemplateParity.expectIdentical(back, original, case: parityCase)
    }

    @Test("without the layouts restored, only the layout files differ", arguments: examples)
    func bundleRoundTripWithoutLayouts(_ example: ParityExample) async throws {
        let (original, back, format) = try await files(of: example, restoresLayouts: false)
        let expectedModel = try await StructuralRoundTrip.decode(
            try await StructuralRoundTrip.xmiResource(of: StructuralRoundTrip.withoutLayouts(
                try StructuralRoundTrip.model(of: example))))
        let expected = try await StructuralRoundTrip.files(of: expectedModel, named: example.name, format: format)
        let parityCase = ParityCase(example: example, format: format, isSuspensible: true)
        TemplateParity.expectIdentical(back, expected, case: parityCase)
        let differing = Set(original.keys).union(back.keys).filter { back[$0] != original[$0] }
        #expect(differing == Set(original.keys).union(expected.keys).filter { expected[$0] != original[$0] })
        #expect(differing.allSatisfy { StructuralRoundTrip.layoutFiles.contains(($0 as NSString).lastPathComponent) },
                "\(differing.sorted())")
    }

    @Test("only the layouts are reported as lost for every machine", arguments: examples)
    func warnings(_ example: ParityExample) async throws {
        let (original, result) = try await roundTrip(example)
        var machines: [String] = []
        switch original {
        case .machine(let name, _): machines = [name]
        case .arrangement(let arrangement):
            for instance in arrangement.namedInstances where !machines.contains(String(instance.typeName)) {
                machines.append(String(instance.typeName))
            }
        }
        #expect(result.diagnostics.warnings.map(\.kind) == machines.map { .notRecovered(.layout, owner: $0) })
    }

    @Test("the traffic light keeps its names, state order, initial state and timed labels")
    func trafficLight() async throws {
        let example = ParityExample(url: try FSMEcoreTestSupport.trafficLightMachineURL())
        let (original, result) = try await roundTrip(example)
        guard case .machine(let name, let machine) = try await StructuralRoundTrip.decode(result.resource) else {
            Issue.record("The traffic light did not come back as a machine")
            return
        }
        #expect(name == "TrafficLight")
        #expect(machine.language.name == StructuralRoundTrip.language(of: original).name)
        let states = machine.llfsm.states.compactMap(machine.llfsm.stateName(for:))
        #expect(states == ["InitialPseudoState", "Red", "Yellow", "Green", "YellowRed"])
        let labels = machine.llfsm.transitions.compactMap(machine.llfsm.label(for:))
        #expect(labels == ["true", "after(60)", "after(5)", "after(60)", "after(3)"])
    }

    @Test("the counter arrangement keeps its instances, type files and suspend state")
    func counterArrangement() async throws {
        let example = ParityExample(url: TemplateParity.examplesDirectory.appendingPathComponent("Counter2.arrangement"))
        let (_, result) = try await roundTrip(example)
        guard case .arrangement(let arrangement) = try await StructuralRoundTrip.decode(result.resource) else {
            Issue.record("The arrangement did not come back as an arrangement")
            return
        }
        #expect(arrangement.namedInstances.map(\.name) == ["Susp", "Instance1", "Instance2", "Instance3"])
        #expect(arrangement.namedInstances.map(\.typeFile)
            == ["SuspendCounter.machine", "Counter.machine", "Counter.machine", "Counter.machine"])
        let counter = try #require(arrangement.namedInstances.last?.machine)
        #expect(counter.llfsm.suspendState.flatMap(counter.llfsm.stateName(for:)) == "SUSPENDED")
    }

    @Test("a model without a sectioned root is rejected")
    func rejectsOtherModels() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await TransformationTestSupport.structuralResource(
            for: try FSMEcoreTestSupport.trafficLightMachineURL())
        await #expect(throws: LLFSMTransformationError.missingRoot("Arrangement")) {
            try await transformations.sectionedToStructural(source)
        }
    }
}
