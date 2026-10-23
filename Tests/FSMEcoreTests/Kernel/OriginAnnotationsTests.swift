//
//  OriginAnnotationsTests.swift
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

/// Tests that origin records are converted, written, read and serialised.
@Suite("Origin annotations")
struct OriginAnnotationsTests {
    @Test("the annotation source and detail keys are fixed")
    func constants() {
        #expect(OriginAnnotations.source == "http://cpslabgu.github.io/llfsm/origin")
        #expect(OriginAnnotations.stateKey == "state")
        #expect(OriginAnnotations.roleKey == "role")
        #expect(OriginAnnotations.transitionKey == "transition")
        #expect(OriginRole.allCases.map(\.rawValue) == [
            "entry", "wait", "internal", "exit", "suspend", "resume", "dispatch", "clock",
        ])
    }

    @Test("records convert to annotation details and back", arguments: [
        OriginRecord(state: "Waiting", role: .exit, transition: 2),
        OriginRecord(state: "Waiting", role: .internal),
        OriginRecord(state: nil, role: .clock),
    ])
    func detailsRoundTrip(_ record: OriginRecord) {
        let details = OriginAnnotations.details(of: record)
        #expect(details[OriginAnnotations.roleKey] == record.role.rawValue)
        #expect(OriginAnnotations.record(fromDetails: details) == record)
    }

    @Test("details without a valid role or with a malformed index describe no record")
    func invalidDetails() {
        #expect(OriginAnnotations.record(fromDetails: [:]) == nil)
        #expect(OriginAnnotations.record(fromDetails: ["role": "sideways"]) == nil)
        #expect(OriginAnnotations.record(fromDetails: ["role": "exit", "transition": "first"]) == nil)
    }

    @Test("an origin is written to, replaced on and removed from a state")
    func writeReadReplaceRemove() async throws {
        let builder = try await KernelModelBuilder.make()
        KernelFixture.turnTakingRelay.build(with: builder)
        let resource = await builder.resource()
        let kernel = builder.kernel
        let state = try #require(builder.objects.values.first {
            $0.eClass.id == kernel.stateClass.id && $0.string(.name) == "Passing"
        })
        #expect(await OriginAnnotations.origin(of: state.id, in: resource) == nil)
        let first = OriginRecord(state: "Holding", role: .exit, transition: 0)
        try await OriginAnnotations.setOrigin(first, on: state.id, in: resource, metamodel: kernel)
        #expect(await OriginAnnotations.origin(of: state.id, in: resource) == first)
        let count = await resource.count()
        let second = OriginRecord(state: "Holding", role: .internal)
        try await OriginAnnotations.setOrigin(second, on: state.id, in: resource, metamodel: kernel)
        #expect(await OriginAnnotations.origin(of: state.id, in: resource) == second)
        #expect(await resource.count() == count)
        try await OriginAnnotations.setOrigin(nil, on: state.id, in: resource, metamodel: kernel)
        #expect(await OriginAnnotations.origin(of: state.id, in: resource) == nil)
        #expect(await resource.count() == count - 1)
        let diagnostics = await KernelValidator(metamodel: kernel).validate(resource)
        #expect(diagnostics.isEmpty)
    }

    @Test("origins survive serialisation, including a zero transition index")
    func originsSerialise() async throws {
        let builder = try await KernelModelBuilder.make()
        KernelFixture.turnTakingRelay.build(with: builder)
        let resource = await builder.resource()
        let kernel = builder.kernel
        let transition = try #require(builder.objects.values.first { $0.eClass.id == kernel.transitionClass.id })
        let record = OriginRecord(state: "Waiting", role: .exit, transition: 0)
        try await OriginAnnotations.setOrigin(record, on: transition.id, in: resource, metamodel: kernel)
        let text = try await KernelFixtureTests.serialise(resource)
        #expect(text.contains("transition=\"0\""))
        let read = try await KernelXMITests.parse(text)
        let index = await KernelModelIndex(resource: read)
        let records = await withTaskGroup(of: OriginRecord?.self) { group in
            for identifier in index.order { group.addTask { await OriginAnnotations.origin(of: identifier, in: read) } }
            var records: [OriginRecord] = []
            for await record in group { if let record { records.append(record) } }
            return records
        }
        #expect(records == [record])
    }

    @Test("only states and transitions carry origins")
    func notAnnotatable() async throws {
        let builder = try await KernelModelBuilder.make()
        KernelFixture.turnTakingRelay.build(with: builder)
        let resource = await builder.resource()
        let kernel = builder.kernel
        let variable = try #require(builder.objects.values.first { $0.eClass.id == kernel.variableClass.id })
        let record = OriginRecord(state: nil, role: .clock)
        await #expect(throws: OriginAnnotationsError.notAnnotatable(className: "Variable")) {
            try await OriginAnnotations.setOrigin(record, on: variable.id, in: resource, metamodel: kernel)
        }
        await #expect(throws: OriginAnnotationsError.objectNotFound) {
            try await OriginAnnotations.setOrigin(record, on: EUUID(), in: resource, metamodel: kernel)
        }
        #expect(!OriginAnnotationsError.objectNotFound.description.isEmpty)
    }

    @Test("the crossing fixture records the origins of its encoded states and transitions")
    func fixtureOrigins() async throws {
        let (_, resource) = try await KernelFixtureTests.load(.crossingController)
        let kernel = try await KernelMetamodel()
        let index = await KernelModelIndex(resource: resource)
        var states: [String: OriginRecord] = [:]
        for identifier in index.order {
            guard let object = index.object(identifier), object.eClass.id == kernel.stateClass.id,
                  let name = object.string(.name) else { continue }
            states[name] = await OriginAnnotations.origin(of: identifier, in: resource)
        }
        #expect(states == [
            "Go": OriginRecord(state: "Go", role: .entry),
            "Go_x0": OriginRecord(state: "Go", role: .exit, transition: 0),
            "Amber": OriginRecord(state: "Amber", role: .entry),
            "Stop": OriginRecord(state: "Stop", role: .entry),
        ])
    }
}
