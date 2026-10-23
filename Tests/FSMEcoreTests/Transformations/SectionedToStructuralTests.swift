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
    private func roundTrip(_ example: ParityExample) async throws -> (
        original: StructuralRoundTrip.Model, result: TransformationResult
    ) {
        let original = try StructuralRoundTrip.model(of: example)
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await StructuralRoundTrip.xmiResource(of: original)
        let sectioned = try await transformations.structuralToSectioned(source, arrangementName: example.name)
        return (original, try await transformations.sectionedToStructural(sectioned.resource))
    }

    @Test("every bundle comes back byte for byte, apart from the documented losses", arguments: examples)
    func bundleRoundTrip(_ example: ParityExample) async throws {
        let (original, result) = try await roundTrip(example)
        let format = try format(of: original)
        let source = try await StructuralRoundTrip.decode(try await StructuralRoundTrip.xmiResource(of: original))
        let originalFiles = try await StructuralRoundTrip.files(of: source, named: example.name, format: format)
        let back = try await StructuralRoundTrip.decode(result.resource)
        let files = try await StructuralRoundTrip.files(of: back, named: example.name, format: format)
        let expectedModel = try await StructuralRoundTrip.decode(
            try await StructuralRoundTrip.xmiResource(of: StructuralRoundTrip.expected(original)))
        let expected = try await StructuralRoundTrip.files(of: expectedModel, named: example.name, format: format)
        let parityCase = ParityCase(example: example, format: format, isSuspensible: true)
        TemplateParity.expectIdentical(files, expected, case: parityCase)
        let differing = Set(originalFiles.keys.filter { files[$0] != originalFiles[$0] })
        #expect(differing == Set(originalFiles.keys.filter { expected[$0] != originalFiles[$0] }))
    }

    @Test("the documented losses are reported for every machine", arguments: examples)
    func warnings(_ example: ParityExample) async throws {
        let (original, result) = try await roundTrip(example)
        var machines: [(String, Machine)] = []
        switch original {
        case .machine(let name, let machine): machines = [(name, machine)]
        case .arrangement(let arrangement):
            for instance in arrangement.namedInstances where !machines.contains(where: { $0.0 == instance.typeName }) {
                machines.append((String(instance.typeName), instance.machine))
            }
        }
        var expected: [TransformationWarning.Kind] = []
        for (name, machine) in machines {
            expected.append(.notRecovered(.includePath, owner: name))
            expected.append(.notRecovered(.layout, owner: name))
            expected.append(.notRecovered(.stateBoilerplate, owner: name))
            let variables = machine.language.extractSections(from: machine.boilerplate)[.variables] ?? ""
            if !VariableDeclarationScanner(language: machine.language.name).scan(variables).declarations.isEmpty {
                expected.append(.notRecovered(.declarationFormatting, owner: name))
            }
        }
        #expect(result.diagnostics.warnings.map(\.kind) == expected)
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
